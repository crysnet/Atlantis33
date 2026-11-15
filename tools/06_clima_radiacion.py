"""Fase 4: descarga las series reales de radiación (RAD) y clima (REMS) de Curiosity y las convierte a JSON por sol.

Fuentes (NASA):
- RAD: CDAWeb (NASA SPDF), conjunto MSL_RAD_OBS-L2, servicio web CDAS en CSV. Variable DOSIMETRY_TOTAL_f
  (calidad filtrada): tasa de dosis absorbida en uGy/dia del detector B (silicio, con y sin corrección de la
  fuente MMRTG del rover) y del detector E (plástico equivalente a tejido).
- REMS: PDS Atmósferas (NMSU), MSL-M-REMS-5-MODRDR-V1.0, volumen mslrem_1001, archivos RMD (un archivo de texto por sol).

Descargas originales en data/raw/rad/ y data/raw/rems/ (no se versionan). Salida: app/assets/site_gale/environment.json.

Uso (desde tools/):
    python3 06_clima_radiacion.py [--descargar] [--sol-final 4843] [--n-sols 30]
Sin --descargar usa los archivos que ya estén en data/raw/.
"""
import argparse
import csv
import datetime as dt
import json
import math
import os
import re
import statistics
import sys
import time

import requests

import common

UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) Chrome/120 Safari/537.36"}
RAD_DIR = os.path.join(common.RAW, "rad")
REMS_DIR = os.path.join(common.RAW, "rems")
CDAS = "https://cdaweb.gsfc.nasa.gov/WS/cdasr/1/dataviews/sp_phys/datasets/MSL_RAD_OBS-L2/data"
REMS_BASE = "https://atmos.nmsu.edu/PDS/data/mslrem_1001/DATA"
SOL_S = 88775.244147  # duración del sol medio marciano en segundos

# Columnas de MODRDR6.FMT (índice = número de columna - 1). -999 es el valor ausente.
C_LMST, C_GROUND, C_AMBIENT, C_UV_ABC, C_PRESSURE, C_HUMIDITY, C_WIND = 1, 7, 15, 20, 37, 30, 3
FALTA = -999.0


def k_a_c(k):
    return k - 273.15


def get(url, headers=None, **kw):
    for intento in range(4):
        try:
            r = requests.get(url, headers={**UA, **(headers or {})}, timeout=120, **kw)
            r.raise_for_status()
            return r
        except Exception as e:  # noqa: BLE001
            if intento == 3:
                raise
            print(f"  reintento {intento + 1} por {e!r}", flush=True)
            time.sleep(3)


# ------------------------------------------------------------------ RAD
def meses(inicio, fin):
    """Pares (inicio, fin) por mes, en formato AAAA-MM-DD."""
    a = dt.date.fromisoformat(inicio)
    b = dt.date.fromisoformat(fin)
    out = []
    while a <= b:
        sig = (a.replace(day=28) + dt.timedelta(days=4)).replace(day=1)
        out.append((a.isoformat(), min(b, sig - dt.timedelta(days=1)).isoformat()))
        a = sig
    return out


def descargar_rad(inicio, fin):
    """Pide RAD por meses (un año entero en una sola petición da 503) y guarda un CSV por mes."""
    os.makedirs(RAD_DIR, exist_ok=True)
    total = 0
    for ini, f in meses(inicio, fin):
        destino = os.path.join(RAD_DIR, f"rad_{ini[:7]}.csv")
        url = f"{CDAS}/{ini.replace('-', '')}T000000Z,{f.replace('-', '')}T235959Z/DOSIMETRY_TOTAL_f?format=csv"
        info = get(url, headers={"Accept": "application/json"}).json()
        archivos = info.get("FileDescription", [])
        if not archivos:
            print(f"RAD {ini[:7]}: sin datos ({info.get('Message') or info.get('Error')})", flush=True)
            continue
        contenido = get(archivos[0]["Name"]).content
        with open(destino, "wb") as out:
            out.write(contenido)
        total += len(contenido)
        print(f"RAD {ini[:7]}: {len(contenido) / 1e3:.0f} KB", flush=True)
    print(f"RAD: {total / 1e6:.2f} MB en total", flush=True)
    return RAD_DIR


def leer_rad(carpeta):
    """Devuelve lista ordenada de (datetime UTC, dosis B corregida, dosis E) en uGy/dia, de todos los CSV de la carpeta."""
    filas = []
    for nombre in sorted(os.listdir(carpeta)):
        if not nombre.startswith("rad_") or not nombre.endswith(".csv"):
            continue
        with open(os.path.join(carpeta, nombre), encoding="utf-8") as f:
            lineas = [l for l in f if not l.startswith("#") and l.strip()]
        if not lineas:
            continue
        lector = csv.reader(lineas)
        cab = next(lector)
        i_b = next(i for i, c in enumerate(cab) if c.startswith("RTG_CORRECTED_DOSE_B"))
        i_e = next(i for i, c in enumerate(cab) if c.startswith("TOTAL_DOSE_E"))
        for r in lector:
            try:
                t = dt.datetime.strptime(r[0][:19], "%Y-%m-%dT%H:%M:%S").replace(tzinfo=dt.timezone.utc)
                b, e = float(r[i_b]), float(r[i_e])
            except ValueError:
                continue
            if b > 0 and e > 0 and not (math.isnan(b) or math.isnan(e)):
                filas.append((t, b, e))
    filas.sort()
    return filas


# ------------------------------------------------------------------ REMS
def rango_de(sol):
    raiz = get(REMS_BASE + "/").text
    for a, b in re.findall(r"SOL_(\d{5})_(\d{5})/", raiz):
        if int(a) <= sol <= int(b):
            return f"SOL_{a}_{b}"
    raise SystemExit(f"No hay carpeta REMS para el sol {sol}")


def descargar_rems(sols):
    os.makedirs(REMS_DIR, exist_ok=True)
    rutas = {}
    for sol in sols:
        local = os.path.join(REMS_DIR, f"RMD_sol{sol:05d}.TAB")
        lbl = os.path.join(REMS_DIR, f"RMD_sol{sol:05d}.LBL")
        if os.path.exists(local) and os.path.exists(lbl) and os.path.getsize(local) > 1e5:
            rutas[sol] = (local, lbl)
            continue
        carpeta = f"{REMS_BASE}/{rango_de(sol)}/SOL{sol:05d}/"
        listado = get(carpeta).text
        m = re.search(r'href="(RME_\d+RMD\d{4}0000000_+P1\.TAB)"', listado)
        if not m:
            print(f"  sol {sol}: sin archivo RMD", flush=True)
            continue
        nombre = m.group(1)
        t0 = time.time()
        with get(carpeta + nombre, stream=True) as r, open(local, "wb") as out:
            for trozo in r.iter_content(1 << 20):
                out.write(trozo)
        with open(lbl, "wb") as out:
            out.write(get(carpeta + nombre.replace(".TAB", ".LBL")).content)
        print(f"  sol {sol}: {nombre} {os.path.getsize(local) / 1e6:.1f} MB en {time.time() - t0:.0f} s", flush=True)
        rutas[sol] = (local, lbl)
    return rutas


def etiqueta(ruta_lbl, clave):
    t = open(ruta_lbl, encoding="utf-8", errors="ignore").read()
    m = re.search(rf"^{clave}\s*=\s*(\S+)", t, flags=re.M)
    return m.group(1) if m else None


def utc(s):
    return dt.datetime.strptime(s[:19], "%Y-%m-%dT%H:%M:%S").replace(tzinfo=dt.timezone.utc)


def mediana(v):
    return statistics.median(v) if v else None


def parsear_rems(sol, ruta_tab, ruta_lbl):
    """Resume un sol de REMS: estadísticas y perfil por hora de tiempo solar medio local (LMST)."""
    horas = {h: {"amb": [], "gnd": [], "pre": [], "uv": [], "hum": []} for h in range(24)}
    n = 0
    primera = None
    with open(ruta_tab, encoding="utf-8", errors="ignore") as f:
        for r in csv.reader(f):
            if len(r) < 40:
                continue
            lmst = r[C_LMST].strip()
            if not lmst.startswith(f"{sol:05d}"):
                continue
            try:
                h = int(lmst[6:8])
            except ValueError:
                continue
            n += 1
            if primera is None:
                primera = lmst
            amb = float(r[C_AMBIENT])
            if amb != FALTA and 120 < amb < 330:
                horas[h]["amb"].append(amb)
            gnd = float(r[C_GROUND])
            if gnd != FALTA and 120 < gnd < 340:
                horas[h]["gnd"].append(gnd)
            pre = float(r[C_PRESSURE])
            if pre != FALTA and 300 < pre < 1500:
                horas[h]["pre"].append(pre)
            uv = float(r[C_UV_ABC])
            if uv != FALTA and uv >= 0:
                horas[h]["uv"].append(uv)
            hum = float(r[C_HUMIDITY])
            if hum != FALTA and 0 <= hum <= 100:
                horas[h]["hum"].append(hum)
    perfil = []
    for h in range(24):
        d = horas[h]
        perfil.append({
            "lmst_hour": h,
            "air_c": None if not d["amb"] else round(k_a_c(mediana(d["amb"])), 1),
            "ground_c": None if not d["gnd"] else round(k_a_c(mediana(d["gnd"])), 1),
            "pressure_pa": None if not d["pre"] else round(statistics.mean(d["pre"]), 1),
            "uv_abc_wm2": None if not d["uv"] else round(statistics.mean(d["uv"]), 3),
            "humidity_pct": None if not d["hum"] else round(statistics.mean(d["hum"]), 2),
            "samples": len(d["amb"]),
        })
    aire = [p["air_c"] for p in perfil if p["air_c"] is not None]
    suelo = [p["ground_c"] for p in perfil if p["ground_c"] is not None]
    pres = [p["pressure_pa"] for p in perfil if p["pressure_pa"] is not None]
    uv = [p["uv_abc_wm2"] for p in perfil if p["uv_abc_wm2"] is not None]
    return {
        "sol": sol,
        "utc_start": etiqueta(ruta_lbl, "START_TIME"),
        "utc_stop": etiqueta(ruta_lbl, "STOP_TIME"),
        "rows": n,
        "hours_with_air_data": len(aire),
        "air_min_c": min(aire) if aire else None,
        "air_max_c": max(aire) if aire else None,
        "ground_min_c": min(suelo) if suelo else None,
        "ground_max_c": max(suelo) if suelo else None,
        "pressure_min_pa": min(pres) if pres else None,
        "pressure_max_pa": max(pres) if pres else None,
        "uv_abc_peak_wm2": max(uv) if uv else None,
        "hourly": perfil,
    }


# ------------------------------------------------------------------ Calibración sol <-> UTC
def calibrar(rutas):
    """Hora UTC del inicio de cada sol (LMST 00:00) a partir de la primera fila de REMS del sol más reciente."""
    sol = max(rutas)
    tab, lbl = rutas[sol]
    with open(tab, encoding="utf-8", errors="ignore") as f:
        fila = next(r for r in csv.reader(f) if len(r) >= 40)
    lmst = fila[C_LMST].strip()
    hh, mm, ss = int(lmst[6:8]), int(lmst[9:11]), float(lmst[12:])
    marte_h = hh + mm / 60 + ss / 3600
    inicio_fila = utc(etiqueta(lbl, "START_TIME"))
    ref = inicio_fila - dt.timedelta(seconds=marte_h / 24 * SOL_S)
    return sol, ref


def inicio_sol(n, ref_sol, ref_utc):
    return ref_utc + dt.timedelta(seconds=(n - ref_sol) * SOL_S)


def sol_de(t, ref_sol, ref_utc):
    return ref_sol + math.floor((t - ref_utc).total_seconds() / SOL_S)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--descargar", action="store_true")
    ap.add_argument("--sol-final", type=int, default=4843)
    ap.add_argument("--n-sols", type=int, default=30)
    ap.add_argument("--rad-inicio", default="2025-11-01")
    ap.add_argument("--rad-fin", default="2026-11-11")
    a = ap.parse_args()
    sols = list(range(a.sol_final - a.n_sols + 1, a.sol_final + 1))

    ruta_rad = RAD_DIR
    if a.descargar:
        ruta_rad = descargar_rad(a.rad_inicio, a.rad_fin)
        rutas = descargar_rems(sols)
    else:
        rutas = {s: (os.path.join(REMS_DIR, f"RMD_sol{s:05d}.TAB"), os.path.join(REMS_DIR, f"RMD_sol{s:05d}.LBL")) for s in sols
                 if os.path.exists(os.path.join(REMS_DIR, f"RMD_sol{s:05d}.TAB"))}

    print("REMS: procesando", len(rutas), "sols", flush=True)
    clima = [parsear_rems(s, *rutas[s]) for s in sorted(rutas)]
    ref_sol, ref_utc = calibrar(rutas)
    # Comprobación de la calibración contra el inicio real de cada archivo de REMS.
    desv = [abs((utc(c["utc_start"]) - inicio_sol(c["sol"], ref_sol, ref_utc)).total_seconds() / 3600 - 0) for c in clima]
    print(f"calibración sol-UTC: inicio del sol {ref_sol} = {ref_utc.isoformat()}; las filas de REMS empiezan entre "
          f"{min(desv):.1f} y {max(desv):.1f} h después del inicio del sol", flush=True)

    rad = leer_rad(ruta_rad)
    print(f"RAD: {len(rad)} mediciones entre {rad[0][0]:%Y-%m-%d} y {rad[-1][0]:%Y-%m-%d}", flush=True)
    por_sol = {}
    for t, b, e in rad:
        por_sol.setdefault(sol_de(t, ref_sol, ref_utc), []).append((b, e))
    dosis = []
    for s in sorted(por_sol):
        v = por_sol[s]
        if len(v) < 20:  # sol con muy poca cobertura
            continue
        dosis.append({
            "sol": s,
            "utc_start": inicio_sol(s, ref_sol, ref_utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "n": len(v),
            "dose_e_mean_ugy_day": round(statistics.mean(x[1] for x in v), 1),
            "dose_e_max_ugy_day": round(max(x[1] for x in v), 1),
            "dose_b_rtg_mean_ugy_day": round(statistics.mean(x[0] for x in v), 1),
        })
    primer_sol_rems = ref_sol - a.n_sols + 1
    previos = [d["dose_e_mean_ugy_day"] for d in dosis if primer_sol_rems - 60 <= d["sol"] < primer_sol_rems]
    base = statistics.median(previos) if previos else None
    print(f"RAD: {len(dosis)} sols con datos; línea base (mediana de {len(previos)} sols, del {primer_sol_rems - 60} al {primer_sol_rems - 1}) = {base} uGy/día", flush=True)

    doc = {
        "generated": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d"),
        "reference_sol": ref_sol,
        "sol_calibration": {"sol": ref_sol, "utc_lmst_midnight": ref_utc.strftime("%Y-%m-%dT%H:%M:%SZ"), "sol_seconds": SOL_S,
                            "note": "El sol se calcula con la duración media del sol marciano; el error es de minutos."},
        "radiation": {
            "source": "NASA SPDF CDAWeb, MSL_RAD_OBS-L2 (DOI 10.48322/20qb-4e17), servicio web CDAS",
            "pi": "D. Hassler, SwRI",
            "variable": "DOSIMETRY_TOTAL_f (calidad filtrada). E = detector de plástico equivalente a tejido; B = silicio con la fuente MMRTG restada",
            "unit": "uGy/dia (dosis absorbida; no es dosis equivalente)",
            "kind": "measured",
            "baseline_e_median_ugy_day": base,
            "baseline_note": f"Mediana de las medias diarias del detector E en los 60 sols previos al periodo de REMS (sols {primer_sol_rems - 60} a {primer_sol_rems - 1}, {len(previos)} con datos)",
            "per_sol": dosis,
        },
        "weather": {
            "source": "NASA PDS Atmosferas (NMSU), MSL-M-REMS-5-MODRDR-V1.0, volumen mslrem_1001",
            "producer": "Centro de Astrobiologia (CAB, INTA-CSIC)",
            "unit": "grados C, Pa, W/m2 (UV A+B+C), % de humedad relativa",
            "kind": "measured",
            "note": "Medianas por hora de tiempo solar medio local (LMST). El viento y la humedad tienen huecos; REMS mide de forma intermitente.",
            "sols": clima,
        },
        "dust": {"kind": "example", "note": "El PDS no tiene un producto de opacidad del polvo de REMS. Pendiente de otra fuente."},
    }
    destino = os.path.join(common.SALIDA, "environment.json")
    os.makedirs(common.SALIDA, exist_ok=True)
    with open(destino, "w", encoding="utf-8") as f:
        json.dump(doc, f, separators=(",", ":"), ensure_ascii=False)
    print(f"escrito {destino} ({os.path.getsize(destino) / 1e3:.0f} KB)", flush=True)


if __name__ == "__main__":
    main()
