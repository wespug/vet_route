enum PerfilUsuario {
  administrador('administrador', 'Administrador'),
  clinica('clinica', 'Clínica'),
  laboratorio('laboratorio', 'Laboratório'),
  entregadores('entregadores', 'Entregadores'),
  desconhecido('', 'Desconhecido');

  // A string exata e limpa que será salva e consultada no Firebase
  final String firebaseValue;

  // A string formatada que aparecerá nos menus e telas do aplicativo
  final String nomeExibicao;

  const PerfilUsuario(this.firebaseValue, this.nomeExibicao);

  // 💡 AQUI ESTÁ A IMPLEMENTAÇÃO:
  // Agora qualquer parte do código que chamar .toFirestoreString vai receber o valor correto do banco!
  String get toFirestoreString => firebaseValue;

  static PerfilUsuario fromString(String? valor) {
    return PerfilUsuario.values.firstWhere(
      (perfil) => perfil.firebaseValue == valor,
      orElse: () => PerfilUsuario.desconhecido,
    );
  }
}
