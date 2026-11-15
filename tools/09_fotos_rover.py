"""Fotos reales de Curiosity (Mastcam izquierda, gran angular) para cada objetivo de demostración.

Fuente: API de imágenes crudas de mars.nasa.gov (NASA/JPL-Caltech/MSSS). Por cada sol de config/objectives.json
elige una foto de Mastcam izquierda de resolución completa (sufijo _DXXX), en color, y la guarda en
data/raw/rover_fotos/. Escribe data/work/fotos_rover.json con cámara, sol, fecha, crédito y URL.
Con --elegir <sol>=<imageid> se fija una foto distinta de la primera.

Uso: python3 09_fotos_rover.py [--camara MAST_LEFT|NAV] [--elegir 4548=<imageid>]
Por defecto MAST_LEFT. Las fotos de cada cámara van a su propia carpeta y su propio JSON.
"""
import json
import os
import re
import sys
import urllib.request

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = ("https://mars.nasa.gov/api/v1/raw_image_items/?order=sample_type_sort+asc&per_page=100&page=0&condition_1=msl:mission"
       "&condition_2=%d:sol:gte&condition_3=%d:sol:lte&condition_4=%s:instrument:in")


def main():
    cam = sys.argv[sys.argv.index("--camara") + 1] if "--camara" in sys.argv else "MAST_LEFT"
    sufijo = "" if cam == "MAST_LEFT" else "_" + cam.lower()
    CRUDO = os.path.join(RAIZ, "data", "raw", "rover_fotos" + sufijo)
    SALIDA = os.path.join(RAIZ, "data", "work", "fotos_rover%s.json" % sufijo)
    fijadas = dict(a.split("=", 1) for a in sys.argv if "=" in a and a[0].isdigit()) if "--elegir" in sys.argv else {}
    objetivos = json.load(open(os.path.join(RAIZ, "config", "objectives.json")))["objectives"]
    os.makedirs(CRUDO, exist_ok=True)
    out = {}
    for o in objetivos:
        sol = int(re.search(r"(\d+)", o["source"]).group(1))
        items = json.load(urllib.request.urlopen(API % (sol, sol, "NAV_LEFT_B,NAV_RIGHT_B" if cam == "NAV" else cam), timeout=60))["items"]
        full = [x for x in items if not x.get("is_thumbnail") and (cam == "NAV" or (x["imageid"].endswith("_DXXX") and "C00" in x["imageid"]))]
        if str(sol) in fijadas:
            full = [x for x in full if x["imageid"] == fijadas[str(sol)]]
        x = full[0]
        ruta = os.path.join(CRUDO, "%s.jpg" % x["imageid"])
        if not os.path.exists(ruta):
            urllib.request.urlretrieve(x["url"], ruta)
        out[o["id"]] = {"sol": sol, "camera": "Mastcam Left (34 mm)" if cam == "MAST_LEFT" else "Navcam (" + x["instrument"] + ")", "imageid": x["imageid"], "date_taken": x["date_taken"],
                        "credit": x.get("image_credit"), "url": x["url"], "file": os.path.basename(ruta), "bytes": os.path.getsize(ruta)}
        print(o["id"], sol, x["imageid"], x["date_taken"], os.path.getsize(ruta), "bytes")
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    json.dump(out, open(SALIDA, "w"), indent=1)
    if cam == "NAV":  # las fotos de Navcam son las que usa la app
        import shutil
        dest = os.path.join(RAIZ, "app", "assets", "site_gale", "rover")
        os.makedirs(dest, exist_ok=True)
        for v in out.values():
            shutil.copy(os.path.join(CRUDO, v["file"]), dest)
        pub = {k: {"sol": v["sol"], "camera": v["camera"], "date_taken": v["date_taken"], "credit": v["credit"], "file": v["file"]} for k, v in out.items()}
        json.dump(pub, open(os.path.join(RAIZ, "app", "assets", "site_gale", "rover_photos.json"), "w"), indent=1)
        print("copiado a", dest)


main()
