import 'package:flutter/material.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';

import '../controllers/clinica_controller.dart';
import '../services/auth_service.dart'; // <-- IMPORTANTE: Adicionado para o Logout

class ClinicaScreen extends StatefulWidget {
  const ClinicaScreen({super.key});

  @override
  State<ClinicaScreen> createState() => _ClinicaScreenState();
}

class _ClinicaScreenState extends State<ClinicaScreen> {
  final ClinicaController _controller = ClinicaController(
    FirestoreColetaRepository(),
  );

  @override
  void initState() {
    super.initState();
    _controller.inicializarPainel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller.clinicaAtual,
        _controller.labDestino,
        _controller.isLoading,
      ]),
      builder: (context, _) {
        final clinica = _controller.clinicaAtual.value;
        final isLoading = _controller.isLoading.value;

        if (clinica == null) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(clinica.nome),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          // === NOVO: MENU LATERAL (DRAWER) ===
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: colorScheme.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.local_hospital,
                        color: colorScheme.onPrimary,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        clinica.nome,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Perfil: Clínica',
                        style: TextStyle(
                          color: colorScheme.onPrimary.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.history, color: colorScheme.primary),
                  title: const Text('Histórico de Coletas'),
                  onTap: () {
                    // Futura tela de histórico
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings, color: colorScheme.primary),
                  title: const Text('Configurações'),
                  onTap: () {
                    // Futura tela de configurações
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.exit_to_app,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Sair do Aplicativo',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    // Aciona o logout. O main.dart ouve isso e redireciona sozinho!
                    AuthService().logout();
                  },
                ),
              ],
            ),
          ),
          // ===================================
          body: Column(
            children: [
              // Botões de Ação
              Container(
                padding: const EdgeInsets.all(16),
                color: colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                        ),
                        onPressed: isLoading
                            ? null
                            : () => _controller.solicitarMotoboy(),
                        icon: Icon(
                          Icons.flash_on,
                          color: colorScheme.onPrimary,
                        ),
                        label: Text(
                          isLoading ? i18n.sending : i18n.immediate,
                          style: TextStyle(color: colorScheme.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Center(child: Text(i18n.clinicTrackingTitle))),
            ],
          ),
        );
      },
    );
  }
}
