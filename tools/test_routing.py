"""Pruebas del núcleo de rutas con rejillas pequeñas y sintéticas.

Uso: cd tools && python3 -m unittest test_routing -v
"""
import math
import unittest

import numpy as np
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra

import common
import routing


def rejilla_sintetica(pend, z=None, rug=None, celda=2.0):
    """Construye una Rejilla sin leer archivos."""
    r = routing.Rejilla.__new__(routing.Rejilla)
    h, w = pend.shape
    r.celda, r.ancho, r.alto = celda, w, h
    r.prohibida = pend > 25.0
    r.pend = pend.astype("float64")
    r.rug = np.zeros_like(r.pend) if rug is None else rug
    r.z = np.zeros_like(r.pend) if z is None else z
    r.pend_real_l = r.pend.ravel().tolist()
    r.pend_l, r.rug_l, r.z_l = r.pend.ravel().tolist(), r.rug.ravel().tolist(), r.z.ravel().tolist()
    r.forb_l = r.prohibida.ravel().tolist()
    r.origen_e = r.origen_n = 0.0
    r.habitat = 0
    return r


def costo_paso(rej, mod, perfil, u, v):
    W = rej.ancho
    ru, cu, rv, cv = u // W, u % W, v // W, v % W
    d = rej.celda * (math.sqrt(2.0) if (ru != rv and cu != cv) else 1.0)
    tan = (rej.z_l[v] - rej.z_l[u]) / d
    t = mod.gmax / mod.factor_velocidad(tan)
    s = rej.pend_l[v]
    ro = min(rej.rug_l[v] / mod.rug_ref, 1.0)
    return d * (1 + perfil["w_slope"] * s * s / (mod.pend_ref ** 2) + perfil["w_rough"] * ro + perfil["w_time"] * (t - 1))


def dijkstra_referencia(rej, mod, perfil, a, b):
    """Costo óptimo por Dijkstra de scipy, sobre el mismo grafo, para contrastar con A*."""
    W, H = rej.ancho, rej.alto
    lim = perfil["slope_limit_deg"]
    bloq = lambda i: rej.forb_l[i] or rej.pend_l[i] > lim
    filas, cols, vals = [], [], []
    for u in range(W * H):
        if bloq(u):
            continue
        r, c = divmod(u, W)
        for dr, dc, _ in routing.VECINOS:
            rr, cc = r + dr, c + dc
            if not (0 <= rr < H and 0 <= cc < W):
                continue
            v = rr * W + cc
            if bloq(v):
                continue
            if dr and dc and (bloq(u + dr * W) or bloq(u + dc)):
                continue
            filas.append(u)
            cols.append(v)
            vals.append(costo_paso(rej, mod, perfil, u, v))
    g = coo_matrix((vals, (filas, cols)), shape=(W * H, W * H)).tocsr()
    return dijkstra(g, indices=a)[b]


class PruebasRutas(unittest.TestCase):
    def setUp(self):
        self.mod = routing.Modelo()

    def test_llano_es_linea_recta(self):
        rej = rejilla_sintetica(np.zeros((20, 20)))
        perfil = self.mod.perfiles["fast"]
        costo, camino = routing.astar(rej, self.mod, perfil, 0, 19 * 20 + 19)
        self.assertEqual(len(camino), 20)  # diagonal pura
        # En llano plano el paso tarda gmax / g(0) veces el mejor paso (la mejor pendiente es una bajada leve).
        factor = 1.0 + perfil["w_time"] * (self.mod.gmax / self.mod.factor_velocidad(0.0) - 1.0)
        self.assertAlmostEqual(costo, 19 * 2.0 * math.sqrt(2.0) * factor, places=6)

    def test_rodea_celdas_prohibidas(self):
        pend = np.zeros((15, 15))
        pend[:12, 7] = 40.0  # muro vertical con paso por abajo
        rej = rejilla_sintetica(pend)
        for nombre in ("safe", "fast", "science"):
            r = routing.astar(rej, self.mod, self.mod.perfiles[nombre], 0, 14)
            self.assertIsNotNone(r, nombre)
            self.assertTrue(all(not rej.forb_l[i] for i in r[1]), nombre)

    def test_sin_camino(self):
        pend = np.zeros((10, 10))
        pend[:, 5] = 40.0
        rej = rejilla_sintetica(pend)
        self.assertIsNone(routing.astar(rej, self.mod, self.mod.perfiles["fast"], 0, 9))

    def test_no_corta_esquina_prohibida(self):
        pend = np.zeros((3, 3))
        pend[0, 1] = 40.0
        pend[1, 0] = 40.0
        rej = rejilla_sintetica(pend)
        # de (0,0) a (1,1) el paso diagonal pasaría entre dos celdas prohibidas
        self.assertIsNone(routing.astar(rej, self.mod, self.mod.perfiles["fast"], 0, 4))

    def test_limite_del_perfil_seguro(self):
        pend = np.zeros((10, 10))
        pend[:, 5] = 23.0  # transitable para rápida (25), no para segura (22)
        rej = rejilla_sintetica(pend)
        self.assertIsNotNone(routing.astar(rej, self.mod, self.mod.perfiles["fast"], 0, 9))
        self.assertIsNone(routing.astar(rej, self.mod, self.mod.perfiles["safe"], 0, 9))

    def test_astar_igual_a_dijkstra(self):
        rng = np.random.default_rng(7)
        for caso in range(3):
            pend = rng.uniform(0, 30, (18, 18))
            z = np.cumsum(rng.normal(0, 0.6, (18, 18)), axis=0)
            rug = rng.uniform(0, 60, (18, 18))
            pend[0, 0] = pend[17, 17] = 0.0
            rej = rejilla_sintetica(pend, z, rug)
            for nombre, perfil in self.mod.perfiles.items():
                ref = dijkstra_referencia(rej, self.mod, perfil, 0, 17 * 18 + 17)
                r = routing.astar(rej, self.mod, perfil, 0, 17 * 18 + 17)
                if math.isinf(ref):
                    self.assertIsNone(r, (caso, nombre))
                else:
                    self.assertIsNotNone(r, (caso, nombre))
                    self.assertAlmostEqual(r[0], ref, places=6, msg=(caso, nombre))

    def test_subir_cuesta_mas_que_bajar(self):
        z = np.tile(np.arange(20.0)[None, :] * 0.5, (5, 1))  # sube hacia el este
        rej = rejilla_sintetica(np.zeros((5, 20)), z)
        perfil = self.mod.perfiles["fast"]
        ida = routing.astar(rej, self.mod, perfil, 2 * 20, 2 * 20 + 19)
        vuelta = routing.astar(rej, self.mod, perfil, 2 * 20 + 19, 2 * 20)
        self.assertGreater(ida[0], vuelta[0])

    def test_metricas_de_un_tramo_llano(self):
        rej = rejilla_sintetica(np.zeros((1, 11)))
        camino = list(range(11))
        m = routing.evaluar(rej, self.mod, camino, {10: 0.5})
        self.assertAlmostEqual(m["distance_m"], 20.0)
        self.assertAlmostEqual(m["walk_h"], 20.0 / (2000.0 * self.mod.factor_velocidad(0.0)), places=9)
        self.assertAlmostEqual(m["stop_h"], 0.5)
        self.assertAlmostEqual(m["m_nominal"], 20.0)
        self.assertEqual(m["ascent_m"], 0.0)

    def test_puntajes_en_rango(self):
        rej = rejilla_sintetica(np.zeros((1, 11)))
        m = routing.evaluar(rej, self.mod, list(range(11)), {10: 0.5})
        s = routing.puntajes(m, 5.0, 10.0, self.mod)
        self.assertTrue(0.0 <= s["hazard"]["score"] <= 100.0)
        self.assertTrue(0.0 <= s["success"]["score"] <= 100.0)
        self.assertAlmostEqual(s["success"]["science_value"], 0.5)


    # --- modo con rover ---

    def test_rover_en_llano_va_mas_rapido_que_a_pie(self):
        mod = routing.Modelo()
        # 2 km de ida y vuelta: el ahorro de tiempo supera lo que cuesta subir y bajar del rover.
        rej = rejilla_sintetica(np.zeros((1, 60)), celda=10.0)
        celdas = list(range(0, 50)) + list(range(48, -1, -1))
        paradas = {49: 0.5}
        pie = routing.evaluar(rej, mod, celdas, paradas)
        rv = routing.tramos_rover(rej, mod, celdas, paradas)
        self.assertEqual(rv, (len(celdas) - 1, len(celdas) - 1))  # todo el camino es transitable: el rover va por todo
        con = routing.evaluar(rej, mod, celdas, paradas, rv)
        self.assertEqual(pie["mode"], "foot")
        self.assertEqual(con["mode"], "rover")
        self.assertAlmostEqual(con["rover_m"], pie["distance_m"], places=6)
        self.assertLess(con["total_h"], pie["total_h"])
        self.assertLess(con["o2_used_frac"], pie["o2_used_frac"])

    def test_rover_solo_hasta_la_pendiente_que_no_pasa(self):
        mod = routing.Modelo()
        pend = np.zeros((1, 8))
        pend[0, 2] = mod.rover_pend + 1.0  # una celda que el rover no cruza
        rej = rejilla_sintetica(pend, celda=10.0)
        celdas = [0, 1, 2, 3, 2, 1, 0]
        paradas = {3: 0.5}
        self.assertEqual(routing.tramos_rover(rej, mod, celdas, paradas), (1, 5))
        m = routing.evaluar(rej, mod, celdas, paradas, (1, 5))
        self.assertAlmostEqual(m["rover_m"], 20.0, places=6)  # un paso de ida y uno de vuelta

    def test_rover_no_se_usa_si_el_inicio_no_es_transitable(self):
        mod = routing.Modelo()
        pend = np.zeros((1, 6))
        pend[0, 1] = mod.rover_pend + 1.0
        rej = rejilla_sintetica(pend, celda=10.0)
        self.assertIsNone(routing.tramos_rover(rej, mod, [0, 1, 2, 1, 0], {2: 0.2}))

    # --- rover de apoyo en el hábitat ---

    def test_apoyo_acorta_la_emergencia_y_no_cambia_la_ruta(self):
        mod = routing.Modelo()
        rej = rejilla_sintetica(np.zeros((1, 120)), celda=10.0)
        celdas = list(range(0, 100)) + list(range(98, -1, -1))  # 1 km de ida y vuelta, todo transitable
        paradas = {99: 0.5}
        pie = routing.evaluar(rej, mod, celdas, paradas)
        con = routing.evaluar(rej, mod, celdas, paradas, apoyo=True)
        self.assertEqual(con["mode"], "support")
        self.assertAlmostEqual(con["total_h"], pie["total_h"], places=9)  # la ruta no cambia
        self.assertAlmostEqual(con["o2_used_frac"], pie["o2_used_frac"], places=9)
        self.assertLess(con["emergency_max_h"], con["emergency_max_foot_h"])
        self.assertGreaterEqual(con["no_return"]["index"], pie["no_return"]["index"])
        self.assertLessEqual(con["max_radius_m"], pie["max_radius_m"])

    def test_apoyo_sin_tramo_transitable_no_ayuda(self):
        mod = routing.Modelo()
        pend = np.zeros((1, 30))
        pend[0, 1] = mod.rover_pend + 1.0  # el rover no sale del hábitat
        rej = rejilla_sintetica(pend, celda=10.0)
        celdas = list(range(0, 20)) + list(range(18, -1, -1))
        pie = routing.evaluar(rej, mod, celdas, {19: 0.2})
        con = routing.evaluar(rej, mod, celdas, {19: 0.2}, apoyo=True)
        self.assertAlmostEqual(con["emergency_max_h"], con["emergency_max_foot_h"], places=9)
        self.assertEqual(con["no_return"]["index"], pie["no_return"]["index"])

    # --- modo en pareja ---

    def test_posiciones_y_separacion(self):
        mod = routing.Modelo()
        rej = rejilla_sintetica(np.zeros((1, 80)), celda=10.0)
        ida = list(range(0, 40)) + list(range(38, -1, -1))
        pa = routing.posiciones(rej, mod, ida, {39: 0.5})
        self.assertEqual(len(pa), int(round(mod.max_eva_h / mod.par_paso_h)) + 1)
        self.assertEqual(pa[0], rej.xy_de(0))
        self.assertEqual(pa[-1], rej.xy_de(0))  # al terminar espera en el hábitat
        self.assertAlmostEqual(routing.separacion_max(pa, pa), 0.0)
        # el otro astronauta se queda en el hábitat: la separación es lo más lejos que llega el primero
        quieto = [rej.xy_de(0)] * len(pa)
        self.assertAlmostEqual(routing.separacion_max(pa, quieto), 39 * 10.0, delta=10.0)

    def test_llegadas_incluyen_la_parada(self):
        mod = routing.Modelo()
        rej = rejilla_sintetica(np.zeros((1, 10)), celda=10.0)
        lle, sal = routing.llegadas(rej, mod, [0, 1, 2, 3], {2: 0.25})
        self.assertAlmostEqual(sal[2] - lle[2], 0.25)
        self.assertAlmostEqual(lle[3] - sal[2], lle[1] - lle[0], places=9)

    # --- transporte por objetivo (a pie, vehículo, híbrido) ---

    def _ida_y_vuelta(self, destino, pend=None):
        """Rejilla de una fila; ruta del hábitat (celda 0) a `destino` y de vuelta por las mismas celdas."""
        mod = routing.Modelo()
        rej = rejilla_sintetica(np.zeros((1, 20)) if pend is None else pend, celda=10.0)
        celdas = list(range(0, destino + 1)) + list(range(destino - 1, -1, -1))
        return mod, rej, celdas, {destino: 0.5}

    def test_vehiculo_todo_transitable_va_y_vuelve_en_vehiculo(self):
        mod, rej, celdas, paradas = self._ida_y_vuelta(8)
        pasos, notas, varado = routing.pasos_rover_objetivos(rej, mod, celdas, paradas, [("a", "vehicle")])
        self.assertEqual(pasos, set(range(1, len(celdas))))
        self.assertEqual(notas, [])
        self.assertFalse(varado)
        pie = routing.evaluar(rej, mod, celdas, paradas)
        con = routing.evaluar(rej, mod, celdas, paradas, pasos_rover=pasos, modo="objective")
        self.assertEqual(con["mode"], "objective")
        self.assertAlmostEqual(con["rover_m"], pie["distance_m"], places=6)
        # solo se baja y se sube del vehículo en el objetivo: dos cambios
        self.assertAlmostEqual(con["total_h"], pie["distance_m"] / mod.rover_v + 0.5 + 2 * mod.rover_cambio_h, places=9)

    def test_hibrido_deja_el_vehiculo_antes_del_tramo_que_no_pasa(self):
        mod = routing.Modelo()
        pend = np.zeros((1, 20))
        pend[0, 4] = mod.rover_pend + 1.0
        mod, rej, celdas, paradas = self._ida_y_vuelta(8, pend)
        pasos, notas, varado = routing.pasos_rover_objetivos(rej, mod, celdas, paradas, [("a", "hybrid")])
        # va en vehículo hasta la celda 3 (pasos 1..3), camina hasta el objetivo y vuelve a pie hasta la celda 3
        n = len(celdas)
        vuelta_3 = celdas.index(3, 9)
        self.assertEqual(pasos, set(range(1, 4)) | set(range(vuelta_3 + 1, n)))
        self.assertEqual(notas, [])
        self.assertFalse(varado)

    def test_vehiculo_que_no_llega_se_trata_como_hibrido_con_aviso(self):
        mod = routing.Modelo()
        pend = np.zeros((1, 20))
        pend[0, 4] = mod.rover_pend + 1.0
        mod, rej, celdas, paradas = self._ida_y_vuelta(8, pend)
        pasos, notas, varado = routing.pasos_rover_objetivos(rej, mod, celdas, paradas, [("a", "vehicle")])
        self.assertEqual(notas, [{"id": "a", "reason": "vehicle_partial"}])
        self.assertIn(3, pasos)
        self.assertNotIn(5, pasos)
        self.assertFalse(varado)

    def test_a_pie_no_usa_vehiculo(self):
        mod, rej, celdas, paradas = self._ida_y_vuelta(8)
        pasos, notas, varado = routing.pasos_rover_objetivos(rej, mod, celdas, paradas, [("a", "foot")])
        self.assertEqual((pasos, notas, varado), (set(), [], False))

    def test_vehiculo_despues_de_ir_a_pie_no_esta_en_el_tramo(self):
        mod = routing.Modelo()
        rej = rejilla_sintetica(np.zeros((1, 20)), celda=10.0)
        celdas = [0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1, 0]
        paradas = {3: 0.2, 6: 0.2}
        pasos, notas, varado = routing.pasos_rover_objetivos(rej, mod, celdas, paradas, [("a", "foot"), ("b", "vehicle")])
        self.assertEqual(notas, [{"id": "b", "reason": "rover_not_here"}])
        self.assertEqual(pasos, set())
        self.assertFalse(varado)

    def test_vehiculo_que_queda_lejos_de_la_vuelta_deja_la_ruta_infactible(self):
        mod = routing.Modelo()
        rej = rejilla_sintetica(np.zeros((1, 20)), celda=10.0)
        # va en vehículo hasta la celda 5, luego a pie a la celda 2 y vuelve: nunca pasa de nuevo por la 5
        celdas = [0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0]
        paradas = {5: 0.2, 8: 0.2}
        pasos, notas, varado = routing.pasos_rover_objetivos(rej, mod, celdas, paradas, [("a", "vehicle"), ("b", "foot")])
        self.assertTrue(varado)
        self.assertIn({"id": None, "reason": "rover_stranded"}, notas)
        m = routing.evaluar(rej, mod, celdas, paradas, pasos_rover=pasos, modo="objective", rover_ok=not varado)
        self.assertFalse(m["rover_ok"])
        self.assertFalse(m["feasible"])
        self.assertTrue(m["time_ok"] and m["o2_ok"])

    def test_el_perfil_del_vehiculo_limita_pendiente_y_rugosidad(self):
        mod = routing.Modelo()
        rug = np.zeros((3, 3))
        rug[1, 1] = mod.rover_rug + 1.0  # roca en el centro
        rej = rejilla_sintetica(np.zeros((3, 3)), rug=rug, celda=10.0)
        perfil = dict(mod.perfiles["safe"], rough_max_cm=mod.rover_rug)
        a_pie = routing.astar(rej, mod, mod.perfiles["safe"], 3, 5)
        veh = routing.astar(rej, mod, perfil, 3, 5)
        self.assertEqual(len(a_pie[1]), 3)  # a pie pasa por el centro
        self.assertNotIn(4, veh[1])  # el vehículo lo rodea
        self.assertIsNone(routing.astar(rej, mod, perfil, 3, 4))  # y no puede llegar a la celda de la roca

    def test_modo_objetivo_a_pie_igual_que_el_modo_a_pie(self):
        mod = routing.Modelo()
        rej = rejilla_sintetica(np.zeros((1, 20)), celda=10.0)
        objs = [{"id": "a", "name": "a", "type": "sample", "priority": 3, "work_min": 30, "x_m": 85.0, "y_m": 5.0}]
        a = routing.Planificador(rej, mod, objs, modo="foot").ruta("safe", ["a"])
        b = routing.Planificador(rej, mod, objs, modo="objetivo").ruta("safe", ["a"])
        self.assertEqual(a[2], b[2])
        for k in ("total_h", "o2_used_frac", "distance_m", "feasible"):
            self.assertAlmostEqual(float(a[3][k]), float(b[3][k]), places=9)


if __name__ == "__main__":
    unittest.main()
