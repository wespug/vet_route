import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import '../../controllers/clinica_admin_controller.dart';
import '../../models/clinica_model.dart';
import '../../models/endereco_model.dart';

class ClinicaGestaoWeb extends StatefulWidget {
  const ClinicaGestaoWeb({super.key});

  @override
  State<ClinicaGestaoWeb> createState() => _ClinicaGestaoWebState();
}

class _ClinicaGestaoWebState extends State<ClinicaGestaoWeb> {
  final ClinicaAdminController _controller = ClinicaAdminController();

  final TextEditingController nomeEC = TextEditingController();
  final TextEditingController emailEC = TextEditingController();
  final TextEditingController telefoneEC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.ouvirClinicas();
  }

  @override
  void dispose() {
    nomeEC.dispose();
    emailEC.dispose();
    telefoneEC.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _salvar() async {
    if (nomeEC.text.isEmpty || emailEC.text.isEmpty) return;

    // 💡 Ajuste os parâmetros aqui caso o seu Entregador() exija campos diferentes (ex: CNH, CPF)
    final novaClinica = Clinica(
      nome: nomeEC.text,
      email: emailEC.text,
      telefone: telefoneEC.text,
      cnpj: '00.000.000/0000-00', // 💡 Parâmetro obrigatório agora presente
      endereco: Endereco(
        logradouro: 'A definir',
        numero: 'S/N',
        bairro: 'A definir',
        cidade: 'A definir',
        estado: 'SP',
        cep: '00000-000',
      ),
    );

    final sucesso = await _controller.salvarClinica(novaClinica);
    if (sucesso && mounted) {
      nomeEC.clear();
      emailEC.clear();
      telefoneEC.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Clínica salva com sucesso!'),
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
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
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Text(
                i18n.clinics ?? 'Gestão de Clínicas',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 500,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTextField(nomeEC, 'Nome da Clínica'),
                    const SizedBox(height: 16),
                    _buildTextField(emailEC, 'E-mail'),
                    const SizedBox(height: 16),
                    _buildTextField(telefoneEC, 'Telefone'),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                        ),
                        onPressed: _salvar,
                        child: const Text(
                          'SALVAR CLÍNICA',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 500,
                child: ValueListenableBuilder<List<Clinica>>(
                  valueListenable: _controller.clinicas,
                  builder: (context, lista, child) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lista.length,
                      itemBuilder: (context, index) {
                        final clinica = lista[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.local_hospital,
                              color: Colors.blue.shade700,
                            ),
                            title: Text(clinica.nome),
                            subtitle: Text(clinica.email),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _controller.deletarClinica(clinica.id!),
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
