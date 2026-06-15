import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';
import 'package:vet_route/models/usuario_model.dart';
import 'package:vet_route/screens/Web/admin_chassi.dart';

class CadastroUsuarioWeb extends StatefulWidget {
  const CadastroUsuarioWeb({super.key});

  @override
  State<CadastroUsuarioWeb> createState() => _CadastroUsuarioWebState();
}

class _CadastroUsuarioWebState extends State<CadastroUsuarioWeb>
    with LoggerMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  String _perfilSelecionado = 'Veterinário';
  bool _carregando = false;

  Future<void> _cadastrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    log.i("Iniciando cadastro Web para o perfil: $_perfilSelecionado");

    try {
      // 1. Cria o usuário no Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text.trim(),
          );

      // 2. Instancia a nossa Model organizada
      final novoUsuario = UsuarioModel(
        id: userCredential.user!.uid,
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        perfil:
            _perfilSelecionado, // Certifique-se de que bate com: 'Administrador', 'Clínica', 'Laboratório' ou 'Motoboy'
        vinculoId: null, // Por enquanto não vinculamos a nenhuma empresa
      );

      // 3. Salva no Firestore usando o método toFirestore() da Model
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(novoUsuario.id)
          .set(novoUsuario.toFirestore());

      log.i("Usuário ${novoUsuario.email} registrado usando UsuarioModel!");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        _limparCampos();
      }
    } catch (e) {
      log.e("Erro ao cadastrar usuário na Web: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _limparCampos() {
    _nomeController.clear();
    _emailController.clear();
    _senhaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AdminChassi(
      titulo: 'Cadastro de Usuários',
      conteudo: Center(
        child: Container(
          width: 500, // Largura ideal fixa para formulários Web Desktop
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Painel Vet Route - Cadastro de Usuário',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campo Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Digite o nome' : null,
                    ),
                    const SizedBox(height: 16),

                    // Campo Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail de Acesso',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Digite o e-mail' : null,
                    ),
                    const SizedBox(height: 16),

                    // Campo Senha
                    TextFormField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha Inicial',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.length < 6
                          ? 'A senha deve ter no mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Seletor de Tipo de Usuário (Perfil)
                    DropdownButtonFormField<String>(
                      value: _perfilSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Perfil',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Veterinário', 'Administrador', 'Motoboy'].map((
                        String perfil,
                      ) {
                        return DropdownMenuItem<String>(
                          value: perfil,
                          child: Text(perfil),
                        );
                      }).toList(),
                      onChanged: (novo) =>
                          setState(() => _perfilSelecionado = novo!),
                    ),
                    const SizedBox(height: 32),

                    // Botão Salvar
                    ElevatedButton(
                      onPressed: _carregando ? null : _cadastrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: _carregando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SALVAR USUÁRIO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
