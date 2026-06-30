class MenuItemModel {
  final String id;
  final String titulo;
  final String icone;
  final String rota;
  final bool isWeb; // 💡 Novo: Aparece na Web?
  final bool isMobile; // 💡 Novo: Aparece na App Mobile?

  MenuItemModel({
    required this.id,
    required this.titulo,
    required this.icone,
    required this.rota,
    this.isWeb = true, // Por defeito, assume Web
    this.isMobile = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'icone': icone,
      'rota': rota,
      'isWeb': isWeb,
      'isMobile': isMobile,
    };
  }

  factory MenuItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MenuItemModel(
      id: id,
      titulo: data['titulo'] ?? '',
      icone: data['icone'] ?? 'widgets_outlined',
      rota: data['rota'] ?? '',
      isWeb: data['isWeb'] ?? true, // Fallback de segurança
      isMobile: data['isMobile'] ?? false,
    );
  }
}
