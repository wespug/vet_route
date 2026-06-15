import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';
import 'package:vet_route/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with LoggerMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // === FUNÇÃO DE PING-PONG ===
  Future<void> _testePingPongFirebase() async {
    try {
      log.i("Disparando o PING para o Firebase...");
      final db = FirebaseFirestore.instance;

      // PING: Gravando um documento no banco
      final docRef = await db.collection("teste_conexao").add({
        "mensagem": "Ping do Vet Route!",
        "hora_do_teste":
            FieldValue.serverTimestamp(), // Pega a hora exata do servidor
      });
      log.i("PING gravado com sucesso! ID gerado: ${docRef.id}");

      // PONG: Lendo o documento que acabamos de gravar
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        log.i("PONG recebido do Firebase! Dados: ${docSnapshot.data()}");
      }
    } catch (e) {
      log.e(
        "Erro no Ping-Pong: $e",
      ); // Se der erro de permissão ou conexão, o logger avisa!
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso Vet Route'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pets, size: 80, color: Colors.green),
                const SizedBox(height: 32),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),

                // === BOTÃO ESQUECI A SENHA ===
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      log.i("Usuário clicou em 'Esqueci minha senha'");
                      // Aqui você pode navegar para a tela de recuperação no futuro:
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => const RecuperarSenhaScreen()));
                    },
                    child: const Text('Esqueci minha senha'),
                  ),
                ),

                const SizedBox(height: 16),

                // ... dentro do seu ElevatedButton de entrar na LoginScreen:
                ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    final senha = _passwordController.text.trim();

                    if (email.isEmpty || senha.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, preencha todos os campos.'),
                        ),
                      );
                      return;
                    }

                    try {
                      log.i("Iniciando tentativa de login para: $email");

                      // Chama o serviço robusto que criamos
                      await AuthService().loginComEmailESenha(email, senha);

                      // ATENÇÃO: Não precisa dar Navigator.push aqui!
                      // O StreamBuilder no main.dart vai perceber o login e mudar a tela sozinho!
                    } catch (e) {
                      log.e("Falha na autenticação da View: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Falha ao entrar: ${e.toString().split(']').last}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'ENTRAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),

                // === BOTÃO DE CADASTRO ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Não tem uma conta?'),
                    TextButton(
                      onPressed: () {
                        log.i("Navegando para tela de cadastro");
                        // Navigator.push(context, MaterialPageRoute(builder: (context) => const CadastroScreen()));
                      },
                      child: const Text(
                        'Cadastre-se',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                // === BOTÃO TEMPORÁRIO DE TESTE PING-PONG ===
                ElevatedButton.icon(
                  onPressed: _testePingPongFirebase,
                  icon: const Icon(Icons.sync_alt, color: Colors.white),
                  label: const Text('TESTE PING-PONG FIREBASE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blueAccent, // Azul para destacar que é um teste
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
