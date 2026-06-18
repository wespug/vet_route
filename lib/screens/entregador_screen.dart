import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';
import '../controllers/entregador_controller.dart';
import '../services/auth_service.dart';

class EntregadorScreen extends StatefulWidget {
  const EntregadorScreen({super.key});

  @override
  State<EntregadorScreen> createState() => _EntregadorScreenState();
}

class _EntregadorScreenState extends State<EntregadorScreen> {
  // Inicialização do controller com o repositório real
  final EntregadorController _controller = EntregadorController(
    FirestoreColetaRepository(),
  );

  @override
  void initState() {
    super.initState();
    // Você precisará acessar o tema aqui. Como não podemos usar 'context'
    // direto no initState, uma forma elegante é usar o addPostFrameCallback:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cs = Theme.of(context).colorScheme;
      _controller.inicializarRadar(cs);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.entregadorRadarTitle),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      drawer: _buildDrawer(cs, i18n),
      // Usamos o ValueListenableBuilder para reagir ao Firestore em tempo real
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          return ValueListenableBuilder<Set<Marker>>(
            valueListenable: _controller.marcadores,
            builder: (context, markers, _) => GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-23.55, -46.63),
                zoom: 12,
              ),
              markers: markers,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(ColorScheme cs, AppLocalizations i18n) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: cs.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delivery_dining, color: cs.onPrimary, size: 42),
                const SizedBox(height: 12),
                Text(
                  i18n.profileEntregador,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: cs.error),
            title: Text(
              i18n.logout,
              style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
            ),
            onTap: () => AuthService().logout(),
          ),
        ],
      ),
    );
  }
}
