#!/usr/bin/env python3
"""
Generates index.json for the CYROID Catalog by walking the directory tree
and reading manifests from each content type.

Usage:
    python scripts/generate-index.py

Output:
    index.json in the repository root
"""

import json
import hashlib
import os
from datetime import datetime, timezone
from pathlib import Path

import yaml


REPO_ROOT = Path(__file__).resolve().parent.parent


def file_checksum(path: Path) -> str:
    """SHA256 checksum of a file."""
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return f"sha256:{h.hexdigest()[:16]}"


def dir_checksum(path: Path) -> str:
    """SHA256 checksum of all files in a directory (sorted, deterministic)."""
    h = hashlib.sha256()
    for f in sorted(path.rglob("*")):
        if f.is_file() and not f.name.startswith("."):
            h.update(str(f.relative_to(path)).encode())
            h.update(f.read_bytes())
    return f"sha256:{h.hexdigest()[:16]}"


def load_yaml(path: Path) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def scan_blueprints() -> list[dict]:
    items = []
    blueprints_dir = REPO_ROOT / "blueprints"
    if not blueprints_dir.exists():
        return items

    for bp_dir in sorted(blueprints_dir.iterdir()):
        if not bp_dir.is_dir():
            continue

        blueprint_file = bp_dir / "blueprint.yaml"
        if not blueprint_file.exists():
            continue

        bp = load_yaml(blueprint_file)
        readme = bp_dir / "README.md"

        # Determine required images from VM definitions
        requires_images = []
        for vm in bp.get("vms", []):
            tag = vm.get("base_image_tag", "")
            if tag.startswith("cyroid/"):
                project = tag.split("/")[1].split(":")[0]
                if project not in requires_images:
                    requires_images.append(project)

        # Check for included content
        has_msel = (bp_dir / "msel.md").exists()
        has_content = (bp_dir / "content").exists() and any(
            (bp_dir / "content").iterdir()
        )

        # Extract tags from walkthrough if available
        tags = []
        walkthrough = bp.get("walkthrough", {})
        if walkthrough:
            tags = walkthrough.get("tags", [])

        items.append({
            "id": bp_dir.name,
            "type": "blueprint",
            "name": bp.get("name", bp_dir.name),
            "description": bp.get("description", "").strip(),
            "tags": tags,
            "version": walkthrough.get("version", "1.0"),
            "path": f"blueprints/{bp_dir.name}",
            "requires_images": requires_images,
            "includes_msel": has_msel,
            "includes_content": has_content,
            "checksum": dir_checksum(bp_dir),
        })

    return items


def scan_scenarios() -> list[dict]:
    items = []
    scenarios_dir = REPO_ROOT / "scenarios"
    if not scenarios_dir.exists():
        return items

    for f in sorted(scenarios_dir.glob("*.yaml")):
        if f.name == "manifest.yaml":
            continue

        scenario = load_yaml(f)
        items.append({
            "id": f.stem,
            "type": "scenario",
            "name": scenario.get("name", f.stem.replace("-", " ").title()),
            "description": scenario.get("description", "").strip(),
            "tags": scenario.get("tags", []),
            "version": str(scenario.get("version", "1.0")),
            "path": f"scenarios/{f.name}",
            "checksum": file_checksum(f),
        })

    return items


def scan_images() -> list[dict]:
    items = []
    images_dir = REPO_ROOT / "images"
    if not images_dir.exists():
        return items

    for img_dir in sorted(images_dir.iterdir()):
        if not img_dir.is_dir():
            continue

        manifest = img_dir / "image.yaml"
        if not manifest.exists():
            continue

        img = load_yaml(manifest)
        items.append({
            "id": img_dir.name,
            "type": "image",
            "name": img.get("name", img_dir.name),
            "description": img.get("description", "").strip(),
            "tags": [img.get("category", "")],
            "version": str(img.get("version", "1.0")),
            "path": f"images/{img_dir.name}",
            "arch": img.get("arch", "x86_64"),
            "docker_tag": img.get("tag", ""),
            "checksum": dir_checksum(img_dir),
        })

    return items


def scan_base_images() -> list[dict]:
    items = []
    base_images_dir = REPO_ROOT / "base-images"
    manifest_file = base_images_dir / "manifest.yaml"
    if not manifest_file.exists():
        return items

    manifest = load_yaml(manifest_file)
    for tmpl in manifest.get("templates", []):
        tmpl_file = base_images_dir / tmpl.get("file", "")
        if not tmpl_file.exists():
            continue

        tmpl_data = load_yaml(tmpl_file)
        items.append({
            "id": tmpl.get("seed_id", tmpl_file.stem),
            "type": "base_image",
            "name": tmpl_data.get("name", tmpl.get("seed_id", "")),
            "description": tmpl.get("description", tmpl_data.get("description", "")).strip(),
            "tags": [tmpl.get("category", "")],
            "version": "1.0",
            "path": f"base-images/{tmpl.get('file', '')}",
            "arch": tmpl.get("arch", "both"),
            "checksum": file_checksum(tmpl_file),
        })

    return items


def main():
    catalog_file = REPO_ROOT / "catalog.yaml"
    catalog_meta = load_yaml(catalog_file) if catalog_file.exists() else {}

    items = []
    items.extend(scan_blueprints())
    items.extend(scan_scenarios())
    items.extend(scan_images())
    items.extend(scan_base_images())

    index = {
        "catalog": {
            "name": catalog_meta.get("name", "CYROID Catalog"),
            "version": catalog_meta.get("version", "0.1.0"),
            "maintainer": catalog_meta.get("maintainer", ""),
            "generated_at": datetime.now(timezone.utc).isoformat(),
        },
        "items": items,
    }

    output = REPO_ROOT / "index.json"
    with open(output, "w") as f:
        json.dump(index, f, indent=2)

    print(f"Generated index.json with {len(items)} items:")
    by_type = {}
    for item in items:
        by_type.setdefault(item["type"], []).append(item)
    for t, group in sorted(by_type.items()):
        print(f"  {t}: {len(group)}")


if __name__ == "__main__":
    main()
