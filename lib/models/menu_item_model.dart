class MenuItemModel {
  final String id;
  final String titulo;
  final String icone; // 💡 String que mapeia para o IconData real
  final String rota; // 💡 Identificador para sabermos qual widget instanciar

  MenuItemModel({
    required this.id,
    required this.titulo,
    required this.icone,
    required this.rota,
  });

  Map<String, dynamic> toMap() {
    return {'titulo': titulo, 'icone': icone, 'rota': rota};
  }

  factory MenuItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MenuItemModel(
      id: id,
      titulo: data['titulo'] ?? '',
      icone: data['icone'] ?? 'widgets_outlined',
      rota: data['rota'] ?? '',
    );
  }
}
