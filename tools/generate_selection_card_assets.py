#!/usr/bin/env python3
"""Generate SVG art for home selection cards.

This script creates:
- assets/images/game_cards/*.svg
- assets/images/category_cards/*.svg
"""

from __future__ import annotations

from dataclasses import dataclass
from html import escape
from pathlib import Path


@dataclass(frozen=True)
class CardSpec:
    title: str
    subtitle: str
    tag: str
    start_color: str
    end_color: str
    accent_color: str


GAME_SPECS: dict[str, CardSpec] = {
    "imagen_palabra.svg": CardSpec(
        title="IMAGEN Y PALABRA",
        subtitle="UNE PALABRA CON SU IMAGEN",
        tag="EMPAREJAR",
        start_color="#1F9D8B",
        end_color="#2A73A7",
        accent_color="#FFFFFF",
    ),
    "escribir_palabra.svg": CardSpec(
        title="ESCRIBIR PALABRA",
        subtitle="COPIA, SEMICOPIA O DICTADO",
        tag="ESCRITURA",
        start_color="#F29F05",
        end_color="#E76F2D",
        accent_color="#FFF8E8",
    ),
    "palabra_palabra.svg": CardSpec(
        title="PALABRA CON PALABRA",
        subtitle="UNE PALABRAS IGUALES O RELACIONADAS",
        tag="RELACIONAR",
        start_color="#6E77E5",
        end_color="#5A4CCF",
        accent_color="#F2F2FF",
    ),
    "imagen_frase.svg": CardSpec(
        title="IMAGEN Y FRASE",
        subtitle="UNE CADA FRASE CON SU IMAGEN",
        tag="COMPRENSION",
        start_color="#00A5B5",
        end_color="#2A83C9",
        accent_color="#E9FDFF",
    ),
    "letra_objetivo.svg": CardSpec(
        title="LETRAS Y VOCALES",
        subtitle="ELIGE VOCAL FIJA O ALEATORIA",
        tag="LETRAS",
        start_color="#DA5E2A",
        end_color="#D63F5E",
        accent_color="#FFF0EA",
    ),
    "cambio_exacto.svg": CardSpec(
        title="TIENDA DE CHUCHES",
        subtitle="PAGA CON MONEDAS EL CAMBIO",
        tag="EUROS",
        start_color="#C74990",
        end_color="#9A4FCE",
        accent_color="#FFE8F5",
    ),
    "ruleta_letras.svg": CardSpec(
        title="RULETA DE LETRAS",
        subtitle="JUEGA POR INICIO, MEDIO O FINAL",
        tag="RULETA",
        start_color="#8E5CD7",
        end_color="#5E68DB",
        accent_color="#F4ECFF",
    ),
    "discriminacion.svg": CardSpec(
        title="DISCRIMINACION",
        subtitle="ELIGE LA OPCION CORRECTA",
        tag="ATENCION",
        start_color="#00996B",
        end_color="#0D7F9E",
        accent_color="#E7FFF5",
    ),
    "discriminacion_inversa.svg": CardSpec(
        title="DISCRIMINACION INVERSA",
        subtitle="ENCUENTRA LA OPCION INTRUSA",
        tag="INTRUSA",
        start_color="#B66A15",
        end_color="#D05336",
        accent_color="#FFF4E8",
    ),
}

CATEGORY_SPECS: dict[str, CardSpec] = {
    "mix_categorias.svg": CardSpec(
        title="MIX DE CATEGORIAS",
        subtitle="COMBINA TODO EL CONTENIDO",
        tag="MIX",
        start_color="#1A7D95",
        end_color="#2F9E8A",
        accent_color="#E9FEFA",
    ),
    "cosas_de_casa.svg": CardSpec(
        title="COSAS DE CASA",
        subtitle="OBJETOS Y RUTINAS DEL HOGAR",
        tag="HOGAR",
        start_color="#2F9E8A",
        end_color="#1F8A74",
        accent_color="#E8FFF8",
    ),
    "comida.svg": CardSpec(
        title="COMIDA",
        subtitle="ALIMENTOS Y HABITOS",
        tag="ALIMENTOS",
        start_color="#E8871E",
        end_color="#D05F2E",
        accent_color="#FFF3E6",
    ),
    "dinero.svg": CardSpec(
        title="DINERO",
        subtitle="COMPRAS, PRECIOS Y CAMBIO",
        tag="EURO",
        start_color="#3AA356",
        end_color="#208A62",
        accent_color="#E8FFE9",
    ),
    "bano.svg": CardSpec(
        title="BANO",
        subtitle="ASEO PERSONAL DIARIO",
        tag="HIGIENE",
        start_color="#3A8CE0",
        end_color="#2B71C8",
        accent_color="#E7F2FF",
    ),
    "profesiones.svg": CardSpec(
        title="PROFESIONES",
        subtitle="OFICIOS Y TRABAJOS",
        tag="OFICIOS",
        start_color="#8D62DA",
        end_color="#7752C7",
        accent_color="#EFE8FF",
    ),
    "salud.svg": CardSpec(
        title="SALUD",
        subtitle="CUIDADO Y BIENESTAR",
        tag="BIENESTAR",
        start_color="#E75B74",
        end_color="#D74362",
        accent_color="#FFE8EE",
    ),
    "emociones.svg": CardSpec(
        title="EMOCIONES",
        subtitle="SENTIR Y EXPRESAR",
        tag="EMOCION",
        start_color="#F2B705",
        end_color="#E1880A",
        accent_color="#FFF5DD",
    ),
    "animales.svg": CardSpec(
        title="ANIMALES",
        subtitle="NUEVO TEMA EN MODO MIX",
        tag="NATURALEZA",
        start_color="#2D8B6C",
        end_color="#1D6C88",
        accent_color="#E5FFF5",
    ),
    "colegio.svg": CardSpec(
        title="COLEGIO",
        subtitle="NUEVO TEMA EN MODO MIX",
        tag="AULA",
        start_color="#2F73D0",
        end_color="#4C56CA",
        accent_color="#E8F0FF",
    ),
    "transporte.svg": CardSpec(
        title="TRANSPORTE",
        subtitle="NUEVO TEMA EN MODO MIX",
        tag="RUTAS",
        start_color="#8250C9",
        end_color="#C2488C",
        accent_color="#F6EAFF",
    ),
}


def render_svg(spec: CardSpec) -> str:
    title = escape(spec.title)
    subtitle = escape(spec.subtitle)
    tag = escape(spec.tag)
    start = escape(spec.start_color)
    end = escape(spec.end_color)
    accent = escape(spec.accent_color)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 384" role="img" aria-label="{title}">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="{start}" />
      <stop offset="100%" stop-color="{end}" />
    </linearGradient>
    <linearGradient id="glass" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.34" />
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0.18" />
    </linearGradient>
    <filter id="softShadow" x="-20%" y="-20%" width="140%" height="160%">
      <feDropShadow dx="0" dy="12" stdDeviation="12" flood-color="#000000" flood-opacity="0.23" />
    </filter>
  </defs>
  <rect x="0" y="0" width="640" height="384" rx="36" fill="url(#bg)" />
  <circle cx="530" cy="-30" r="170" fill="#FFFFFF" fill-opacity="0.10" />
  <circle cx="-40" cy="300" r="180" fill="#FFFFFF" fill-opacity="0.08" />
  <circle cx="610" cy="345" r="120" fill="#FFFFFF" fill-opacity="0.11" />
  <rect x="44" y="42" width="552" height="300" rx="30" fill="url(#glass)" stroke="#FFFFFF" stroke-opacity="0.34" />
  <g filter="url(#softShadow)">
    <rect x="76" y="150" width="300" height="152" rx="24" fill="#FFFFFF" fill-opacity="0.18" stroke="#FFFFFF" stroke-opacity="0.52" />
  </g>
  <text x="78" y="104" font-family="Arial, Helvetica, sans-serif" font-size="31" font-weight="800" fill="#FFFFFF">{title}</text>
  <text x="78" y="134" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="{accent}">{subtitle}</text>
  <rect x="96" y="204" width="236" height="60" rx="999" fill="#FFFFFF" fill-opacity="0.90" />
  <text x="214" y="244" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="26" font-weight="800" fill="{end}">{tag}</text>
  <rect x="426" y="144" width="154" height="154" rx="32" fill="#FFFFFF" fill-opacity="0.88" />
  <path d="M470 196 L542 196 M470 224 L542 224 M470 252 L522 252" stroke="{start}" stroke-width="12" stroke-linecap="round" />
  <circle cx="456" cy="196" r="10" fill="{start}" />
  <circle cx="456" cy="224" r="10" fill="{start}" />
  <circle cx="456" cy="252" r="10" fill="{start}" />
</svg>
"""


def write_cards(base_dir: Path, specs: dict[str, CardSpec]) -> None:
    base_dir.mkdir(parents=True, exist_ok=True)
    for filename, spec in specs.items():
        path = base_dir / filename
        path.write_text(render_svg(spec), encoding="utf-8")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    write_cards(root / "assets" / "images" / "game_cards", GAME_SPECS)
    write_cards(root / "assets" / "images" / "category_cards", CATEGORY_SPECS)
    print(
        "Generated",
        len(GAME_SPECS),
        "game cards and",
        len(CATEGORY_SPECS),
        "category cards.",
    )


if __name__ == "__main__":
    main()

