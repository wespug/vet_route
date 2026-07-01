class MenuItemModel {
  final String id;
  final String titulo;
  final String icone;
  final String rota;
  final bool isWeb;
  final bool isMobile;
  final int peso; // 💡 Novo: Define a ordem de exibição

  MenuItemModel({
    required this.id,
    required this.titulo,
    required this.icone,
    required this.rota,
    this.isWeb = true,
    this.isMobile = false,
    this.peso =
        99, // 💡 Padrão: 99 (joga para o fim da lista se não houver peso)
  });

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'icone': icone,
      'rota': rota,
      'isWeb': isWeb,
      'isMobile': isMobile,
      'peso': peso, // 💡 Persistindo no Firestore
    };
  }

  factory MenuItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MenuItemModel(
      id: id,
      titulo: data['titulo'] ?? '',
      icone: data['icone'] ?? 'widgets_outlined',
      rota: data['rota'] ?? '',
      isWeb: data['isWeb'] ?? true,
      isMobile: data['isMobile'] ?? false,
      peso: data['peso'] ?? 99, // 💡 Lendo do Firestore (fallback de segurança)
    );
  }
}
