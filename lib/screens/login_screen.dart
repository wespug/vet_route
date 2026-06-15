import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with LoggerMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // === FUNÇÃO DE PING-PONG (Mantida apenas para Dev, sem tradução) ===
  Future<void> _testePingPongFirebase() async {
    try {
      log.i("Disparando o PING para o Firebase...");
      final db = FirebaseFirestore.instance;

      final docRef = await db.collection("teste_conexao").add({
        "mensagem": "Ping do Vet Route!",
        "hora_do_teste": FieldValue.serverTimestamp(),
      });
      log.i("PING gravado com sucesso! ID gerado: ${docRef.id}");

      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        log.i("PONG recebido do Firebase! Dados: ${docSnapshot.data()}");
      }
    } catch (e) {
      log.e("Erro no Ping-Pong: $e");
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
    // Inicializa o dicionário
    final i18n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.appTitle),
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
                  decoration: InputDecoration(
                    labelText: i18n.email,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: i18n.password,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),

                // === BOTÃO ESQUECI A SENHA ===
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      log.i("Usuário clicou em 'Esqueci minha senha'");
                    },
                    child: Text(i18n.forgotPassword),
                  ),
                ),

                const SizedBox(height: 16),

                // === BOTÃO ENTRAR PRINCIPAL ===
                ElevatedButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    final senha = _passwordController.text.trim();

                    if (email.isEmpty || senha.isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(i18n.errorEmpty)));
                      return;
                    }

                    try {
                      log.i("Iniciando tentativa de login para: $email");
                      await AuthService().loginComEmailESenha(email, senha);
                    } catch (e) {
                      log.e("Falha na autenticação da View: $e");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${i18n.errorPrefix} ${e.toString().split(']').last}',
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
                  child: Text(
                    i18n.loginBtn,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // === BOTÃO DE CADASTRO ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(i18n.noAccount),
                    TextButton(
                      onPressed: () {
                        log.i("Navegando para tela de cadastro");
                      },
                      child: Text(
                        i18n.register,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ==========================================
                // ÁREA DE TESTES (APENAS DEV) - MANTIDA CHUMBADA
                // ==========================================
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
