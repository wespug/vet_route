import 'package:flutter/material.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/screens/web/clinicas/clinica_usuario_view.dart';
import 'package:vet_route/screens/widgets/generic_tab_hub.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/screens/web/clinicas/lista_clinicas_view.dart';
import 'package:vet_route/screens/web/clinicas/clinica_dashboard_view.dart';

class ClinicasHub extends StatefulWidget {
  const ClinicasHub({super.key});

  @override
  State<ClinicasHub> createState() => _ClinicasHubState();
}

class _ClinicasHubState extends State<ClinicasHub> {
  Clinica? _clinicaSelecionada;

  Widget _resolverConteudoDaAba(String rotaSubmenu) {
    switch (rotaSubmenu) {
      case 'clinica_dashboard':
        return ClinicaDashboardView(clinicaContexto: _clinicaSelecionada!);

      case 'clinica_adicionar_usuario':
        return UsuariosClinicaView(
          clinicaContexto: _clinicaSelecionada!,
          chavePermissao:
              'clinica_gestao', // 💡 AQUI ESTÁ A CORREÇÃO! A chave foi injetada!
        );

      default:
        return _buildPlaceholder(
          'Funcionalidade ($rotaSubmenu) configurada na gestão, mas em desenvolvimento 🚧',
          Icons.construction_rounded,
        );
    }
  }

  Widget _buildPlaceholder(String texto, IconData icone) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            texto,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_clinicaSelecionada == null) {
      return ListaClinicasView(
        onClinicaSelected: (clinica) {
          setState(() {
            _clinicaSelecionada = clinica;
          });
        },
      );
    }

    return ListenableBuilder(
      listenable: permissoesGlobais,
      builder: (context, child) {
        final menusFiltrados = permissoesGlobais.menusPermitidos.where(
          (m) => m.rota == 'clinica_gestao',
        );

        if (menusFiltrados.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        final menuPai = menusFiltrados.first;
        final submenus = permissoesGlobais.getSubmenusDoMenu(menuPai.id);

        final submenusFiltrados = submenus
            .where((s) => s.rota != 'lista_clinicas_aba')
            .toList();

        if (submenusFiltrados.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBarraTopoBreadcrumb(),
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "Nenhum submenu configurado para este módulo no Firestore.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        submenusFiltrados.sort((a, b) => a.peso.compareTo(b.peso));

        final abasDinamicas = submenusFiltrados.map((submenu) {
          return TabItemModel(
            titulo: submenu.titulo,
            conteudo: _resolverConteudoDaAba(submenu.rota),
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarraTopoBreadcrumb(),
            const SizedBox(height: 16),
            Expanded(child: GenericTabHub(abas: abasDinamicas)),
          ],
        );
      },
    );
  }

  Widget _buildBarraTopoBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_hospital_outlined,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Clínicas",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                _clinicaSelecionada!.nome,
                style: const TextStyle(
                  color: Colors.teal,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _clinicaSelecionada = null;
              });
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text(
              "Voltar para Lista",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }
}
