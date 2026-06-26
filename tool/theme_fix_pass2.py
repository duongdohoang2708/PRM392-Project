import re
import glob
import os

SKIP = {"lib/theme/app_theme.dart", "lib/theme/app_colors.dart"}


def norm(path: str) -> str:
    return path.replace(os.sep, "/")


replacements = [
    ("color: AppColors.textPrimary,", "color: AppColors.textPrimaryOf(context),"),
    ("color: AppColors.textSecondary,", "color: AppColors.textSecondaryOf(context),"),
    (
        "foregroundColor: AppColors.textPrimary,",
        "foregroundColor: AppColors.textPrimaryOf(context),",
    ),
    (
        "foregroundColor: AppColors.textSecondary,",
        "foregroundColor: AppColors.textSecondaryOf(context),",
    ),
    (
        "backgroundColor: AppColors.background,",
        "backgroundColor: AppColors.backgroundOf(context),",
    ),
    (
        "backgroundColor: AppColors.surface,",
        "backgroundColor: AppColors.cardOf(context),",
    ),
    (
        "dropdownColor: AppColors.surface,",
        "dropdownColor: AppColors.surfaceOf(context),",
    ),
    ("color: AppColors.surface,", "color: AppColors.cardOf(context),"),
    ("color: AppColors.background,", "color: AppColors.backgroundOf(context),"),
    (
        "Border.all(color: AppColors.border)",
        "Border.all(color: AppColors.borderOf(context))",
    ),
    (
        "Border.all(color: AppColors.border,",
        "Border.all(color: AppColors.borderOf(context),",
    ),
    (
        "const Divider(color: AppColors.border,",
        "Divider(color: AppColors.borderOf(context),",
    ),
    (
        "Divider(color: AppColors.border,",
        "Divider(color: AppColors.borderOf(context),",
    ),
    (
        "Icon(Icons.menu, color: AppColors.textPrimary)",
        "Icon(Icons.menu, color: AppColors.textPrimaryOf(context))",
    ),
    (
        "Icon(Icons.chevron_left, color: AppColors.textPrimary)",
        "Icon(Icons.chevron_left, color: AppColors.textPrimaryOf(context))",
    ),
    (
        "Icon(Icons.chevron_right, color: AppColors.textPrimary)",
        "Icon(Icons.chevron_right, color: AppColors.textPrimaryOf(context))",
    ),
    (
        "Icon(Icons.delete_outline, color: AppColors.textPrimary)",
        "Icon(Icons.delete_outline, color: AppColors.textPrimaryOf(context))",
    ),
    (
        "style: TextStyle(color: AppColors.textPrimary)",
        "style: TextStyle(color: AppColors.textPrimaryOf(context))",
    ),
    (
        "style: TextStyle(color: AppColors.textSecondary)",
        "style: TextStyle(color: AppColors.textSecondaryOf(context))",
    ),
    (
        "style: const TextStyle(color: AppColors.textPrimary)",
        "style: TextStyle(color: AppColors.textPrimaryOf(context))",
    ),
    (
        "style: const TextStyle(color: AppColors.textSecondary)",
        "style: TextStyle(color: AppColors.textSecondaryOf(context))",
    ),
]

ternary_replacements = [
    ("? AppColors.textPrimary,", "? AppColors.textPrimaryOf(context),"),
    (": AppColors.textPrimary,", ": AppColors.textPrimaryOf(context),"),
    ("? AppColors.textSecondary,", "? AppColors.textSecondaryOf(context),"),
    (": AppColors.textSecondary,", ": AppColors.textSecondaryOf(context),"),
]


def strip_const_with_context(content: str) -> str:
    content = re.sub(
        r"const TextStyle\(([^)]*Of\(context\)[^)]*)\)",
        r"TextStyle(\1)",
        content,
    )

    def fix_text(match: re.Match[str]) -> str:
        block = match.group(0)
        if "Of(context)" in block:
            return block.replace("const Text(", "Text(", 1)
        return block

    content = re.sub(
        r"const Text\([^;]*?\),", fix_text, content, flags=re.DOTALL
    )
    lines = content.split("\n")
    out = []
    for line in lines:
        if line.strip().startswith("const ") and "Of(context)" in line:
            line = line.replace("const ", "", 1)
        out.append(line)
    return "\n".join(out)


def fix_alpha_blend_surface(content: str) -> str:
    content = re.sub(
        r"Color\.alphaBlend\(\s*(\w+)\.withValues\(alpha: 0\.08\),\s*AppColors\.cardOf\(context\),\s*\)",
        r"AppColors.taskCardOf(context, \1)",
        content,
    )
    content = re.sub(
        r"Color\.alphaBlend\(\s*(\w+Color)\.withValues\(alpha: 0\.08\),\s*AppColors\.cardOf\(context\),\s*\)",
        r"AppColors.taskCardOf(context, \1)",
        content,
    )
    content = re.sub(
        r"Color\.alphaBlend\(\s*(\w+)\.withValues\(alpha: 0\.08\),\s*AppColors\.surface,\s*\)",
        r"AppColors.taskCardOf(context, \1)",
        content,
    )
    return content


def main() -> None:
    changed_files = []
    for path in glob.glob("lib/**/*.dart", recursive=True):
        if norm(path) in SKIP:
            continue
        with open(path, encoding="utf-8") as f:
            content = f.read()
        if "AppColors." not in content:
            continue
        new = content
        for old, rep in replacements:
            new = new.replace(old, rep)
        for old, rep in ternary_replacements:
            new = new.replace(old, rep)
        new = fix_alpha_blend_surface(new)
        new = strip_const_with_context(new)
        if new != content:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new)
            changed_files.append(path)

    print(f"Updated {len(changed_files)} files")
    for path in sorted(changed_files):
        print(path)


if __name__ == "__main__":
    main()
