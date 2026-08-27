"""Generate Android adaptive launcher icons and splash assets."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "icons" / "app_logo.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
BG = (8, 9, 11, 255)  # AppColors.bg0 #08090B

LEGACY_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

FOREGROUND_SIZE = 432
SAFE_RATIO = 0.66


def flatten_on_bg(logo: Image.Image) -> Image.Image:
    """Composite translucent logo onto solid brand background (kills white bleed)."""
    base = Image.new("RGBA", logo.size, BG)
    base.alpha_composite(logo.convert("RGBA"))
    return base


def fit_logo(logo: Image.Image, canvas_size: int, content_ratio: float) -> Image.Image:
    canvas = Image.new("RGBA", (canvas_size, canvas_size), BG)
    max_side = int(canvas_size * content_ratio)
    scaled = logo.copy()
    scaled.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
    x = (canvas_size - scaled.width) // 2
    y = (canvas_size - scaled.height) // 2
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def rounded_legacy(logo: Image.Image, size: int, radius_ratio: float = 0.22) -> Image.Image:
    base = fit_logo(logo, size, 0.92)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    radius = int(size * radius_ratio)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    return out


def main() -> None:
    logo = flatten_on_bg(Image.open(SRC))
    print(f"source flattened: {logo.size}")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    drawable = RES / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)

    # Adaptive foreground: padded logo on brand bg (safe zone for round masks).
    fg = fit_logo(logo, FOREGROUND_SIZE, SAFE_RATIO)
    fg_path = drawable / "ic_launcher_foreground.png"
    fg.save(fg_path, optimize=True)
    print(f"wrote {fg_path}")

    # Android 12+ always draws a centered splash icon. Use a solid tile matching
    # splash_background so the circle is invisible (avoids OEM fallback to the
    # sharp full-bleed launcher artwork).
    splash_path = drawable / "splash_icon.png"
    Image.new("RGBA", (288, 288), BG).save(splash_path, optimize=True)
    print(f"wrote {splash_path} (solid brand bg)")

    for folder, size in LEGACY_SIZES.items():
        out_dir = RES / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        out = out_dir / "ic_launcher.png"
        rounded_legacy(logo, size).save(out, optimize=True)
        print(f"wrote {out} ({size}px)")

    (anydpi / "ic_launcher.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
""",
        encoding="utf-8",
    )
    print("wrote adaptive ic_launcher.xml")

    obsolete = drawable / "ic_launcher_background.png"
    if obsolete.exists():
        obsolete.unlink()
        print(f"removed {obsolete}")


if __name__ == "__main__":
    main()
