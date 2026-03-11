#!/usr/bin/env python3
"""Genera audios offline y actualiza audioAsset en el dataset.

Uso rápido:
  python3 tools/sync_offline_audio.py
  python3 tools/sync_offline_audio.py --dry-run
  python3 tools/sync_offline_audio.py --overwrite --only-words GRIFO DUCHA
"""

from __future__ import annotations

import argparse
import json
import math
import random
import re
import struct
import unicodedata
import wave
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATASET = ROOT / "assets/data/lectoescritura_dataset.json"
DEFAULT_AUDIO_DIR = ROOT / "assets/audio"
SAMPLE_RATE = 22_050


def normalize(text: str) -> str:
    decomposed = unicodedata.normalize("NFD", text.upper().strip())
    return "".join(char for char in decomposed if unicodedata.category(char) != "Mn")


def clamp(sample: float) -> float:
    return max(-1.0, min(1.0, sample))


def envelope(index: int, total: int, attack: float = 0.04, release: float = 0.18) -> float:
    if total <= 0:
        return 0.0
    attack_samples = max(1, int(total * attack))
    release_samples = max(1, int(total * release))
    if index < attack_samples:
        return index / attack_samples
    if index >= total - release_samples:
        remaining = total - index
        return max(0.0, remaining / release_samples)
    return 1.0


def sine_wave(freq: float, t: float) -> float:
    return math.sin(2.0 * math.pi * freq * t)


def triangle_wave(freq: float, t: float) -> float:
    phase = (t * freq) % 1.0
    return 4.0 * abs(phase - 0.5) - 1.0


def smooth_noise(rng: random.Random, duration: float, *, gain: float, smooth: float) -> list[float]:
    total = max(1, int(SAMPLE_RATE * duration))
    value = 0.0
    samples: list[float] = []
    for index in range(total):
        value = value * smooth + rng.uniform(-1.0, 1.0) * (1.0 - smooth)
        samples.append(clamp(value * gain * envelope(index, total)))
    return samples


def mix_tracks(*tracks: list[float]) -> list[float]:
    length = max((len(track) for track in tracks), default=0)
    mixed = [0.0] * length
    for track in tracks:
        for index, sample in enumerate(track):
            mixed[index] += sample
    peak = max((abs(sample) for sample in mixed), default=1.0)
    scale = 0.92 / peak if peak > 0.92 else 1.0
    return [clamp(sample * scale) for sample in mixed]


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for sample in samples:
            pcm = int(clamp(sample) * 32767.0)
            frames.extend(struct.pack("<h", pcm))
        wav_file.writeframes(frames)


def generate_water_like(rng: random.Random, duration: float, *, pressure: float) -> list[float]:
    total = max(1, int(SAMPLE_RATE * duration))
    last_a = 0.0
    last_b = 0.0
    samples: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        white = rng.uniform(-1.0, 1.0)
        last_a = last_a * 0.84 + white * 0.16
        last_b = last_b * 0.96 + white * 0.04
        shimmer = 0.60 + 0.22 * math.sin(2.0 * math.pi * 4.8 * t)
        shimmer += 0.10 * math.sin(2.0 * math.pi * 7.3 * t)
        stream = (last_a * 0.72 + last_b * 0.28) * shimmer
        sample = stream * pressure * envelope(index, total, attack=0.02, release=0.12)
        samples.append(clamp(sample))
    return samples


def generate_grifo(rng: random.Random) -> list[float]:
    return generate_water_like(rng, 1.55, pressure=0.42)


def generate_ducha(rng: random.Random) -> list[float]:
    base = generate_water_like(rng, 1.9, pressure=0.48)
    splash = smooth_noise(rng, 1.9, gain=0.16, smooth=0.72)
    return mix_tracks(base, splash)


def generate_manguera(rng: random.Random) -> list[float]:
    water = generate_water_like(rng, 1.8, pressure=0.54)
    pulse = [
        clamp(
            sample
            * (0.86 + 0.14 * math.sin(2.0 * math.pi * 1.7 * index / SAMPLE_RATE))
        )
        for index, sample in enumerate(water)
    ]
    return pulse


def generate_timbre(_: random.Random) -> list[float]:
    notes = [
        (880.0, 0.18),
        (659.0, 0.18),
        (880.0, 0.18),
        (659.0, 0.28),
    ]
    samples: list[float] = []
    for freq, duration in notes:
        total = int(SAMPLE_RATE * duration)
        for index in range(total):
            t = index / SAMPLE_RATE
            tone = sine_wave(freq, t) * 0.54 + sine_wave(freq * 2, t) * 0.14
            samples.append(clamp(tone * envelope(index, total, attack=0.01, release=0.35)))
        silence = [0.0] * int(SAMPLE_RATE * 0.04)
        samples.extend(silence)
    return samples


def generate_secador(rng: random.Random) -> list[float]:
    total = int(SAMPLE_RATE * 1.65)
    samples: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        white = rng.uniform(-1.0, 1.0) * 0.18
        hum = sine_wave(98.0, t) * 0.18 + sine_wave(196.0, t) * 0.08
        fan = triangle_wave(34.0, t) * 0.05
        sample = (white + hum + fan) * envelope(index, total, attack=0.02, release=0.10)
        samples.append(clamp(sample))
    return samples


def generate_secadora(rng: random.Random) -> list[float]:
    total = int(SAMPLE_RATE * 1.9)
    samples: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        white = rng.uniform(-1.0, 1.0) * 0.10
        rumble = sine_wave(64.0, t) * 0.24 + sine_wave(128.0, t) * 0.07
        drum = max(0.0, triangle_wave(1.35, t)) * 0.10
        samples.append(clamp((white + rumble + drum) * envelope(index, total, 0.03, 0.12)))
    return samples


def generate_lavadora(rng: random.Random) -> list[float]:
    total = int(SAMPLE_RATE * 2.1)
    samples: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        hum = sine_wave(56.0, t) * 0.20 + sine_wave(112.0, t) * 0.10
        wobble = sine_wave(3.4, t) * 0.06
        clicks = (1.0 if int(t * 5.0) % 5 == 0 and (t * 5.0) % 1.0 < 0.03 else 0.0) * 0.08
        noise = rng.uniform(-1.0, 1.0) * 0.04
        samples.append(clamp((hum + wobble + clicks + noise) * envelope(index, total, 0.03, 0.12)))
    return samples


def generate_perro(rng: random.Random) -> list[float]:
    samples: list[float] = []
    bark_lengths = [0.18, 0.12, 0.22]
    for bark_index, duration in enumerate(bark_lengths):
        total = int(SAMPLE_RATE * duration)
        for index in range(total):
            t = index / SAMPLE_RATE
            sweep = 210.0 - (75.0 * (index / max(1, total - 1)))
            tone = sine_wave(sweep, t) * 0.30 + rng.uniform(-1.0, 1.0) * 0.12
            burst = 1.0 + 0.18 * bark_index
            samples.append(clamp(tone * burst * envelope(index, total, 0.02, 0.40)))
        samples.extend([0.0] * int(SAMPLE_RATE * 0.08))
    return samples


def generate_gato(_: random.Random) -> list[float]:
    duration = 1.25
    total = int(SAMPLE_RATE * duration)
    samples: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        progress = index / max(1, total - 1)
        freq = 720.0 - (progress * 310.0)
        tone = sine_wave(freq, t) * 0.34 + sine_wave(freq * 2, t) * 0.10
        vibrato = 1.0 + 0.03 * sine_wave(5.0, t)
        samples.append(clamp(tone * vibrato * envelope(index, total, 0.06, 0.30)))
    return samples


def generate_vaca(_: random.Random) -> list[float]:
    duration = 1.8
    total = int(SAMPLE_RATE * duration)
    samples: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        progress = index / max(1, total - 1)
        freq = 165.0 - (progress * 42.0)
        tone = sine_wave(freq, t) * 0.40 + sine_wave(freq * 0.5, t) * 0.12
        samples.append(clamp(tone * envelope(index, total, 0.05, 0.22)))
    return samples


def generate_gallo(_: random.Random) -> list[float]:
    samples: list[float] = []
    phrases = [(690.0, 0.12), (820.0, 0.12), (1040.0, 0.18), (720.0, 0.22)]
    for freq, duration in phrases:
        total = int(SAMPLE_RATE * duration)
        for index in range(total):
            t = index / SAMPLE_RATE
            tone = sine_wave(freq, t) * 0.28 + sine_wave(freq * 2.02, t) * 0.08
            samples.append(clamp(tone * envelope(index, total, 0.02, 0.35)))
        samples.extend([0.0] * int(SAMPLE_RATE * 0.03))
    return samples


Generator = Callable[[random.Random], list[float]]

SOUND_GENERATORS: dict[str, tuple[str, Generator]] = {
    "GRIFO": ("grifo_agua.wav", generate_grifo),
    "DUCHA": ("ducha_agua.wav", generate_ducha),
    "MANGUERA": ("manguera_agua.wav", generate_manguera),
    "TIMBRE": ("timbre_casa.wav", generate_timbre),
    "SECADOR": ("secador_aire.wav", generate_secador),
    "SECADORA": ("secadora_tambor.wav", generate_secadora),
    "LAVADORA": ("lavadora_ciclo.wav", generate_lavadora),
    "PERRO": ("perro_ladrido.wav", generate_perro),
    "GATO": ("gato_maullido.wav", generate_gato),
    "VACA": ("vaca_mugido.wav", generate_vaca),
    "GALLO": ("gallo_canto.wav", generate_gallo),
}


def phrase_tokens(item: dict) -> list[str]:
    tokens: list[str] = []
    for key in ("word",):
        value = item.get(key)
        if isinstance(value, str) and value.strip():
            tokens.append(value)
    for value in item.get("words", []) or []:
        if isinstance(value, str) and value.strip():
            tokens.append(value)
    for value in item.get("relatedWords", []) or []:
        if isinstance(value, str) and value.strip():
            tokens.append(value)
    for phrase in item.get("phrases", []) or []:
        if not isinstance(phrase, str):
            continue
        tokens.extend(re.findall(r"[A-ZÁÉÍÓÚÑ]+", phrase.upper()))
    return tokens


def find_sound_key(item: dict, allowed: set[str] | None) -> str | None:
    for token in phrase_tokens(item):
        normalized = normalize(token)
        if allowed is not None and normalized not in allowed:
            continue
        if normalized in SOUND_GENERATORS:
            return normalized
    return None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", type=Path, default=DEFAULT_DATASET)
    parser.add_argument("--audio-dir", type=Path, default=DEFAULT_AUDIO_DIR)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--only-words", nargs="*", default=[])
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    dataset_path: Path = args.dataset.resolve()
    audio_dir: Path = args.audio_dir.resolve()
    with dataset_path.open("r", encoding="utf-8") as handle:
        payload = json.load(handle)

    items = payload.get("items", [])
    if not isinstance(items, list):
        raise SystemExit("El dataset no contiene una lista válida en 'items'.")

    allowed = {normalize(word) for word in args.only_words if word.strip()} or None
    generated_files: set[Path] = set()
    updated_items = 0

    for item in items:
        if not isinstance(item, dict):
            continue
        sound_key = find_sound_key(item, allowed)
        if sound_key is None:
            continue

        filename, generator = SOUND_GENERATORS[sound_key]
        output_path = audio_dir / filename
        asset_path = output_path.relative_to(ROOT).as_posix()

        if args.overwrite or not output_path.exists():
            seed = sum(ord(char) for char in sound_key)
            samples = generator(random.Random(seed))
            if not args.dry_run:
                write_wav(output_path, samples)
            generated_files.add(output_path)

        if item.get("audioAsset") != asset_path:
            item["audioAsset"] = asset_path
            updated_items += 1

    if not args.dry_run:
        with dataset_path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")

    print(f"Items con audio asignado: {updated_items}")
    print(f"Archivos generados: {len(generated_files)}")
    if generated_files:
        for path in sorted(generated_files):
            print(f" - {path.relative_to(ROOT).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
