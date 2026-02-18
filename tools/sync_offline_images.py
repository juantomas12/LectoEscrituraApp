#!/usr/bin/env python3
"""SYNC OFFLINE IMAGES FOR THE LECTOESCRITURA DATASET.

WORKFLOW
1) READ DATASET JSON.
2) FOR ITEMS WITHOUT IMAGE / MISSING FILE / SVG PLACEHOLDER, SEARCH CANDIDATES.
3) DOWNLOAD BEST CANDIDATE LOCALLY INTO assets/images/<category>/.
4) UPDATE imageAsset IN DATASET.
5) SAVE SOURCE + LICENSE TRACEABILITY IN assets/data/image_sources.json.

SUPPORTED PROVIDERS
- arasaac (PICTOGRAMS EDUCATIVOS EN ESPAÑOL, SIN API KEY)
- pexels (HIGH-QUALITY STOCK PHOTOS, REQUIRES API KEY)
- google_cse (OFFICIAL GOOGLE CUSTOM SEARCH API, REQUIRES API KEY + CX)
- openverse (NO KEY, CREATIVE COMMONS INDEX)
- wikimedia (NO KEY, CREATIVE COMMONS / PUBLIC DOMAIN SOURCES)
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
from io import BytesIO
import json
import os
import re
import socket
import sys
import time
import unicodedata
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode, urlparse
from urllib.request import Request, urlopen

try:
    from PIL import Image
except Exception:  # pragma: no cover - optional dependency
    Image = None

USER_AGENT = "LECTOESCRITURA-APP-IMAGE-SYNC/1.0"
DEFAULT_TIMEOUT = 20
DEFAULT_MIN_WIDTH = 640
DEFAULT_MIN_HEIGHT = 480
DEFAULT_MAX_BYTES = 8 * 1024 * 1024
ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp"}
CATEGORY_HINTS = {
    "COSAS DE CASA": "HOME OBJECT",
    "COMIDA": "FOOD",
    "DINERO": "MONEY",
    "BAÑO": "BATHROOM",
    "PROFESIONES": "PROFESSION",
    "SALUD": "HEALTH",
    "EMOCIONES": "EMOTION",
}
CATEGORY_KEYWORDS = {
    "COSAS DE CASA": ["home", "house", "furniture", "kitchen", "room", "table", "chair", "bed"],
    "COMIDA": ["food", "meal", "fruit", "bread", "kitchen", "dish", "cooking"],
    "DINERO": ["money", "coin", "banknote", "cash", "wallet", "payment", "finance"],
    "BAÑO": ["bathroom", "shower", "toothbrush", "soap", "toilet", "hygiene"],
    "PROFESIONES": ["profession", "worker", "job", "teacher", "doctor", "police", "firefighter"],
    "SALUD": ["health", "medical", "doctor", "hospital", "medicine", "exercise"],
    "EMOCIONES": ["emotion", "face", "smile", "sad", "angry", "feeling"],
}
NOISY_TOKENS = {
    "campaign",
    "election",
    "arizona",
    "city",
    "building",
    "logo",
    "flag",
    "municipality",
    "district",
    "province",
    "village",
    "town",
    "cabin",
    "geograph",
    "street",
    "road",
    "park",
    "mountain",
    "valley",
    "lake",
    "river",
    "tower",
    "apartment",
}
HARD_REJECT_TOKENS = {
    "title page",
    "libretto",
    "manuscript",
    "book",
    "document",
    "duca",
    "governatore",
    "comandante",
    "pari di francia",
    "map",
    "mapa",
    "mappa",
    "karte",
    "cartography",
    "atlas",
    "canton",
    "switzerland",
    "tessin",
    "italien",
    "geograph.org.uk",
    "biblioteca nacional",
    "state park",
    "national park",
    "acervo do museu",
    "museu paulista",
    "primera y segunda parte",
    "grandezas y cosas notables",
    "painting",
    "illustration",
    "engraving",
    "etching",
    "lithograph",
    "poster",
    "doll",
    "miniature",
}
PLACE_LIKE_TOKENS = {
    "valencia",
    "village",
    "town",
    "city",
    "municipality",
    "district",
    "province",
    "ruins",
    "vista de",
    "canton",
    "switzerland",
    "italien",
    "county",
    "avenue",
    "street",
    "road",
    "mountain",
    "river",
    "lake",
    "park",
    "tower",
}
INAPPROPRIATE_TOKENS = {
    "nude",
    "naked",
    "erotic",
    "porn",
    "sex",
    "gore",
    "blood",
    "corpse",
    "dead body",
    "defecates",
}
WORD_OBJECT_HINTS = {
    "MESA": ["table", "furniture", "desk", "dining"],
    "SILLA": ["chair", "seat", "furniture", "armchair"],
    "CAMA": ["bed", "bedroom", "mattress", "sleep"],
    "SOFA": ["sofa", "couch", "living room", "furniture"],
    "LAMPARA": ["lamp", "lighting", "light fixture", "table lamp"],
    "PUERTA": ["door", "entrance", "doorway", "wooden door"],
    "VENTANA": ["window", "house window", "glass window"],
    "ARMARIO": ["wardrobe", "closet", "cabinet", "furniture"],
    "ESPEJO": ["mirror", "bath mirror", "wall mirror"],
    "RELOJ": ["clock", "wall clock", "watch", "timepiece"],
    "CORTINA": ["curtain", "drape", "window curtain"],
    "ALFOMBRA": ["carpet", "rug", "floor rug"],
    "PAN": ["bread", "loaf", "bakery bread"],
    "LECHE": ["milk", "milk glass", "dairy milk"],
    "AGUA": ["water", "drinking water", "water glass"],
    "ARROZ": ["rice", "rice bowl", "cooked rice"],
    "SOPA": ["soup", "soup bowl", "hot soup"],
    "MANZANA": ["apple", "fruit apple", "red apple"],
    "PERA": ["pear", "fruit pear", "green pear"],
    "HUEVO": ["egg", "hen egg", "boiled egg"],
    "QUESO": ["cheese", "cheese block", "dairy cheese"],
    "YOGUR": ["yogurt", "yoghurt", "dairy cup"],
    "POLLO": ["chicken meat", "cooked chicken", "food chicken"],
    "PESCADO": ["fish food", "cooked fish", "seafood"],
    "MONEDA": ["coin", "money coin", "currency"],
    "BILLETE": ["banknote", "paper money", "cash"],
    "CARTERA": ["wallet", "money wallet", "leather wallet"],
    "BANCO": ["piggy bank", "money box", "savings bank"],
    "PRECIO": ["price tag", "label price", "store tag"],
    "COMPRA": ["shopping cart", "grocery shopping", "shopping bag"],
    "VENTA": ["sale sign", "store sale", "shopping sale"],
    "CAJA": ["cash register", "money box", "store checkout"],
    "CAMBIO": ["coins change", "cash change", "money coins"],
    "CUENTA": ["bill receipt", "invoice", "restaurant bill"],
    "AHORRO": ["piggy bank", "savings", "money saving"],
    "PAGO": ["payment card", "card payment", "cash payment"],
    "JABON": ["soap", "bar soap", "hand soap"],
    "TOALLA": ["towel", "bath towel", "white towel"],
    "CEPILLO": ["toothbrush", "brush", "dental brush"],
    "PASTA": ["toothpaste", "dental cream", "tube"],
    "DUCHA": ["shower", "bathroom shower", "shower head"],
    "GRIFO": ["faucet", "tap", "sink faucet"],
    "PEINE": ["comb", "hair comb", "hairbrush"],
    "CHAMPU": ["shampoo bottle", "hair shampoo", "bath bottle"],
    "SECADOR": ["hair dryer", "dryer", "bathroom appliance"],
    "PAPEL": ["toilet paper", "paper roll", "bath paper"],
    "INODORO": ["toilet", "wc", "bathroom toilet"],
    "DOCENTE": ["teacher", "classroom", "school teacher"],
    "MEDICO": ["doctor", "medical doctor", "hospital doctor"],
    "ENFERMERA": ["nurse", "hospital nurse", "medical staff"],
    "BOMBERO": ["firefighter", "fireman", "fire rescue"],
    "POLICIA": ["police officer", "police uniform", "law enforcement"],
    "PANADERO": ["baker", "bakery worker", "bread baker"],
    "COCINERO": ["cook", "chef", "kitchen chef"],
    "CARPINTERO": ["carpenter", "woodworker", "workshop"],
    "MECANICO": ["mechanic", "car repair", "garage mechanic"],
    "VETERINARIO": ["veterinarian", "pet doctor", "animal clinic"],
    "PILOTO": ["pilot", "airplane pilot", "cockpit"],
    "AGRICULTOR": ["farmer", "agriculture", "field farmer"],
    "CUERPO": ["human body", "anatomy", "body diagram"],
    "CORAZON": ["heart", "human heart", "cardiology"],
    "PULSO": ["pulse", "heartbeat", "heart rate"],
    "FIEBRE": ["thermometer", "fever", "body temperature"],
    "MEDICINA": ["medicine", "pill", "medical drug"],
    "DOCTOR": ["doctor", "medical professional", "clinic"],
    "DESCANSO": ["resting", "sleep", "relaxing"],
    "EJERCICIO": ["exercise", "fitness", "workout"],
    "VACUNA": ["vaccine", "syringe", "immunization"],
    "HERIDA": ["wound", "bandage", "injury care"],
    "CURA": ["healing", "first aid", "medical treatment"],
    "ALEGRIA": ["happy face", "joy emotion", "smile"],
    "TRISTEZA": ["sad face", "sad emotion", "crying"],
    "ENOJO": ["angry face", "anger emotion", "mad"],
    "MIEDO": ["fear emotion", "scared face", "anxiety"],
    "CALMA": ["calm face", "peaceful", "relax"],
    "SORPRESA": ["surprised face", "astonished", "emotion"],
    "AMOR": ["love heart", "affection", "hug"],
    "NERVIOS": ["nervous face", "anxiety", "stress"],
    "ORGULLO": ["proud face", "achievement", "success"],
    "VERGUENZA": ["embarrassed face", "shy emotion", "blush"],
    "PACIENCIA": ["patient waiting", "calm waiting", "self control"],
    "EMPATIA": ["empathy", "helping hand", "support"],
}
STRICT_HINT_WORDS = set(WORD_OBJECT_HINTS.keys())
AMBIGUOUS_ITEM_WORDS = {
    "MESA",
    "SILLA",
    "CAMA",
    "BANCO",
}
ARASAAC_QUERY_ALIASES = {
    "DOCENTE": ["PROFESOR", "MAESTRO"],
    "DOCTOR": ["MEDICO"],
    "ENOJO": ["ENFADO", "ENFADADO", "RABIA"],
    "ORGULLO": ["ORGULLOSO"],
    "PAGO": ["PAGAR"],
}


def _log(message: str) -> None:
    print(message)


def _deaccent(text: str) -> str:
    normalized = unicodedata.normalize("NFKD", text)
    return "".join(ch for ch in normalized if not unicodedata.combining(ch))


def _slug(text: str) -> str:
    ascii_text = _deaccent(text).lower()
    ascii_text = re.sub(r"[^a-z0-9]+", "_", ascii_text).strip("_")
    return ascii_text or "general"


def _clean_text(value: str) -> str:
    no_tags = re.sub(r"<[^>]*>", "", value)
    return html.unescape(no_tags).strip()


def _normalized_text(value: str) -> str:
    return re.sub(r"\\s+", " ", _deaccent(value).lower()).strip()


def _contains_token(text: str, token: str) -> bool:
    normalized_token = _normalized_text(token)
    if not text or not normalized_token:
        return False
    pattern = rf"(^|[^a-z0-9]){re.escape(normalized_token)}([^a-z0-9]|$)"
    return re.search(pattern, text) is not None


def _contains_any(text: str, tokens: Iterable[str]) -> bool:
    return any(_contains_token(text, token) for token in tokens)


def _dedupe_tokens(tokens: Iterable[str]) -> List[str]:
    output: List[str] = []
    seen = set()
    for token in tokens:
        clean = _normalized_text(token)
        if not clean or clean in seen:
            continue
        output.append(clean)
        seen.add(clean)
    return output


def _item_core_hint_tokens(item: Dict[str, Any]) -> List[str]:
    word = _deaccent(_item_main_word(item)).upper()
    return _dedupe_tokens(WORD_OBJECT_HINTS.get(word, []))


def _item_hint_tokens(item: Dict[str, Any]) -> List[str]:
    word = _deaccent(_item_main_word(item)).upper()
    raw_word = _normalized_text(word)
    return _dedupe_tokens([*WORD_OBJECT_HINTS.get(word, []), raw_word])


def _candidate_combined_text(candidate: Dict[str, Any]) -> str:
    title = _normalized_text(str(candidate.get("title", "")))
    source_page = _normalized_text(str(candidate.get("source_page", "")))
    description = _normalized_text(str(candidate.get("description", "")))
    categories = candidate.get("categories")
    categories_text = ""
    if isinstance(categories, list):
        categories_text = _normalized_text(" ".join(str(value) for value in categories))
    return " ".join(part for part in [title, source_page, description, categories_text] if part).strip()


def _title_looks_narrative_or_catalog(title: str) -> bool:
    if not title:
        return False

    words = re.findall(r"[a-z0-9]+", title)
    if len(words) >= 16:
        return True

    if " is a " in title and len(words) >= 10:
        return True

    if " allows " in title or " sleeps " in title:
        return True

    if title.count(",") >= 3 and len(words) >= 10:
        return True

    if re.search(r"\\(\\d{6,}\\)", title):
        return True

    return False


def _candidate_has_object_clues(item: Dict[str, Any], combined_text: str) -> bool:
    category = str(item.get("category", "")).strip().upper()
    category_tokens = CATEGORY_KEYWORDS.get(category, [])
    hint_tokens = _item_hint_tokens(item)
    return _contains_any(combined_text, category_tokens) or _contains_any(combined_text, hint_tokens)


def _candidate_metadata_is_bad(item: Dict[str, Any], candidate: Dict[str, Any]) -> bool:
    title = _normalized_text(str(candidate.get("title", "")))
    combined = _candidate_combined_text(candidate)
    provider = str(candidate.get("provider", "")).strip().lower()

    if _contains_any(combined, HARD_REJECT_TOKENS):
        return True

    if _contains_any(combined, INAPPROPRIATE_TOKENS):
        return True

    if _title_looks_narrative_or_catalog(title):
        return True

    if _contains_any(combined, PLACE_LIKE_TOKENS) and not _candidate_has_object_clues(item, combined):
        return True

    if provider != "arasaac":
        item_word = _deaccent(_item_main_word(item)).upper()
        if item_word in AMBIGUOUS_ITEM_WORDS:
            hint_tokens = _item_core_hint_tokens(item)
            if hint_tokens and not _contains_any(combined, hint_tokens):
                return True
        elif item_word in STRICT_HINT_WORDS:
            hint_tokens = _item_hint_tokens(item)
            if hint_tokens and not _contains_any(combined, hint_tokens):
                return True

    return False


def _looks_like_text_document(image_bytes: bytes) -> bool:
    if Image is None:
        return False
    try:
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
        image.thumbnail((256, 256))
    except Exception:
        return False

    pixels = list(image.getdata())
    if not pixels:
        return False

    total = len(pixels)
    white = 0
    dark = 0
    colorful = 0
    gray = 0

    for r, g, b in pixels:
        if r > 235 and g > 235 and b > 235:
            white += 1
        if r < 50 and g < 50 and b < 50:
            dark += 1
        if max(r, g, b) - min(r, g, b) > 35:
            colorful += 1
        if abs(r - g) < 12 and abs(g - b) < 12 and abs(r - b) < 12:
            gray += 1

    white_ratio = white / total
    dark_ratio = dark / total
    colorful_ratio = colorful / total
    gray_ratio = gray / total

    if white_ratio > 0.58 and colorful_ratio < 0.08 and dark_ratio > 0.005:
        return True
    if gray_ratio > 0.92 and colorful_ratio < 0.04:
        return True
    return False


def _request_json(
    url: str,
    params: Dict[str, Any],
    timeout: int = DEFAULT_TIMEOUT,
    headers: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    full_url = f"{url}?{urlencode(params)}"
    request_headers = {"User-Agent": USER_AGENT}
    if headers:
        request_headers.update(headers)
    req = Request(full_url, headers=request_headers)
    with urlopen(req, timeout=timeout) as response:
        payload = response.read().decode("utf-8")
    return json.loads(payload)


def _infer_mime_from_url(url: str) -> Optional[str]:
    path = urlparse(url).path.lower()
    if path.endswith(".jpg") or path.endswith(".jpeg"):
        return "image/jpeg"
    if path.endswith(".png"):
        return "image/png"
    if path.endswith(".webp"):
        return "image/webp"
    return None


def _mime_to_ext(mime: str) -> str:
    return {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
    }.get(mime, ".jpg")


def _is_free_license(license_name: str) -> bool:
    if not license_name:
        return False
    upper = re.sub(r"\\s+", " ", license_name.upper()).strip()
    if "NC" in upper:
        return False
    if upper in {"BY", "BY-SA", "CC0", "PDM", "PD"}:
        return True
    if upper.startswith("BY ") or upper.startswith("BY-SA "):
        return True
    allowed_tokens = [
        "CC0",
        "PUBLIC DOMAIN",
        "CC BY",
        "CC-BY",
        "CC BY-SA",
        "CC-BY-SA",
        "PD",
        "GNU FREE DOCUMENTATION",
    ]
    return any(token in upper for token in allowed_tokens)


def _search_google_cse(
    query: str,
    api_key: str,
    cx: str,
    limit: int,
) -> List[Dict[str, Any]]:
    data = _request_json(
        "https://www.googleapis.com/customsearch/v1",
        {
            "key": api_key,
            "cx": cx,
            "q": query,
            "searchType": "image",
            "safe": "active",
            "num": min(limit, 10),
            "hl": "es",
            "gl": "es",
            # LIMIT TO COMMON FREE-LICENSE FLAGS AVAILABLE IN CSE.
            "rights": "cc_publicdomain|cc_attribute|cc_sharealike",
        },
    )

    output: List[Dict[str, Any]] = []
    for item in data.get("items", []):
        image = item.get("image", {})
        width = int(image.get("width", 0) or 0)
        height = int(image.get("height", 0) or 0)
        mime = item.get("mime") or _infer_mime_from_url(item.get("link", ""))
        output.append(
            {
                "provider": "google_cse",
                "image_url": item.get("link", ""),
                "source_page": image.get("contextLink", ""),
                "title": item.get("title", ""),
                "attribution": item.get("displayLink", ""),
                "license": "GOOGLE RIGHTS FILTER",
                "mime": mime,
                "width": width,
                "height": height,
            }
        )
    return output


def _search_arasaac(query: str, limit: int) -> List[Dict[str, Any]]:
    clean_query = re.sub(r"\s+", " ", query).strip().lower()
    if not clean_query:
        return []
    token = clean_query.split(" ")[0]
    if not token:
        return []

    normalized_token = _deaccent(token).upper()
    search_terms = [normalized_token]
    for alias in ARASAAC_QUERY_ALIASES.get(normalized_token, []):
        if alias not in search_terms:
            search_terms.append(alias)

    raw_entries: Dict[str, Dict[str, Any]] = {}
    for search_term in search_terms:
        url = f"https://api.arasaac.org/v1/pictograms/es/search/{quote(search_term.lower())}"
        req = Request(url, headers={"User-Agent": USER_AGENT})
        try:
            with urlopen(req, timeout=DEFAULT_TIMEOUT) as response:
                payload = response.read().decode("utf-8")
        except HTTPError as err:
            if err.code == 404:
                continue
            raise

        try:
            items = json.loads(payload)
        except json.JSONDecodeError:
            continue

        if not isinstance(items, list):
            continue

        for raw in items:
            if not isinstance(raw, dict):
                continue
            pictogram_id = raw.get("_id") or raw.get("id")
            if not pictogram_id:
                continue
            pictogram_id = str(pictogram_id).strip()
            if not pictogram_id:
                continue
            raw_entries[pictogram_id] = raw

    if not raw_entries:
        return []

    target_terms = {_normalized_text(normalized_token)}
    target_terms.update(_normalized_text(value) for value in ARASAAC_QUERY_ALIASES.get(normalized_token, []))

    ranked: List[Dict[str, Any]] = []
    for pictogram_id, raw in raw_entries.items():
        if not isinstance(raw, dict):
            continue

        keywords_value = raw.get("keywords")
        keywords: List[str] = []
        if isinstance(keywords_value, list):
            for keyword_item in keywords_value:
                if not isinstance(keyword_item, dict):
                    continue
                keyword_text = str(keyword_item.get("keyword", "")).strip()
                if keyword_text:
                    keywords.append(keyword_text)

        keyword_tokens = [_normalized_text(value) for value in keywords if value.strip()]
        relevance = 0.0
        for keyword_token in keyword_tokens:
            if keyword_token in target_terms:
                relevance = max(relevance, 20.0)
            elif any(keyword_token.startswith(target + " ") for target in target_terms):
                relevance = max(relevance, 12.0)
            elif any(target in keyword_token for target in target_terms):
                relevance = max(relevance, 6.0)

        title = keywords[0] if keywords else normalized_token
        description = " ".join(keywords)
        image_url = f"https://static.arasaac.org/pictograms/{pictogram_id}/{pictogram_id}_500.png"

        ranked.append(
            {
                "provider": "arasaac",
                "image_url": image_url,
                "source_page": f"https://arasaac.org/pictograms/{pictogram_id}",
                "title": title,
                "description": description,
                "attribution": "ARASAAC",
                "license": "CC BY-NC-SA 4.0",
                "mime": "image/png",
                # KEEP ZERO TO BYPASS MIN-WIDTH FILTER FOR PICTOGRAMS.
                "width": 0,
                "height": 0,
                "_relevance": relevance,
            }
        )

    ranked.sort(key=lambda value: float(value.get("_relevance", 0)), reverse=True)
    return ranked[: max(1, min(limit, 30))]


def _search_pexels(query: str, api_key: str, limit: int) -> List[Dict[str, Any]]:
    data = _request_json(
        "https://api.pexels.com/v1/search",
        {
            "query": query,
            "per_page": min(max(limit, 1), 80),
            "orientation": "landscape",
            "size": "large",
        },
        headers={"Authorization": api_key},
    )

    output: List[Dict[str, Any]] = []
    for photo in data.get("photos", []):
        src = photo.get("src", {})
        image_url = str(
            src.get("large2x")
            or src.get("large")
            or src.get("original")
            or src.get("medium")
            or ""
        ).strip()
        if not image_url:
            continue
        mime = _infer_mime_from_url(image_url)
        width = int(photo.get("width", 0) or 0)
        height = int(photo.get("height", 0) or 0)
        photo_url = str(photo.get("url", "")).strip()
        alt_text = str(photo.get("alt", "")).strip()
        photographer = str(photo.get("photographer", "")).strip()
        output.append(
            {
                "provider": "pexels",
                "image_url": image_url,
                "source_page": photo_url,
                "title": alt_text or f"PEXELS PHOTO {photo.get('id', '')}",
                "description": alt_text,
                "attribution": photographer,
                "license": "PEXELS LICENSE",
                "mime": mime,
                "width": width,
                "height": height,
            }
        )
    return output


def _search_openverse(query: str, limit: int) -> List[Dict[str, Any]]:
    data = _request_json(
        "https://api.openverse.org/v1/images/",
        {
            "q": query,
            "page_size": min(max(limit, 1), 20),
            "mature": "false",
            # COMMERCIAL FILTER REDUCES RISK OF NON-FREE OR UNCLEAR LICENSES.
            "license_type": "commercial",
        },
    )

    output: List[Dict[str, Any]] = []
    for item in data.get("results", []):
        image_url = str(item.get("url", "")).strip()
        if not image_url:
            continue
        mime = str(item.get("mimetype") or "").strip() or _infer_mime_from_url(image_url)
        width = int(item.get("width", 0) or 0)
        height = int(item.get("height", 0) or 0)

        license_code = str(item.get("license", "")).strip().upper()
        license_version = str(item.get("license_version", "")).strip()
        license_name = " ".join(part for part in [license_code, license_version] if part).strip()
        tags_value = item.get("tags")
        description = ""
        if isinstance(tags_value, list):
            tags: List[str] = []
            for tag in tags_value:
                if isinstance(tag, dict):
                    tag_name = str(tag.get("name", "")).strip()
                    if tag_name:
                        tags.append(tag_name)
                else:
                    clean_tag = str(tag).strip()
                    if clean_tag:
                        tags.append(clean_tag)
            description = " ".join(tags)
        elif isinstance(tags_value, str):
            description = tags_value.strip()

        output.append(
            {
                "provider": "openverse",
                "image_url": image_url,
                "source_page": str(item.get("foreign_landing_url", "")).strip(),
                "title": str(item.get("title", "")).strip(),
                "description": description,
                "attribution": str(item.get("creator", "")).strip(),
                "license": license_name,
                "mime": mime,
                "width": width,
                "height": height,
            }
        )
    return output


def _search_wikimedia(query: str, limit: int) -> List[Dict[str, Any]]:
    data = _request_json(
        "https://commons.wikimedia.org/w/api.php",
        {
            "action": "query",
            "format": "json",
            "generator": "search",
            "gsrsearch": query,
            "gsrnamespace": 6,
            "gsrlimit": min(limit, 25),
            "prop": "imageinfo|categories",
            "iiprop": "url|mime|size|extmetadata",
            "iiurlwidth": 1280,
            "cllimit": 25,
        },
    )

    pages = data.get("query", {}).get("pages", {})
    output: List[Dict[str, Any]] = []

    for page in pages.values():
        info_list = page.get("imageinfo", [])
        if not info_list:
            continue
        info = info_list[0]
        metadata = info.get("extmetadata", {})

        license_name = _clean_text(metadata.get("LicenseShortName", {}).get("value", ""))
        artist = _clean_text(metadata.get("Artist", {}).get("value", ""))
        description = _clean_text(metadata.get("ImageDescription", {}).get("value", ""))

        image_url = info.get("thumburl") or info.get("url") or ""
        mime = info.get("mime") or _infer_mime_from_url(image_url)

        title = page.get("title", "")
        page_slug = title.replace(" ", "_")
        source_page = f"https://commons.wikimedia.org/wiki/{quote(page_slug)}"

        width = int(info.get("thumbwidth", info.get("width", 0)) or 0)
        height = int(info.get("thumbheight", info.get("height", 0)) or 0)
        category_titles: List[str] = []
        for category_item in page.get("categories", []):
            category_title = _clean_text(str(category_item.get("title", "")))
            if category_title.lower().startswith("category:"):
                category_title = category_title.split(":", 1)[1]
            if category_title:
                category_titles.append(category_title)

        output.append(
            {
                "provider": "wikimedia",
                "image_url": image_url,
                "source_page": source_page,
                "title": title,
                "description": description,
                "categories": category_titles,
                "attribution": artist,
                "license": license_name,
                "mime": mime,
                "width": width,
                "height": height,
            }
        )

    return output


def _download_binary(url: str, timeout: int = DEFAULT_TIMEOUT) -> bytes:
    req = Request(url, headers={"User-Agent": USER_AGENT})
    with urlopen(req, timeout=timeout) as response:
        return response.read()


def _build_query(item: Dict[str, Any]) -> str:
    category = str(item.get("category", "")).strip()
    word = str(item.get("word") or "").strip()
    if not word:
        words = item.get("words") or []
        if isinstance(words, list) and words:
            word = str(words[0]).strip()
    if not word:
        word = str(item.get("id", "OBJETO"))

    # PHRASE BOOSTS NATURAL IMAGE RESULTS.
    return f"{word} {category} FOTO REAL"


def _build_query_variants(item: Dict[str, Any]) -> List[str]:
    category = str(item.get("category", "")).strip().upper()
    base_query = _build_query(item)
    word = str(item.get("word") or "").strip()
    if not word:
        words = item.get("words") or []
        if isinstance(words, list) and words:
            word = str(words[0]).strip()
    if not word:
        word = str(item.get("id", "OBJETO")).strip()

    deaccent_word = _deaccent(word)
    deaccent_category = _deaccent(category)
    hint = CATEGORY_HINTS.get(category, "")
    hint_tokens = WORD_OBJECT_HINTS.get(deaccent_word.upper(), [])
    hint_primary = hint_tokens[0] if hint_tokens else ""
    hint_pair = " ".join(hint_tokens[:2]).strip()
    hint_phrase = " ".join(hint_tokens[:3]).strip()

    raw_variants = [
        f"{hint_primary} photo".strip(),
        f"{hint_primary} {hint} photo".strip(),
        f"{hint_pair} photo".strip(),
        f"{hint_phrase} object photo".strip(),
        base_query,
        f"{deaccent_word} {hint}".strip(),
        f"{deaccent_word} {deaccent_category}",
        deaccent_word,
    ]

    output: List[str] = []
    seen = set()
    for variant in raw_variants:
        clean = re.sub(r"\\s+", " ", variant).strip()
        if not clean or clean in seen:
            continue
        output.append(clean)
        seen.add(clean)
    return output


def _item_main_word(item: Dict[str, Any]) -> str:
    word = str(item.get("word") or "").strip()
    if word:
        return word
    words = item.get("words") or []
    if isinstance(words, list) and words:
        return str(words[0]).strip()
    return str(item.get("id", "")).strip()


def _score_candidate(candidate: Dict[str, Any], item: Dict[str, Any], query: str) -> float:
    score = 0.0
    title = _normalized_text(str(candidate.get("title", "")))
    combined = _candidate_combined_text(candidate)

    main_word = _normalized_text(_item_main_word(item))
    category = str(item.get("category", "")).strip().upper()
    hint = _normalized_text(CATEGORY_HINTS.get(category, ""))
    category_keywords = CATEGORY_KEYWORDS.get(category, [])
    word_hint_tokens = _item_hint_tokens(item)

    if main_word and _contains_token(combined, main_word):
        score += 8.0
    if hint and _contains_token(combined, hint):
        score += 3.5
    for token in category_keywords:
        if _contains_token(combined, token):
            score += 1.25
    for token in word_hint_tokens:
        if _contains_token(combined, token):
            score += 3.0
    for token in NOISY_TOKENS:
        if _contains_token(combined, token):
            score -= 1.0
    if _contains_any(combined, HARD_REJECT_TOKENS):
        score -= 12.0
    if _contains_any(combined, INAPPROPRIATE_TOKENS):
        score -= 20.0
    if _contains_any(combined, PLACE_LIKE_TOKENS) and not _candidate_has_object_clues(item, combined):
        score -= 8.0
    if _title_looks_narrative_or_catalog(title):
        score -= 7.0

    title_word_count = len(re.findall(r"[a-z0-9]+", title))
    if 1 <= title_word_count <= 8:
        score += 1.4
    elif title_word_count > 14:
        score -= 3.5

    width = int(candidate.get("width", 0) or 0)
    height = int(candidate.get("height", 0) or 0)
    megapixels = (width * height) / 1_000_000
    score += min(megapixels, 3.0)

    provider = str(candidate.get("provider", ""))
    if provider == "google_cse":
        score += 2.0
    elif provider == "arasaac":
        score += 15.0
    elif provider == "pexels":
        score += 2.8
    elif provider == "wikimedia":
        score += 1.0

    if _normalized_text(query) in combined:
        score += 1.0

    return score


def _iter_candidates(
    providers: Iterable[str],
    query: str,
    pexels_api_key: str,
    google_api_key: str,
    google_cx: str,
    per_provider_limit: int,
) -> Iterable[Dict[str, Any]]:
    for provider in providers:
        provider = provider.strip().lower()
        if not provider:
            continue

        try:
            if provider == "arasaac":
                for candidate in _search_arasaac(query, per_provider_limit):
                    yield candidate
            elif provider == "pexels":
                if not pexels_api_key:
                    _log("[SKIP] PEXELS SIN API KEY. USA ENV PEXELS_API_KEY.")
                    continue
                for candidate in _search_pexels(query, pexels_api_key, per_provider_limit):
                    yield candidate
            elif provider == "google_cse":
                if not google_api_key or not google_cx:
                    _log("[SKIP] GOOGLE CSE SIN API KEY/CX. USA ENV GOOGLE_CSE_API_KEY Y GOOGLE_CSE_CX.")
                    continue
                for candidate in _search_google_cse(query, google_api_key, google_cx, per_provider_limit):
                    yield candidate
            elif provider == "openverse":
                for candidate in _search_openverse(query, per_provider_limit):
                    yield candidate
            elif provider == "wikimedia":
                for candidate in _search_wikimedia(query, per_provider_limit):
                    yield candidate
            else:
                _log(f"[SKIP] PROVEEDOR DESCONOCIDO: {provider}")
        except (HTTPError, URLError, TimeoutError, socket.timeout, OSError) as err:
            if isinstance(err, HTTPError) and err.code == 429:
                _log(f"[WARN] RATE LIMIT EN {provider}. ESPERANDO 2.5s...")
                time.sleep(2.5)
            _log(f"[WARN] ERROR EN PROVEEDOR {provider}: {err}")


def _candidate_is_valid(
    candidate: Dict[str, Any],
    min_width: int,
    min_height: int,
    require_free_license: bool,
    accept_google_rights_filter: bool,
) -> bool:
    image_url = candidate.get("image_url") or ""
    mime = candidate.get("mime") or _infer_mime_from_url(image_url)
    width = int(candidate.get("width", 0) or 0)
    height = int(candidate.get("height", 0) or 0)
    provider = str(candidate.get("provider", ""))
    license_name = str(candidate.get("license", ""))

    if not image_url:
        return False
    if mime not in ALLOWED_MIME:
        return False
    if width and width < min_width:
        return False
    if height and height < min_height:
        return False

    if not require_free_license:
        return True

    if provider == "google_cse":
        return accept_google_rights_filter
    if provider == "arasaac":
        return True
    if provider == "pexels":
        return True

    return _is_free_license(license_name)


def _load_json(path: Path) -> Dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _save_json(path: Path, payload: Dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _should_process_item(item: Dict[str, Any], root: Path, refresh_existing: bool, replace_svg: bool) -> bool:
    image_asset = str(item.get("imageAsset") or "").strip()
    if not image_asset:
        return True

    asset_path = root / image_asset

    if refresh_existing:
        return True

    if replace_svg and image_asset.lower().endswith(".svg"):
        return True

    return not asset_path.exists()


def _load_sources(path: Path) -> Dict[str, Dict[str, Any]]:
    if not path.exists():
        return {}
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}

    if isinstance(raw, dict) and isinstance(raw.get("sources"), list):
        return {str(item.get("itemId")): item for item in raw["sources"] if item.get("itemId")}

    if isinstance(raw, list):
        return {str(item.get("itemId")): item for item in raw if isinstance(item, dict) and item.get("itemId")}

    return {}


def _save_sources(path: Path, source_map: Dict[str, Dict[str, Any]]) -> None:
    payload = {
        "generatedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
        "sources": [source_map[key] for key in sorted(source_map.keys())],
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="SYNC ONLINE IMAGES INTO OFFLINE DATASET ASSETS")
    parser.add_argument("--dataset", default="assets/data/lectoescritura_dataset.json")
    parser.add_argument("--sources", default="assets/data/image_sources.json")
    parser.add_argument(
        "--providers",
        default="arasaac,pexels,openverse,wikimedia,google_cse",
        help="ORDERED LIST: arasaac,pexels,openverse,wikimedia,google_cse",
    )
    parser.add_argument("--per-provider-limit", type=int, default=10)
    parser.add_argument("--min-width", type=int, default=DEFAULT_MIN_WIDTH)
    parser.add_argument("--min-height", type=int, default=DEFAULT_MIN_HEIGHT)
    parser.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    parser.add_argument("--refresh-existing", action="store_true")
    parser.add_argument("--replace-svg", action="store_true", default=True)
    parser.add_argument("--no-replace-svg", dest="replace_svg", action="store_false")
    parser.add_argument("--require-free-license", action="store_true", default=True)
    parser.add_argument("--allow-any-license", dest="require_free_license", action="store_false")
    parser.add_argument("--accept-google-rights-filter", action="store_true", default=True)
    parser.add_argument("--strict-google-license", dest="accept_google_rights_filter", action="store_false")
    parser.add_argument("--limit", type=int, default=0, help="0 = SIN LÍMITE")
    parser.add_argument("--level", action="append", type=int, default=[])
    parser.add_argument("--item-id", action="append", default=[])
    parser.add_argument("--interactive", action="store_true")
    parser.add_argument("--preview-candidates", type=int, default=5)
    parser.add_argument("--auto-retry-candidates", type=int, default=6)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--sleep", type=float, default=0.15)

    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    dataset_path = root / args.dataset
    sources_path = root / args.sources

    if not dataset_path.exists():
        _log(f"[ERROR] DATASET NO ENCONTRADO: {dataset_path}")
        return 1

    pexels_api_key = os.getenv("PEXELS_API_KEY", "").strip()
    google_api_key = os.getenv("GOOGLE_CSE_API_KEY", "").strip()
    google_cx = os.getenv("GOOGLE_CSE_CX", "").strip()

    dataset = _load_json(dataset_path)
    items = dataset.get("items")
    if not isinstance(items, list):
        _log("[ERROR] FORMATO DE DATASET INVÁLIDO: FALTA LISTA 'items'")
        return 1

    source_map = _load_sources(sources_path)

    target_item_ids = {value.strip() for value in args.item_id if value.strip()}
    target_levels = {int(value) for value in args.level if int(value) > 0}
    providers = [token.strip() for token in args.providers.split(",") if token.strip()]

    if any(provider.lower() == "pexels" for provider in providers) and not pexels_api_key:
        _log("[INFO] PEXELS DESACTIVADO (FALTA PEXELS_API_KEY).")
        providers = [provider for provider in providers if provider.lower() != "pexels"]

    if any(provider.lower() == "google_cse" for provider in providers) and (not google_api_key or not google_cx):
        _log("[INFO] GOOGLE_CSE DESACTIVADO (FALTA GOOGLE_CSE_API_KEY/GOOGLE_CSE_CX).")
        providers = [provider for provider in providers if provider.lower() != "google_cse"]

    query_cache: Dict[str, List[Dict[str, Any]]] = {}

    updated = 0
    skipped = 0
    failed = 0

    try:
        for item in items:
            item_id = str(item.get("id", "")).strip()
            if not item_id:
                skipped += 1
                continue

            if target_item_ids and item_id not in target_item_ids:
                skipped += 1
                continue

            level_value = int(item.get("level", 0) or 0)
            if target_levels and level_value not in target_levels:
                skipped += 1
                continue

            if not _should_process_item(item, root, args.refresh_existing, args.replace_svg):
                skipped += 1
                continue

            queries = _build_query_variants(item)
            category = str(item.get("category", "GENERAL"))
            category_slug = _slug(category)

            _log(f"[SEARCH] {item_id} -> {queries[0] if queries else item_id}")

            scored_candidates: List[Dict[str, Any]] = []
            seen_urls = set()
            for query in queries:
                cache_key = (
                    f"{query}|{','.join(providers)}|{args.per_provider_limit}|"
                    f"{pexels_api_key != ''}|{google_api_key != ''}|{google_cx != ''}"
                )
                if cache_key in query_cache:
                    query_candidates = query_cache[cache_key]
                else:
                    query_candidates = list(
                        _iter_candidates(
                            providers=providers,
                            query=query,
                            pexels_api_key=pexels_api_key,
                            google_api_key=google_api_key,
                            google_cx=google_cx,
                            per_provider_limit=args.per_provider_limit,
                        )
                    )
                    query_cache[cache_key] = query_candidates

                for candidate in query_candidates:
                    image_url = str(candidate.get("image_url", "")).strip()
                    if not image_url or image_url in seen_urls:
                        continue
                    seen_urls.add(image_url)

                    if not _candidate_is_valid(
                        candidate,
                        min_width=args.min_width,
                        min_height=args.min_height,
                        require_free_license=args.require_free_license,
                        accept_google_rights_filter=args.accept_google_rights_filter,
                    ):
                        continue
                    candidate["_query"] = query
                    candidate["_score"] = _score_candidate(candidate, item, query)
                    scored_candidates.append(candidate)

            if not scored_candidates:
                _log(f"[MISS] SIN CANDIDATOS VÁLIDOS PARA {item_id}")
                failed += 1
                continue

            scored_candidates.sort(key=lambda value: float(value.get("_score", 0)), reverse=True)
            filtered_candidates = [
                candidate
                for candidate in scored_candidates
                if not _candidate_metadata_is_bad(item, candidate)
            ]

            if not filtered_candidates:
                _log(f"[MISS] {item_id}: SOLO HUBO CANDIDATOS SOSPECHOSOS, SE REINTENTARÁ MÁS TARDE")
                failed += 1
                continue

            scored_candidates = filtered_candidates

            chosen = scored_candidates[0]
            chosen_query = str(chosen.get("_query", ""))

            if args.interactive:
                preview_count = max(1, min(args.preview_candidates, len(scored_candidates)))
                _log(f"[REVIEW] TOP {preview_count} CANDIDATOS PARA {item_id}:")
                for idx, cand in enumerate(scored_candidates[:preview_count], start=1):
                    _log(
                        f"  {idx}) SCORE={cand.get('_score'):.2f} | {cand.get('provider')} | "
                        f"LIC={cand.get('license')} | {cand.get('title')}"
                    )
                    _log(f"     {cand.get('image_url')}")
                choice = input("ELIGE NÚMERO (ENTER=1, 0=OMITIR): ").strip()
                if choice == "0":
                    _log(f"[SKIP] OMITIDO POR USUARIO: {item_id}")
                    skipped += 1
                    continue
                if choice:
                    try:
                        selected_index = int(choice) - 1
                        if 0 <= selected_index < preview_count:
                            chosen = scored_candidates[selected_index]
                            chosen_query = str(chosen.get("_query", ""))
                    except ValueError:
                        pass

            mime = chosen.get("mime") or _infer_mime_from_url(chosen.get("image_url", "")) or "image/jpeg"
            ext = _mime_to_ext(mime)
            file_name = f"{_slug(item_id)}{ext}"

            relative_path = Path("assets") / "images" / category_slug / file_name
            absolute_path = root / relative_path

            if args.dry_run:
                _log(f"[DRY] {item_id} -> {relative_path.as_posix()} ({chosen.get('provider')})")
                updated += 1
            else:
                selected_content: Optional[bytes] = None
                retry_pool = scored_candidates[: max(1, args.auto_retry_candidates)]
                download_error: Optional[str] = None

                for ranked_candidate in retry_pool:
                    try:
                        content = _download_binary(ranked_candidate["image_url"])
                    except (HTTPError, URLError, TimeoutError, OSError) as err:
                        download_error = str(err)
                        continue

                    if len(content) > args.max_bytes:
                        download_error = f"IMAGEN DEMASIADO GRANDE ({len(content)} bytes)"
                        continue

                    if (
                        str(ranked_candidate.get("provider", "")).strip().lower() != "arasaac"
                        and _looks_like_text_document(content)
                    ):
                        _log(
                            f"[RETRY] {item_id} DESCARTADA POR PARECER DOCUMENTO/TEXTO: "
                            f"{ranked_candidate.get('title', '')}"
                        )
                        continue

                    chosen = ranked_candidate
                    chosen_query = str(chosen.get("_query", ""))
                    mime = chosen.get("mime") or _infer_mime_from_url(chosen.get("image_url", "")) or "image/jpeg"
                    ext = _mime_to_ext(mime)
                    file_name = f"{_slug(item_id)}{ext}"
                    relative_path = Path("assets") / "images" / category_slug / file_name
                    absolute_path = root / relative_path
                    selected_content = content
                    break

                if selected_content is None:
                    _log(f"[ERROR] {item_id}: NO SE ENCONTRÓ UNA IMAGEN VÁLIDA. {download_error or ''}".strip())
                    failed += 1
                    continue

                absolute_path.parent.mkdir(parents=True, exist_ok=True)
                absolute_path.write_bytes(selected_content)

                item["imageAsset"] = relative_path.as_posix()

                source_map[item_id] = {
                    "itemId": item_id,
                    "query": chosen_query,
                    "provider": chosen.get("provider", ""),
                    "imageUrl": chosen.get("image_url", ""),
                    "sourcePage": chosen.get("source_page", ""),
                    "title": chosen.get("title", ""),
                    "license": chosen.get("license", ""),
                    "attribution": chosen.get("attribution", ""),
                    "mime": mime,
                    "width": int(chosen.get("width", 0) or 0),
                    "height": int(chosen.get("height", 0) or 0),
                    "downloadedAt": dt.datetime.now(dt.timezone.utc).isoformat(),
                    "storedAs": relative_path.as_posix(),
                }

                # SAVE INCREMENTALLY TO AVOID LOSING PROGRESS IF THE PROCESS STOPS.
                _save_json(dataset_path, dataset)
                _save_sources(sources_path, source_map)

                updated += 1
                _log(f"[OK] {item_id} -> {relative_path.as_posix()} ({chosen.get('provider')})")

            if args.limit and updated >= args.limit:
                _log(f"[STOP] LÍMITE ALCANZADO: {args.limit}")
                break

            if args.sleep > 0:
                time.sleep(args.sleep)
    except KeyboardInterrupt:
        _log("[INTERRUPTED] PROCESO DETENIDO POR USUARIO. PROGRESO GUARDADO.")

    if not args.dry_run:
        _save_json(dataset_path, dataset)
        _save_sources(sources_path, source_map)

    _log("\nRESUMEN")
    _log(f"- ACTUALIZADOS: {updated}")
    _log(f"- OMITIDOS: {skipped}")
    _log(f"- FALLIDOS: {failed}")
    _log(f"- DATASET: {dataset_path}")
    _log(f"- FUENTES: {sources_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
