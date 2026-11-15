"""Fase 4, criterio de cierre: compara tres soles al azar del JSON de la app con los archivos originales de la NASA.

Recalcula con numpy, de forma independiente a 06_clima_radiacion.py, el clima de REMS (temperatura del aire, presión)
y la dosis media de RAD de cada sol elegido, y los compara con app/assets/site_gale/environment.json.

Uso (desde tools/):
    python3 comprobar_ambiente.py [--semilla 7]
"""
import argparse
import csv
import datetime as dt
import json
import math
import os
import random

import numpy as np

import common

REMS_DIR = os.path.join(common.RAW, "rems")
RAD_DIR = os.path.join(common.RAW, "rad")
SOL_S = 88775.244147


def rems_crudo(sol):
    """Mediana horaria del aire y media horaria de la presión, a partir del archivo original."""
    ruta = os.path.join(REMS_DIR, f"RMD_sol{sol:05d}.TAB")
    horas_aire = {h: [] for h in range(24)}
    horas_pres = {h: [] for h in range(24)}
    with open(ruta, encoding="utf-8", errors="ignore") as f:
        for r in csv.reader(f):
            if len(r) < 40 or not r[1].strip().startswith(f"{sol:05d}"):
                continue
            h = int(r[1].strip()[6:8])
            a, p = float(r[15]), float(r[37])
            if -999 != a and 120 < a < 330:
                horas_aire[h].append(a - 273.15)
            if -999 != p and 300 < p < 1500:
                horas_pres[h].append(p)
    aire = [float(np.median(v)) for v in horas_aire.values() if v]
    pres = [float(np.mean(v)) for v in horas_pres.values() if v]
    return min(aire), max(aire), min(pres), max(pres), len(aire)


def rad_crudo(sol, ref_sol, ref_utc):
    """Media de la dosis E de todas las mediciones de RAD dentro del sol, a partir de los CSV originales."""
    ini = ref_utc + dt.timedelta(seconds=(sol - ref_sol) * SOL_S)
    fin = ini + dt.timedelta(seconds=SOL_S)
    vals = []
    for nombre in sorted(os.listdir(RAD_DIR)):
        if not nombre.endswith(".csv"):
            continue
        with open(os.path.join(RAD_DIR, nombre), encoding="utf-8") as f:
            lineas = [l for l in f if not l.startswith("#") and l.strip()]
        if not lineas:
            continue
        lector = csv.reader(lineas)
        cab = next(lector)
        ie = next(i for i, c in enumerate(cab) if c.startswith("TOTAL_DOSE_E"))
        ib = next(i for i, c in enumerate(cab) if c.startswith("RTG_CORRECTED_DOSE_B"))
        for r in lector:
            t = dt.datetime.strptime(r[0][:19], "%Y-%m-%dT%H:%M:%S").replace(tzinfo=dt.timezone.utc)
            if ini <= t < fin:
                e, b = float(r[ie]), float(r[ib])
                if e > 0 and b > 0 and not math.isnan(e):
                    vals.append(e)
    return float(np.mean(vals)), len(vals)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--semilla", type=int, default=7)
    a = ap.parse_args()
    env = json.load(open(os.path.join(common.SALIDA, "environment.json"), encoding="utf-8"))
    ref_sol = env["sol_calibration"]["sol"]
    ref_utc = dt.datetime.strptime(env["sol_calibration"]["utc_lmst_midnight"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)
    clima = {c["sol"]: c for c in env["weather"]["sols"]}
    rad = {r["sol"]: r for r in env["radiation"]["per_sol"]}
    random.seed(a.semilla)
    elegidos = sorted(random.sample(sorted(clima), 3))
    print(f"soles elegidos al azar (semilla {a.semilla}): {elegidos}\n")
    ok = True
    for sol in elegidos:
        amin, amax, pmin, pmax, horas = rems_crudo(sol)
        c = clima[sol]
        edos, n = rad_crudo(sol, ref_sol, ref_utc)
        r = rad[sol]
        filas = [
            ("aire mínimo (°C)", amin, c["air_min_c"], 0.06),
            ("aire máximo (°C)", amax, c["air_max_c"], 0.06),
            ("presión mínima (Pa)", pmin, c["pressure_min_pa"], 0.06),
            ("presión máxima (Pa)", pmax, c["pressure_max_pa"], 0.06),
            ("horas con dato de aire", horas, c["hours_with_air_data"], 0.5),
            ("dosis E media (µGy/día)", edos, r["dose_e_mean_ugy_day"], 0.06),
            ("mediciones de RAD", n, r["n"], 0.5),
        ]
        print(f"SOL {sol}  (REMS {c['utc_start']} a {c['utc_stop']})")
        for nombre, crudo, json_, tol in filas:
            bien = abs(crudo - json_) <= tol
            ok &= bien
            print(f"  {nombre:26s} archivo original {crudo:10.2f}   JSON de la app {json_:10.2f}   {'coincide' if bien else 'NO COINCIDE'}")
        print()
    print("RESULTADO:", "los tres soles coinciden con los archivos originales" if ok else "HAY DIFERENCIAS")


if __name__ == "__main__":
    main()
