# APP DE LECTOESCRITURA (FLUTTER, OFFLINE)

APP EDUCATIVA DE LECTOESCRITURA PARA PRIMARIA Y SECUNDARIA, CON NIVELACIÓN PROGRESIVA, TODO EL TEXTO VISIBLE EN MAYÚSCULAS Y DATASET LOCAL SIN INTERNET.

## ARQUITECTURA

- PATRÓN: `MVVM`
- ESTADO: `RIVERPOD`
- PERSISTENCIA LOCAL: `HIVE`
- DATASET: `JSON` EN `assets/data/lectoescritura_dataset.json`
- IMÁGENES: `SVG` LOCALES EN `assets/images/`
- AUDIO: `TTS LOCAL` (PLUGIN `flutter_tts`)

## MÓDULOS IMPLEMENTADOS

- NIVEL 1:
  - RELACIONAR IMÁGENES CON PALABRAS
  - IMAGEN CON PALABRA PARA ESCRIBIR (COPIA / SEMICOPIA / DICTADO)
- NIVEL 2:
  - RELACIONAR PALABRAS CON PALABRAS (MODOS IGUALES / RELACIONADAS)
- NIVEL 3:
  - RELACIONAR FRASES CON IMÁGENES

## ACCESIBILIDAD

- MODO ALTO CONTRASTE
- MODO DISLEXIA (SIMILAR: ESPACIADO Y LEGIBILIDAD)
- TOLERANCIA DE ACENTOS CONFIGURABLE
- AUDIO OPCIONAL
- BOTONES GRANDES Y FEEDBACK VISUAL/TEXTUAL (NO SOLO COLOR)

## CONTENIDO INICIAL

CATEGORÍAS:
- COSAS DE CASA
- COMIDA
- DINERO
- BAÑO
- PROFESIONES
- SALUD
- EMOCIONES

CONTEOS CARGADOS:
- NIVEL 1: 12 ÍTEMS POR CATEGORÍA
- NIVEL 2: 8 PARES POR CATEGORÍA
- NIVEL 3: 6 ÍTEMS (2 FRASES C/U) POR CATEGORÍA

NOTA: CON 7 CATEGORÍAS, NIVEL 1 QUEDA EN 84 PALABRAS TOTALES.

## EJECUCIÓN

```bash
flutter pub get
flutter run
```

## CÓMO AÑADIR NUEVOS ÍTEMS (SIN TOCAR CÓDIGO)

1. AÑADE O EDITA OBJETOS EN `assets/data/lectoescritura_dataset.json`.
2. EJECUTA EL SYNC AUTOMÁTICO DE IMÁGENES:
```bash
python3 tools/sync_offline_images.py
```
3. EL SCRIPT BUSCA IMÁGENES, LAS DESCARGA EN `assets/images/<categoria>/` Y ACTUALIZA `imageAsset` EN EL JSON.
4. PARA DICTADO, PUEDES USAR:
   - `ttsText` (TTS LOCAL), O
   - `audioAsset` SI AÑADES AUDIO EN `assets/audio/`.
5. REINICIA LA APP.

### BÚSQUEDA RECOMENDADA EN PEXELS (MÁS CALIDAD)

EL SCRIPT SOPORTA `PEXELS` (STOCK FOTOGRÁFICO) COMO PRIMERA OPCIÓN PARA OBJETOS REALES.

1. CREA UNA API KEY EN PEXELS.
2. EXPORTA VARIABLE:
```bash
export PEXELS_API_KEY=\"TU_API_KEY\"
```
3. EJECUTA:
```bash
python3 tools/sync_offline_images.py --providers pexels,openverse,wikimedia
```

SI NO HAY API KEY, EL SCRIPT SALTA PEXELS Y USA LAS SIGUIENTES FUENTES.

### BÚSQUEDA EN GOOGLE (API OFICIAL)

EL SCRIPT SOPORTA GOOGLE CUSTOM SEARCH (IMÁGENES) PARA BUSCAR CADA NUEVO ÍTEM.

1. CREA CREDENCIALES EN GOOGLE CSE.
2. EXPORTA VARIABLES DE ENTORNO:
```bash
export GOOGLE_CSE_API_KEY=\"TU_API_KEY\"
export GOOGLE_CSE_CX=\"TU_CX\"
```
3. EJECUTA:
```bash
python3 tools/sync_offline_images.py --providers google_cse,wikimedia
```

SI GOOGLE NO ESTÁ CONFIGURADO, EL SCRIPT USA OPENVERSE/WIKIMEDIA COMO RESPALDO.

### OPCIONES ÚTILES DEL SCRIPT

```bash
# SOLO UN ÍTEM
python3 tools/sync_offline_images.py --item-id CDC_N1_01

# REVISIÓN MANUAL DE CALIDAD (ELIGES LA MEJOR IMAGEN)
python3 tools/sync_offline_images.py --interactive --item-id CDC_N1_01

# DETECCIÓN AUTOMÁTICA DE IMÁGENES MALAS (PORTADAS/TEXTO/LUGARES)
python3 tools/sync_offline_images.py --auto-retry-candidates 10

# REEMPLAZAR TAMBIÉN PLACEHOLDERS SVG
python3 tools/sync_offline_images.py --replace-svg

# MODO PRUEBA (SIN GUARDAR)
python3 tools/sync_offline_images.py --dry-run
```

EL REGISTRO DE FUENTE/LICENCIA SE GUARDA EN `assets/data/image_sources.json`.

## CAMBIAR IMÁGENES DESDE LA APP (SIN EDITAR JSON)

1. ENTRA EN `AJUSTES`.
2. ABRE `EDITAR IMÁGENES DE ÍTEMS`.
3. BUSCA EL ÍTEM (POR EJEMPLO `SILLA` O `CDC_N1_02`).
4. PULSA `CAMBIAR` Y SELECCIONA OTRA IMAGEN LOCAL.
5. SE GUARDA EN LOCAL (HIVE) Y QUEDA PERSISTENTE.

SI QUIERES VOLVER AL VALOR DEL DATASET, USA `RESTAURAR`.

### ESQUEMA DE CADA ÍTEM JSON

```json
{
  "id": "CDC_N1_01",
  "category": "COSAS DE CASA",
  "level": 1,
  "activityType": "IMAGEN_PALABRA",
  "word": "MESA",
  "words": ["MESA"],
  "imageAsset": "assets/images/cosas_de_casa/cdc_n1_01.svg",
  "phrases": [],
  "audioAsset": null,
  "ttsText": "MESA",
  "relatedWords": []
}
```

## ARCHIVOS CLAVE

- `lib/main.dart`
- `lib/application/providers/app_providers.dart`
- `lib/domain/models/`
- `lib/data/repositories/`
- `lib/presentation/screens/`
- `assets/data/lectoescritura_dataset.json`
- `tools/sync_offline_images.py`
- `assets/data/image_sources.json`
