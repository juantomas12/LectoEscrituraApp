enum ActivityType {
  imagenPalabra,
  escribirPalabra,
  palabraPalabra,
  imagenFrase,
  sonidos,
  letraObjetivo,
  cambioExacto,
  ruletaLetras,
  discriminacion,
  discriminacionInversa,
  eligePalabra,
  verdaderoFalso,
  palabraIncompleta,
  letraInicial,
  letraFinal,
  cuentaSilabas,
  primeraSilaba,
  ultimaSilaba,
  ordenaLetras,
  ordenaFrase,
}

extension ActivityTypeX on ActivityType {
  String get key => switch (this) {
    ActivityType.imagenPalabra => 'IMAGEN_PALABRA',
    ActivityType.escribirPalabra => 'ESCRIBIR_PALABRA',
    ActivityType.palabraPalabra => 'PALABRA_PALABRA',
    ActivityType.imagenFrase => 'IMAGEN_FRASE',
    ActivityType.sonidos => 'SONIDOS',
    ActivityType.letraObjetivo => 'LETRA_OBJETIVO',
    ActivityType.cambioExacto => 'CAMBIO_EXACTO',
    ActivityType.ruletaLetras => 'RULETA_LETRAS',
    ActivityType.discriminacion => 'DISCRIMINACION',
    ActivityType.discriminacionInversa => 'DISCRIMINACION_INVERSA',
    ActivityType.eligePalabra => 'ELIGE_PALABRA',
    ActivityType.verdaderoFalso => 'VERDADERO_FALSO',
    ActivityType.palabraIncompleta => 'PALABRA_INCOMPLETA',
    ActivityType.letraInicial => 'LETRA_INICIAL',
    ActivityType.letraFinal => 'LETRA_FINAL',
    ActivityType.cuentaSilabas => 'CUENTA_SILABAS',
    ActivityType.primeraSilaba => 'PRIMERA_SILABA',
    ActivityType.ultimaSilaba => 'ULTIMA_SILABA',
    ActivityType.ordenaLetras => 'ORDENA_LETRAS',
    ActivityType.ordenaFrase => 'ORDENA_FRASE',
  };

  String get label => switch (this) {
    ActivityType.imagenPalabra => 'RELACIONAR IMÁGENES CON PALABRAS',
    ActivityType.escribirPalabra => 'IMAGEN CON PALABRA PARA ESCRIBIRLA',
    ActivityType.palabraPalabra => 'RELACIONAR PALABRAS CON PALABRAS',
    ActivityType.imagenFrase => 'RELACIONAR FRASES CON IMÁGENES',
    ActivityType.sonidos => 'RELACIONAR SONIDOS CON IMÁGENES',
    ActivityType.letraObjetivo => 'LETRA OBJETIVO CON PALABRAS E IMÁGENES',
    ActivityType.cambioExacto => 'LA TIENDA DE CHUCHES: CAMBIO EXACTO',
    ActivityType.ruletaLetras => 'RULETA DE LETRAS Y VOCALES',
    ActivityType.discriminacion => 'DISCRIMINACIÓN VISUAL',
    ActivityType.discriminacionInversa => 'DISCRIMINACIÓN INVERSA',
    ActivityType.eligePalabra => 'ELIGE LA PALABRA CORRECTA',
    ActivityType.verdaderoFalso => 'VERDADERO O FALSO',
    ActivityType.palabraIncompleta => 'PALABRA INCOMPLETA',
    ActivityType.letraInicial => 'LETRA INICIAL',
    ActivityType.letraFinal => 'LETRA FINAL',
    ActivityType.cuentaSilabas => 'CUENTA SÍLABAS',
    ActivityType.primeraSilaba => 'PRIMERA SÍLABA',
    ActivityType.ultimaSilaba => 'ÚLTIMA SÍLABA',
    ActivityType.ordenaLetras => 'ORDENA LETRAS',
    ActivityType.ordenaFrase => 'ORDENA FRASE',
  };

  static ActivityType fromKey(String key) {
    final normalized = key.trim().toUpperCase();
    return ActivityType.values.firstWhere(
      (type) => type.key == normalized,
      orElse: () => ActivityType.imagenPalabra,
    );
  }
}
