"""F7 (C offline): mapas base de toda la región a 40 m por píxel, compartidos por los sitios de Gale y de Meridiani.

Entrada: data/raw/base/{gale,meridiani}_ctx_z10/ (mosaico CTX completo de Mars Trek, nivel 10, de `10_meridiani_datos.py base`)
Salida: app/assets/base_gale/ y app/assets/base_meridiani/ (pirámide de teselas JPEG de 512 px, niveles 0 a 4; un mundo cuadrado
        de 327 680 m, 40 m por píxel en el nivel 4) y la clave `base` en el site.json de cada sitio de la región.
El mapa base se dibuja bajo el marco de contexto y la ortofoto de detalle; sirve para que el mapa no termine en ningún borde.

Orden: después de 04, 11, 12, 15, 17 y 14 (los que reescriben site.json). Uso (desde tools/): python3 16_mapa_base.py
"""
import importlib.util
import json
import os

import common


def _cargar(nombre, archivo):
    spec = importlib.util.spec_from_file_location(nombre, os.path.join(os.path.dirname(os.path.abspath(__file__)), archivo))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


datos = _cargar("datos10", "10_meridiani_datos.py")
s11 = _cargar("sitio11", "11_sitio_meridiani.py")
ASSETS = os.path.join(common.RAIZ, "app", "assets")

REGIONES = [
    ("base_gale", datos.BASE_GALE, ("Gale_CTX_BlockAdj_dd", 10, os.path.join(datos.RAW_B, "gale_ctx_z10")),
     ["site_gale", "site_gale_reach"], "CTX (MRO) mosaic of Gale crater, via NASA Mars Trek (WMTS level 10, 40 m/px)"),
    ("base_meridiani", datos.BASE_MERIDIANI, ("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 10, os.path.join(datos.RAW_B, "meridiani_ctx_z10")),
     ["site_meridiani_endeavour", "site_meridiani_endeavour_reach", "site_meridiani_habitat", "site_meridiani_regional"],
     "CTX (MRO) mosaic of Meridiani Planum - Sinus Meridiani, via NASA Mars Trek (WMTS level 10, 40 m/px)"),
]


def main():
    p = common.params()
    for asset, ventana, tesela, sitios, fuente in REGIONES:
        print("==", asset)
        s = {"tesela": tesela, "ventana": ventana, "mundo_m": ventana["size_m"], "zmax": 4}
        gris = s11.mosaico_ortofoto(s)
        s11.exportar_teselas(s, p, ASSETS, gris, nombre=asset)
        mpp = [ventana["size_m"] / (p["tiles"]["tile_px"] * 2 ** z) for z in range(5)]
        for sitio in sitios:
            ruta = os.path.join(ASSETS, sitio, "site.json")
            if not os.path.exists(ruta):
                continue
            site = json.load(open(ruta, encoding="utf-8"))
            g = site["georeference"]
            site["base"] = {"asset_dir": asset, "x_m": ventana["x0"] - g["origin_easting_m"], "y_m": g["origin_northing_m"] - ventana["y0"],
                            "size_m": ventana["size_m"], "tile_px": p["tiles"]["tile_px"], "max_zoom": 4, "world_size_m": ventana["size_m"],
                            "m_per_px": mpp, "source": fuente, "resolution_m": 40.7}
            with open(ruta, "w", encoding="utf-8") as f:
                json.dump(site, f, indent=2)
            print("  base añadida a", sitio)


if __name__ == "__main__":
    main()
