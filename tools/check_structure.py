"""Check resource references without Godot. Not a GDScript/runtime validator."""

from pathlib import Path
import re


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    errors = []
    files = [*root.rglob("*.gd"), *root.rglob("*.tscn"), root / "project.godot"]
    references = 0
    for path in files:
        source = path.read_text(encoding="utf-8")
        for reference in re.findall(r'"res://([^"\n]+)"', source):
            references += 1
            if not (root / reference).is_file():
                errors.append(f"{path.relative_to(root)}: missing {reference}")
        if path.parent.name == "domain":
            for forbidden in ("extends Node", "FileAccess", "res://presentation/", "res://infrastructure/"):
                if forbidden in source:
                    errors.append(f"{path.name}: forbidden domain dependency {forbidden}")
    for error in errors:
        print(error)
    print(f"{len(files)} source/config files; {references} references; {len(errors)} errors")
    return int(bool(errors))


if __name__ == "__main__":
    raise SystemExit(main())
