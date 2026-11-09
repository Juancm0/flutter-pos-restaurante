/// Secciones del negocio
enum Section {
  combi('Combi', 'Área de comida'),
  bar('Bar', 'Área de bebidas');

  const Section(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Crear desde string
  static Section fromString(String value) {
    switch (value.toLowerCase()) {
      case 'combi':
        return Section.combi;
      case 'bar':
        return Section.bar;
      default:
        throw ArgumentError('Invalid section: $value');
    }
  }

  /// Convertir a string para Firestore
  String toFirestore() => name;
}
