from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "flowmova-logo-mark-color-aligned.svg"
LOGO_WITH_TEXT = ROOT / "flowmova-logo-with-text-color-aligned.svg"
MARK_MONOCHROME = ROOT / "flowmova-logo-mark-monochrome.svg"
LOGO_WITH_TEXT_MONOCHROME = ROOT / "flowmova-logo-with-text-monochrome.svg"
APP_ICON = ROOT / "flowmova-app-icon-color.svg"
MONOCHROME_COLOR = "#13233E"

SVG_NS = "http://www.w3.org/2000/svg"
NS = f"{{{SVG_NS}}}"


def read_mark() -> tuple[list[ET.Element], list[ET.Element]]:
    tree = ET.parse(SOURCE)
    root = tree.getroot()
    defs_element = root.find(NS + "defs")
    defs = list(defs_element) if defs_element is not None else []
    paths = [deepcopy(path) for path in root.findall(NS + "path")]
    return defs, paths


def svg_root(width: int, height: int, view_box: str, title_text: str, desc_text: str) -> ET.Element:
    root = ET.Element(
        NS + "svg",
        {
            "width": str(width),
            "height": str(height),
            "viewBox": view_box,
            "role": "img",
            "aria-labelledby": "title desc",
        },
    )
    title = ET.SubElement(root, NS + "title", {"id": "title"})
    title.text = title_text
    desc = ET.SubElement(root, NS + "desc", {"id": "desc"})
    desc.text = desc_text
    return root


def add_defs(root: ET.Element, defs_children: list[ET.Element]) -> None:
    defs = ET.SubElement(root, NS + "defs")
    for child in defs_children:
        defs.append(deepcopy(child))


def add_mark(root: ET.Element, paths: list[ET.Element], transform: str | None = None) -> None:
    group_attrs = {"fill-rule": "evenodd"}
    if transform:
        group_attrs["transform"] = transform
    group = ET.SubElement(root, NS + "g", group_attrs)
    for path in paths:
        group.append(deepcopy(path))


def monochrome_paths(paths: list[ET.Element]) -> list[ET.Element]:
    mono_paths = [deepcopy(path) for path in paths]
    for path in mono_paths:
        path.set("fill", MONOCHROME_COLOR)
    return mono_paths


def build_mark_monochrome(paths: list[ET.Element]) -> None:
    root = svg_root(
        3000,
        2000,
        "0 0 3000 2000",
        "FlowMova icone monochrome",
        "Icone FlowMova en une seule couleur.",
    )
    add_mark(root, monochrome_paths(paths))
    ET.ElementTree(root).write(MARK_MONOCHROME, encoding="utf-8", xml_declaration=False)


def build_logo_with_text(defs_children: list[ET.Element], paths: list[ET.Element]) -> None:
    root = svg_root(
        2500,
        1900,
        "250 360 2500 1900",
        "FlowMova logo avec texte",
        "Logo FlowMova couleur avec icone et texte en dessous.",
    )
    add_defs(root, defs_children)
    add_mark(root, paths)
    text = ET.SubElement(
        root,
        NS + "text",
        {
            "x": "1500",
            "y": "1920",
            "text-anchor": "middle",
            "font-family": "Nunito Sans, Inter, Segoe UI, Arial, sans-serif",
            "font-size": "340",
            "font-weight": "750",
            "letter-spacing": "-3",
            "fill": "#13233E",
        },
    )
    text.text = "FlowMova"
    ET.ElementTree(root).write(LOGO_WITH_TEXT, encoding="utf-8", xml_declaration=False)


def build_logo_with_text_monochrome(paths: list[ET.Element]) -> None:
    root = svg_root(
        2500,
        1900,
        "250 360 2500 1900",
        "FlowMova logo monochrome avec texte",
        "Logo FlowMova en une seule couleur avec icone et texte en dessous.",
    )
    add_mark(root, monochrome_paths(paths))
    text = ET.SubElement(
        root,
        NS + "text",
        {
            "x": "1500",
            "y": "1920",
            "text-anchor": "middle",
            "font-family": "Nunito Sans, Inter, Segoe UI, Arial, sans-serif",
            "font-size": "340",
            "font-weight": "750",
            "letter-spacing": "-3",
            "fill": MONOCHROME_COLOR,
        },
    )
    text.text = "FlowMova"
    ET.ElementTree(root).write(LOGO_WITH_TEXT_MONOCHROME, encoding="utf-8", xml_declaration=False)


def build_app_icon(defs_children: list[ET.Element], paths: list[ET.Element]) -> None:
    root = svg_root(
        1024,
        1024,
        "0 0 1024 1024",
        "FlowMova icone app",
        "Icone d'application FlowMova avec fond blanc arrondi.",
    )
    add_defs(root, defs_children)
    ET.SubElement(root, NS + "rect", {"x": "64", "y": "64", "width": "896", "height": "896", "rx": "190", "fill": "#FFFFFF"})
    add_mark(root, paths, "translate(4 177) scale(0.34)")
    ET.ElementTree(root).write(APP_ICON, encoding="utf-8", xml_declaration=False)


def main() -> None:
    ET.register_namespace("", SVG_NS)
    defs_children, paths = read_mark()
    build_logo_with_text(defs_children, paths)
    build_mark_monochrome(paths)
    build_logo_with_text_monochrome(paths)
    build_app_icon(defs_children, paths)


if __name__ == "__main__":
    main()
