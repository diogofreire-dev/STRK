"""Gera design/social_preview.png (1280x640), a imagem de pré-visualização do
repositório no GitHub. Corre sem abrir a janela do Blender e NÃO grava o
mascote.blend:

    /Applications/Blender.app/Contents/MacOS/Blender -b design/mascote.blend \
        --python design/social_preview.py
"""
import math
import os

import bpy
import numpy as np

HERE = os.path.dirname(bpy.data.filepath)
OUT = os.path.join(HERE, "social_preview.png")
W, H = 1280, 640
scene = bpy.context.scene
O = bpy.data.objects

# ── Pose "festa" ─────────────────────────────────────────────────────────────
face = ["Eye_L", "Eye_R", "Shine_L", "Shine_R", "Mouth", "Cheek_L", "Cheek_R",
        "EyeClosed_L", "EyeClosed_R", "EyeHappy_L", "EyeHappy_R", "MouthOpen",
        "Tongue", "MouthO"]
show = ["EyeHappy_L", "EyeHappy_R", "MouthOpen", "Tongue", "Cheek_L", "Cheek_R"]
for n in face:
    O[n].hide_render = n not in show
O["Body"].data.materials[0] = bpy.data.materials["M_Body"]
for n in ("Lick_L", "Lick_R"):
    O[n].data.materials[0] = bpy.data.materials["M_Side"]
    O[n].scale = O[n].scale * 1.2
bpy.data.materials["M_Body"].node_tree.nodes["Principled BSDF"].inputs[
    "Emission Strength"].default_value = 0.6
O["MascotRoot"].rotation_euler = (0, math.radians(-8), 0)

# ── Câmara: 2:1, mascote no terço direito ────────────────────────────────────
cam = scene.camera
cam.data.type = "ORTHO"
ortho = 7.6
cam.data.ortho_scale = ortho
cam.location = (-(0.70 - 0.5) * ortho, -8, 0.6)
scene.render.resolution_x, scene.render.resolution_y = W, H
scene.render.film_transparent = True

# ── Texto (Inter, licença OFL, vem com o Blender) ────────────────────────────
font_path = os.path.join(bpy.utils.resource_path("LOCAL"), "datafiles", "fonts", "Inter.woff2")
try:
    font = bpy.data.fonts.load(font_path)
except Exception:
    font = None  # usa a fonte por omissão do Blender


def emission_mat(name, rgb, strength=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*rgb, 1)
    em.inputs["Strength"].default_value = strength
    nt.links.new(em.outputs[0], out.inputs[0])
    return m


def srgb_to_lin(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c]


def text(body, size, x, z, color, bold=0.0, spacing=1.0):
    cu = bpy.data.curves.new("txt", "FONT")
    cu.body = body
    cu.size = size
    cu.offset = bold          # engrossa as letras (a Inter incluída é a Regular)
    cu.space_character = spacing
    if font:
        cu.font = font
    ob = bpy.data.objects.new("txt", cu)
    scene.collection.objects.link(ob)
    ob.location = (x, -2, z)
    ob.rotation_euler = (math.radians(90), 0, 0)   # virado para a câmara
    ob.data.materials.append(emission_mat("txt", srgb_to_lin(color)))
    return ob


left = cam.location.x - ortho / 2 + 0.55
text("STRK", 1.35, left, 0.75, "#F2F2F2", bold=0.045, spacing=0.92)
text("Os teus hábitos, em chama.", 0.30, left, 0.22, "#B9B4AE", bold=0.004)
text("Flutter  ·  Firebase  ·  Blender", 0.20, left, -0.35, "#FF7A1A", bold=0.002)

scene.render.filepath = os.path.join(HERE, "_social_fg.png")
bpy.ops.render.render(write_still=True)

# ── Fundo escuro com brilho, composto por baixo do render ────────────────────
fg_img = bpy.data.images.load(scene.render.filepath)
fg = np.array(fg_img.pixels[:], dtype=np.float32).reshape(H, W, 4)
bpy.data.images.remove(fg_img)
os.remove(scene.render.filepath)

y, x = np.mgrid[0:H, 0:W].astype(np.float32)
base = np.array([13, 13, 13], dtype=np.float32) / 255
warm = np.array([58, 22, 8], dtype=np.float32) / 255
hot = np.array([255, 107, 0], dtype=np.float32) / 255
# Brilho centrado atrás da mascote (y=0 é a base da imagem no Blender).
d = np.sqrt(((x - 0.70 * W) / W) ** 2 + ((y - 0.52 * H) / W) ** 2)
t = np.clip(1 - d / 0.55, 0, 1) ** 1.8
col = base + (warm - base) * t[..., None]
g = np.clip(1 - d / 0.26, 0, 1) ** 2.2 * 0.30
col = col + (hot - col) * g[..., None]

a = fg[..., 3:4]
out = np.ones((H, W, 4), dtype=np.float32)
out[..., :3] = fg[..., :3] * a + col * (1 - a)

img = bpy.data.images.new("social", W, H, alpha=False)
img.pixels[:] = out.ravel()
img.filepath_raw = OUT
img.file_format = "PNG"
img.save()
print("Gravado:", OUT)
