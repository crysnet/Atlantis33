"""F5b: marco de contexto y rasgos (puntos y polígonos) de los cuatro sitios.

Entrada: data/raw/contexto/ y data/raw/meridiani_regional/ctx_z11/ (teselas CTX de Mars Trek, de 10_meridiani_datos.py),
         data/raw/rasgos/ (de 13_rasgos_datos.py), app/assets/site_*/site.json
Salida en cada app/assets/site_*/:
  context/{z}/{x}/{y}.jpg   pirámide de teselas CTX en grises, más gruesa que la ortofoto, que cubre mucho más que la ventana
  vectors.json              minerales, zonas de exploración, dunas, cráteres de 1 km o más, nombres de la UAI y unidades geológicas,
                            en coordenadas locales del sitio, recortados al marco de contexto
  y añade `context` y las capas nuevas a site.json.

Orden: 11_sitio_meridiani.py, 12_capas_meridiani.py y este (11 reescribe site.json; Gale lo escribe 04_exportar.py).

Uso (desde tools/): python3 14_contexto_y_rasgos.py
"""
import importlib.util
import json
import math
import os

import common

R = common.R_MARTE
ASSETS = os.path.join(common.RAIZ, "app", "assets")
RASGOS = os.path.join(common.RAW, "rasgos")


def _cargar(nombre, archivo):
    spec = importlib.util.spec_from_file_location(nombre, os.path.join(os.path.dirname(os.path.abspath(__file__)), archivo))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


datos = _cargar("datos10", "10_meridiani_datos.py")
sitios11 = _cargar("sitio11", "11_sitio_meridiani.py")

# asset, ventana de contexto, teselas (producto, nivel, carpeta), región de rasgos, niveles de la pirámide y mundo (m)
SITIOS = [
    ("site_gale", datos.GALE_CTX, ("Gale_CTX_BlockAdj_dd", 11, os.path.join(datos.RAW_C, "gale_ctx_z11")), "gale", 2, 40960.0,
     "CTX (MRO) mosaic of Gale crater, via NASA Mars Trek (WMTS level 11, 20 m/px)", 20.35),
    ("site_gale_reach", datos.GALE_CTX, ("Gale_CTX_BlockAdj_dd", 11, os.path.join(datos.RAW_C, "gale_ctx_z11")), "gale", 2, 40960.0,
     "CTX (MRO) mosaic of Gale crater, via NASA Mars Trek (WMTS level 11, 20 m/px)", 20.35),
    ("site_meridiani_endeavour", datos.ENDEAVOUR_CTX, ("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 11, os.path.join(datos.RAW_C, "endeavour_ctx_z11")), "meridiani", 2, 40960.0,
     "CTX (MRO) mosaic of Meridiani Planum - Sinus Meridiani, via NASA Mars Trek (WMTS level 11, 20 m/px)", 20.35),
    ("site_meridiani_endeavour_reach", datos.ENDEAVOUR_CTX, ("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 11, os.path.join(datos.RAW_C, "endeavour_ctx_z11")), "meridiani", 2, 40960.0,
     "CTX (MRO) mosaic of Meridiani Planum - Sinus Meridiani, via NASA Mars Trek (WMTS level 11, 20 m/px)", 20.35),
    ("site_meridiani_habitat", datos.REGIONAL, ("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 11, os.path.join(datos.RAW_R, "ctx_z11")), "meridiani", 3, 102400.0,
     "CTX (MRO) mosaic of Meridiani Planum - Sinus Meridiani, via NASA Mars Trek (WMTS level 11, 20 m/px)", 20.35),
    ("site_meridiani_regional", datos.REGIONAL_CTX, ("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 9, os.path.join(datos.RAW_C, "regional_ctx_z9")), "meridiani", 2, 204800.0,
     "CTX (MRO) mosaic of Meridiani Planum - Sinus Meridiani, via NASA Mars Trek (WMTS level 9, 81 m/px)", 81.4),
]


# ---------------------------------------------------------------- geometría

def recortar_anillo(pts, x0, y0, x1, y1):
    """Sutherland-Hodgman: recorta un anillo (lista de (x, y)) a un rectángulo."""
    def borde(entrada, dentro, cruce):
        salida = []
        if not entrada:
            return salida
        prev = entrada[-1]
        for cur in entrada:
            if dentro(cur):
                if not dentro(prev):
                    salida.append(cruce(prev, cur))
                salida.append(cur)
            elif dentro(prev):
                salida.append(cruce(prev, cur))
            prev = cur
        return salida

    def en_x(xv):
        return lambda a, b: (xv, a[1] + (b[1] - a[1]) * (xv - a[0]) / (b[0] - a[0]))

    def en_y(yv):
        return lambda a, b: (a[0] + (b[0] - a[0]) * (yv - a[1]) / (b[1] - a[1]), yv)

    p = borde(pts, lambda q: q[0] >= x0, en_x(x0))
    p = borde(p, lambda q: q[0] <= x1, en_x(x1))
    p = borde(p, lambda q: q[1] >= y0, en_y(y0))
    p = borde(p, lambda q: q[1] <= y1, en_y(y1))
    return p


def simplificar(pts, tol):
    """Ramer-Douglas-Peucker iterativo."""
    if len(pts) < 4:
        return pts
    marca = [False] * len(pts)
    marca[0] = marca[-1] = True
    pila = [(0, len(pts) - 1)]
    while pila:
        a, b = pila.pop()
        (ax, ay), (bx, by) = pts[a], pts[b]
        dx, dy = bx - ax, by - ay
        norma = math.hypot(dx, dy) or 1e-12
        dmax, imax = 0.0, -1
        for i in range(a + 1, b):
            d = abs(dy * (pts[i][0] - ax) - dx * (pts[i][1] - ay)) / norma
            if d > dmax:
                dmax, imax = d, i
        if dmax > tol:
            marca[imax] = True
            pila.append((a, imax))
            pila.append((imax, b))
    return [p for p, m in zip(pts, marca) if m]


def poligonos(geom):
    if geom["type"] == "Polygon":
        return [geom["coordinates"]]
    if geom["type"] == "MultiPolygon":
        return geom["coordinates"]
    return []


# ---------------------------------------------------------------- rasgos

def vectores(site, ctx, region):
    g = site["georeference"]
    x0o, y0o = g["origin_easting_m"], g["origin_northing_m"]
    cx0, cy0 = ctx["x0"] - x0o, y0o - ctx["y0"]  # esquina noroeste del marco en el plano local (y al sur)
    lado = ctx["size_m"]
    cx1, cy1 = cx0 + lado, cy0 + lado
    tol = lado * 0.0015

    def loc(lon, lat):
        return R * math.radians(lon) - x0o, y0o - R * math.radians(lat)

    def dentro(x, y):
        return cx0 <= x <= cx1 and cy0 <= y <= cy1

    carpeta = os.path.join(RASGOS, region)

    def leer(nombre):
        return json.load(open(os.path.join(carpeta, nombre), encoding="utf-8"))

    feats = []
    vistos = set()
    for f in leer("acuosos.geojson")["features"]:
        lon, lat = f["geometry"]["coordinates"][:2]
        x, y = loc(lon, lat)
        clave = (round(lon, 3), round(lat, 3), f["properties"]["Class"])
        if dentro(x, y) and clave not in vistos:
            vistos.add(clave)
            feats.append({"kind": "mineral", "cls": f["properties"]["Class"], "source": "aqueous", "x_m": round(x, 1), "y_m": round(y, 1)})
    for f in leer("hidratados.geojson")["features"]:
        x, y = loc(*f["geometry"]["coordinates"][:2])
        if dentro(x, y):
            feats.append({"kind": "mineral", "cls": "hydrous", "source": f["properties"]["Instrument"], "x_m": round(x, 1), "y_m": round(y, 1)})
    for archivo, tipo in (("ez_puntos.geojson", "ez"), ("ez_habitables.geojson", "habitation"), ("ez_aterrizaje.geojson", "landing")):
        for f in leer(archivo)["features"]:
            x, y = loc(*f["geometry"]["coordinates"][:2])
            if dentro(x, y):
                feats.append({"kind": "zone", "type": tipo, "name": f["properties"]["name"], "x_m": round(x, 1), "y_m": round(y, 1)})
    for archivo, tipo in (("ez_roi.geojson", "roi"), ("ez_radios.geojson", "ez_radius")):
        for f in leer(archivo)["features"]:
            for poly in poligonos(f["geometry"]):
                ring = [loc(lo, la) for lo, la in poly[0]]
                paso = max(1, len(ring) // 72)
                ring = ring[::paso]
                xs, ys = [p[0] for p in ring], [p[1] for p in ring]
                if max(xs) >= cx0 and min(xs) <= cx1 and max(ys) >= cy0 and min(ys) <= cy1:
                    feats.append({"kind": "zone", "type": tipo, "name": f["properties"].get("name", ""), "ring": [[round(a, 1), round(b, 1)] for a, b in ring]})
    for f in leer("dunas.geojson")["features"]:
        for poly in poligonos(f["geometry"]):
            ring = simplificar(recortar_anillo([loc(lo, la) for lo, la in poly[0]], cx0, cy0, cx1, cy1), tol)
            if len(ring) >= 3:
                feats.append({"kind": "landform", "type": "dune", "name": "Dune field", "ring": [[round(a, 1), round(b, 1)] for a, b in ring]})
    for f in leer("crateres.geojson")["features"]:
        p = f["properties"]
        x, y = loc(p["lon_e"] if p["lon_e"] <= 180 else p["lon_e"] - 360, p["lat"])
        if dentro(x, y):
            feats.append({"kind": "crater", "x_m": round(x, 1), "y_m": round(y, 1), "d_m": round(p["diamkm"] * 1000.0, 0), "id": p["craterid"]})
    for q in leer("nombres.json"):
        x, y = loc(q["lon"], q["lat"])
        if dentro(x, y):
            feats.append({"kind": "name", "name": q["name"], "type": (q["type"] or "").split(",")[0], "x_m": round(x, 1), "y_m": round(y, 1)})
    for f in leer("geologia.geojson")["features"]:
        pr = f["properties"]
        for poly in poligonos(f["geometry"]):
            anillos = []
            for i, ring in enumerate(poly):
                r = simplificar(recortar_anillo([loc(lo, la) for lo, la in ring], cx0, cy0, cx1, cy1), tol)
                if len(r) >= 3:
                    anillos.append([[round(a, 1), round(b, 1)] for a, b in r])
            if anillos:
                feats.append({"kind": "geology", "unit": pr["unit"], "desc": pr.get("unitdesc", ""), "rings": anillos})
    doc = {
        "source": "NASA Mars Trek (JPL): aqueous and hydrous minerals, exploration zones (NASA EMC 2015), dune field database, IAU names; USGS Astrogeology: Robbins crater database (1 km and larger) and global geologic map SIM 3292",
        "kind": "measured", "retrieved": "2026-11-14", "frame_m": [cx0, cy0, lado], "features": feats,
    }
    return doc


def main():
    p = common.params()
    for asset, ctxw, tesela, region, zmax, mundo, fuente, res in SITIOS:
        print("==", asset)
        salida = os.path.join(ASSETS, asset)
        ruta = os.path.join(salida, "site.json")
        if not os.path.exists(ruta):
            print("  (sin site.json: se omite)")
            continue
        site = json.load(open(ruta, encoding="utf-8"))
        s = {"tesela": tesela, "ventana": ctxw, "mundo_m": mundo, "zmax": zmax}
        gris = sitios11.mosaico_ortofoto(s)
        sitios11.exportar_teselas(s, p, salida, gris, nombre="context")
        g = site["georeference"]
        site["context"] = {
            "x_m": ctxw["x0"] - g["origin_easting_m"], "y_m": g["origin_northing_m"] - ctxw["y0"], "size_m": ctxw["size_m"],
            "template": "context/{z}/{x}/{y}.jpg", "tile_px": p["tiles"]["tile_px"], "min_zoom": 0, "max_zoom": zmax, "world_size_m": mundo,
            "m_per_px": [mundo / (p["tiles"]["tile_px"] * 2 ** z) for z in range(zmax + 1)], "source": fuente, "resolution_m": res,
        }
        doc = vectores(site, ctxw, region)
        with open(os.path.join(salida, "vectors.json"), "w", encoding="utf-8") as f:
            json.dump(doc, f, separators=(",", ":"))
        cuenta = {}
        for q in doc["features"]:
            k = q.get("cls") or q.get("type") or q["kind"]
            cuenta[k] = cuenta.get(k, 0) + 1
        print(f"  vectors.json: {len(doc['features'])} elementos {cuenta}; {os.path.getsize(os.path.join(salida, 'vectors.json')) / 1e3:.0f} KB")
        ids = {q["id"] for q in site["layers"]}
        nuevas = [
            {"id": "minerals_pts", "kind": "measured", "file": "vectors.json", "source": "Aqueous mineral distribution and hydrous mineral detections (CRISM, OMEGA) via NASA Mars Trek", "resolution_m": None},
            {"id": "zones", "kind": "measured", "file": "vectors.json", "source": "Exploration zones, habitation zones, landing sites and regions of interest (NASA EMC workshop, 2015) via NASA Mars Trek", "resolution_m": None},
            {"id": "names", "kind": "measured", "file": "vectors.json", "source": "IAU place names via NASA Mars Trek", "resolution_m": None},
            {"id": "craters", "kind": "measured", "file": "vectors.json", "source": "Robbins crater database, craters of 1 km and larger (USGS Astrogeology)", "resolution_m": None},
            {"id": "geology", "kind": "measured", "file": "vectors.json", "source": "Global geologic map SIM 3292 (USGS Astrogeology) and dune field database (via NASA Mars Trek); global scale", "resolution_m": None},
        ]
        site["layers"] += [q for q in nuevas if q["id"] not in ids]
        with open(ruta, "w", encoding="utf-8") as f:
            json.dump(site, f, indent=2)


if __name__ == "__main__":
    main()
