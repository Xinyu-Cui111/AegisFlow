"""Remove checkerboard / gray backdrop from DeskPetMascot.png (keep character)."""
from __future__ import annotations

from collections import deque
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    import subprocess
    import sys

    subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow", "-q"])
    from PIL import Image

SRC = Path(__file__).resolve().parents[1] / (
    "Modules/DeskPet/AegisAssets.xcassets/DeskPetMascot.imageset/DeskPetMascot.png"
)


def is_checker(r: int, g: int, b: int, a: int) -> bool:
    if a < 8:
        return True
    mx, mn = max(r, g, b), min(r, g, b)
    sat = mx - mn
    if sat > 28:
        return False
    avg = (r + g + b) / 3.0
    if avg > 230 and sat < 18:
        return True
    if 150 < avg < 210 and sat < 22:
        return True
    if 90 < avg < 150 and sat < 18:
        return True
    return False


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    px = im.load()
    w, h = im.size
    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
            continue
        r, g, b, a = px[x, y]
        if not is_checker(r, g, b, a):
            continue
        visited[y][x] = True
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            q.append((nx, ny))

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if not a or not is_checker(r, g, b, a):
                continue
            cnt = hit = 0
            for ny in range(max(0, y - 2), min(h, y + 3)):
                for nx in range(max(0, x - 2), min(w, x + 3)):
                    rr, gg, bb, aa = px[nx, ny]
                    cnt += 1
                    if aa < 8 or is_checker(rr, gg, bb, aa):
                        hit += 1
            if cnt and hit / cnt > 0.55:
                px[x, y] = (0, 0, 0, 0)

    im.save(SRC, "PNG")
    opaque = sum(1 for yy in range(h) for xx in range(w) if px[xx, yy][3] > 8)
    print(f"saved {SRC} size={w}x{h} opaque_pixels={opaque}")


if __name__ == "__main__":
    main()
