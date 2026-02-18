enum AppCategory {
  cosasDeCasa,
  comida,
  dinero,
  bano,
  profesiones,
  salud,
  emociones,
}

typedef Category = AppCategory;

extension AppCategoryX on AppCategory {
  String get id => switch (this) {
    AppCategory.cosasDeCasa => 'COSAS_DE_CASA',
    AppCategory.comida => 'COMIDA',
    AppCategory.dinero => 'DINERO',
    AppCategory.bano => 'BAÑO',
    AppCategory.profesiones => 'PROFESIONES',
    AppCategory.salud => 'SALUD',
    AppCategory.emociones => 'EMOCIONES',
  };

  String get label => switch (this) {
    AppCategory.cosasDeCasa => 'COSAS DE CASA',
    AppCategory.comida => 'COMIDA',
    AppCategory.dinero => 'DINERO',
    AppCategory.bano => 'BAÑO',
    AppCategory.profesiones => 'PROFESIONES',
    AppCategory.salud => 'SALUD',
    AppCategory.emociones => 'EMOCIONES',
  };

  static AppCategory fromLabel(String raw) {
    final normalized = raw.trim().toUpperCase();
    return AppCategory.values.firstWhere(
      (category) =>
          category.label.toUpperCase() == normalized ||
          category.id.toUpperCase() == normalized,
      orElse: () => AppCategory.cosasDeCasa,
    );
  }
}
