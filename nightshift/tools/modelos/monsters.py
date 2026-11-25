"""Los cinco monstruos de Night Shift at The Grand Tenebris, hechos con primitivas.
Convencion: origen en los pies, +Y arriba, la cara mira a +Z. Unidades = metros."""
import math
from mlib import Part, node, box, sph, cyl, cap, torus, prism, light, on_ellipsoid as oe

GOLD = {"color": (0.83, 0.66, 0.24), "metal": 0.85, "rough": 0.32}
SHOE = {"color": (0.025, 0.022, 0.022), "rough": 0.28}
SOCKET = {"color": (0.015, 0.008, 0.008), "rough": 0.9}


def eye_mat(c, energy=3.0):
    return {"color": c, "emission": c, "energy": energy, "rough": 0.2, "local": True}


def eyes(head_c, head_r, xoff, y, mat_socket="socket", r_eye=0.02, r_sock=0.034, sock_scale=(1.2, 1.0, 0.5)):
    zs = oe(head_c, head_r, xoff, y) - 0.006
    ze = zs + r_sock * sock_scale[2] * 0.45
    parts = []
    for side, sx in (("L", 1), ("R", -1)):
        parts.append(sph("Socket" + side, r_sock, mat_socket, (sx * xoff, y, zs), scale=sock_scale, seg=(12, 8)))
        parts.append(sph("Eye" + side, r_eye, "eye", (sx * xoff, y, ze), seg=(12, 8)))
    return parts


# ============================================================== EL BOTONES
def botones():
    M = {
        "uniform": {"color": (0.50, 0.06, 0.09), "rough": 0.62},
        "uniform_dark": {"color": (0.27, 0.03, 0.05), "rough": 0.7},
        "gold": GOLD,
        "skin": {"color": (0.80, 0.77, 0.69), "rough": 0.5},
        "skin_shade": {"color": (0.58, 0.52, 0.46), "rough": 0.6},
        "pants": {"color": (0.05, 0.05, 0.07), "rough": 0.7},
        "shoe": SHOE,
        "stitch": {"color": (0.02, 0.01, 0.01), "rough": 0.9},
        "mouth": {"color": (0.22, 0.02, 0.03), "rough": 0.4},
        "socket": SOCKET,
        "eye": eye_mat((1.0, 0.93, 0.62), 3.2),
    }
    body = node("Body", rot=(5, 0, 0))
    for side, sx in (("L", 1), ("R", -1)):
        body.add(cap("Leg" + side, 0.072, 0.92, "pants", (sx * 0.1, 0.48, 0)))
        body.add(box("Stripe" + side, (0.012, 0.78, 0.03), "gold", (sx * 0.171, 0.5, 0)))
        body.add(box("Shoe" + side, (0.12, 0.08, 0.27), "shoe", (sx * 0.1, 0.04, 0.045)))
    body.add(box("Hips", (0.31, 0.16, 0.19), "pants", (0, 0.92, 0)))
    body.add(cyl("Torso", 0.205, 0.17, 0.52, "uniform", (0, 1.2, 0), scale=(1, 1, 0.62)))
    body.add(cyl("Hem", 0.178, 0.2, 0.1, "uniform_dark", (0, 0.92, 0), scale=(1, 1, 0.66)))
    body.add(cyl("Belt", 0.181, 0.181, 0.035, "gold", (0, 1.0, 0), scale=(1, 1, 0.64)))
    for i in range(4):
        y = 1.06 + i * 0.1
        r_here = 0.17 + (y - 0.94) / 0.52 * 0.035
        for side, sx in (("L", 1), ("R", -1)):
            body.add(sph("Button%d%s" % (i, side), 0.016, "gold", (sx * 0.06, y, r_here * 0.62 + 0.004), seg=(8, 6)))
    for side, sx in (("L", 1), ("R", -1)):
        body.add(box("Epaulette" + side, (0.15, 0.035, 0.13), "gold", (sx * 0.2, 1.47, 0)))
        body.add(cyl("Fringe" + side, 0.066, 0.078, 0.06, "gold", (sx * 0.215, 1.425, 0), seg=10))
    body.add(cyl("Collar", 0.07, 0.092, 0.075, "uniform_dark", (0, 1.49, 0)))
    body.add(cyl("Neck", 0.044, 0.044, 0.12, "skin", (0, 1.55, 0), seg=10))

    for side, sx in (("L", 1), ("R", -1)):
        arm = node("Arm" + side, pos=(sx * 0.235, 1.43, 0), rot=(-6, 0, sx * 5))
        arm.add(cap("Upper", 0.055, 0.42, "uniform", (0, -0.2, 0)))
        arm.add(cap("Fore", 0.05, 0.44, "uniform", (0, -0.56, 0.03), rot=(-8, 0, 0)))
        arm.add(cyl("Cuff", 0.058, 0.058, 0.05, "gold", (0, -0.76, 0.055), rot=(-8, 0, 0), seg=12))
        arm.add(sph("Hand", 0.052, "skin", (0, -0.85, 0.07), scale=(0.8, 1.45, 0.6), seg=(12, 8)))
        for k, dx in enumerate((-0.022, 0.0, 0.022)):
            arm.add(cap("Finger%d" % k, 0.011, 0.17 - abs(dx) * 1.2, "skin", (dx, -0.97, 0.075), rot=(-6, 0, 0)))
        body.add(arm)

    hc, hr = (0, 0.14, 0), (0.12, 0.15, 0.124)
    head = node("Head", pos=(0, 1.6, 0.01), rot=(4, 0, 11))
    head.add(sph("Skull", 1.0, "skin", hc, scale=hr))
    head.add(sph("Jaw", 0.1, "skin", (0, 0.05, 0.02), scale=(0.86, 0.6, 0.86)))
    head.add(*eyes(hc, hr, 0.047, 0.165, r_eye=0.021))
    head.add(sph("Nose", 0.016, "skin_shade", (0, 0.12, oe(hc, hr, 0, 0.12) - 0.004), seg=(8, 6)))
    for side, sx in (("L", 1), ("R", -1)):
        head.add(sph("Ear" + side, 0.03, "skin", (sx * 0.116, 0.14, 0), scale=(0.45, 1, 0.8), seg=(10, 6)))
    # Sonrisa cosida: arco + puntadas
    n = 7
    for i in range(n):
        x = -0.064 + i * (0.128 / (n - 1))
        y = 0.072 + 9.0 * x * x
        z = max(oe(hc, hr, x, y), oe((0, 0.05, 0.02), (0.086, 0.06, 0.086), x, y)) + 0.002
        slope = math.degrees(math.atan(18.0 * x))
        head.add(box("Smile%d" % i, (0.024, 0.009, 0.006), "mouth", (x, y, z), rot=(0, 0, slope)))
        head.add(box("Stitch%d" % i, (0.004, 0.032, 0.005), "stitch", (x, y, z + 0.002), rot=(0, 0, slope)))
    # Gorra pillbox
    head.add(cyl("Cap", 0.102, 0.104, 0.09, "uniform", (0, 0.295, -0.012), rot=(-10, 0, 0), seg=18))
    head.add(cyl("CapBand", 0.106, 0.106, 0.026, "gold", (0, 0.262, -0.006), rot=(-10, 0, 0), seg=18))
    head.add(sph("CapButton", 0.013, "gold", (0, 0.343, -0.02), seg=(8, 6)))
    head.add(box("Strap", (0.2, 0.01, 0.008), "gold", (0, 0.02, 0.055), rot=(-30, 0, 0)))
    head.add(light("EyeLight", (1.0, 0.9, 0.6), 0.35, 0.45, (0, 0.165, 0.2)))
    body.add(head)

    root = node("Botones")
    root.add(body)
    props = {"breathe": 0.012, "sway_deg": 1.6, "twitch": 1.2, "eye_color": (1.0, 0.93, 0.62), "eye_energy": 3.2}
    return root, M, props


# ============================================================== EL CHEF
def chef():
    M = {
        "coat": {"color": (0.84, 0.82, 0.78), "rough": 0.85},
        "coat_shade": {"color": (0.58, 0.56, 0.54), "rough": 0.85},
        "apron": {"color": (0.74, 0.72, 0.68), "rough": 0.8},
        "blood": {"color": (0.40, 0.015, 0.025), "rough": 0.25},
        "blood_dark": {"color": (0.22, 0.01, 0.015), "rough": 0.3},
        "pants": {"color": (0.17, 0.17, 0.19), "rough": 0.8},
        "shoe": SHOE,
        "skin": {"color": (0.72, 0.58, 0.52), "rough": 0.45},
        "skin_shade": {"color": (0.52, 0.38, 0.34), "rough": 0.55},
        "kerchief": {"color": (0.52, 0.05, 0.06), "rough": 0.6},
        "steel": {"color": (0.70, 0.72, 0.76), "metal": 0.9, "rough": 0.18},
        "edge": {"color": (0.9, 0.92, 1.0), "metal": 0.9, "rough": 0.1, "emission": (0.85, 0.9, 1.0), "energy": 0.7},
        "wood": {"color": (0.22, 0.13, 0.07), "rough": 0.6},
        "teeth": {"color": (0.82, 0.78, 0.6), "rough": 0.4},
        "mouth": {"color": (0.1, 0.01, 0.015), "rough": 0.6},
        "socket": SOCKET,
        "eye": eye_mat((1.0, 0.16, 0.08), 3.5),
    }
    body = node("Body", rot=(6, 0, 0))
    for side, sx in (("L", 1), ("R", -1)):
        body.add(cap("Leg" + side, 0.12, 0.86, "pants", (sx * 0.16, 0.46, 0)))
        body.add(box("Shoe" + side, (0.2, 0.1, 0.32), "shoe", (sx * 0.16, 0.05, 0.05)))
    body.add(sph("Belly", 0.42, "coat", (0, 1.15, 0.02), scale=(1, 1.05, 0.85), seg=(20, 12)))
    body.add(cyl("Chest", 0.38, 0.41, 0.46, "coat", (0, 1.5, 0), scale=(1, 1, 0.7), seg=20))
    for side, sx in (("L", 1), ("R", -1)):
        body.add(sph("Shoulder" + side, 0.16, "coat", (sx * 0.36, 1.68, 0), seg=(14, 8)))
        for i in range(3):
            body.add(sph("Button%d%s" % (i, side), 0.024, "coat_shade", (sx * 0.11, 1.42 + i * 0.1, 0.272), seg=(8, 6)))
    apron = box("Apron", (0.5, 0.74, 0.03), "apron", (0, 1.0, 0.385), rot=(8, 0, 0))
    stains = [((0.13, 0.17), (-0.13, 0.08), "blood"), ((0.07, 0.26), (0.11, -0.12), "blood"),
              ((0.22, 0.07), (0.06, 0.24), "blood_dark"), ((0.025, 0.2), (-0.16, -0.1), "blood"),
              ((0.02, 0.14), (0.17, 0.05), "blood_dark"), ((0.09, 0.09), (-0.02, -0.26), "blood_dark")]
    for i, (sz, (x, y), m) in enumerate(stains):
        apron.add(box("Stain%d" % i, (sz[0], sz[1], 0.004), m, (x, y, 0.017)))
    body.add(apron)
    for side, sx in (("L", 1), ("R", -1)):
        body.add(box("ApronStrap" + side, (0.045, 0.34, 0.02), "apron", (sx * 0.16, 1.55, 0.27), rot=(-12, 0, -sx * 8)))
    body.add(cyl("Kerchief", 0.14, 0.175, 0.07, "kerchief", (0, 1.77, 0), seg=14))
    body.add(cyl("Neck", 0.13, 0.13, 0.1, "skin", (0, 1.8, 0), seg=14))

    for side, sx in (("L", 1), ("R", -1)):
        arm = node("Arm" + side, pos=(sx * 0.43, 1.65, 0), rot=(0, 0, sx * 8))
        arm.add(cap("Upper", 0.11, 0.5, "coat", (0, -0.22, 0)))
        arm.add(cyl("Roll", 0.118, 0.118, 0.08, "coat_shade", (0, -0.43, 0.03), rot=(-20, 0, 0), seg=12))
        arm.add(cap("Fore", 0.095, 0.48, "skin", (0, -0.6, 0.13), rot=(-38, 0, 0)))
        arm.add(sph("Hand", 0.1, "skin", (0, -0.78, 0.29), scale=(1, 1.1, 0.95), seg=(12, 8)))
        if sx < 0:
            cleaver = node("Cleaver", pos=(0, -0.8, 0.32), rot=(-25, 0, 0))
            cleaver.add(cyl("Handle", 0.022, 0.022, 0.17, "wood", (0, 0, 0), seg=8))
            cleaver.add(box("Blade", (0.012, 0.17, 0.3), "steel", (0, 0.16, 0.12)))
            cleaver.add(box("Edge", (0.014, 0.012, 0.3), "edge", (0, 0.08, 0.12)))
            cleaver.add(box("BladeBlood", (0.015, 0.07, 0.09), "blood", (0, 0.12, 0.2)))
            cleaver.add(cyl("Rivet", 0.012, 0.012, 0.016, "steel", (0, 0.22, -0.01), rot=(0, 0, 90), seg=8))
            arm.add(cleaver)
        body.add(arm)

    hc, hr = (0, 0.17, 0), (0.21, 0.2, 0.2)
    head = node("Head", pos=(0, 1.84, 0.02), rot=(8, 0, -4))
    head.add(sph("Skull", 1.0, "skin", hc, scale=hr, seg=(18, 12)))
    head.add(sph("Jowls", 0.17, "skin", (0, 0.06, 0.03), scale=(1.15, 0.7, 1.0)))
    head.add(*eyes(hc, hr, 0.075, 0.205, r_eye=0.026, r_sock=0.045))
    head.add(box("Brow", (0.27, 0.04, 0.06), "skin_shade", (0, 0.255, oe(hc, hr, 0, 0.255) - 0.02), rot=(22, 0, 0)))
    head.add(sph("Nose", 0.042, "skin_shade", (0, 0.15, oe(hc, hr, 0, 0.15) + 0.012), scale=(1, 0.8, 1), seg=(10, 8)))
    zj = oe((0, 0.06, 0.03), (0.1955, 0.119, 0.17), 0, 0.06)
    head.add(box("Maw", (0.2, 0.075, 0.05), "mouth", (0, 0.055, zj - 0.012)))
    for i in range(8):
        x = -0.085 + i * (0.17 / 7)
        head.add(box("ToothU%d" % i, (0.017, 0.026, 0.01), "teeth", (x, 0.082, zj + 0.012)))
        head.add(box("ToothD%d" % i, (0.017, 0.022, 0.01), "teeth", (x, 0.03, zj + 0.012)))
    for side, sx in (("L", 1), ("R", -1)):
        head.add(cyl("Fang" + side, 0.0, 0.013, 0.055, "teeth", (sx * 0.075, 0.064, zj + 0.016), rot=(180, 0, 0), seg=8))
    head.add(cyl("Band", 0.175, 0.175, 0.06, "coat_shade", (0, 0.35, -0.02), seg=18))
    head.add(cyl("Toque", 0.17, 0.165, 0.34, "coat", (0, 0.5, -0.02), seg=18))
    head.add(sph("ToquePuff", 0.21, "coat", (0, 0.69, -0.02), scale=(1, 0.55, 1), seg=(16, 8)))
    head.add(light("EyeLight", (1.0, 0.2, 0.1), 0.45, 0.6, (0, 0.205, 0.32)))
    body.add(head)

    root = node("Chef")
    root.add(body)
    props = {"breathe": 0.02, "sway_deg": 1.0, "twitch": 0.6, "eye_color": (1.0, 0.16, 0.08), "eye_energy": 3.5}
    return root, M, props


# ============================================================== LA MUCAMA
def mucama():
    M = {
        "dress": {"color": (0.065, 0.065, 0.09), "rough": 0.72},
        "dress_hi": {"color": (0.14, 0.14, 0.18), "rough": 0.7},
        "apron": {"color": (0.82, 0.82, 0.79), "rough": 0.8},
        "lace": {"color": (0.9, 0.9, 0.88), "rough": 0.9},
        "skin": {"color": (0.66, 0.69, 0.72), "rough": 0.45},
        "hair": {"color": (0.03, 0.025, 0.03), "rough": 0.45},
        "tear": {"color": (0.02, 0.015, 0.03), "rough": 0.05},
        "wood": {"color": (0.33, 0.2, 0.1), "rough": 0.5},
        "feather": {"color": (0.52, 0.45, 0.36), "rough": 1.0},
        "feather_d": {"color": (0.3, 0.25, 0.2), "rough": 1.0},
        "mouth": {"color": (0.08, 0.03, 0.05), "rough": 0.6},
        "socket": {"color": (0.06, 0.05, 0.09), "rough": 0.8},
        "eye": eye_mat((0.82, 0.9, 1.0), 2.6),
    }
    body = node("Body")
    body.add(cyl("Skirt", 0.17, 0.42, 0.9, "dress", (0, 0.47, 0), seg=20))
    body.add(cyl("Hem", 0.43, 0.45, 0.06, "dress_hi", (0, 0.03, 0), seg=20))
    body.add(cyl("Lace", 0.41, 0.42, 0.03, "lace", (0, 0.085, 0), seg=20))
    slope = math.degrees(math.atan(0.25 / 0.9))

    def skirt_r(y):
        return 0.42 - (y - 0.02) / 0.9 * 0.25
    body.add(box("Apron", (0.27, 0.62, 0.02), "apron", (0, 0.6, skirt_r(0.6) + 0.004), rot=(-slope, 0, 0)))
    body.add(box("ApronLace", (0.29, 0.035, 0.022), "lace", (0, 0.29, skirt_r(0.29) + 0.006), rot=(-slope, 0, 0)))
    body.add(cyl("Waist", 0.15, 0.17, 0.1, "dress", (0, 0.92, 0), seg=16))
    body.add(cyl("Ties", 0.156, 0.16, 0.04, "apron", (0, 0.905, 0), seg=16))
    body.add(cyl("Bodice", 0.17, 0.14, 0.42, "dress", (0, 1.15, 0), scale=(1, 1, 0.7), seg=16))
    body.add(box("Bib", (0.19, 0.24, 0.02), "apron", (0, 1.06, 0.11)))
    for side, sx in (("L", 1), ("R", -1)):
        body.add(box("BibStrap" + side, (0.035, 0.26, 0.02), "apron", (sx * 0.09, 1.25, 0.095), rot=(-14, 0, 0)))
        body.add(sph("Puff" + side, 0.09, "dress_hi", (sx * 0.19, 1.33, 0), seg=(12, 8)))
    body.add(cyl("Collar", 0.07, 0.1, 0.05, "lace", (0, 1.38, 0), seg=14))
    body.add(cyl("Neck", 0.037, 0.037, 0.12, "skin", (0, 1.44, 0), seg=10))

    for side, sx in (("L", 1), ("R", -1)):
        arm = node("Arm" + side, pos=(sx * 0.2, 1.32, 0), rot=(-4, 0, sx * 4))
        arm.add(cap("Upper", 0.044, 0.36, "dress", (0, -0.18, 0)))
        arm.add(cap("Fore", 0.04, 0.42, "dress", (0, -0.53, 0.02)))
        arm.add(cyl("Cuff", 0.048, 0.048, 0.04, "lace", (0, -0.72, 0.03), seg=10))
        arm.add(sph("Hand", 0.045, "skin", (0, -0.8, 0.03), scale=(0.8, 1.6, 0.5), seg=(10, 8)))
        for k, dx in enumerate((-0.018, 0.0, 0.018)):
            arm.add(cap("Finger%d" % k, 0.009, 0.16 - abs(dx) * 1.5, "skin", (dx, -0.92, 0.03)))
        if sx < 0:
            duster = node("Duster", pos=(0, -0.83, 0.06), rot=(30, 0, 0))
            duster.add(cyl("Stick", 0.013, 0.015, 0.5, "wood", (0, 0.16, 0), seg=8))
            duster.add(sph("Core", 0.06, "feather_d", (0, 0.44, 0), scale=(1, 1.3, 1), seg=(10, 8)))
            for k in range(9):
                a = k * 40.0
                tilt = 35 if k % 2 == 0 else 55
                f = node("Plume%d" % k, pos=(0, 0.44, 0), rot=(0, a, 0))
                f.add(cyl("Feather", 0.0, 0.045, 0.2, "feather" if k % 2 == 0 else "feather_d",
                          (0, 0.09, 0), rot=(tilt, 0, 0), seg=6))
                duster.add(f)
            arm.add(duster)
        body.add(arm)

    hc, hr = (0, 0.12, 0), (0.099, 0.132, 0.104)
    head = node("Head", pos=(0, 1.49, 0), rot=(12, 0, -9))
    head.add(sph("Face", 1.0, "skin", hc, scale=hr, seg=(16, 10)))
    head.add(sph("HairBack", 0.125, "hair", (0, 0.15, -0.035), scale=(1.02, 1.2, 0.85), seg=(16, 10)))
    head.add(box("HairLong", (0.23, 0.52, 0.06), "hair", (0, -0.1, -0.085), rot=(-6, 0, 0)))
    for side, sx in (("L", 1), ("R", -1)):
        head.add(box("Strand" + side, (0.04, 0.4, 0.04), "hair", (sx * 0.098, 0.0, 0.035), rot=(0, 0, sx * 3)))
    head.add(box("Bangs", (0.2, 0.05, 0.05), "hair", (0, 0.245, 0.06), rot=(-25, 0, 0)))
    head.add(cyl("Cap", 0.095, 0.115, 0.04, "lace", (0, 0.29, -0.02), rot=(-15, 0, 0), seg=16))
    head.add(torus("Frill", 0.09, 0.128, "lace", (0, 0.272, -0.012), rot=(-15, 0, 0)))
    head.add(*eyes(hc, hr, 0.04, 0.15, mat_socket="socket", r_eye=0.019, r_sock=0.028))
    for side, sx in (("L", 1), ("R", -1)):
        head.add(box("Tear" + side, (0.008, 0.085, 0.006), "tear",
                     (sx * 0.043, 0.098, oe(hc, hr, sx * 0.043, 0.098) + 0.002), rot=(0, 0, -sx * 4)))
    head.add(box("Mouth", (0.034, 0.008, 0.006), "mouth", (0, 0.058, oe(hc, hr, 0, 0.058) + 0.001)))
    head.add(light("EyeLight", (0.75, 0.85, 1.0), 0.3, 0.45, (0, 0.15, 0.18)))
    body.add(head)

    root = node("Mucama")
    root.add(body)
    props = {"breathe": 0.01, "sway_deg": 2.5, "twitch": 2.0, "eye_color": (0.82, 0.9, 1.0), "eye_energy": 2.6}
    return root, M, props


# ============================================================== CORNELIUS
def cornelius():
    M = {
        "suit": {"color": (0.035, 0.035, 0.05), "rough": 0.45},
        "suit_hi": {"color": (0.11, 0.11, 0.15), "rough": 0.4},
        "waistcoat": {"color": (0.40, 0.30, 0.09), "rough": 0.45, "metal": 0.2},
        "shirt": {"color": (0.84, 0.83, 0.79), "rough": 0.7},
        "skin": {"color": (0.70, 0.68, 0.60), "rough": 0.5},
        "hatband": {"color": (0.32, 0.03, 0.05), "rough": 0.5},
        "gold": GOLD,
        "watch": {"color": (0.9, 0.74, 0.3), "metal": 0.9, "rough": 0.2, "emission": (1.0, 0.82, 0.35), "energy": 0.6},
        "ebony": {"color": (0.04, 0.025, 0.02), "rough": 0.18},
        "shoe": SHOE,
        "hair": {"color": (0.55, 0.55, 0.57), "rough": 0.6},
        "mouth": {"color": (0.12, 0.04, 0.04), "rough": 0.6},
        "socket": SOCKET,
        "eye": eye_mat((1.0, 0.8, 0.22), 3.0),
    }
    body = node("Body")
    for side, sx in (("L", 1), ("R", -1)):
        body.add(cap("Leg" + side, 0.062, 1.02, "suit", (sx * 0.085, 0.53, 0)))
        body.add(box("Shoe" + side, (0.095, 0.07, 0.29), "shoe", (sx * 0.085, 0.035, 0.055)))
        body.add(prism("Toe" + side, (0.095, 0.08, 0.07), "shoe", (sx * 0.085, 0.035, 0.225), rot=(90, 0, 0)))
    body.add(cyl("Coat", 0.205, 0.15, 0.62, "suit", (0, 1.25, 0), scale=(1, 1, 0.6), seg=18))
    body.add(box("Waistcoat", (0.15, 0.36, 0.02), "waistcoat", (0, 1.2, 0.1)))
    body.add(box("ShirtV", (0.07, 0.14, 0.02), "shirt", (0, 1.44, 0.108)))
    for side, sx in (("L", 1), ("R", -1)):
        body.add(box("Lapel" + side, (0.05, 0.32, 0.015), "suit_hi", (sx * 0.075, 1.36, 0.11), rot=(0, 0, sx * 12)))
        body.add(prism("Bow" + side, (0.05, 0.045, 0.02), "suit_hi", (sx * 0.025, 1.5, 0.118), rot=(0, 0, -sx * 90)))
        body.add(box("Tail" + side, (0.12, 0.52, 0.03), "suit", (sx * 0.065, 0.75, -0.085), rot=(6, 0, 0)))
        body.add(prism("TailTip" + side, (0.12, 0.12, 0.03), "suit", (sx * 0.065, 0.44, -0.12), rot=(6, 0, 180)))
        body.add(sph("Shoulder" + side, 0.08, "suit", (sx * 0.19, 1.52, 0), scale=(1.3, 0.75, 1), seg=(12, 8)))
    for i in range(3):
        body.add(sph("WButton%d" % i, 0.011, "gold", (0, 1.1 + i * 0.08, 0.112), seg=(8, 6)))
    body.add(cyl("Chain", 0.004, 0.004, 0.13, "gold", (0.045, 1.13, 0.113), rot=(0, 0, 70), seg=6))
    body.add(cyl("Watch", 0.03, 0.03, 0.012, "watch", (0.11, 1.105, 0.118), rot=(90, 0, 0), seg=14))
    body.add(cyl("HighCollar", 0.055, 0.066, 0.07, "shirt", (0, 1.565, 0), seg=12))
    body.add(cyl("Neck", 0.034, 0.034, 0.1, "skin", (0, 1.6, 0), seg=10))
    # Baston
    body.add(cyl("Cane", 0.014, 0.014, 0.66, "ebony", (-0.235, 0.33, 0.17), seg=8))
    body.add(sph("CaneKnob", 0.032, "gold", (-0.235, 0.675, 0.17), seg=(10, 8)))

    for side, sx in (("L", 1), ("R", -1)):
        arm = node("Arm" + side, pos=(sx * 0.225, 1.5, 0), rot=((-14 if sx < 0 else -2), 0, sx * 3))
        arm.add(cap("Upper", 0.05, 0.46, "suit", (0, -0.22, 0)))
        arm.add(cap("Fore", 0.045, 0.42, "suit", (0, -0.6, 0.02)))
        arm.add(cyl("Cuff", 0.048, 0.048, 0.04, "shirt", (0, -0.79, 0.025), seg=10))
        arm.add(sph("Hand", 0.045, "skin", (0, -0.86, 0.03), scale=(0.8, 1.4, 0.6), seg=(10, 8)))
        for k, dx in enumerate((-0.017, 0.0, 0.017)):
            arm.add(cap("Finger%d" % k, 0.008, 0.15 - abs(dx) * 1.5, "skin", (dx, -0.96, 0.03)))
        body.add(arm)

    hc, hr = (0, 0.13, 0), (0.085, 0.13, 0.09)
    head = node("Head", pos=(0, 1.64, 0), rot=(-3, 0, 4))
    head.add(sph("Face", 1.0, "skin", hc, scale=hr, seg=(16, 12)))
    head.add(*eyes(hc, hr, 0.036, 0.17, r_eye=0.016, r_sock=0.027))
    head.add(torus("Monocle", 0.025, 0.033, "gold", (-0.036, 0.17, oe(hc, hr, 0.036, 0.17) + 0.008), rot=(90, 0, 0)))
    head.add(cyl("MonocleChain", 0.003, 0.003, 0.16, "gold", (-0.07, 0.1, 0.06), rot=(15, 0, 20), seg=6))
    for side, sx in (("L", 1), ("R", -1)):
        head.add(box("Moustache" + side, (0.05, 0.012, 0.012), "hair",
                     (sx * 0.026, 0.07, oe(hc, hr, sx * 0.026, 0.07) + 0.004), rot=(0, 0, -sx * 18)))
        head.add(box("Sideburn" + side, (0.018, 0.08, 0.04), "hair", (sx * 0.08, 0.14, 0.0)))
    head.add(box("Mouth", (0.04, 0.005, 0.006), "mouth", (0, 0.045, oe(hc, hr, 0, 0.045) + 0.002)))
    head.add(sph("Nose", 0.014, "skin", (0, 0.11, oe(hc, hr, 0, 0.11) + 0.004), scale=(1, 1.6, 1), seg=(8, 6)))
    head.add(cyl("Brim", 0.17, 0.17, 0.014, "suit", (0, 0.27, 0), seg=20))
    head.add(cyl("HatBand", 0.099, 0.099, 0.04, "hatband", (0, 0.297, 0), seg=18))
    head.add(cyl("Crown", 0.1, 0.095, 0.31, "suit", (0, 0.43, 0), seg=18))
    head.add(light("EyeLight", (1.0, 0.8, 0.3), 0.3, 0.45, (0, 0.17, 0.16)))
    body.add(head)

    root = node("Cornelius")
    root.add(body)
    props = {"breathe": 0.006, "sway_deg": 0.8, "twitch": 0.35, "eye_color": (1.0, 0.8, 0.22), "eye_energy": 3.0}
    return root, M, props


# ============================================================== LA BAILARINA
def bailarina():
    M = {
        "porcelain": {"color": (0.94, 0.91, 0.87), "rough": 0.12},
        "porcelain_d": {"color": (0.76, 0.72, 0.68), "rough": 0.15},
        "tutu": {"color": (0.92, 0.78, 0.87), "rough": 0.6},
        "tutu_d": {"color": (0.70, 0.5, 0.64), "rough": 0.6},
        "bodice": {"color": (0.84, 0.4, 0.57), "rough": 0.45},
        "ribbon": {"color": (0.9, 0.55, 0.68), "rough": 0.4},
        "hair": {"color": (0.08, 0.06, 0.07), "rough": 0.2},
        "crack": {"color": (0.06, 0.03, 0.03), "rough": 0.9},
        "gold": GOLD,
        "eye": eye_mat((1.0, 0.13, 0.12), 2.5),
    }
    body = node("Body")
    body.add(cyl("Stand", 0.12, 0.13, 0.02, "gold", (0, -0.01, 0), seg=20))
    body.add(cap("Leg", 0.03, 0.46, "porcelain", (0, 0.25, 0)))
    body.add(cap("Slipper", 0.028, 0.11, "ribbon", (0, 0.05, 0.002)))
    raised = node("LegRaised", pos=(0, 0.47, -0.01), rot=(72, 0, 0))
    raised.add(cap("Leg", 0.028, 0.42, "porcelain", (0, -0.21, 0)))
    raised.add(cap("Slipper", 0.027, 0.1, "ribbon", (0, -0.41, 0)))
    body.add(raised)
    body.add(sph("Pelvis", 0.05, "bodice", (0, 0.5, 0), scale=(1.2, 0.8, 1), seg=(12, 8)))
    body.add(cyl("TutuOuter", 0.25, 0.27, 0.014, "tutu_d", (0, 0.495, 0), seg=10))
    body.add(cyl("Tutu", 0.2, 0.23, 0.03, "tutu", (0, 0.51, 0), seg=12))
    body.add(cyl("TutuTop", 0.15, 0.2, 0.03, "tutu_d", (0, 0.535, 0), seg=12))
    body.add(cyl("Bodice", 0.054, 0.044, 0.2, "bodice", (0, 0.63, 0), scale=(1, 1, 0.8), seg=12))
    body.add(sph("Chest", 0.05, "porcelain", (0, 0.725, 0), scale=(1.15, 0.75, 0.85), seg=(12, 8)))
    body.add(cyl("Neck", 0.019, 0.019, 0.07, "porcelain", (0, 0.77, 0), seg=8))
    for side, sx in (("L", 1), ("R", -1)):
        arm = node("Arm" + side, pos=(sx * 0.06, 0.74, 0.0), rot=(10, 0, -sx * 163))
        arm.add(cap("Upper", 0.017, 0.3, "porcelain", (0, -0.15, 0)))
        arm.add(sph("Hand", 0.017, "porcelain", (0, -0.31, 0), seg=(8, 6)))
        body.add(arm)
    hc, hr = (0, 0.07, 0), (0.07, 0.072, 0.07)
    head = node("Head", pos=(0, 0.8, 0), rot=(0, 0, 8))
    head.add(sph("Face", 1.0, "porcelain", hc, scale=hr, seg=(16, 10)))
    head.add(sph("HairCap", 0.073, "hair", (0, 0.1, -0.015), scale=(1.03, 0.75, 0.95), seg=(16, 10)))
    head.add(sph("Bun", 0.035, "hair", (0, 0.15, -0.035), seg=(10, 8)))
    head.add(torus("BunRibbon", 0.03, 0.04, "ribbon", (0, 0.135, -0.03), rot=(25, 0, 0)))
    for side, sx in (("L", 1), ("R", -1)):
        z = oe(hc, hr, sx * 0.025, 0.068)
        head.add(sph("Eye" + side, 0.011, "eye", (sx * 0.025, 0.068, z - 0.004), seg=(10, 6)))
        head.add(sph("Blush" + side, 0.014, "ribbon", (sx * 0.04, 0.045, oe(hc, hr, sx * 0.04, 0.045) - 0.006),
                     scale=(1, 0.6, 0.4), seg=(8, 6)))
    cracks = [(0.03, 0.1, 30, 0.05), (0.018, 0.035, -25, 0.045), (0.042, 0.06, 70, 0.03), (-0.035, 0.1, -40, 0.03)]
    for i, (x, y, a, ln) in enumerate(cracks):
        head.add(box("Crack%d" % i, (0.003, ln, 0.003), "crack", (x, y, oe(hc, hr, x, y) + 0.0005), rot=(0, 0, a)))
    head.add(box("Mouth", (0.016, 0.005, 0.004), "crack", (0, 0.035, oe(hc, hr, 0, 0.035) + 0.001)))
    body.add(head)
    body.add(box("CrackBody", (0.003, 0.07, 0.003), "crack", (0.02, 0.72, 0.042), rot=(0, 0, 20)))

    root = node("Bailarina")
    root.add(body)
    props = {"breathe": 0.0, "sway_deg": 0.0, "twitch": 0.8, "eye_color": (1.0, 0.13, 0.12), "eye_energy": 2.5}
    return root, M, props


ALL = {"botones": botones, "chef": chef, "mucama": mucama, "cornelius": cornelius, "bailarina": bailarina}
