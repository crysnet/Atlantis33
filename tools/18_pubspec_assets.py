"""Reescribe en app/pubspec.yaml las líneas de assets de los sitios nuevos (Meridiani, Gale de largo alcance) y de los mapas base.

Flutter exige declarar cada carpeta de assets; las pirámides de teselas tienen una carpeta por columna. Las líneas de `site_gale/`
(las originales) no se tocan. Uso (desde tools/): python3 18_pubspec_assets.py   (correrlo después de regenerar cualquier sitio)
"""
import os
import re

import common

APP = os.path.join(common.RAIZ, "app")
ASSETS = os.path.join(APP, "assets")
JSON = ["site.json", "params.json", "objectives.json", "curiosity_waypoints.json", "environment.json", "rover_photos.json", "vectors.json"]


def lineas():
    out = []
    for nombre in sorted(os.listdir(ASSETS)):
        d = os.path.join(ASSETS, nombre)
        if not os.path.isdir(d) or nombre == "site_gale":
            continue
        if nombre.startswith("base_"):
            for r, _, fs in sorted(os.walk(d)):
                if fs:
                    out.append("    - " + os.path.relpath(r, APP) + "/")
        elif nombre.startswith("site_"):
            out += [f"    - assets/{nombre}/{f}" for f in JSON if os.path.exists(os.path.join(d, f))]
            out += [f"    - assets/{nombre}/{s}/" for s in ("grid", "layers", "rover") if os.path.isdir(os.path.join(d, s))]
            for sub in ("ortho", "context"):
                for r, _, fs in sorted(os.walk(os.path.join(d, sub))):
                    if fs:
                        out.append("    - " + os.path.relpath(r, APP) + "/")
    return out


def main():
    ruta = os.path.join(APP, "pubspec.yaml")
    t = open(ruta, encoding="utf-8").read().split("\n")
    t = [l for l in t if not re.search(r"assets/(site_(meridiani|gale_reach)|base_)", l)]
    i = next(k for k, l in enumerate(t) if "assets/site_gale/site.json" in l)
    nuevas = lineas()
    t[i:i] = nuevas
    open(ruta, "w", encoding="utf-8").write("\n".join(t))
    print(len(nuevas), "líneas de assets escritas")


if __name__ == "__main__":
    main()
