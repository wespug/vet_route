import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
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
  bool _carregando = false; // Controle de loading no botão

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

                // === BOTÃO ENTRAR PRINCIPAL INTELIGENTE ===
                ElevatedButton(
                  onPressed: _carregando
                      ? null
                      : () async {
                          final email = _emailController.text.trim();
                          final senha = _passwordController.text.trim();

                          if (email.isEmpty || senha.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(i18n.errorEmpty)),
                            );
                            return;
                          }

                          setState(() => _carregando = true);

                          try {
                            log.i("Iniciando tentativa de login para: $email");

                            // 1. Autentica no Firebase Auth
                            UserCredential credential = await FirebaseAuth
                                .instance
                                .signInWithEmailAndPassword(
                                  email: email,
                                  password: senha,
                                );

                            if (credential.user == null)
                              throw Exception(
                                "Falha ao recuperar credenciais.",
                              );

                            // 2. Busca a ficha do usuário no Firestore
                            final docUser = await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(credential.user!.uid)
                                .get();
                            if (!docUser.exists) {
                              await AuthService().logout();
                              throw Exception(
                                "Registro de usuário não localizado no banco de dados.",
                              );
                            }

                            final userData = docUser.data();
                            if (userData?['ativo'] == false) {
                              await AuthService().logout();
                              throw Exception(
                                "Esta conta está desativada. Contate o suporte.",
                              );
                            }

                            final String perfilId = userData?['perfilId'] ?? '';

                            // 3. Busca os privilégios de plataforma no Perfil
                            final docPerfil = await FirebaseFirestore.instance
                                .collection('perfis')
                                .doc(perfilId)
                                .get();
                            if (!docPerfil.exists) {
                              await AuthService().logout();
                              throw Exception(
                                "Perfil de acesso associado a esta conta não existe.",
                              );
                            }

                            final perfilData = docPerfil.data();
                            final bool visivelWeb =
                                perfilData?['visivelWeb'] ?? false;
                            final bool visivelApp =
                                perfilData?['visivelApp'] ?? false;

                            if (!mounted) return;
                            FocusScope.of(context).unfocus();

                            // ============================================================
                            // 🖥️ TRIAGEM DE DIRECIONAMENTO SE ESTIVER NO NAVEGADOR (WEB)
                            // ============================================================
                            if (kIsWeb) {
                              if (visivelWeb) {
                                log.i(
                                  "Acesso Web Autorizado. Inicializando permissões...",
                                );
                                await permissoesGlobais.inicializarParaUsuario(
                                  perfilId,
                                );

                                if (!mounted) return;
                                // Encaminha para o Chassi Genérico de Menus (Padrão SaaS)
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/admin',
                                );
                              } else {
                                await AuthService().logout();
                                throw Exception(
                                  "Acesso Negado. Seu perfil não tem permissão para usar a versão Web.",
                                );
                              }
                            }
                            // ============================================================
                            // 📱 TRIAGEM DE DIRECIONAMENTO SE ESTIVER NO CELULAR (MOBILE)
                            // ============================================================
                            else {
                              if (visivelApp) {
                                final nomePerfil = (perfilData?['nome'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                log.i(
                                  "Acesso Mobile Autorizado. Roteando para visão nativa...",
                                );

                                if (nomePerfil.contains('clínica') ||
                                    nomePerfil.contains('clinica')) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/clinica',
                                  );
                                } else if (nomePerfil.contains('laboratório') ||
                                    nomePerfil.contains('laboratorio')) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/laboratorio',
                                  );
                                } else if (nomePerfil.contains('motoboy') ||
                                    nomePerfil.contains('entregador')) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/motoboy',
                                  );
                                } else {
                                  // Fallback para gestores acessando o celular
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Scaffold(
                                        appBar: AppBar(
                                          title: const Text(
                                            'Painel Gerencial Mobile',
                                          ),
                                          backgroundColor:
                                              Colors.blueGrey.shade900,
                                        ),
                                        body: const Center(
                                          child: Text(
                                            "Visão Mobile Gerencial em Desenvolvimento 🚧",
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                await AuthService().logout();
                                throw Exception(
                                  "Acesso Negado. Seu perfil está restrito para a versão Web de computador.",
                                );
                              }
                            }
                          } catch (e) {
                            log.e("Falha na autenticação da View: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${i18n.errorPrefix} ${e.toString().replaceAll("Exception: ", "")}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _carregando = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _carregando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
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

                // MANTIDO INTACTO A SEU PEDIDO 🛡️
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    ActionChip(
                      label: const Text(
                        'Super Admin',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.teal.shade100,
                      onPressed: () =>
                          _preencherTeste('super@admin.com', '12345678'),
                    ),
                    ActionChip(
                      label: const Text(
                        'Admin',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.teal.shade100,
                      onPressed: () =>
                          _preencherTeste('adm@admin.com', '12345678'),
                    ),
                    ActionChip(
                      label: const Text(
                        'Clinica',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.green.shade100,
                      onPressed: () =>
                          _preencherTeste('clinica@gmail.com', '12345678'),
                    ),
                    ActionChip(
                      label: const Text(
                        'Entregadores',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.indigo.shade100,
                      onPressed: () =>
                          _preencherTeste('entregadores@gmail.com', '12345678'),
                    ),
                    ActionChip(
                      label: const Text(
                        'Laboratório',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.orange.shade100,
                      onPressed: () =>
                          _preencherTeste('laboratorio@gmail.com', '12345678'),
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
