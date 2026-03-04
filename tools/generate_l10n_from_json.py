#!/usr/bin/env python3
"""Generate ARB localization files from JSON dictionaries.

Source of truth:
  - assets/i18n/es.json
  - assets/i18n/en.json
  - assets/i18n/fr.json

Output:
  - lib/l10n/app_es.arb
  - lib/l10n/app_en.arb
  - lib/l10n/app_fr.arb
"""

from __future__ import annotations

import json
from pathlib import Path
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]
I18N_DIR = PROJECT_ROOT / "assets" / "i18n"
L10N_DIR = PROJECT_ROOT / "lib" / "l10n"
LOCALES = ("es", "en", "fr")


def load_json(path: Path) -> dict[str, str]:
    if not path.exists():
        raise FileNotFoundError(f"Missing file: {path}")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object in {path}")
    out: dict[str, str] = {}
    for key, value in data.items():
        if not isinstance(key, str) or not isinstance(value, str):
            raise ValueError(
                f"Invalid entry in {path}: keys/values must be strings ({key!r})",
            )
        out[key] = value
    return out


def validate_same_keys(base: dict[str, str], other: dict[str, str], locale: str) -> None:
    base_keys = set(base.keys())
    other_keys = set(other.keys())
    missing = sorted(base_keys - other_keys)
    extra = sorted(other_keys - base_keys)
    if missing or extra:
        message = [f"Key mismatch for locale '{locale}':"]
        if missing:
            message.append(f"  Missing keys ({len(missing)}): {', '.join(missing)}")
        if extra:
            message.append(f"  Extra keys ({len(extra)}): {', '.join(extra)}")
        raise ValueError("\n".join(message))


def write_arb(locale: str, entries: dict[str, str]) -> None:
    L10N_DIR.mkdir(parents=True, exist_ok=True)
    arb = {"@@locale": locale}
    transformed: dict[str, str] = {}
    for key, value in entries.items():
        pieces = [segment for segment in key.replace("-", ".").split(".") if segment]
        if not pieces:
            raise ValueError(f"Invalid key '{key}'")
        camel = pieces[0].lower() + "".join(
            part[:1].upper() + part[1:] for part in pieces[1:]
        )
        if camel in transformed:
            raise ValueError(
                f"ARB key collision between '{key}' and another key -> '{camel}'",
            )
        transformed[camel] = value

    for key in sorted(transformed.keys()):
        arb[key] = transformed[key]

    out_path = L10N_DIR / f"app_{locale}.arb"
    out_path.write_text(
        json.dumps(arb, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Generated {out_path.relative_to(PROJECT_ROOT)}")


def main() -> int:
    try:
        localized: dict[str, dict[str, str]] = {}
        for locale in LOCALES:
            localized[locale] = load_json(I18N_DIR / f"{locale}.json")

        base = localized["es"]
        for locale in LOCALES:
            validate_same_keys(base, localized[locale], locale)
            write_arb(locale, localized[locale])

        print("Done.")
        return 0
    except Exception as exc:  # noqa: BLE001
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
