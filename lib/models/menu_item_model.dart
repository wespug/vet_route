class MenuItemModel {
  final String id;
  final String titulo;

  MenuItemModel({required this.id, required this.titulo});

  Map<String, dynamic> toMap() {
    return {'titulo': titulo};
  }

  factory MenuItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MenuItemModel(id: id, titulo: data['titulo'] ?? '');
  }
}
