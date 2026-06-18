// lib/models/perfil_usuario.dart

enum PerfilUsuario {
  administrador('Administrador'),
  clinica('Clínica'),
  laboratorio('Laboratório'),
  motoboy('Motoboy'),
  desconhecido('');

  // A string exata que está salva no Firebase
  final String firebaseValue;

  const PerfilUsuario(this.firebaseValue);

  // Mágica de Sênior: Um método para converter o que vem do banco direto para o Enum
  static PerfilUsuario fromString(String? valor) {
    return PerfilUsuario.values.firstWhere(
      (perfil) => perfil.firebaseValue == valor,
      orElse: () => PerfilUsuario.desconhecido,
    );
  }
}
