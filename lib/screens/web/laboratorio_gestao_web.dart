import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import '../../controllers/laboratorio_admin_controller.dart';
import '../../models/laboratorio_model.dart';
import '../../models/endereco_model.dart';

class LaboratorioGestaoWeb extends StatefulWidget {
  const LaboratorioGestaoWeb({super.key});

  @override
  State<LaboratorioGestaoWeb> createState() => _LaboratorioGestaoWebState();
}

class _LaboratorioGestaoWebState extends State<LaboratorioGestaoWeb> {
  final LaboratorioAdminController _controller = LaboratorioAdminController();

  // Controladores do formulário
  final TextEditingController nomeEC = TextEditingController();
  final TextEditingController emailEC = TextEditingController();
  final TextEditingController telefoneEC = TextEditingController();
  final TextEditingController cnpjEC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.ouvirLaboratorios();
  }

  @override
  void dispose() {
    nomeEC.dispose();
    emailEC.dispose();
    telefoneEC.dispose();
    cnpjEC.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _salvar() async {
    if (nomeEC.text.isEmpty || emailEC.text.isEmpty) return;

    final novoLab = Laboratorio(
      nome: nomeEC.text,
      email: emailEC.text,
      telefone: telefoneEC.text,
      cnpj: cnpjEC.text.isEmpty ? '00.000.000/0000-00' : cnpjEC.text,
      endereco: Endereco(
        logradouro: 'A definir',
        numero: 'S/N',
        bairro: 'A definir',
        cidade: 'A definir',
        estado: 'SP',
        cep: '00000-000',
      ),
    );

    final sucesso = await _controller.salvarLaboratorio(novoLab);
    if (sucesso && mounted) {
      // Limpa os campos após salvar
      nomeEC.clear();
      emailEC.clear();
      telefoneEC.clear();
      cnpjEC.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Laboratório salvo com sucesso!'),
          backgroundColor: Colors.teal.shade600,
        ),
      );
    }
  }

  // 💡 Widget auxiliar para deixar o código limpo e igual ao seu print
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;

    return Scaffold(
      // 🎨 Cor de fundo igual a do seu print
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 💡 Título Superior
              Text(
                i18n.labManagement ?? 'Gestão de Laboratórios',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // 📦 CARD DO FORMULÁRIO (Clone do seu Print)
              Container(
                width: 500, // Largura fixa para ficar bonito no centro da tela
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Painel Vet Route - Cadastro de Laboratório',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.teal.shade600,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      nomeEC,
                      i18n.labName ?? 'Nome Completo do Laboratório',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(emailEC, i18n.email ?? 'E-mail'),
                    const SizedBox(height: 16),
                    _buildTextField(telefoneEC, i18n.phone ?? 'Telefone'),
                    const SizedBox(height: 16),
                    _buildTextField(cnpjEC, 'CNPJ'),
                    const SizedBox(height: 24),

                    // 🔘 BOTÃO DE SALVAR
                    ValueListenableBuilder<bool>(
                      valueListenable: _controller.isLoading,
                      builder: (context, isLoading, child) {
                        return SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: isLoading ? null : _salvar,
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    (i18n.saveBtn ?? 'SALVAR LABORATÓRIO')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // 📋 LISTA DE LABORATÓRIOS SALVOS LOGO ABAIXO
              SizedBox(
                width: 500,
                child: ValueListenableBuilder<List<Laboratorio>>(
                  valueListenable: _controller.laboratorios,
                  builder: (context, lista, child) {
                    if (lista.isEmpty) {
                      return Center(
                        child: Text(
                          i18n.noLabsRegistered ??
                              'Nenhum laboratório cadastrado ainda.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap:
                          true, // Necessário dentro de SingleChildScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // Evita scroll duplo
                      itemCount: lista.length,
                      itemBuilder: (context, index) {
                        final lab = lista[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade50,
                              child: Icon(
                                Icons.science,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            title: Text(
                              lab.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${lab.email}\nCNPJ: ${lab.cnpj}'),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                if (lab.id != null)
                                  _controller.deletarLaboratorio(lab.id!);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
