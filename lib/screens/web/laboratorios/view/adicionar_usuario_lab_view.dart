import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/laboratorio_admin_controller.dart';
import 'package:vet_route/controllers/perfil_controller.dart';
import 'package:vet_route/models/laboratorio_model.dart';

class AdicionarUsuarioLabView extends StatefulWidget {
  final Laboratorio?
  labContexto; // 💡 RECEBE O CONTEXTO SELECIONADO NA UX MESTRE-DETALHE

  const AdicionarUsuarioLabView({super.key, this.labContexto});

  @override
  State<AdicionarUsuarioLabView> createState() =>
      _AdicionarUsuarioLabViewState();
}

class _AdicionarUsuarioLabViewState extends State<AdicionarUsuarioLabView> {
  final _formKey = GlobalKey<FormState>();

  final LaboratorioAdminController _labController =
      LaboratorioAdminController();
  final PerfilController _perfilController = PerfilController();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  String? _idLaboratorioSelecionado;
  String? _idPerfilSelecionado;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _labController.ouvirLaboratorios();
    _perfilController.carregarPerfis();

    // 💡 UX Inteligente: Se já houver um laboratório selecionado no Hub, trava ele aqui!
    if (widget.labContexto != null) {
      _idLaboratorioSelecionado = widget.labContexto!.id;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _labController.dispose();
    _perfilController.dispose();
    super.dispose();
  }

  Future<void> _executarCadastroSaaS() async {
    if (!_formKey.currentState!.validate() ||
        _idLaboratorioSelecionado == null ||
        _idPerfilSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, preencha todos os campos e seleções."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final email = _emailController.text.trim();
      final senha = _senhaController.text.trim();
      final nome = _nomeController.text.trim();

      FirebaseApp appSecundario = await Firebase.initializeApp(
        name: 'CriadorUsuariosAdmin',
        options: Firebase.app().options,
      );

      UserCredential credencial = await FirebaseAuth.instanceFor(
        app: appSecundario,
      ).createUserWithEmailAndPassword(email: email, password: senha);

      final novoUid = credencial.user!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(novoUid).set({
        'nome': nome,
        'email': email,
        'perfilId': _idPerfilSelecionado,
        'vinculoId':
            _idLaboratorioSelecionado, // Amarrado com o ID do laboratório sob gestão!
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      });

      await appSecundario.delete();

      if (mounted) {
        _nomeController.clear();
        _emailController.clear();
        _senhaController.clear();
        setState(() {
          if (widget.labContexto == null) _idLaboratorioSelecionado = null;
          _idPerfilSelecionado = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Operador cadastrado e vinculado com sucesso! 🚀"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Falha ao registrar: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 💡 CORRIGIDO AQUI: De 'declareFinalBlock' para 'finally'
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Credenciamento Operacional 👤",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.labContexto != null
                    ? "Cadastrando operador exclusivo para o laboratório ${widget.labContexto!.nome}."
                    : "Cadastre operadores e vincule-os a um laboratório específico.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: "Nome Completo do Operador",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "E-mail de Login",
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Senha Provisória",
                        prefixIcon: Icon(Icons.lock_open_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  // VÍNCULO MULTI-TENANT (Fica travado e desativado caso venha do Hub do Lab!)
                  Expanded(
                    child: ValueListenableBuilder<List<Laboratorio>>(
                      valueListenable: _labController.laboratorios,
                      builder: (context, listaLabs, child) {
                        return DropdownButtonFormField<String>(
                          value: _idLaboratorioSelecionado,
                          decoration: const InputDecoration(
                            labelText: "Vincular ao Laboratório",
                            prefixIcon: Icon(Icons.business_rounded),
                          ),
                          // Se já estamos dentro de um lab, o administrador não pode alterar o drop!
                          onChanged: widget.labContexto != null
                              ? null
                              : (val) => setState(
                                  () => _idLaboratorioSelecionado = val,
                                ),
                          items: listaLabs.map((lab) {
                            return DropdownMenuItem<String>(
                              value: lab.id,
                              child: Text(lab.nome),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 24),

                  Expanded(
                    child: ListenableBuilder(
                      listenable: _perfilController,
                      builder: (context, child) {
                        return DropdownButtonFormField<String>(
                          value: _idPerfilSelecionado,
                          decoration: const InputDecoration(
                            labelText: "Perfil de Permissões (Web/Mobile)",
                            prefixIcon: Icon(Icons.gpp_good_outlined),
                          ),
                          items: _perfilController.perfis.map((perfil) {
                            return DropdownMenuItem<String>(
                              value: perfil.id,
                              child: Text(perfil.nome),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _idPerfilSelecionado = val),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: 280,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _executarCadastroSaaS,
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.how_to_reg_rounded),
                  label: Text(
                    _salvando ? "Processando..." : "Cadastrar e Vincular",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
