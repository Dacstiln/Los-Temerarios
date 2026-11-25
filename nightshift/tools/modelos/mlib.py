"""Mini-libreria para describir modelos 3D con primitivas de Godot,
exportarlos a .tscn y renderizar una vista previa (sin Godot)."""
import math
import numpy as np


# ------------------------------------------------------------------ jerarquia
class Part:
    def __init__(self, name, kind="node", params=None, mat=None, pos=(0, 0, 0),
                 rot=(0, 0, 0), scale=(1, 1, 1), children=None, extra=None):
        self.name = name
        self.kind = kind          # node | box | sphere | cyl | capsule | torus | prism | light
        self.params = params or {}
        self.mat = mat
        self.pos = tuple(float(v) for v in pos)
        self.rot = tuple(float(v) for v in rot)      # grados, orden YXZ (como Godot)
        self.scale = tuple(float(v) for v in scale)
        self.children = children or []
        self.extra = extra or {}

    def add(self, *parts):
        self.children.extend(parts)
        return self


def node(name, pos=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), children=None):
    return Part(name, "node", pos=pos, rot=rot, scale=scale, children=children)


def box(name, size, mat, pos=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), children=None):
    return Part(name, "box", {"size": size}, mat, pos, rot, scale, children)


def sph(name, r, mat, pos=(0, 0, 0), scale=(1, 1, 1), rot=(0, 0, 0), seg=(18, 10), children=None):
    return Part(name, "sphere", {"radius": r, "height": 2 * r, "seg": seg[0], "rings": seg[1]},
                mat, pos, rot, scale, children)


def cyl(name, rt, rb, h, mat, pos=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), seg=16, children=None):
    return Part(name, "cyl", {"top": rt, "bottom": rb, "height": h, "seg": seg},
                mat, pos, rot, scale, children)


def cap(name, r, h, mat, pos=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1), children=None):
    return Part(name, "capsule", {"radius": r, "height": max(h, 2 * r + 0.001)},
                mat, pos, rot, scale, children)


def torus(name, ri, ro, mat, pos=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    return Part(name, "torus", {"inner": ri, "outer": ro}, mat, pos, rot, scale)


def prism(name, size, mat, pos=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    return Part(name, "prism", {"size": size}, mat, pos, rot, scale)


def light(name, color, energy, rng, pos=(0, 0, 0)):
    return Part(name, "light", {"color": color, "energy": energy, "range": rng}, pos=pos)


def on_ellipsoid(center, radii, x, y, inset=0.0):
    """z de la superficie frontal de un elipsoide en (x, y) (para pegar rasgos a la cara)."""
    cx, cy, cz = center
    rx, ry, rz = radii
    v = 1.0 - ((x - cx) / rx) ** 2 - ((y - cy) / ry) ** 2
    return cz + rz * math.sqrt(max(v, 0.0)) - inset


# ------------------------------------------------------------------ matematicas
def rot_matrix(deg):
    rx, ry, rz = (math.radians(a) for a in deg)
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return Ry @ Rx @ Rz          # Godot: euler YXZ


def local_matrix(p):
    m = np.eye(4)
    m[:3, :3] = rot_matrix(p.rot) @ np.diag(p.scale)
    m[:3, 3] = p.pos
    return m


# ------------------------------------------------------------------ export .tscn
def _f(v):
    s = ("%.5f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def _color(c):
    c = list(c) + [1.0] * (4 - len(c))
    return "Color(%s)" % ", ".join(_f(x) for x in c)


def _vec3(v):
    return "Vector3(%s)" % ", ".join(_f(x) for x in v)


def _transform(p):
    m = local_matrix(p)
    rows = [m[i, j] for i in range(3) for j in range(3)]
    return "Transform3D(%s)" % ", ".join(_f(x) for x in rows + list(m[:3, 3]))


def _mesh_key(p):
    q = dict(p.params)
    return (p.kind,) + tuple(sorted((k, tuple(v) if isinstance(v, (list, tuple)) else v) for k, v in q.items()))


def _mesh_body(p):
    q = p.params
    if p.kind == "box":
        return "BoxMesh", ["size = %s" % _vec3(q["size"])]
    if p.kind == "sphere":
        return "SphereMesh", ["radius = %s" % _f(q["radius"]), "height = %s" % _f(q["height"]),
                              "radial_segments = %d" % q["seg"], "rings = %d" % q["rings"]]
    if p.kind == "cyl":
        return "CylinderMesh", ["top_radius = %s" % _f(q["top"]), "bottom_radius = %s" % _f(q["bottom"]),
                                "height = %s" % _f(q["height"]), "radial_segments = %d" % q["seg"], "rings = 1"]
    if p.kind == "capsule":
        return "CapsuleMesh", ["radius = %s" % _f(q["radius"]), "height = %s" % _f(q["height"]),
                               "radial_segments = 16", "rings = 6"]
    if p.kind == "torus":
        return "TorusMesh", ["inner_radius = %s" % _f(q["inner"]), "outer_radius = %s" % _f(q["outer"]),
                             "rings = 24", "ring_segments = 8"]
    if p.kind == "prism":
        return "PrismMesh", ["size = %s" % _vec3(q["size"])]
    raise ValueError(p.kind)


def export_tscn(root, materials, root_props, script_path, header_comment=""):
    meshes, mesh_ids = [], {}
    used_mats = []

    def walk(p):
        if p.kind not in ("node", "light"):
            k = _mesh_key(p)
            if k not in mesh_ids:
                mesh_ids[k] = "mesh_%d" % (len(meshes) + 1)
                meshes.append((mesh_ids[k], p))
            if p.mat not in used_mats:
                used_mats.append(p.mat)
        for c in p.children:
            walk(c)
    walk(root)

    out = []
    n_res = 1 + len(used_mats) + len(meshes)
    out.append("[gd_scene load_steps=%d format=3]" % (n_res + 1))
    out.append("")
    out.append('[ext_resource type="Script" path="%s" id="1_rig"]' % script_path)
    out.append("")
    for name in used_mats:
        m = materials[name]
        out.append('[sub_resource type="StandardMaterial3D" id="mat_%s"]' % name)
        if m.get("local"):
            out.append("resource_local_to_scene = true")
        out.append("resource_name = \"%s\"" % name)
        out.append("albedo_color = %s" % _color(m["color"]))
        out.append("metallic = %s" % _f(m.get("metal", 0.0)))
        out.append("roughness = %s" % _f(m.get("rough", 0.7)))
        if "emission" in m:
            out.append("emission_enabled = true")
            out.append("emission = %s" % _color(m["emission"]))
            out.append("emission_energy_multiplier = %s" % _f(m.get("energy", 1.0)))
        out.append("")
    for mid, p in meshes:
        t, body = _mesh_body(p)
        out.append('[sub_resource type="%s" id="%s"]' % (t, mid))
        out.extend(body)
        out.append("")

    def emit(p, parent_path, is_root=False):
        if is_root:
            out.append('[node name="%s" type="Node3D"]' % p.name)
            out.append('script = ExtResource("1_rig")')
            for k, v in root_props.items():
                out.append("%s = %s" % (k, _color(v) if isinstance(v, tuple) else _f(v)))
            out.append("")
            child_parent = "."
        else:
            t = {"node": "Node3D", "light": "OmniLight3D"}.get(p.kind, "MeshInstance3D")
            out.append('[node name="%s" type="%s" parent="%s"]' % (p.name, t, parent_path))
            if p.pos != (0, 0, 0) or p.rot != (0, 0, 0) or p.scale != (1, 1, 1):
                out.append("transform = %s" % _transform(p))
            if p.kind == "light":
                q = p.params
                out.append("light_color = %s" % _color(q["color"]))
                out.append("light_energy = %s" % _f(q["energy"]))
                out.append("omni_range = %s" % _f(q["range"]))
                out.append("omni_attenuation = 2.0")
            elif p.kind != "node":
                out.append('mesh = SubResource("%s")' % mesh_ids[_mesh_key(p)])
                out.append('surface_material_override/0 = SubResource("mat_%s")' % p.mat)
                out.append("cast_shadow = 1")
            out.append("")
            child_parent = p.name if parent_path == "." else parent_path + "/" + p.name
        names = set()
        for c in p.children:
            assert c.name not in names, "nombre repetido: %s en %s" % (c.name, p.name)
            names.add(c.name)
            emit(c, child_parent)
    emit(root, None, True)
    text = "\n".join(out).rstrip() + "\n"
    if header_comment:
        pass  # los .tscn no admiten comentarios de forma estable; la doc va en el script
    return text


# ------------------------------------------------------------------ triangulos (vista previa)
def _tri_box(q):
    sx, sy, sz = (v / 2 for v in q["size"])
    v = np.array([[x, y, z] for x in (-sx, sx) for y in (-sy, sy) for z in (-sz, sz)])
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return [(v[a], v[b], v[c]) for f in faces for (a, b, c) in ((f[0], f[1], f[2]), (f[0], f[2], f[3]))]


def _grid(fn, nu, nv):
    tris = []
    for i in range(nu):
        for j in range(nv):
            p00, p10, p01, p11 = fn(i, j), fn(i + 1, j), fn(i, j + 1), fn(i + 1, j + 1)
            tris += [(p00, p10, p11), (p00, p11, p01)]
    return tris


def _tri_sphere(q):
    r, h = q["radius"], q["height"]
    nu, nv = q["seg"], q["rings"]

    def fn(i, j):
        th = 2 * math.pi * i / nu
        ph = math.pi * j / nv
        return np.array([r * math.sin(ph) * math.cos(th), (h / 2) * math.cos(ph), r * math.sin(ph) * math.sin(th)])
    return _grid(fn, nu, nv)


def _tri_cyl(q):
    rt, rb, h, n = q["top"], q["bottom"], q["height"], q["seg"]
    tris = []
    for i in range(n):
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        t0 = np.array([rt * math.cos(a0), h / 2, rt * math.sin(a0)])
        t1 = np.array([rt * math.cos(a1), h / 2, rt * math.sin(a1)])
        b0 = np.array([rb * math.cos(a0), -h / 2, rb * math.sin(a0)])
        b1 = np.array([rb * math.cos(a1), -h / 2, rb * math.sin(a1)])
        tris += [(b0, t0, t1), (b0, t1, b1)]
        tris += [(np.array([0, h / 2, 0]), t1, t0), (np.array([0, -h / 2, 0]), b0, b1)]
    return tris


def _tri_capsule(q):
    r, H = q["radius"], q["height"]
    half = H / 2 - r
    nu, nv = 16, 12

    def fn(i, j):
        th = 2 * math.pi * i / nu
        ph = math.pi * j / nv
        y = r * math.cos(ph) + (half if j <= nv / 2 else -half)
        return np.array([r * math.sin(ph) * math.cos(th), y, r * math.sin(ph) * math.sin(th)])
    return _grid(fn, nu, nv)


def _tri_torus(q):
    ri, ro = q["inner"], q["outer"]
    R, a = (ri + ro) / 2, (ro - ri) / 2

    def fn(i, j):
        th = 2 * math.pi * i / 24
        ph = 2 * math.pi * j / 8
        rr = R + a * math.cos(ph)
        return np.array([rr * math.cos(th), a * math.sin(ph), rr * math.sin(th)])
    return _grid(fn, 24, 8)


def _tri_prism(q):
    sx, sy, sz = (v / 2 for v in q["size"])
    a, b, c = np.array([-sx, -sy, 0]), np.array([sx, -sy, 0]), np.array([0, sy, 0])
    f, k = np.array([0, 0, sz]), np.array([0, 0, -sz])
    tris = [(a + f, b + f, c + f), (a + k, c + k, b + k)]
    for p, q2 in ((a, b), (b, c), (c, a)):
        tris += [(p + f, p + k, q2 + k), (p + f, q2 + k, q2 + f)]
    return tris


TRI = {"box": _tri_box, "sphere": _tri_sphere, "cyl": _tri_cyl, "capsule": _tri_capsule,
       "torus": _tri_torus, "prism": _tri_prism}


def collect_triangles(root, overrides=None):
    """Devuelve lista (tri_world[3x3], mat_name). overrides: name -> Part extra transform."""
    out = []

    def walk(p, parent_m):
        m = parent_m @ local_matrix(p)
        if overrides and p.name in overrides:
            m = m @ overrides[p.name]
        if p.kind in TRI:
            for t in TRI[p.kind](p.params):
                pts = np.array([m[:3, :3] @ v + m[:3, 3] for v in t])
                out.append((pts, p.mat))
        for c in p.children:
            walk(c, m)
    walk(root, np.eye(4))
    return out


def bounds(root):
    tris = collect_triangles(root)
    pts = np.concatenate([t for t, _ in tris])
    return pts.min(axis=0), pts.max(axis=0)
