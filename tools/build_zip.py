"""Builds dist/CombinedAddonMenus-<version>.zip for a manual CurseForge upload.
Same contents as CurseForge's automatic packaging: the repo root, minus what .pkgmeta ignores.
Paths use forward slashes (Compress-Archive does not)."""
import pathlib, re, zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
meta = (ROOT / ".pkgmeta").read_text(encoding="utf-8")
ignore = set(re.findall(r"^\s+-\s+(\S+)\s*$", meta, re.M))
version = re.search(r"^## Version:\s*(\S+)", (ROOT / "CombinedAddonMenus.toc").read_text(encoding="utf-8"), re.M).group(1)
out = ROOT / "dist" / f"CombinedAddonMenus-{version}.zip"
out.parent.mkdir(exist_ok=True)
for old in out.parent.glob("*.zip"):
    old.unlink()
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(ROOT.rglob("*")):
        rel = f.relative_to(ROOT)
        if not f.is_file() or rel.parts[0] in ignore or any(p.startswith(".") for p in rel.parts) or "__pycache__" in rel.parts:
            continue
        z.write(f, "CombinedAddonMenus/" + rel.as_posix())
print(out)
for n in zipfile.ZipFile(out).namelist():
    print(" ", n)
