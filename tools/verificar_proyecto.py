"""
BotMp3 - verificador estático del proyecto (no requiere Flutter instalado).

Comprueba:
  1. Dependencias: todo `import 'package:x/...'` está declarado en pubspec.yaml.
  2. Imports relativos: el archivo destino existe.
  3. Imports olvidados: se usa una clase del proyecto sin importarla.
  4. Balance de llaves/paréntesis por archivo.
  5. Assets declarados en pubspec existen en disco.

Uso:
    python tools/verificar_proyecto.py
"""

from __future__ import annotations

import os
import re
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, "lib")

SDK_PACKAGES = {"flutter", "flutter_test", "flutter_localizations", "flutter_web_plugins"}

DECLARATION_RE = re.compile(
    r"^\s*(?:abstract\s+|sealed\s+|final\s+|base\s+|mixin\s+)?"
    r"(class|enum|mixin|extension|typedef)\s+([A-Za-z_][A-Za-z0-9_]*)",
    re.MULTILINE,
)
IMPORT_RE = re.compile(r"^\s*import\s+'([^']+)'", re.MULTILINE)
PART_RE = re.compile(r"^\s*part\s+'([^']+)'", re.MULTILINE)
PART_OF_RE = re.compile(r"^\s*part\s+of\s+'([^']+)'", re.MULTILINE)
PACKAGE_RE = re.compile(r"^package:([^/]+)/")


def read(path: str) -> str:
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


def dart_files() -> list[str]:
    files: list[str] = []
    for base, _dirs, names in os.walk(LIB):
        for name in names:
            if name.endswith(".dart"):
                files.append(os.path.join(base, name))
    return sorted(files)


def pubspec_dependencies() -> set[str]:
    path = os.path.join(ROOT, "pubspec.yaml")
    text = read(path)
    deps: set[str] = set()
    section = None
    for line in text.splitlines():
        if re.match(r"^[a-z_]+:", line):
            section = line.split(":")[0].strip()
            continue
        if section in {"dependencies", "dev_dependencies"}:
            match = re.match(r"^\s{2}([a-z_][a-z0-9_]*):", line)
            if match:
                deps.add(match.group(1))
    return deps | SDK_PACKAGES


def declared_symbols(files: list[str]) -> dict[str, str]:
    symbols: dict[str, str] = {}
    for path in files:
        for _kind, name in DECLARATION_RE.findall(read(path)):
            symbols.setdefault(name, path)
    return symbols


def normalize(path: str) -> str:
    return os.path.normcase(os.path.abspath(path))


def main() -> int:
    problems: list[str] = []
    warnings: list[str] = []

    files = dart_files()
    if not files:
        print("No se encontraron archivos .dart")
        return 1

    deps = pubspec_dependencies()
    symbols = declared_symbols(files)
    symbols_by_file: dict[str, set[str]] = defaultdict(set)
    for name, path in symbols.items():
        symbols_by_file[normalize(path)].add(name)

    # Los archivos `part of` comparten el espacio de nombres de su librería padre.
    library_members: dict[str, set[str]] = defaultdict(set)
    for path in files:
        text = read(path)
        part_of = PART_OF_RE.search(text)
        if part_of:
            parent = normalize(os.path.join(os.path.dirname(path), part_of.group(1)))
            library_members[parent].add(normalize(path))
            library_members[parent] |= library_members.get(normalize(path), set())
        for target in PART_RE.findall(text):
            child = normalize(os.path.join(os.path.dirname(path), target))
            library_members[normalize(path)].add(child)
            library_members[normalize(path)] |= library_members.get(child, set())

    for path in files:
        text = read(path)
        rel = os.path.relpath(path, ROOT)

        # 1) Dependencias declaradas
        for target in IMPORT_RE.findall(text):
            match = PACKAGE_RE.match(target)
            if match:
                package = match.group(1)
                if package not in deps:
                    problems.append(f"{rel}: import de paquete no declarado -> {target}")
            elif target.startswith("dart:"):
                continue
            else:
                resolved = os.path.normpath(os.path.join(os.path.dirname(path), target))
                if not os.path.exists(resolved):
                    problems.append(f"{rel}: import relativo inexistente -> {target}")

        # 2) Archivos part
        for target in PART_RE.findall(text):
            resolved = os.path.normpath(os.path.join(os.path.dirname(path), target))
            if not os.path.exists(resolved):
                problems.append(f"{rel}: part inexistente -> {target}")
        for target in PART_OF_RE.findall(text):
            resolved = os.path.normpath(os.path.join(os.path.dirname(path), target))
            if not os.path.exists(resolved):
                problems.append(f"{rel}: part of inexistente -> {target}")

        # 3) Balance de llaves y paréntesis
        stripped = re.sub(r"'(?:[^'\\]|\\.)*'", "''", text)
        stripped = re.sub(r'"(?:[^"\\]|\\.)*"', '""', stripped)
        stripped = re.sub(r"//[^\n]*", "", stripped)
        stripped = re.sub(r"/\*.*?\*/", "", stripped, flags=re.DOTALL)
        for open_char, close_char, label in (("{", "}", "llaves"), ("(", ")", "paréntesis"),
                                             ("[", "]", "corchetes")):
            if stripped.count(open_char) != stripped.count(close_char):
                problems.append(
                    f"{rel}: {label} descompensados "
                    f"({stripped.count(open_char)} vs {stripped.count(close_char)})"
                )

        # 4) Clases usadas sin importar (solo símbolos del propio proyecto)
        imported_files = {normalize(path)}
        for target in IMPORT_RE.findall(text):
            if not PACKAGE_RE.match(target) and not target.startswith("dart:"):
                imported_files.add(
                    normalize(os.path.join(os.path.dirname(path), target))
                )
        # Un archivo `part of` hereda todo lo que importa su librería padre.
        part_parent = PART_OF_RE.search(text)
        if part_parent:
            parent_path = normalize(os.path.join(os.path.dirname(path), part_parent.group(1)))
            imported_files.add(parent_path)
            parent_text = read(parent_path)
            for target in IMPORT_RE.findall(parent_text):
                if not PACKAGE_RE.match(target) and not target.startswith("dart:"):
                    imported_files.add(
                        normalize(os.path.join(os.path.dirname(parent_path), target))
                    )

        available = set()
        for imported in imported_files:
            available |= symbols_by_file.get(imported, set())
            for member in library_members.get(imported, set()):
                available |= symbols_by_file.get(member, set())
        # Los `part` comparten el espacio de nombres de la librería principal.
        for target in PART_RE.findall(text):
            available |= symbols_by_file.get(
                normalize(os.path.join(os.path.dirname(path), target)), set()
            )
        for member in library_members.get(normalize(path), set()):
            available |= symbols_by_file.get(member, set())

        own = symbols_by_file.get(normalize(path), set())
        used = set(re.findall(r"\b([A-Z][A-Za-z0-9_]{3,})\s*\(", text))
        for name in sorted(used):
            if name in own or name in available:
                continue
            if name not in symbols:
                continue  # clase del SDK/paquete
            owner = os.path.relpath(symbols[name], ROOT)
            warnings.append(f"{rel}: usa {name} (definida en {owner}) sin importarla")

    # 5) Assets declarados
    pubspec = read(os.path.join(ROOT, "pubspec.yaml"))
    assets_block = re.search(r"assets:\s*\n((?:\s*-\s*.+\n)+)", pubspec)
    if assets_block:
        for asset in re.findall(r"-\s*(\S+)", assets_block.group(1)):
            candidate = os.path.join(ROOT, asset.rstrip("/"))
            if not os.path.exists(candidate):
                problems.append(f"pubspec.yaml: asset inexistente -> {asset}")

    print(f"Archivos .dart analizados: {len(files)}")
    print(f"Clases/enums declarados: {len(symbols)}")
    print(f"Dependencias declaradas: {len(deps - SDK_PACKAGES)}")

    if warnings:
        print(f"\nAVISOS ({len(warnings)}):")
        for item in warnings:
            print("  -", item)

    if problems:
        print(f"\nERRORES ({len(problems)}):")
        for item in problems:
            print("  -", item)
        return 1

    print("\nOK: no se detectaron problemas de imports, llaves ni assets.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
