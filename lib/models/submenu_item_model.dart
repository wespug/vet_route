class SubmenuItemModel {
  final String id;
  final String menuId; // Chave do Menu Pai
  final String titulo;
  final String icone; // 💡 Novo
  final String rota; // 💡 Novo
  final bool isWeb; // 💡 Novo
  final bool isMobile; // 💡 Novo

  SubmenuItemModel({
    required this.id,
    required this.menuId,
    required this.titulo,
    required this.icone,
    required this.rota,
    this.isWeb = true,
    this.isMobile = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'titulo': titulo,
      'icone': icone,
      'rota': rota,
      'isWeb': isWeb,
      'isMobile': isMobile,
    };
  }

  factory SubmenuItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SubmenuItemModel(
      id: id,
      menuId: data['menuId'] ?? '',
      titulo: data['titulo'] ?? '',
      icone: data['icone'] ?? 'subdirectory_arrow_right',
      rota: data['rota'] ?? '',
      isWeb: data['isWeb'] ?? true,
      isMobile: data['isMobile'] ?? false,
    );
  }
}
