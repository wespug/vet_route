import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/l10n/app_localizations.dart';
import 'package:vet_route/repositories/firestore_coleta_repository.dart';

import '../controllers/laboratorio_controller.dart';
import '../services/auth_service.dart';

class LaboratorioScreen extends StatefulWidget {
  const LaboratorioScreen({super.key});

  @override
  State<LaboratorioScreen> createState() => _LaboratorioScreenState();
}

class _LaboratorioScreenState extends State<LaboratorioScreen> {
  late GoogleMapController mapController;
  final LaboratorioController _controller = LaboratorioController(
    FirestoreColetaRepository(),
  );

  @override
  void initState() {
    super.initState();
    _controller.inicializarPainel();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _receberEncomendaMotoboy() {
    _controller.receberEncomenda();
    final i18n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(i18n.labReceiveInit),
        backgroundColor: colorScheme.primary,
      ),
    );
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
        _controller.laboratorioAtual,
        _controller.tabAtiva,
        _controller.isLoading,
        _controller.marcadoresMapa,
      ]),
      builder: (context, _) {
        final lab = _controller.laboratorioAtual.value;
        final isLoading = _controller.isLoading.value;

        if (isLoading || lab == null) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text('${i18n.labBtnReceiveProduct} - ${lab.nome}'),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
          ),
          drawer: _buildDrawer(i18n, colorScheme, lab.nome),
          body: Column(
            children: [
              _buildDashboardCards(i18n, colorScheme),
              Expanded(
                child: _buildAreaDinamica(
                  i18n,
                  colorScheme,
                  lab.endereco.coordenada!,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomButton(i18n, colorScheme),
        );
      },
    );
  }

  Widget _buildDrawer(
    AppLocalizations i18n,
    ColorScheme colorScheme,
    String nomeLab,
  ) {
    return Drawer(
      backgroundColor: colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.science, color: colorScheme.onPrimary, size: 42),
                const SizedBox(height: 12),
                Text(
                  nomeLab,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  i18n.profileLabel,
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: colorScheme.error),
            title: Text(
              i18n.logout,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => AuthService().logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(AppLocalizations i18n, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 60,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _receberEncomendaMotoboy,
          icon: const Icon(Icons.qr_code_scanner, size: 28),
          label: Text(
            i18n.labBtnReceiveProduct,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCards(AppLocalizations i18n, ColorScheme colorScheme) {
    final tabAtiva = _controller.tabAtiva.value;
    return Container(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _cardDash(
            i18n.open,
            '0',
            colorScheme.error,
            Icons.access_time,
            tabAtiva == TabLabDashboard.emEspera,
            colorScheme,
            () => _controller.alterarTab(TabLabDashboard.emEspera),
          ),
          _cardDash(
            i18n.onWay,
            '0',
            colorScheme.primary,
            Icons.local_shipping,
            tabAtiva == TabLabDashboard.aCaminho,
            colorScheme,
            () => _controller.alterarTab(TabLabDashboard.aCaminho),
          ),
          _cardDash(
            i18n.finished,
            '0',
            colorScheme.secondary,
            Icons.fact_check_outlined,
            tabAtiva == TabLabDashboard.recebidas,
            colorScheme,
            () => _controller.alterarTab(TabLabDashboard.recebidas),
          ),
        ],
      ),
    );
  }

  Widget _cardDash(
    String titulo,
    String qtd,
    Color cor,
    IconData icone,
    bool ativo,
    ColorScheme cs,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ativo ? cor : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ativo ? cor : cs.outlineVariant, width: 2),
        ),
        child: Column(
          children: [
            Icon(icone, color: ativo ? cs.onPrimary : cor, size: 28),
            const SizedBox(height: 8),
            Text(
              qtd,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ativo ? cs.onPrimary : cs.onSurface,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ativo ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaDinamica(
    AppLocalizations i18n,
    ColorScheme cs,
    LatLng coord,
  ) {
    if (_controller.tabAtiva.value == TabLabDashboard.recebidas) {
      return Center(
        child: Text(
          i18n.emptyFinished,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    } else if (_controller.tabAtiva.value == TabLabDashboard.emEspera) {
      return Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(target: coord, zoom: 12),
              markers: _controller.marcadoresMapa.value,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                i18n.emptyWaiting,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(target: coord, zoom: 14),
          markers: _controller.marcadoresMapa.value,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            color: cs.surface.withValues(alpha: 0.9),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                i18n.radarText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
