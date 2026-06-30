class SubmenuItemModel {
  final String id;
  final String menuId; // 💡 Chave estrangeira ligando ao Menu pai
  final String titulo;

  SubmenuItemModel({
    required this.id,
    required this.menuId,
    required this.titulo,
  });

  Map<String, dynamic> toMap() {
    return {'menuId': menuId, 'titulo': titulo};
  }

  factory SubmenuItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SubmenuItemModel(
      id: id,
      menuId: data['menuId'] ?? '',
      titulo: data['titulo'] ?? '',
    );
  }
}
