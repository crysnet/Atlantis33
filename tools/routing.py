"""Núcleo de rutas de la fase 2: A* sobre la rejilla de costos, perfiles, métricas y puntajes.

Referencia en Python de lo que la app reimplementa en Dart (app/lib/routing/). Los dos deben dar el mismo resultado.
Todos los parámetros salen de config/params.json; los objetivos, de config/objectives.json.

Modelo (resumen; el detalle y los supuestos están en config/params.json):
- Costo de un paso de la celda u a la celda v, con distancia d:
    d * (1 + w_pendiente * (pendiente_v / 25)^2 + w_rugosidad * min(rugosidad_v / 40 cm, 1)
          + w_arena * arena_v + w_tiempo * (t - 1))
  donde t = vmax / v(theta) >= 1 es cuánto más lento que el mejor paso es ese paso, y theta es la pendiente en el
  sentido del paso (sube o baja). Como el multiplicador es >= 1, la distancia en línea recta es una heurística admisible.
- Celdas prohibidas: pendiente por encima del límite del perfil, o sin dato. No se corta esquina junto a una celda prohibida.
- Una salida parte del hábitat, visita objetivos y vuelve al hábitat.
"""
import itertools
import json
import math
import os
from array import array
from heapq import heappop, heappush

import numpy as np

import common

SQRT2 = math.sqrt(2.0)
VECINOS = [(-1, -1, SQRT2), (-1, 0, 1.0), (-1, 1, SQRT2), (0, -1, 1.0), (0, 1, 1.0), (1, -1, SQRT2), (1, 0, 1.0), (1, 1, SQRT2)]


def acotar(x, a=0.0, b=1.0):
    return a if x < a else b if x > b else x


class Modelo:
    """Parámetros del modelo, leídos de config/params.json."""

    def __init__(self, p=None):
        p = p or common.params()
        self.p = p
        r, m, c = p["routing"], p["mobility"], p["consumables"]
        self.celda = float(r["cell_m"])
        self.pend_ref = float(r["slope_exponent_ref_deg"])
        self.rug_ref = float(r["roughness_ref_cm"])
        self.perfiles = r["profiles"]
        self.v0 = m["flat_speed_kmh"] * 1000.0  # m por hora
        self.k = m["tobler_k"]
        self.fmin = m["min_speed_factor"]
        self.max_eva_h = m["max_eva_h"]
        self.gmax = math.exp(self.k * 0.05)
        self.o2_cap = c["o2_capacity_h"]
        self.o2_reserva = c["o2_reserve_min_frac"]
        self.o2_subida = c["o2_uphill_factor"]
        self.o2_parada = c["o2_stop_rate"]
        self.dosis_dia = p["radiation"]["dose_rate_ugy_per_day"]
        self.hz = p["hazard"]
        self.ex = p["success"]
        self.ciencia_con_holgura = bool(r.get("science_keep_comfort", False))
        # "primary": segura y rápida van al objetivo de mayor prioridad; "by_profile": cada una elige el suyo.
        self.destino_segura_rapida = r.get("safe_fast_targets", "primary")
        rv = p["rover"]
        self.rover_v = rv["speed_kmh"] * 1000.0  # m por hora
        self.rover_pend = rv["slope_limit_deg"]
        self.rover_rug = rv["rough_max_cm"]
        self.rover_o2 = rv["o2_rate"]
        self.rover_cambio_h = rv["transfer_min"] / 60.0
        self.apoyo_salida_h = rv["support_dispatch_min"] / 60.0
        pr = p["pair"]
        self.par_sep = float(pr["max_separation_m"])
        self.par_paso_h = pr["sample_min"] / 60.0

    def holgado(self, m):
        """Ruta factible con margen cómodo: los factores de tiempo y de consumibles del puntaje de éxito valen 1."""
        margen_t = (self.max_eva_h - m["total_h"]) / self.max_eva_h
        margen_o2 = m["o2_remaining_frac"] - self.o2_reserva
        return m["feasible"] and margen_t >= self.ex["time_margin_good"] and margen_o2 >= self.ex["o2_margin_good"]

    def factor_velocidad(self, tan):
        g = math.exp(-self.k * (abs(tan + 0.05) - 0.05))
        return g if g > self.fmin else self.fmin


class Rejilla:
    """Rejilla de costos a la resolución de ruteo. Las celdas se indexan en plano: fila * ancho + columna."""

    def __init__(self, modelo, directorio=None):
        d = directorio or common.COSTOS_DIR
        meta = json.load(open(os.path.join(d, "costos.json")))
        w0, h0, c0 = meta["width"], meta["height"], meta["cell_m"]
        comp = meta["components"]
        s = np.fromfile(os.path.join(d, comp["slope"]["file"]), "u1").reshape(h0, w0)
        r = np.fromfile(os.path.join(d, comp["rough"]["file"]), "u1").reshape(h0, w0)
        f = np.fromfile(os.path.join(d, comp["forbidden"]["file"]), "u1").reshape(h0, w0)
        e = np.fromfile(os.path.join(d, comp["elev"]["file"]), "<u2").reshape(h0, w0)
        slope = np.where(s == comp["slope"]["nodata"], np.nan, s * comp["slope"]["unit_deg"]).astype("float64")
        rough = np.where(r == comp["rough"]["nodata"], np.nan, r * comp["rough"]["unit_cm"]).astype("float64")
        z = np.where(e == comp["elev"]["nodata"], np.nan, comp["elev"]["offset_m"] + e * comp["elev"]["unit_m"]).astype("float64")
        forb = f.astype("float64")
        k = int(round(modelo.celda / c0))
        if k > 1:
            slope, rough, z, forb = (common.bloque_medio(a, k) for a in (slope, rough, z, forb))
            forb = (forb >= 0.5).astype("float64")
        self.celda = c0 * k
        self.alto, self.ancho = slope.shape
        malo = ~np.isfinite(slope) | ~np.isfinite(z) | (forb > 0)
        self.prohibida = malo
        self.pend = np.where(malo, 999.0, slope)
        # Pendiente real, sin el 999 que marca las celdas prohibidas. Solo para informes y comparaciones.
        self.pend_real = np.where(np.isfinite(slope), slope, 0.0)
        self.pend_real_l = self.pend_real.ravel().tolist()
        self.rug = np.where(np.isfinite(rough), rough, 0.0)
        self.z = np.where(np.isfinite(z), z, 0.0)
        self.pend_l = self.pend.ravel().tolist()
        self.rug_l = self.rug.ravel().tolist()
        self.z_l = self.z.ravel().tolist()
        self.forb_l = malo.ravel().tolist()
        self.origen_e = meta["origin_easting"]
        self.origen_n = meta["origin_northing"]
        h = meta["habitat"]
        self.habitat = (int(h["row"] // k)) * self.ancho + int(h["col"] // k)

    def celda_de(self, x_m, y_m):
        return int(y_m // self.celda) * self.ancho + int(x_m // self.celda)

    def xy_de(self, idx):
        r, c = divmod(idx, self.ancho)
        return (c + 0.5) * self.celda, (r + 0.5) * self.celda


def astar(rej, mod, perfil, inicio, meta):
    """A* de `inicio` a `meta` (índices planos). Devuelve (costo, [índices]) o None si no hay camino."""
    W, H, cell = rej.ancho, rej.alto, rej.celda
    pend, rug, z, forb = rej.pend_l, rej.rug_l, rej.z_l, rej.forb_l
    lim = perfil["slope_limit_deg"]
    rmax = perfil.get("rough_max_cm", math.inf)  # solo el perfil del vehículo lo trae
    ws, wr, wt = perfil["w_slope"], perfil["w_rough"], perfil["w_time"]
    inv_p2 = 1.0 / (mod.pend_ref * mod.pend_ref)
    inv_r = 1.0 / mod.rug_ref
    k, fmin, gmax = mod.k, mod.fmin, mod.gmax
    if forb[inicio] or pend[inicio] > lim or rug[inicio] > rmax or forb[meta] or pend[meta] > lim or rug[meta] > rmax:
        return None
    mr, mc = divmod(meta, W)
    g = array("d", [math.inf]) * (W * H)
    padre = array("i", [-1]) * (W * H)
    g[inicio] = 0.0
    ir, ic = divmod(inicio, W)
    dr0, dc0 = abs(ir - mr), abs(ic - mc)
    heap = [(cell * (max(dr0, dc0) + (SQRT2 - 1.0) * min(dr0, dc0)), 0.0, inicio)]
    exp = math.exp
    while heap:
        _, gu, u = heappop(heap)
        if gu > g[u]:
            continue
        if u == meta:
            break
        r, c = divmod(u, W)
        zu = z[u]
        for dr, dc, dist in VECINOS:
            rr, cc = r + dr, c + dc
            if rr < 0 or rr >= H or cc < 0 or cc >= W:
                continue
            v = rr * W + cc
            if forb[v] or pend[v] > lim or rug[v] > rmax:
                continue
            if dr and dc:
                a, b = u + dr * W, u + dc
                if forb[a] or pend[a] > lim or rug[a] > rmax or forb[b] or pend[b] > lim or rug[b] > rmax:
                    continue
            d = cell * dist
            gt = exp(-k * (abs((z[v] - zu) / d + 0.05) - 0.05))
            if gt < fmin:
                gt = fmin
            s = pend[v]
            ro = rug[v] * inv_r
            if ro > 1.0:
                ro = 1.0
            ng = gu + d * (1.0 + ws * s * s * inv_p2 + wr * ro + wt * (gmax / gt - 1.0))
            if ng < g[v]:
                g[v] = ng
                padre[v] = u
                da, db = abs(rr - mr), abs(cc - mc)
                heappush(heap, (ng + cell * (max(da, db) + (SQRT2 - 1.0) * min(da, db)), ng, v))
    if g[meta] == math.inf:
        return None
    camino = [meta]
    while camino[-1] != inicio:
        camino.append(padre[camino[-1]])
    camino.reverse()
    return g[meta], camino


def corredores_rover(rej, mod, celdas):
    """(a, b): el rover puede recorrer los pasos 1..a (tramo inicial) y b+1..n-1 (tramo final) de la ruta.

    Un paso es transitable si la celda no está prohibida y su pendiente y rugosidad no pasan los límites del rover.
    Si la primera celda (el hábitat) no es transitable devuelve (None, None).
    """
    n = len(celdas)
    ok = [(not rej.forb_l[c]) and rej.pend_real_l[c] <= mod.rover_pend and rej.rug_l[c] <= mod.rover_rug for c in celdas]
    if not ok[0]:
        return None, None
    a = 0
    while a + 1 < n and ok[a + 1]:
        a += 1
    b = n - 1
    while b - 1 >= 0 and ok[b - 1]:
        b -= 1
    return a, b


def tramos_rover(rej, mod, celdas, paradas):
    """Dónde usa el rover una ruta de ida y vuelta, o None si no lo usa.

    Regla: el rover se deja en un punto de aparcamiento P. Va de ida por el tramo inicial transitable (celdas con
    pendiente y rugosidad dentro de los límites del rover) hasta P. El resto de la ida y las paradas son a pie. En la
    vuelta, el astronauta vuelve a pie hasta P (la ruta de regreso tiene que pasar por esa celda), sube al rover y lo
    maneja hasta el hábitat por el tramo final transitable. P es la celda más lejana del tramo inicial que cumple eso.
    Devuelve (k, j): el rover va en los pasos 1..k y en los pasos j+1..n-1.
    """
    n = len(celdas)
    if n < 3:
        return None
    a, b = corredores_rover(rej, mod, celdas)
    if a is None:
        return None
    s_ult = max(paradas) if paradas else n // 2
    donde = {}
    for i, c in enumerate(celdas):
        donde.setdefault(c, []).append(i)
    for k in range(a, 0, -1):
        js = [j for j in donde[celdas[k]] if j > s_ult and j >= b]
        if js:
            return k, min(js)
    return None


def pasos_rover_objetivos(rej, mod, celdas, paradas, transportes):
    """Qué pasos de una ruta se hacen en vehículo cuando cada objetivo trae su transporte.

    `paradas`: {posición en celdas: horas}. `transportes`: [(id, "foot" | "vehicle" | "hybrid")] en orden de visita.
    Devuelve (pasos, notas, varado): `pasos` es el conjunto de pasos (1..n-1) hechos en vehículo, `notas` una lista de
    {"id", "reason"} y `varado` es verdadero si el vehículo se queda sin recoger (la ruta no es factible).

    Reglas (supuestos del equipo): hay un solo vehículo, que sale del hábitat con el astronauta. Un paso es transitable
    para el vehículo con los mismos límites del rover (pendiente, rugosidad, sin celdas prohibidas).
    - Un objetivo "foot" se hace a pie; si el astronauta se aleja del vehículo, este se queda donde está.
    - "vehicle": el astronauta se sube al vehículo donde este esté (si la ruta pasa por esa celda) y va hasta el
      objetivo. Si el tramo no es transitable entero, se avisa (`vehicle_partial`) y se trata como "hybrid".
    - "hybrid": va en vehículo por el tramo transitable y deja el vehículo en la celda más lejana desde la que se pueda
      recogerlo al final (la ruta de regreso pasa por esa celda y desde ahí es transitable hasta el hábitat); el resto
      del tramo, a pie. Es el caso A -> A.1 en vehículo y A.1 -> B a pie.
    - Si el vehículo no está en el tramo (`rover_not_here`), no puede salir (`rover_cannot_start`), no avanza
      (`rover_blocked`) o no hay dónde recogerlo (`no_recovery`), el objetivo se hace a pie con aviso.
    - Al final, si el vehículo no está en el hábitat, el astronauta lo recoge en la primera celda de la ruta de regreso
      donde esté y de ahí es transitable hasta el hábitat. Si no puede, `varado` (`rover_stranded`).
    """
    n = len(celdas)
    ok = [(not rej.forb_l[c]) and rej.pend_real_l[c] <= mod.rover_pend and rej.rug_l[c] <= mod.rover_rug for c in celdas]
    suf = [True] * n  # suf[j]: los pasos j+1..n-1 son todos transitables
    for j in range(n - 2, -1, -1):
        suf[j] = suf[j + 1] and ok[j + 1]
    donde = {}
    for i, c in enumerate(celdas):
        donde.setdefault(c, []).append(i)

    def recuperable(x, b):
        return any(j > b and suf[j] for j in donde[celdas[x]])

    pos = sorted(paradas)
    tramos = []
    prev = 0
    for p, (id_, t) in zip(pos, transportes):
        tramos.append((prev, p, t, id_))
        prev = p
    rover_celda = celdas[0]
    pasos, notas = set(), []
    for a, b, t, id_ in tramos:
        if t == "foot":
            continue
        i = next((x for x in range(a, b + 1) if celdas[x] == rover_celda), None)
        if i is None:
            notas.append({"id": id_, "reason": "rover_not_here"})
            continue
        if not ok[i]:
            notas.append({"id": id_, "reason": "rover_cannot_start"})
            continue
        m = i
        while m + 1 <= b and ok[m + 1]:
            m += 1
        if m == i:
            notas.append({"id": id_, "reason": "rover_blocked"})
            continue
        if t == "vehicle" and m < b:
            notas.append({"id": id_, "reason": "vehicle_partial"})
            t = "hybrid"
        k = None
        for x in range(m, i, -1):
            if x == b or recuperable(x, b):
                k = x
                break
        if k is None:
            notas.append({"id": id_, "reason": "no_recovery"})
            continue
        pasos.update(range(i + 1, k + 1))
        rover_celda = celdas[k]
    varado = False
    if rover_celda != celdas[-1]:
        a_f = pos[-1] if pos else 0
        i = next((x for x in range(a_f, n) if celdas[x] == rover_celda and suf[x]), None)
        if i is None:
            varado = True
            notas.append({"id": None, "reason": "rover_stranded"})
        else:
            pasos.update(range(i + 1, n))
    return pasos, notas, varado


def evaluar(rej, mod, celdas, paradas, rover=None, apoyo=False, pasos_rover=None, modo=None, rover_ok=True):
    """Métricas de una ruta. `celdas`: índices planos del camino completo. `paradas`: {posición en celdas: horas de trabajo}.

    `rover`: None (a pie) o (k, j) de `tramos_rover`. En los tramos con rover la velocidad es constante, el oxígeno
    se gasta a `rover_o2` del ritmo nominal sin recargo por subida, y bajar y subir del rover cuesta `rover_cambio_h`.

    `apoyo`: un rover espera en el hábitat y sale ante una emergencia (`apoyo_salida_h` después del aviso). No cambia la
    marcha ni el tiempo de la ruta. Cambia el tiempo de regreso en una emergencia, el punto de no retorno y el radio
    que cuenta en el peligro. Ver `emergencia_apoyo`.

    `pasos_rover`: alternativa a `rover` para el modo por objetivo. Conjunto de pasos (1..n-1) hechos en vehículo, de
    `pasos_rover_objetivos`. Bajar y subir del vehículo cuesta `rover_cambio_h` cada vez, salvo al salir del hábitat y al
    llegar a él. `modo` cambia la etiqueta `mode` y `rover_ok` falso (vehículo varado) vuelve infactible la ruta.
    """
    if rover is not None:
        paradas = dict(paradas)
        for i in rover:
            paradas[i] = paradas.get(i, 0.0) + mod.rover_cambio_h
    elif pasos_rover:
        paradas = dict(paradas)
        n_ = len(celdas)
        paradas0 = set(paradas)
        for p in range(n_):
            ent, sal = p in pasos_rover, (p + 1) in pasos_rover
            baja = ent and p < n_ - 1 and (not sal or p in paradas0)
            sube = sal and p > 0 and (not ent or p in paradas0)
            for _ in range(int(baja) + int(sube)):
                paradas[p] = paradas.get(p, 0.0) + mod.rover_cambio_h
    W, cell, v0 = rej.ancho, rej.celda, mod.v0
    z, pend, rug = rej.z_l, rej.pend_l, rej.rug_l
    p = mod.p
    s_nom, s_cau, s_lim = p["slope"]["nominal_max_deg"], p["slope"]["caution_max_deg"], p["slope"]["forbidden_above_deg"]
    n = len(celdas)
    t_cum = [0.0] * n
    ret_cum = [0.0] * n
    dist = marcha = parada_h = subida = bajada = o2 = 0.0
    m_nom = m_cau = m_alta = 0.0
    max_pend = pend[celdas[0]]
    rug_acum = 0.0
    xs0, ys0 = rej.xy_de(rej.habitat)
    radio_max = 0.0
    dist_cum = [0.0] * n
    rover_m = rover_h = 0.0
    w_cum = [0.0] * n  # solo marcha, sin paradas
    rad = [0.0] * n  # distancia en línea recta al hábitat
    for i in range(1, n):
        u, v = celdas[i - 1], celdas[i]
        diag = (v // W != u // W) and (v % W != u % W)
        d = cell * (SQRT2 if diag else 1.0)
        dz = z[v] - z[u]
        tan = dz / d
        en_rover = (i <= rover[0] or i > rover[1]) if rover is not None else (pasos_rover is not None and i in pasos_rover)
        if en_rover:
            dt = dt_ret = d / mod.rover_v
            o2 += dt * mod.rover_o2 / mod.o2_cap
            rover_m += d
            rover_h += dt
        else:
            dt = d / (v0 * mod.factor_velocidad(tan))
            dt_ret = d / (v0 * mod.factor_velocidad(-tan))
            o2 += dt * (1.0 + mod.o2_subida * max(0.0, tan)) / mod.o2_cap
        marcha += dt
        dist += d
        if dz > 0:
            subida += dz
        else:
            bajada -= dz
        s = pend[v]
        max_pend = max(max_pend, s)
        if s < s_nom:
            m_nom += d
        elif s < s_cau:
            m_cau += d
        else:
            m_alta += d
        rug_acum += min(rug[v] / mod.rug_ref, 1.0)
        x, y = rej.xy_de(v)
        radio_max = max(radio_max, math.hypot(x - xs0, y - ys0))
        t_cum[i] = t_cum[i - 1] + dt
        w_cum[i] = w_cum[i - 1] + dt
        rad[i] = math.hypot(x - xs0, y - ys0)
        ret_cum[i] = ret_cum[i - 1] + dt_ret
        dist_cum[i] = dist
        if i in paradas:
            h = paradas[i]
            parada_h += h
            o2 += h * mod.o2_parada / mod.o2_cap
            t_cum[i] += h
    total = marcha + parada_h
    # punto de no retorno: primer punto desde el que terminar cuesta menos que deshacer el camino andado.
    emerg = None
    ret_ef = ret_cum
    if apoyo:
        emerg, ret_ef = emergencia_apoyo(rej, mod, celdas, w_cum, ret_cum, dist_cum)
        # el radio que cuenta en el peligro se reduce en la proporción en que el rover acorta el regreso
        radio_max = max(rad[i] * (emerg["con"][i] / emerg["a_pie"][i] if emerg["a_pie"][i] > 0 else 1.0) for i in range(n))
    pnr = n - 1
    for i in range(n):
        if total - t_cum[i] <= ret_ef[i]:
            pnr = i
            break
    px, py = rej.xy_de(celdas[pnr])
    dosis = mod.dosis_dia * total / 24.0
    return {
        "distance_m": dist,
        "mode": modo or ("support" if apoyo else ("foot" if rover is None else "rover")),
        "emergency_max_h": max(emerg["con"]) if emerg else None,
        "emergency_max_foot_h": max(emerg["a_pie"]) if emerg else None,
        "rover_m": rover_m,
        "rover_h": rover_h,
        "walk_h": marcha,
        "stop_h": parada_h,
        "total_h": total,
        "max_slope_deg": max_pend,
        "m_nominal": m_nom,
        "m_caution": m_cau,
        "m_high_caution": m_alta,
        "ascent_m": subida,
        "descent_m": bajada,
        "o2_used_frac": o2,
        "o2_remaining_frac": 1.0 - o2,
        "dose_ugy": dosis,
        "max_radius_m": radio_max,
        "rough_mean_norm": rug_acum / max(1, n - 1),
        "no_return": {"index": pnr, "x_m": px, "y_m": py, "along_m": dist_cum[pnr], "from_habitat_m": math.hypot(px - xs0, py - ys0)},
        "time_ok": total <= mod.max_eva_h,
        "o2_ok": (1.0 - o2) >= mod.o2_reserva,
        "rover_ok": rover_ok,
        "feasible": total <= mod.max_eva_h and (1.0 - o2) >= mod.o2_reserva and rover_ok,
    }


def emergencia_apoyo(rej, mod, celdas, w_cum, ret_cum, dist_cum):
    """Tiempo para llegar al hábitat si hay una emergencia en cada punto de la ruta, con un rover de apoyo.

    A pie, el astronauta elige lo más corto entre deshacer lo andado (`ret_cum`) y seguir hasta el final de la ruta.
    Con el rover, que sale del hábitat `apoyo_salida_h` después del aviso y solo anda por los tramos transitables, el
    astronauta camina hacia el rover y se encuentran en un punto m de la ruta (se prueban todos y se toma el mejor):
      - deshacer: m entre 1 y el último punto transitable del tramo inicial que no pasa de i; el rover llega por ese
        tramo y vuelven en rover hasta el hábitat.
      - seguir: m en el tramo final transitable, a partir de i; el rover llega en sentido contrario y vuelven en rover.
    Cada opción espera a que lleguen los dos y añade el cambio de subir al rover. Devuelve ({"a_pie": [h], "con": [h]},
    ret_ef) donde `ret_ef[i]` es el costo de deshacer con rover (o a pie si no mejora), que usa el punto de no retorno.
    """
    n = len(celdas)
    a, b = corredores_rover(rej, mod, celdas)
    v, cam, sal = mod.rover_v, mod.rover_cambio_h, mod.apoyo_salida_h
    a_pie, con, ret_ef = [0.0] * n, [0.0] * n, [0.0] * n
    for i in range(n):
        seguir = w_cum[n - 1] - w_cum[i]
        a_pie[i] = min(ret_cum[i], seguir)
        mejor = a_pie[i]
        ret_ef[i] = ret_cum[i]
        if a is not None:
            for m in range(1, min(i, a) + 1):
                tr = dist_cum[m] / v
                t = max(ret_cum[i] - ret_cum[m], sal + tr) + tr + cam
                if t < ret_ef[i]:
                    ret_ef[i] = t
                if t < mejor:
                    mejor = t
            for m in range(max(i, b), n - 1):
                tr = (dist_cum[n - 1] - dist_cum[m]) / v
                t = max(w_cum[m] - w_cum[i], sal + tr) + tr + cam
                if t < mejor:
                    mejor = t
        con[i] = mejor
    return {"a_pie": a_pie, "con": con}, ret_ef


def llegadas(rej, mod, celdas, paradas):
    """Hora de llegada a cada celda de una ruta a pie y hora en que se sale de ella (con el trabajo de la parada).

    Mismo paso que `evaluar`: `llegada[i]` es cuando se llega a la celda i; `salida[i] = llegada[i] + horas de trabajo`.
    """
    W, cell = rej.ancho, rej.celda
    z = rej.z_l
    n = len(celdas)
    lle, sal = [0.0] * n, [0.0] * n
    sal[0] = paradas.get(0, 0.0)
    for i in range(1, n):
        u, v = celdas[i - 1], celdas[i]
        diag = (v // W != u // W) and (v % W != u % W)
        d = cell * (SQRT2 if diag else 1.0)
        tan = (z[v] - z[u]) / d
        lle[i] = sal[i - 1] + d / (mod.v0 * mod.factor_velocidad(tan))
        sal[i] = lle[i] + paradas.get(i, 0.0)
    return lle, sal


def posiciones(rej, mod, celdas, paradas):
    """Posición (x, y) en metros de un astronauta cada `par_paso_h` horas durante la salida. Al terminar espera en el hábitat."""
    lle, _ = llegadas(rej, mod, celdas, paradas)
    n_m = int(round(mod.max_eva_h / mod.par_paso_h)) + 1
    out, i = [], 0
    for k in range(n_m):
        t = k * mod.par_paso_h
        while i + 1 < len(celdas) and lle[i + 1] <= t:
            i += 1
        out.append(rej.xy_de(celdas[i]))
    return out


def separacion_max(pa, pb):
    """Mayor distancia en línea recta, en metros, entre dos astronautas a lo largo de la salida."""
    return max(math.hypot(a[0] - b[0], a[1] - b[1]) for a, b in zip(pa, pb))


def puntajes(m, pri_visitada, pri_total, mod):
    """Puntaje de peligro (0 a 100) y de éxito (0 a 100) con su desglose."""
    hz, ex = mod.hz, mod.ex
    w = hz["weights"]
    expo = (hz["slope_caution_weight"] * m["m_caution"] + hz["slope_high_weight"] * (m["m_high_caution"])) / hz["slope_exposure_ref_m"]
    r_wb = hz["walkback_max_h"] * mod.v0
    margen_t = (mod.max_eva_h - m["total_h"]) / mod.max_eva_h
    margen_o2 = m["o2_remaining_frac"] - mod.o2_reserva
    comp = {
        "slope": acotar(expo),
        "terrain": acotar(m["rough_mean_norm"]),
        "walkback": acotar((m["max_radius_m"] - r_wb) / r_wb),
        "consumables": acotar(max(1.0 - margen_o2 / hz["consumables_margin_good"], 1.0 - margen_t / hz["time_margin_good"])),
        "radiation": acotar(m["dose_ugy"] / (mod.dosis_dia * mod.max_eva_h / 24.0)),
        "day": acotar(hz["day_conditions_component"]),
    }
    peligro = sum(w[k] * comp[k] for k in comp)
    valor = pri_visitada / pri_total if pri_total else 0.0
    f_t = acotar(margen_t / ex["time_margin_good"])
    f_o = acotar(margen_o2 / ex["o2_margin_good"])
    exito = 100.0 * valor * f_t * f_o * (1.0 - peligro / 200.0)
    return {
        "hazard": {"score": peligro, "components": comp, "weights": w},
        "success": {"score": exito, "science_value": valor, "time_factor": f_t, "consumables_factor": f_o, "hazard_penalty": 1.0 - peligro / 200.0},
    }


class Planificador:
    """Calcula las tres rutas de una salida. Guarda en memoria los tramos ya calculados."""

    def __init__(self, rej, mod, objetivos, modo="foot"):
        self.rej, self.mod = rej, mod
        # "foot" (a pie), "rover" (con rover), "support" (a pie con rover de apoyo en el hábitat) u
        # "objetivo" (cada objetivo trae su transporte: a pie, vehículo o híbrido)
        self.modo = modo
        self.obj = []
        for o in objetivos:
            idx = rej.celda_de(o["x_m"], o["y_m"])
            self.obj.append(dict(o, idx=idx, bloqueado=bool(rej.forb_l[idx]), transport=o.get("transport", "foot")))
        self.por_id = {o["id"]: o for o in self.obj}
        self.tramos = {}
        self.pri_total = float(sum(o["priority"] for o in self.obj))
        self.busquedas = 0

    def tramo(self, perfil, a, b, veh=False):
        """Mejor camino de a a b. Con `veh`, solo por celdas que el vehículo puede recorrer (límites del rover)."""
        clave = (perfil, a, b, veh)
        if clave not in self.tramos:
            self.busquedas += 1
            pf = self.mod.perfiles[perfil]
            if veh:
                pf = dict(pf, slope_limit_deg=min(pf["slope_limit_deg"], self.mod.rover_pend), rough_max_cm=self.mod.rover_rug)
            self.tramos[clave] = astar(self.rej, self.mod, pf, a, b)
        return self.tramos[clave]

    def _veh(self, id_):
        """En el modo por objetivo, el tramo hacia este objetivo se busca por celdas transitables para el vehículo."""
        return self.modo == "objetivo" and id_ is not None and self.por_id[id_]["transport"] == "vehicle"

    def armar(self, perfil, orden):
        """Ruta hábitat -> objetivos en `orden` -> hábitat. Devuelve (costo, celdas, paradas) o None."""
        hab = self.rej.habitat
        puntos = [hab] + [self.por_id[i]["idx"] for i in orden] + [hab]
        celdas, paradas, costo = [hab], {}, 0.0
        for k in range(len(puntos) - 1):
            # El regreso al hábitat va en vehículo si el último objetivo se hizo en vehículo (el vehículo está ahí).
            veh = self._veh(orden[k] if k < len(orden) else (orden[-1] if orden else None))
            t = self.tramo(perfil, puntos[k], puntos[k + 1], veh)
            if t is None and veh:
                # sin camino transitable para el vehículo: se busca a pie y `pasos_rover_objetivos` lo avisa
                t = self.tramo(perfil, puntos[k], puntos[k + 1])
            if t is None:
                return None
            costo += t[0]
            celdas.extend(t[1][1:])
            if 1 <= k + 1 <= len(orden):
                paradas[len(celdas) - 1] = self.por_id[orden[k]]["work_min"] / 60.0
        return costo, celdas, paradas

    def mejor_orden(self, perfil, ids):
        """Mejor orden de visita de `ids`: fuerza bruta hasta 6 objetivos; vecino más cercano si son más."""
        hab = self.rej.habitat
        if len(ids) > 6:
            orden, actual, resto = [], hab, list(ids)
            while resto:
                def c(i):
                    t = self.tramo(perfil, actual, self.por_id[i]["idx"], self._veh(i))
                    return t[0] if t else math.inf
                nxt = min(resto, key=c)
                orden.append(nxt)
                resto.remove(nxt)
                actual = self.por_id[nxt]["idx"]
            return [orden]
        cands = []
        for perm in itertools.permutations(ids):
            r = self.armar(perfil, list(perm))
            if r is not None:
                cands.append((r[0], list(perm)))
        cands.sort(key=lambda t: t[0])
        return [o for _, o in cands]

    def ruta(self, perfil, ids):
        """Mejor ruta factible que visita todos los `ids`, o la de menor costo marcada como no factible."""
        mejor = None
        for orden in self.mejor_orden(perfil, ids):
            armada = self.armar(perfil, orden)
            if armada is None:
                continue
            costo, celdas, paradas = armada
            m = self.evaluar(celdas, paradas, orden)
            if mejor is None:
                mejor = (costo, orden, celdas, m, paradas)
            if m["feasible"]:
                return costo, orden, celdas, m, paradas
        return mejor

    def evaluar(self, celdas, paradas, orden=None):
        """Métricas de una ruta en el modo del planificador (a pie, con rover, con rover de apoyo o por objetivo)."""
        if self.modo == "objetivo":
            transportes = [(i, self.por_id[i]["transport"]) for i in (orden or [])]
            pasos, notas, varado = pasos_rover_objetivos(self.rej, self.mod, celdas, paradas, transportes)
            m = evaluar(self.rej, self.mod, celdas, paradas, pasos_rover=pasos, modo="objective", rover_ok=not varado)
            m["_notas"] = notas  # solo para `resultado`, que lo saca de las métricas
            return m
        rover = tramos_rover(self.rej, self.mod, celdas, paradas) if self.modo == "rover" else None
        return evaluar(self.rej, self.mod, celdas, paradas, rover, apoyo=self.modo == "support")

    def resultado(self, perfil, costo, orden, celdas, m, omitidos):
        pri = float(sum(self.por_id[i]["priority"] for i in orden))
        notas = m.pop("_notas", None)
        extra = {"transport": {"objectives": {i: self.por_id[i]["transport"] for i in orden}, "notes": notas}} if notas is not None else {}
        return {
            **extra,
            "profile": perfil,
            "status": "ok" if m["feasible"] else "not_feasible",
            "visited": orden,
            "skipped": omitidos,
            "weighted_cost": costo,
            "cells": [[c % self.rej.ancho, c // self.rej.ancho] for c in celdas],
            "metrics": m,
            **puntajes(m, pri, self.pri_total, self.mod),
        }

    def principal(self, perfil):
        """Segura y rápida: van al objetivo de mayor prioridad y vuelven."""
        libres = [o for o in self.obj if not o["bloqueado"]]
        if not libres:
            return {"profile": perfil, "status": "no_target", "visited": [], "skipped": [], "cells": []}
        o = sorted(libres, key=lambda o: (-o["priority"], o["id"]))[0]
        r = self.ruta(perfil, [o["id"]])
        if self.mod.destino_segura_rapida == "by_profile" and perfil in ("safe", "fast"):
            o, r = self.elegir_destino(perfil, libres) or (o, r)
        omit = [{"id": x["id"], "reason": "blocked" if x["bloqueado"] else "not_primary"} for x in self.obj if x["id"] != o["id"]]
        if r is None:
            return {"profile": perfil, "status": "unreachable", "visited": [], "skipped": omit + [{"id": o["id"], "reason": "unreachable"}], "cells": []}
        return self.resultado(perfil, r[0], r[1], r[2], r[3], omit)

    def elegir_destino(self, perfil, libres):
        """Con `safe_fast_targets: by_profile`, la segura y la rápida eligen entre los objetivos alcanzables.

        Solo cuentan los objetivos con al menos el 60 % de la prioridad máxima (para que ninguna ruta se vaya al más
        cercano de poco valor). Entre ellos: la segura toma el de menor puntaje de peligro y la rápida el que más
        prioridad da por hora (prioridad / horas de la salida). Desempate: mayor prioridad, id.
        Las factibles van antes que las no factibles.
        Devuelve (objetivo, ruta) o None si ninguno es alcanzable.
        """
        mejor = None
        tope = max(o["priority"] for o in libres)
        for o in libres:
            if o["priority"] < 0.6 * tope:
                continue
            r = self.ruta(perfil, [o["id"]])
            if r is None:
                continue
            m = r[3]
            pri = float(o["priority"])
            if perfil == "safe":
                valor = -puntajes(m, pri, self.pri_total, self.mod)["hazard"]["score"]
            else:
                valor = pri / m["total_h"] if m["total_h"] > 0 else 0.0
            clave = (not m["feasible"], -valor, -o["priority"], o["id"])
            if mejor is None or clave < mejor[0]:
                mejor = (clave, o, r)
        return None if mejor is None else (mejor[1], mejor[2])

    def ciencia(self, perfil="science"):
        """Ciencia: añade objetivos por prioridad mientras la salida siga siendo factible.

        Con `science_keep_comfort`, solo el primer objetivo exige factibilidad; los siguientes exigen además margen
        cómodo (ver `Modelo.holgado`). Así la ruta no agota el tiempo y el oxígeno, que hundiría su puntaje de éxito.
        """
        elegidos, omit = [], []
        for o in sorted(self.obj, key=lambda o: (-o["priority"], o["id"])):
            if o["bloqueado"]:
                omit.append({"id": o["id"], "reason": "blocked"})
                continue
            r = self.ruta(perfil, elegidos + [o["id"]])
            exige_holgura = self.mod.ciencia_con_holgura and bool(elegidos)
            if r is None:
                omit.append({"id": o["id"], "reason": "unreachable"})
            elif not r[3]["feasible"]:
                omit.append({"id": o["id"], "reason": "time" if not r[3]["time_ok"] else ("oxygen" if not r[3]["o2_ok"] else "rover")})
            elif exige_holgura and not self.mod.holgado(r[3]):
                omit.append({"id": o["id"], "reason": "margin"})
            else:
                elegidos.append(o["id"])
        if not elegidos:
            return {"profile": perfil, "status": "no_target", "visited": [], "skipped": omit, "cells": []}
        r = self.ruta(perfil, elegidos)
        return self.resultado(perfil, r[0], r[1], r[2], r[3], omit)

    def pareja(self, perfil="science"):
        """Dos astronautas salen juntos y se reparten los objetivos, siempre a menos de `par_sep` metros uno del otro.

        Prueba todos los pares de subconjuntos no vacíos de objetivos (un objetivo puede ir en los dos). Cada ruta debe
        ser factible, y con más de un objetivo, con margen cómodo (la regla de la ruta de ciencia). La separación se
        comprueba cada `par_paso_h` horas. Gana la pareja de mayor puntaje de éxito; empata el menor tiempo.
        Devuelve {"mode": "pair", "assignments", "routes": {"pair1", "pair2"}, "pair": {...}}.
        """
        libres = [o["id"] for o in sorted(self.obj, key=lambda o: (-o["priority"], o["id"])) if not o["bloqueado"]]
        k = len(libres)
        validas = {}  # máscara -> (costo, orden, celdas, m, posiciones)
        for mask in range(1, 1 << k):
            ids = [libres[i] for i in range(k) if mask >> i & 1]
            r = self.ruta(perfil, ids)
            if r is None or not r[3]["feasible"] or (len(ids) > 1 and not self.mod.holgado(r[3])):
                continue
            costo, orden, celdas, m, paradas = r
            validas[mask] = (costo, orden, celdas, m, posiciones(self.rej, self.mod, celdas, paradas))
        mejor = None
        masks = sorted(validas)
        for ia, ma in enumerate(masks):
            for mb in masks[ia:]:
                sep = separacion_max(validas[ma][4], validas[mb][4])
                if sep > self.mod.par_sep:
                    continue
                visitadas = set(validas[ma][1]) | set(validas[mb][1])
                pri = float(sum(self.por_id[i]["priority"] for i in visitadas))
                pa = puntajes(validas[ma][3], float(sum(self.por_id[i]["priority"] for i in validas[ma][1])), self.pri_total, self.mod)
                pb = puntajes(validas[mb][3], float(sum(self.por_id[i]["priority"] for i in validas[mb][1])), self.pri_total, self.mod)
                peligro = max(pa["hazard"]["score"], pb["hazard"]["score"])
                f_t = min(pa["success"]["time_factor"], pb["success"]["time_factor"])
                f_o = min(pa["success"]["consumables_factor"], pb["success"]["consumables_factor"])
                valor = pri / self.pri_total if self.pri_total else 0.0
                exito = 100.0 * valor * f_t * f_o * (1.0 - peligro / 200.0)
                t_max = max(validas[ma][3]["total_h"], validas[mb][3]["total_h"])
                clave = (exito, -t_max)
                if mejor is None or clave[0] > mejor[0][0] + 1e-9 or (abs(clave[0] - mejor[0][0]) <= 1e-9 and clave[1] > mejor[0][1] + 1e-9):
                    mejor = (clave, ma, mb, sep, valor, peligro, f_t, f_o, exito, t_max)
        if mejor is None:
            return {"mode": "pair", "status": "no_pair", "max_separation_limit_m": self.mod.par_sep, "routes": {}, "pair": None}
        _, ma, mb, sep, valor, peligro, f_t, f_o, exito, t_max = mejor
        rutas = {}
        for nombre, mask in (("pair1", ma), ("pair2", mb)):
            costo, orden, celdas, m, _ = validas[mask]
            otra = validas[mb if mask == ma else ma][1] if ma != mb else orden
            omit = [{"id": i, "reason": "other_astronaut" if i in otra else "not_in_pair"} for i in libres if i not in orden]
            omit += [{"id": o["id"], "reason": "blocked"} for o in self.obj if o["bloqueado"]]
            rutas[nombre] = self.resultado(nombre, costo, orden, celdas, m, omit)
        visitadas = sorted(set(validas[ma][1]) | set(validas[mb][1]))
        return {
            "mode": "pair",
            "status": "ok",
            "max_separation_limit_m": self.mod.par_sep,
            "routes": rutas,
            "pair": {
                "visited": visitadas,
                "max_separation_m": sep,
                "total_h": t_max,
                "o2_remaining_min_frac": min(rutas["pair1"]["metrics"]["o2_remaining_frac"], rutas["pair2"]["metrics"]["o2_remaining_frac"]),
                "hazard": peligro,
                "success": {"score": exito, "science_value": valor, "time_factor": f_t, "consumables_factor": f_o, "hazard_penalty": 1.0 - peligro / 200.0},
            },
        }

    def las_tres(self):
        return {"safe": self.principal("safe"), "fast": self.principal("fast"), "science": self.ciencia("science")}
