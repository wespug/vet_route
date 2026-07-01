class SubmenuItemModel {
  final String id;
  final String menuId; // Referência ao Menu Pai
  final String titulo;
  final String icone;
  final String rota;
  final bool isWeb;
  final bool isMobile;
  final int peso; // 💡 NOVO: Campo para ordenação

  SubmenuItemModel({
    required this.id,
    required this.menuId,
    required this.titulo,
    required this.icone,
    required this.rota,
    this.isWeb = true,
    this.isMobile = false,
    this.peso = 99, // 💡 Fallback de segurança joga pro final da lista
  });

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'titulo': titulo,
      'icone': icone,
      'rota': rota,
      'isWeb': isWeb,
      'isMobile': isMobile,
      'peso': peso, // 💡 Persistindo no Firestore
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
      peso: data['peso'] ?? 99, // 💡 Lendo do Firestore
    );
  }
}
