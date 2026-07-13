import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/screens/web/mobile_chassi.dart';
import 'package:vet_route/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with LoggerMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _carregando = false;

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
        log.i("PONG recebido! O Firebase está a responder perfeitamente.");
      }
    } catch (e) {
      log.e("Erro de conexão no Ping-Pong: $e");
    }
  }

  void _preencherTeste(String email, String senha) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = senha;
    });
    _fazerLogin();
  }

  Future<void> _fazerLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o e-mail e a senha!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      String? nomePerfil = await AuthService().loginComEmailESenha(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (nomePerfil != null) {
        if (kIsWeb) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // 📱 Navega para o Mobile Chassi
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MobileChassi()),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pets, size: 64, color: Colors.indigo),
                const SizedBox(height: 24),
                const Text(
                  'Acesso Vet Route',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _carregando ? null : _fazerLogin,
                    child: _carregando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    ActionChip(
                      label: const Text(
                        'Admin Web',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.teal.shade100,
                      onPressed: () =>
                          _preencherTeste('super@admin.com', '12345678'),
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
                        'Atendente',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.indigo.shade100,
                      onPressed: () =>
                          _preencherTeste('atendente1@gmail.com', '12345678'),
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
