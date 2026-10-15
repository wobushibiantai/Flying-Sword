"""Check the exported artwork, independent of the Aseprite drawing scripts."""
from pathlib import Path
from PIL import Image
from hashlib import sha256

base = Path(__file__).resolve().parents[1] / "assets"
for action in ("idle", "walk", "cast", "fly", "hover"):
    page = Image.open(base / "character" / "pixel" / f"{action}.png").convert("RGBA")
    assert page.size == (1536, 1536), (action, page.size)
    for direction in range(8):
        seen = set()
        for frame in range(24):
            index = direction * 24 + frame
            x, y = (index % 16) * 96, (index // 16) * 128
            cell = page.crop((x, y, x + 96, y + 128))
            bounds = cell.getbbox()
            assert bounds and bounds[0] > 0 and bounds[1] > 0 and bounds[2] < 96 and bounds[3] < 128, (action, direction, frame, bounds)
            seen.add(sha256(cell.tobytes()).digest())
        assert len(seen) == 24, (action, direction, "duplicate frames", len(seen))
    print("PIXEL_FRAME_OK", action, "192 distinct frames")

expected = {
    "combat": 15,
    "world": 5,
    "ui": 17,
}
for folder, count in expected.items():
    path = base / "pixel" / folder
    sources = {p.stem for p in path.glob("*.aseprite")}
    exports = {p.stem for p in path.glob("*.png")}
    assert sources == exports and len(sources) == count, (folder, sorted(sources ^ exports), len(sources))
    for name in sources:
        with Image.open(path / f"{name}.png") as image:
            assert image.getbbox(), (folder, name, "empty")
print("PIXEL_SOURCES_OK 42 editable Aseprite/PNG asset pairs")
