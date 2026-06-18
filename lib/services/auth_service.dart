import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _log = Logger();

  // Canal em tempo real que avisa o app se o usuário está logado ou não
  Stream<User?> get usuarioStatus => _auth.authStateChanges();

  // Função robusta de Login
  Future<User?> loginComEmailESenha(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _log.i("Usuário autenticado com sucesso:> ${credential.user?.email}");
      return credential.user;
    } catch (e) {
      _log.e("Erro no processo de login: $e");
      rethrow;
    }
  }

  // Função de Logout (Sair do sistema)
  Future<void> logout() async {
    _log.i("Usuário solicitou desligamento do sistema.");
    await _auth.signOut();
  }
}
