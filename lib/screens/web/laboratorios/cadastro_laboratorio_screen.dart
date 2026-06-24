import 'package:flutter/material.dart';
import 'package:vet_route/controllers/laboratorio_admin_controller.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/endereco_model.dart'; // 💡 Importante para o Endereço!

class CadastroLaboratorioScreen extends StatefulWidget {
  const CadastroLaboratorioScreen({Key? key}) : super(key: key);

  @override
  State<CadastroLaboratorioScreen> createState() =>
      _CadastroLaboratorioScreenState();
}

class _CadastroLaboratorioScreenState extends State<CadastroLaboratorioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores dos campos de texto
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cnpjController = TextEditingController();

  final LaboratorioAdminController _controller = LaboratorioAdminController();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cnpjController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    // Só prossegue se todos os campos obrigatórios estiverem preenchidos
    if (_formKey.currentState!.validate()) {
      // 1. Montamos o objeto (Ajuste os campos conforme o seu LaboratorioModel real)
      final novoLab = Laboratorio(
        id: '', // Deixe vazio ou null para o Firestore gerar o ID automático
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim(),
        cnpj: _cnpjController.text.trim(),
        endereco: Endereco(
          logradouro: 'A definir',
          numero: 'S/N',
          bairro: 'A definir',
          cidade: 'A definir',
          estado: 'A definir',
          cep: '00000-000',
        ),
      );

      // 2. Enviamos para o Firestore via Controller
      final sucesso = await _controller.salvarLaboratorio(novoLab);

      // 3. Feedback visual e navegação
      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laboratório cadastrado com sucesso!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Fecha a tela e volta para a lista
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao cadastrar laboratório. Tente novamente.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Cadastrar Novo Laboratório"),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            // Impede que o formulário fique gigante em monitores largos
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.science, size: 28, color: Colors.teal),
                          SizedBox(width: 12),
                          Text(
                            "Dados do Laboratório",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // NOME
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: "Nome do Laboratório",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'O nome é obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // E-MAIL
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "E-mail Corporativo",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? 'Insira um e-mail válido'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // TELEFONE E CNPJ (Lado a lado se tiver espaço, ou empilhados)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _telefoneController,
                              decoration: const InputDecoration(
                                labelText: "Telefone",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _cnpjController,
                              decoration: const InputDecoration(
                                labelText: "CNPJ",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // BOTÃO SALVAR REATIVO
                      ValueListenableBuilder<bool>(
                        valueListenable: _controller.isLoading,
                        builder: (context, isLoading, child) {
                          return SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal, // Cor de destaque
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: isLoading ? null : _salvar,
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "SALVAR LABORATÓRIO",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
