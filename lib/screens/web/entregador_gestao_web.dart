import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import '../../controllers/entregador_admin_controller.dart';
import '../../models/entregador_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Para o LatLng inicial, se o seu modelo exigir

class EntregadorGestaoWeb extends StatefulWidget {
  const EntregadorGestaoWeb({super.key});

  @override
  State<EntregadorGestaoWeb> createState() => _EntregadorGestaoWebState();
}

class _EntregadorGestaoWebState extends State<EntregadorGestaoWeb> {
  final EntregadorAdminController _controller = EntregadorAdminController();

  // Controladores do formulário
  final TextEditingController nomeEC = TextEditingController();
  final TextEditingController emailEC = TextEditingController();
  final TextEditingController telefoneEC = TextEditingController();
  final TextEditingController veiculoEC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.ouvirEntregadores();
  }

  @override
  void dispose() {
    nomeEC.dispose();
    emailEC.dispose();
    telefoneEC.dispose();
    veiculoEC.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _salvar() async {
    if (nomeEC.text.isEmpty || emailEC.text.isEmpty) return;

    // 💡 Ajuste os parâmetros aqui caso o seu Entregador() exija campos diferentes (ex: CNH, CPF)

    final novoEntregador = Entregador(
      nome: nomeEC.text,
      email: emailEC.text,
      telefone: telefoneEC.text,
      veiculo: veiculoEC.text.isEmpty ? 'Não informado' : veiculoEC.text,
    );

    final sucesso = await _controller.salvarEntregador(novoEntregador);
    if (sucesso && mounted) {
      nomeEC.clear();
      emailEC.clear();
      telefoneEC.clear();
      veiculoEC.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Motoboy salvo com sucesso!'),
          backgroundColor:
              Colors.orange.shade700, // 🎨 Identidade visual do entregador
        ),
      );
    }
  }

  // Widget auxiliar para manter o padrão visual dos inputs
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
          borderSide: BorderSide(
            color: Colors.orange.shade600,
            width: 2,
          ), // 🎨 Cor Laranja no foco
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
      backgroundColor: const Color(0xFFF4F6F9), // Fundo padrão AdminLTE
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 💡 Título Superior
              Text(
                i18n.couriers ?? 'Gestão de Motoboys',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // 📦 CARD DO FORMULÁRIO
              Container(
                width: 500,
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
                      'Painel Vet Route - Cadastro de Motoboy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange.shade700, // 🎨 Título na cor tema
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      nomeEC,
                      i18n.nameLabel ?? 'Nome Completo do Motoboy',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(emailEC, i18n.email ?? 'E-mail'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      telefoneEC,
                      i18n.phone ?? 'Telefone (WhatsApp)',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      veiculoEC,
                      'Veículo (Modelo e Placa)',
                    ), // Pode adicionar no i18n depois
                    const SizedBox(height: 24),

                    // 🔘 BOTÃO DE SALVAR
                    ValueListenableBuilder<bool>(
                      valueListenable: _controller.isLoading,
                      builder: (context, isLoading, child) {
                        return SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.orange.shade600, // 🎨 Botão Laranja
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
                                    (i18n.saveBtn ?? 'SALVAR MOTOBOY')
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

              // 📋 LISTA DE MOTOBOYS CADASTRADOS
              SizedBox(
                width: 500,
                child: ValueListenableBuilder<List<Entregador>>(
                  valueListenable: _controller
                      .entregadores, // Verifique se a variável chama "entregadores" no AdminController
                  builder: (context, lista, child) {
                    if (lista.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum motoboy cadastrado ainda.', // Pode jogar no i18n depois
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lista.length,
                      itemBuilder: (context, index) {
                        final entregador = lista[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade50,
                              child: Icon(
                                Icons.motorcycle,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            title: Text(
                              entregador.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${entregador.telefone}\nVeículo: ${entregador.veiculo}',
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                if (entregador.id != null) {
                                  _controller.deletarEntregador(entregador.id!);
                                }
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
