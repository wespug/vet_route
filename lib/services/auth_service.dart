import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Adicionado para buscar dados
  final Logger _log = Logger();

  // Canal em tempo real que avisa o app se o usuário está logado ou não
  Stream<User?> get usuarioStatus => _auth.authStateChanges();

  // MÁGICA 1: Função robusta que agora retorna o NOME do Perfil!
  Future<String?> loginComEmailESenha(String email, String password) async {
    try {
      // 1. Faz o login seguro no Firebase Auth
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user == null) throw Exception("Usuário não encontrado após login.");

      _log.i("Autenticação Auth concluída UID:> ${user.uid}");

      // 2. Busca o documento desse usuário lá no banco de dados (Firestore)
      DocumentSnapshot docUsuario = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!docUsuario.exists) {
        await logout(); // Desloga por segurança se não existir no banco
        throw Exception("Este e-mail não possui um perfil no banco de dados.");
      }

      Map<String, dynamic> dadosUsuario =
          docUsuario.data() as Map<String, dynamic>;

      // Proteção extra: Conta está ativa?
      if (dadosUsuario['ativo'] == false) {
        await logout();
        throw Exception("Esta conta está desativada. Contate o suporte.");
      }

      String perfilId = dadosUsuario['perfilId'] ?? '';
      if (perfilId.isEmpty) {
        throw Exception("Usuário sem perfil de acesso definido.");
      }

      // 3. Vai na tabela de perfis e descobre qual é o NOME do cargo!
      DocumentSnapshot docPerfil = await _firestore
          .collection('perfis')
          .doc(perfilId)
          .get();

      if (!docPerfil.exists) {
        throw Exception("O cargo vinculado a esta conta não existe mais.");
      }

      Map<String, dynamic> dadosPerfil =
          docPerfil.data() as Map<String, dynamic>;
      String nomePerfil = dadosPerfil['nome'] ?? 'Desconhecido';

      _log.i("Sucesso Absoluto! O usuário logado é um(a): $nomePerfil");

      return nomePerfil; // Retorna "Admin", "Clínica", "Motoboy"...
    } on FirebaseAuthException catch (e) {
      _log.e("Erro Auth: ${e.code}");
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        throw Exception("E-mail ou senha incorretos.");
      }
      throw Exception(e.message ?? "Erro de segurança ao fazer login.");
    } catch (e) {
      _log.e("Erro interno no processo de login: $e");
      rethrow;
    }
  }

  // Função de Logout (Sair do sistema)
  Future<void> logout() async {
    _log.i("Usuário solicitou desligamento do sistema.");
    await _auth.signOut();
  }
}
