# APP DE LECTOESCRITURA (FLUTTER, OFFLINE)

## REGLA DE TRABAJO PARA EL ASISTENTE

ANTES DE EMPEZAR CUALQUIER TAREA EN ESTE PROYECTO, EL ASISTENTE DEBE LEER ESTE `README.md` COMPLETO.

ANTES DE EJECUTAR CUALQUIER SCRIPT O CAMBIO, EL ASISTENTE DEBE ENVIAR PRIMERO ESTE RESUMEN:

1. QUÉ SE VA A CAMBIAR.
2. CÓMO SE VA A HACER (PLAN/PASOS).
3. QUÉ NO SE VA A MODIFICAR EN ESTE CAMBIO.
4. CONFIRMACIÓN DE QUE PRIMERO SE EXPLICAN LOS PASOS Y DESPUÉS SE EJECUTA.

AL TERMINAR CADA CAMBIO, EL ASISTENTE DEBE HACER ESTE CIERRE OBLIGATORIO:

1. REVISAR ERRORES (`./tools/check_build_deploy.sh` EJECUTA `ANALYZE` + `TEST`).
2. SI NO HAY ERRORES, COMPILAR WEB PARA `/lectorEscrituraapp/`.
3. DESPLEGAR EN `https://iaprende.itacaflow.com/lectorEscrituraapp/`.
4. HACER `git add` DE LOS ARCHIVOS DEL CAMBIO, `git commit` Y `git push` A GITHUB.

AL RECIBIR CUALQUIER PROMPT DEL USUARIO, EL ASISTENTE DEBE RESPONDER Y OPERAR CON ESTE PROCESO:

PROCESO:
1. DEVUÉLVEME UN PLAN DE 4-6 PASOS.
2. EJECUTA CAMBIOS PASO A PASO.
3. TRAS CADA PASO, VALIDA CON: `pnpm test` Y `pnpm lint` (SI FALLA, ARRÉGLALO ANTES DE SEGUIR).

## TRADUCCIONES (NUEVA REGLA)

DESDE AHORA, LA FUENTE DE VERDAD DE TRADUCCIONES ES `JSON`.

ARCHIVOS BASE:
- `assets/i18n/es.json` (ESPAÑOL BASE)
- `assets/i18n/en.json` (INGLÉS)
- `assets/i18n/fr.json` (FRANCÉS)

GENERACIÓN:
```bash
python3 tools/generate_l10n_from_json.py
./flutter-local gen-l10n
```

SALIDA GENERADA:
- `lib/l10n/app_es.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_localizations*.dart`

REGLAS OBLIGATORIAS:
1. CUALQUIER NUEVA CLAVE SE AÑADE PRIMERO EN `es.json`.
2. ESA MISMA CLAVE DEBE EXISTIR EN `en.json` Y `fr.json`.
3. SI FALTAN CLAVES ENTRE IDIOMAS, EL SCRIPT FALLA.
4. NO EDITAR `*.arb` A MANO: SE REGENERAN DESDE `JSON`.
5. LAS CLAVES EN JSON PUEDEN USAR `.` (EJ: `home.title`) Y EL SCRIPT LAS CONVIERTE A `camelCase` PARA `ARB`.

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
# Recomendado: usa el wrapper del repo (Flutter local en .tools/flutter)
./flutter-local pub get
./flutter-local devices
./flutter-local run -d chrome

# Alternativa: usa el flutter del sistema
# flutter pub get
# flutter run
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
# COMPRESIÓN AUTOMÁTICA SI LA IMAGEN SUPERA 1MB (ACTIVO POR DEFECTO)
python3 tools/sync_offline_images.py --auto-compress-over-mb 1

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

# DESACTIVAR COMPRESIÓN AUTOMÁTICA
python3 tools/sync_offline_images.py --auto-compress-over-mb 0
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
