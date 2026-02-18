enum ActivityType {
  imagenPalabra,
  escribirPalabra,
  palabraPalabra,
  imagenFrase,
}

extension ActivityTypeX on ActivityType {
  String get key => switch (this) {
    ActivityType.imagenPalabra => 'IMAGEN_PALABRA',
    ActivityType.escribirPalabra => 'ESCRIBIR_PALABRA',
    ActivityType.palabraPalabra => 'PALABRA_PALABRA',
    ActivityType.imagenFrase => 'IMAGEN_FRASE',
  };

  String get label => switch (this) {
    ActivityType.imagenPalabra => 'RELACIONAR IMÁGENES CON PALABRAS',
    ActivityType.escribirPalabra => 'IMAGEN CON PALABRA PARA ESCRIBIRLA',
    ActivityType.palabraPalabra => 'RELACIONAR PALABRAS CON PALABRAS',
    ActivityType.imagenFrase => 'RELACIONAR FRASES CON IMÁGENES',
  };

  static ActivityType fromKey(String key) {
    final normalized = key.trim().toUpperCase();
    return ActivityType.values.firstWhere(
      (type) => type.key == normalized,
      orElse: () => ActivityType.imagenPalabra,
    );
  }
}
