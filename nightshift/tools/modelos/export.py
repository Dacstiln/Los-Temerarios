"""Genera scenes/3d/monsters/<key>_3d.tscn a partir de monsters.py.
Uso: python3 export.py   (desde nightshift/tools/modelos)"""
import os
import monsters as MS
from mlib import export_tscn

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "scenes", "3d", "monsters")

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for key, fn in MS.ALL.items():
        root, mats, props = fn()
        path = os.path.join(OUT, "%s_3d.tscn" % key)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(export_tscn(root, mats, props, "res://scripts/3d/monster_rig_3d.gd"))
        print("escrito", os.path.normpath(path))
