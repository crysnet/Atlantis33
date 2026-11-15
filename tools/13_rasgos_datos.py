"""F5b: descarga los rasgos cercanos a los sitios (puntos y polígonos) de Mars Trek y del USGS, para dibujarlos en el mapa.

Salida en data/raw/rasgos/ (no versionado), una carpeta por región:
  gale/ y meridiani/ con
    acuosos.geojson, hidratados.geojson   minerales (Mars Trek, servicios ArcGIS)
    ez_puntos.geojson, ez_habitables.geojson, ez_aterrizaje.geojson, ez_roi.geojson, ez_radios.geojson   zonas de exploración (NASA EMC)
    dunas.geojson                          campos de dunas (Mars Trek)
    crateres.geojson                       cráteres de la base de Robbins de 1 km o más (USGS Astrogeology)
    geologia.geojson                       unidades del mapa geológico global SIM 3292 (USGS Astrogeology)
    nombres.json                           nombres oficiales de la UAI (nomenclatura de Mars Trek)
  catalogo_trek.json                       catálogo de Mars Trek (1.5 MB), solo para hallar servicios y nombres

Uso (desde tools/): python3 13_rasgos_datos.py
Fuentes y fechas en RECURSOS.md. Términos de uso de Trek y del servicio del USGS sin consultar.
"""
import json
import os
import re
import urllib.parse
import urllib.request

import common

UA = {"User-Agent": "research-client"}
RAIZ = os.path.join(common.RAW, "rasgos")
TREK = "https://trek.nasa.gov/mars/trekarcgis/rest/services"
USGS = "https://astrogeology.usgs.gov/pygeoapi/collections/"
# regiones: (lon0, lat0, lon1, lat1) con longitudes de -180 a 180; incluyen los marcos de contexto de todos los sitios
REGIONES = {"gale": (136.2, -5.9, 138.6, -3.7), "meridiani": (-7.4, -4.9, -3.6, -1.3)}
CAPAS_TREK = {
    "acuosos": "Aquieous_Mineral_Distribution_Options_clon0/MapServer/0",
    "hidratados": "Hydrous_Mineral_Detections_OMEGA_CRISM_clon0/MapServer/0",
    "ez_puntos": "EZ/MapServer/0",
    "ez_habitables": "EZMars/MapServer/1",
    "ez_aterrizaje": "EZMars/MapServer/2",
    "ez_roi": "EZMars/MapServer/3",
    "ez_radios": "EZMars/MapServer/4",
}


def pedir(url, params=None):
    if params:
        url += "?" + urllib.parse.urlencode(params)
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120) as r:
        return json.loads(r.read())


def consulta_arcgis(capa, bbox):
    return pedir(f"{capa}/query", {"where": "1=1", "geometry": ",".join(map(str, bbox)), "geometryType": "esriGeometryEnvelope",
                                   "spatialRel": "esriSpatialRelIntersects", "outFields": "*", "returnGeometry": "true", "f": "geojson"})


def catalogo():
    ruta = os.path.join(RAIZ, "catalogo_trek.json")
    if not os.path.exists(ruta):
        os.makedirs(RAIZ, exist_ok=True)
        with open(ruta, "w", encoding="utf-8") as f:
            json.dump(pedir("https://trek.nasa.gov/mars/TrekServices/ws/index/eq/searchItems", {"rows": 2100})["response"]["docs"], f)
    return json.load(open(ruta, encoding="utf-8"))


def servicio_por_titulo(cat, titulo):
    uuid = next(x["item_UUID"] for x in cat if x.get("title") == titulo and "Feature" in str(x.get("serviceTypes")))
    docs = pedir("https://trek.nasa.gov/mars/TrekServices/ws/index/getLayerServices", {"uuid": uuid})["response"]["docs"]
    return next(s["endPoint"] for s in docs if s.get("protocol") == "ArcGISFeature")


def main():
    cat = catalogo()
    dunas = servicio_por_titulo(cat, "Dune Field")
    dunas = dunas if dunas.rstrip("/").split("/")[-1].isdigit() else dunas + "/0"
    puntos = []
    for x in cat:
        if x.get("itemType") == "nomenclature":
            m = re.match(r"POINT\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)", str(x.get("shape", "")))
            if m:
                puntos.append({"name": x["title"], "type": x.get("productCat2") or x.get("keyword"), "lon": float(m.group(1)), "lat": float(m.group(2))})
    for nombre, (l0, b0, l1, b1) in REGIONES.items():
        d = os.path.join(RAIZ, nombre)
        os.makedirs(d, exist_ok=True)
        for clave, ruta in CAPAS_TREK.items():
            g = consulta_arcgis(f"{TREK}/{ruta}", (l0, b0, l1, b1))
            json.dump(g, open(os.path.join(d, clave + ".geojson"), "w"))
            print(f"{nombre}/{clave}: {len(g.get('features', []))}")
        g = consulta_arcgis(dunas, (l0, b0, l1, b1))
        json.dump(g, open(os.path.join(d, "dunas.geojson"), "w"))
        print(f"{nombre}/dunas: {len(g.get('features', []))}")
        for clave, col in (("crateres", "mars/robbinsv1"), ("geologia", "mars/sim3292_global_geologic_map/units")):
            g = pedir(f"{USGS}{col}/items", {"f": "json", "limit": 10000, "bbox": f"{l0},{b0},{l1},{b1}"})
            json.dump(g, open(os.path.join(d, clave + ".geojson"), "w"))
            print(f"{nombre}/{clave}: {len(g['features'])}")
        nom = [p for p in puntos if l0 <= p["lon"] <= l1 and b0 <= p["lat"] <= b1]
        json.dump(nom, open(os.path.join(d, "nombres.json"), "w"), ensure_ascii=False)
        print(f"{nombre}/nombres: {len(nom)} {[p['name'] for p in nom]}")


if __name__ == "__main__":
    main()
