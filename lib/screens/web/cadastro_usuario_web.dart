import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vet_route/controllers/core/logger_mixin.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/models/usuario_model.dart';
import 'package:vet_route/screens/web/admin_chassi.dart';

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

  // ATENÇÃO: Estes são os valores do BANCO DE DADOS, não devem ser traduzidos diretamente.
  String _perfilSelecionado = 'Veterinário';
  final List<String> _perfisDisponiveis = [
    'Veterinário',
    'Administrador',
    'Motoboy',
    'Clínica',
    'Laboratório',
  ];

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
        perfilId: _perfilSelecionado,
        vinculoId: null, // Por enquanto não vinculamos a nenhuma empresa
      );

      // 3. Salva no Firestore usando o método toFirestore() da Model
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(novoUsuario.id)
          .set(novoUsuario.toMap());

      log.i("Usuário ${novoUsuario.email} registrado usando UsuarioModel!");

      if (mounted) {
        // Pega as traduções para os alertas
        final i18n = AppLocalizations.of(context)!;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(i18n.regSuccess),
            backgroundColor: Colors.green,
          ),
        );
        _limparCampos();
      }
    } catch (e) {
      log.e("Erro ao cadastrar usuário na Web: $e");
      if (mounted) {
        final i18n = AppLocalizations.of(context)!;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${i18n.regError} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _limparCampos() {
    _nomeController.clear();
    _emailController.clear();
    _senhaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Inicializando o dicionário na tela
    final i18n = AppLocalizations.of(context)!;

    return AdminChassi(
      titulo: i18n.regTitle,
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
                    Text(
                      i18n.regHeader,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campo Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: i18n.nameLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? i18n.nameError : null,
                    ),
                    const SizedBox(height: 16),

                    // Campo Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: i18n.email,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? i18n.emailError : null,
                    ),
                    const SizedBox(height: 16),

                    // Campo Senha
                    TextFormField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: i18n.password,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? i18n.passwordError : null,
                    ),
                    const SizedBox(height: 16),

                    // Seletor de Tipo de Usuário (Perfil)
                    DropdownButtonFormField<String>(
                      initialValue: _perfilSelecionado,
                      decoration: InputDecoration(
                        labelText: i18n.profileLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: _perfisDisponiveis.map((String perfil) {
                        return DropdownMenuItem<String>(
                          value:
                              perfil, // O valor real no banco continua sendo em Português
                          child: Text(
                            perfil,
                          ), // DICA: No futuro, podemos criar uma função que traduz apenas a visualização desta string!
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
                          : Text(
                              i18n.saveBtn,
                              style: const TextStyle(
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
