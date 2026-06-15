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

  // === FUNÇÃO AUXILIAR PARA DEV ===
  void _preencherTeste(String email, String senha) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = senha;
    });
    log.i("Credenciais de teste preenchidas para: $email");
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
                    },
                    child: const Text('Esqueci minha senha'),
                  ),
                ),

                const SizedBox(height: 16),

                // === BOTÃO ENTRAR PRINCIPAL ===
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
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // === ÁREA DE TESTES (APENAS DEV) ===
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Preenchimento Rápido (Testes):',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    ActionChip(
                      label: const Text(
                        'Admin',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.teal.shade100,
                      onPressed: () =>
                          _preencherTeste('admin@vetroute.com', '123456'),
                    ),
                    ActionChip(
                      label: const Text(
                        'Clínica',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.green.shade100,
                      onPressed: () =>
                          _preencherTeste('clinica@vetroute.com', '123456'),
                    ),
                    ActionChip(
                      label: const Text(
                        'Laboratório',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.indigo.shade100,
                      onPressed: () =>
                          _preencherTeste('lab@vetroute.com', '123456'),
                    ),
                    ActionChip(
                      label: const Text(
                        'Motoboy',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.orange.shade100,
                      onPressed: () =>
                          _preencherTeste('motoboy@vetroute.com', '123456'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
