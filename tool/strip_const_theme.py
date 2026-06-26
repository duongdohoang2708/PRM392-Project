"""Strip invalid const widgets that reference theme context helpers."""
import re
import glob
import os

SKIP = {"lib/theme/app_theme.dart", "lib/theme/app_colors.dart"}


def norm(path: str) -> str:
    return path.replace(os.sep, "/")


def strip_const_with_context(content: str) -> str:
    content = re.sub(
        r"const TextStyle\(([^)]*Of\([^)]+\)[^)]*)\)",
        r"TextStyle(\1)",
        content,
        flags=re.DOTALL,
    )

    for widget in ("Text", "Icon", "Padding", "Center", "Align", "SizedBox"):
        pattern = rf"const {widget}\([^;]*?\),"

        def fix(match: re.Match[str], w=widget) -> str:
            block = match.group(0)
            if "Of(" in block:
                return block.replace(f"const {w}(", f"{w}(", 1)
            return block

        content = re.sub(pattern, fix, content, flags=re.DOTALL)

    lines = content.split("\n")
    out = []
    for line in lines:
        if "const " in line and "Of(" in line:
            line = line.replace("const ", "", 1)
        out.append(line)
    return "\n".join(out)


def main() -> None:
    for path in glob.glob("lib/**/*.dart", recursive=True):
        if norm(path) in SKIP:
            continue
        with open(path, encoding="utf-8") as f:
            content = f.read()
        if "Of(" not in content:
            continue
        new = strip_const_with_context(content)
        if new != content:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new)
            print(path)


if __name__ == "__main__":
    main()
