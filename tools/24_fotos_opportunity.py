"""Fotos reales de Opportunity en Perseverance Valley (borde de Endeavour), para la tarjeta del Casco en Meridiani.

La API de imágenes crudas de mars.nasa.gov solo trae Curiosity, así que se usan cuatro imágenes publicadas por el JPL en la
NASA Image and Video Library (images-api.nasa.gov; crédito NASA/JPL-Caltech). Son mosaicos ya procesados, no imágenes crudas.
Se descargan una vez a data/raw/opportunity_fotos/ y se copian a app/assets/meridiani_opportunity/ con zone_photos.json.

Uso: python 24_fotos_opportunity.py
"""
import json
import os
import shutil
import urllib.request

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(RAIZ, "data", "raw", "opportunity_fotos")
DEST = os.path.join(RAIZ, "app", "assets", "meridiani_opportunity")
BASE = "https://images-assets.nasa.gov/image/%s/%s.jpg"

# id PIA, versión, cámara, sol (el primero, si abarca varios), fecha, títulos (EN: el del JPL; ES: traducción del equipo)
FOTOS = [
    ("PIA21724", "PIA21724~medium", "Navcam", 4782, "2017-07-07", "View Down 'Perseverance Valley' After Entry at Top", "Vista cuesta abajo de «Perseverance Valley» al entrar por arriba"),
    ("PIA21725", "PIA21725~small", "Navcam", 4793, "2017-07-18", "View Back Uphill After Entering 'Perseverance Valley'", "Vista hacia atrás, cuesta arriba, tras entrar a «Perseverance Valley»"),
    ("PIA22074", "PIA22074~medium", "Pancam", 4840, "2017-09-04", "View From Within 'Perseverance Valley' on Mars", "Vista desde dentro de «Perseverance Valley»"),
    ("PIA22071", "PIA22071~small", "Navcam", 4911, "2017-11-11", "Opportunity's View Downhill Catches Martian Shadows", "La vista cuesta abajo de Opportunity capta sombras marcianas"),
]


def main():
    os.makedirs(RAW, exist_ok=True)
    os.makedirs(DEST, exist_ok=True)
    out = []
    for pia, version, cam, sol, fecha, en, es in FOTOS:
        ruta = os.path.join(RAW, version + ".jpg")
        if not os.path.exists(ruta):
            req = urllib.request.Request(BASE % (pia, version), headers={"User-Agent": "research-client"})
            with urllib.request.urlopen(req, timeout=60) as r, open(ruta, "wb") as f:
                f.write(r.read())
        archivo = pia + ".jpg"
        shutil.copyfile(ruta, os.path.join(DEST, archivo))
        print(f"{archivo}: {os.path.getsize(ruta)} bytes")
        out.append({"id": pia, "file": archivo, "camera": cam, "sol": sol, "date_taken": fecha, "title_en": en, "title_es": es,
                    "credit": "NASA/JPL-Caltech", "source": f"https://photojournal.jpl.nasa.gov/catalog/{pia}"})
    with open(os.path.join(DEST, "zone_photos.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
