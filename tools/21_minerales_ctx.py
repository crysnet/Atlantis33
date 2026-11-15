"""Capas de ciencia (búsqueda de biofirmas) en todo el mosaico CTX de Meridiani.

14_contexto_y_rasgos.py solo guarda los minerales que caen dentro del marco de contexto de cada sitio
(Endeavour 40 km, regional 200 km). Este script los amplía al recuadro completo del mosaico CTX
«Meridiani Planum - Sinus Meridiani» de Mars Trek, que el mapa base de 40 m (`base_meridiani`) ya cubre
sin red, y añade las redes de valles:

  acuosos    «Aqueous Mineral Distribution» (puntos: sulfate, phyllosilicate, carbonate)  -> capa aqueous_pts
  hidratados «Hydrous Mineral Detections (OMEGA, CRISM)» (puntos)                         -> capa hydrous_pts
  valles     «Valley Networks» (Hynek et al. 2010; líneas)                                 -> capa valleys

Fuente: NASA Mars Trek, servicios ArcGIS (consulta GeoJSON). Salida: data/raw/rasgos/meridiani/*_ctx.geojson
y las claves de vectors.json de cada sitio de Meridiani (sustituye los minerales y los valles; no toca el resto).

Correrlo SIEMPRE después de 14_contexto_y_rasgos.py (14 reescribe vectors.json).

Uso: python 21_minerales_ctx.py [--descargar]
"""
import json
import math
import os
import sys
import urllib.parse
import urllib.request

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(RAIZ, "app", "assets")
CARPETA = os.path.join(RAIZ, "data", "raw", "rasgos", "meridiani")
R = 3396190.0  # radio de la esfera de Marte de los mosaicos (m)

# Recuadro del mosaico CTX S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd en el catálogo de Mars Trek (lon0, lat0, lon1, lat1)
RECUADRO_CTX = (-8.09, -4.89, -2.80, -0.61)
TREK = "https://trek.nasa.gov/mars/trekarcgis/rest/services/"
CAPAS = {
    "acuosos": "Aquieous_Mineral_Distribution_Options_clon0/MapServer/0",
    "hidratados": "Hydrous_Mineral_Detections_OMEGA_CRISM_clon0/MapServer/0",
    "valles": "Hynek_Valley_Networks/MapServer/0",
}
SITIOS = ["site_meridiani_endeavour", "site_meridiani_endeavour_reach", "site_meridiani_habitat", "site_meridiani_regional"]


def ruta(clave):
    return os.path.join(CARPETA, f"{clave}_ctx.geojson")


def descargar(clave):
    params = {"where": "1=1", "geometry": ",".join(map(str, RECUADRO_CTX)), "geometryType": "esriGeometryEnvelope",
              "spatialRel": "esriSpatialRelIntersects", "outFields": "*", "returnGeometry": "true", "f": "geojson"}
    req = urllib.request.Request(TREK + CAPAS[clave] + "/query?" + urllib.parse.urlencode(params),
                                 headers={"User-Agent": "research-client"})
    with urllib.request.urlopen(req, timeout=120) as r:
        datos = r.read()
    os.makedirs(CARPETA, exist_ok=True)
    with open(ruta(clave), "wb") as f:
        f.write(datos)
    print(f"descargado {ruta(clave)} ({len(datos)} bytes)")


def lineas(geom):
    if geom["type"] == "LineString":
        return [geom["coordinates"]]
    if geom["type"] == "MultiLineString":
        return geom["coordinates"]
    return []


def main():
    datos = {}
    for clave in CAPAS:
        if "--descargar" in sys.argv or not os.path.exists(ruta(clave)):
            descargar(clave)
        datos[clave] = json.load(open(ruta(clave), encoding="utf-8"))["features"]
        print(f"{clave}: {len(datos[clave])} elementos en el recuadro CTX")
    for asset in SITIOS:
        d = os.path.join(ASSETS, asset)
        site = json.load(open(os.path.join(d, "site.json"), encoding="utf-8"))
        g, base = site["georeference"], site["base"]
        x0, y0 = g["origin_easting_m"], g["origin_northing_m"]
        bx0, by0 = base["x_m"], base["y_m"]
        bx1, by1 = bx0 + base["size_m"], by0 + base["size_m"]

        def loc(lon, lat):
            return round(R * math.radians(lon) - x0, 1), round(y0 - R * math.radians(lat), 1)

        def dentro(x, y):
            return bx0 <= x <= bx1 and by0 <= y <= by1

        rv = os.path.join(d, "vectors.json")
        doc = json.load(open(rv, encoding="utf-8"))
        feats = [f for f in doc["features"] if f.get("kind") not in ("mineral", "valley")]
        vistos = set()
        minerales = []
        for clave, origen in (("acuosos", None), ("hidratados", "Instrument")):
            for p in datos[clave]:
                x, y = loc(*p["geometry"]["coordinates"][:2])
                cls = p["properties"]["Class"] if clave == "acuosos" else "hydrous"
                fuente = "aqueous" if clave == "acuosos" else (p["properties"].get(origen) or "")
                if dentro(x, y) and (cls, fuente, x, y) not in vistos:
                    vistos.add((cls, fuente, x, y))
                    minerales.append({"kind": "mineral", "cls": cls, "source": fuente, "x_m": x, "y_m": y})
        valles = []
        for p in datos["valles"]:
            caminos = []
            for linea in lineas(p["geometry"]):
                tramo = []  # se parte la línea en tramos que quedan dentro del mapa base
                for lon, lat, *_ in linea:
                    x, y = loc(lon, lat)
                    if dentro(x, y):
                        tramo.append([x, y])
                    else:
                        if len(tramo) >= 2:
                            caminos.append(tramo)
                        tramo = []
                if len(tramo) >= 2:
                    caminos.append(tramo)
            if caminos:
                valles.append({"kind": "valley", "paths": caminos})
        doc["features"] = feats + minerales + valles
        doc.pop("hydrous_extent", None)
        doc["science_extent"] = ("Aqueous minerals, hydrous minerals (CRISM, OMEGA) and Hynek valley networks via NASA Mars Trek, "
                                 "CTX Meridiani mosaic bbox lon %.2f..%.2f, lat %.2f..%.2f (21_minerales_ctx.py)"
                                 % (RECUADRO_CTX[0], RECUADRO_CTX[2], RECUADRO_CTX[1], RECUADRO_CTX[3]))
        with open(rv, "w", encoding="utf-8") as f:
            json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
        cuenta = {}
        for m in minerales:
            cuenta[m["cls"]] = cuenta.get(m["cls"], 0) + 1
        print(f"{asset}: minerales {cuenta}, valles {len(valles)} ({sum(len(v['paths']) for v in valles)} líneas)")


if __name__ == "__main__":
    main()
