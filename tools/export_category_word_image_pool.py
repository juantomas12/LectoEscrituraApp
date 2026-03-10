#!/usr/bin/env python3
"""Export fixed-size word+image pools per category from the local dataset.

Default behavior:
- Reads: assets/data/lectoescritura_dataset.json
- Uses only items with activityType == IMAGEN_PALABRA
- Builds a pool of 50 entries per category
- If a category has fewer than 50 base entries, repeats items cyclically
- Writes: assets/data/category_word_image_pool_50.json
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATASET = PROJECT_ROOT / "assets" / "data" / "lectoescritura_dataset.json"
DEFAULT_OUTPUT = PROJECT_ROOT / "assets" / "data" / "category_word_image_pool_50.json"


@dataclass(frozen=True)
class BaseEntry:
    item_id: str
    category: str
    word: str
    image_asset: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export N word+image entries per category from dataset JSON.",
    )
    parser.add_argument(
        "--dataset",
        type=Path,
        default=DEFAULT_DATASET,
        help="Path to dataset JSON (default: assets/data/lectoescritura_dataset.json).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="Output JSON path.",
    )
    parser.add_argument(
        "--activity-type",
        default="IMAGEN_PALABRA",
        help="Activity type key to use for base words/images.",
    )
    parser.add_argument(
        "--per-category",
        type=int,
        default=50,
        help="Pool size per category (default: 50).",
    )
    return parser.parse_args()


def _resolve_path(path: Path) -> Path:
    return path if path.is_absolute() else PROJECT_ROOT / path


def load_dataset(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Dataset not found: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Invalid dataset JSON object: {path}")
    if not isinstance(data.get("items"), list):
        raise ValueError("Dataset must contain an 'items' array.")
    return data


def collect_base_entries(items: list[dict], activity_type: str) -> dict[str, list[BaseEntry]]:
    grouped: dict[str, list[BaseEntry]] = defaultdict(list)
    for raw in items:
        if not isinstance(raw, dict):
            continue
        if str(raw.get("activityType", "")).strip().upper() != activity_type:
            continue
        category = str(raw.get("category", "")).strip().upper()
        item_id = str(raw.get("id", "")).strip()
        word = str(raw.get("word", "")).strip().upper()
        image_asset = str(raw.get("imageAsset", "")).strip()
        if not category or not item_id or not word or not image_asset:
            continue
        grouped[category].append(
            BaseEntry(
                item_id=item_id,
                category=category,
                word=word,
                image_asset=image_asset,
            ),
        )

    for category in grouped:
        grouped[category].sort(key=lambda e: e.item_id)
    return dict(grouped)


def build_pool(entries: list[BaseEntry], pool_size: int) -> list[dict]:
    if not entries:
        return []
    out: list[dict] = []
    for idx in range(pool_size):
        src = entries[idx % len(entries)]
        out.append(
            {
                "poolIndex": idx + 1,
                "poolId": f"{src.item_id}__POOL_{idx + 1}",
                "sourceItemId": src.item_id,
                "word": src.word,
                "imageAsset": src.image_asset,
            },
        )
    return out


def build_export(
    grouped: dict[str, list[BaseEntry]],
    *,
    dataset_path: Path,
    activity_type: str,
    per_category: int,
) -> dict:
    categories: list[dict] = []
    for category in sorted(grouped.keys()):
        base_entries = grouped[category]
        categories.append(
            {
                "category": category,
                "baseCount": len(base_entries),
                "poolCount": per_category,
                "items": build_pool(base_entries, per_category),
            },
        )

    return {
        "metadata": {
            "generator": "tools/export_category_word_image_pool.py",
            "dataset": str(dataset_path.relative_to(PROJECT_ROOT)),
            "activityType": activity_type,
            "poolPerCategory": per_category,
            "categoryCount": len(categories),
            "totalPoolItems": len(categories) * per_category,
        },
        "categories": categories,
    }


def main() -> int:
    args = parse_args()
    dataset_path = _resolve_path(args.dataset)
    output_path = _resolve_path(args.output)
    activity_type = str(args.activity_type).strip().upper()
    per_category = int(args.per_category)
    if per_category <= 0:
        print("Error: --per-category must be > 0", file=sys.stderr)
        return 1

    try:
        dataset = load_dataset(dataset_path)
        grouped = collect_base_entries(dataset["items"], activity_type)
        if not grouped:
            print(
                f"Error: no valid entries found for activityType={activity_type}",
                file=sys.stderr,
            )
            return 1

        export_data = build_export(
            grouped,
            dataset_path=dataset_path,
            activity_type=activity_type,
            per_category=per_category,
        )

        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(
            json.dumps(export_data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

        print(f"Generated: {output_path.relative_to(PROJECT_ROOT)}")
        for category in export_data["categories"]:
            print(
                f"- {category['category']}: "
                f"base={category['baseCount']} -> pool={category['poolCount']}",
            )
        print(
            f"Done. Total categories={export_data['metadata']['categoryCount']}, "
            f"total pool items={export_data['metadata']['totalPoolItems']}.",
        )
        return 0
    except Exception as exc:  # noqa: BLE001
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
