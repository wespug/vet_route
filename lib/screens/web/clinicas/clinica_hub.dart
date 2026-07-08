import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';
import 'package:vet_route/screens/widgets/generic_tab_hub.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/screens/web/clinicas/lista_clinicas_view.dart';
import 'package:vet_route/screens/web/clinicas/clinica_dashboard_view.dart';
import 'package:vet_route/screens/web/clinicas/clinica_usuario_view.dart';

class ClinicasHub extends StatefulWidget {
  const ClinicasHub({super.key});

  @override
  State<ClinicasHub> createState() => _ClinicasHubState();
}

class _ClinicasHubState extends State<ClinicasHub> {
  Clinica? _clinicaSelecionada;
  bool _isLoading = true;
  bool _isUsuarioRestrito = false;

  @override
  void initState() {
    super.initState();
    _verificarVinculoUsuario();
  }

  Future<void> _verificarVinculoUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      if (userData != null &&
          userData.containsKey('vinculoId') &&
          userData['vinculoId'] != null &&
          userData['vinculoId'].toString().isNotEmpty) {
        final vinculoId = userData['vinculoId'];

        final clinicaDoc = await FirebaseFirestore.instance
            .collection('clinicas')
            .doc(vinculoId)
            .get();

        if (clinicaDoc.exists) {
          setState(() {
            _clinicaSelecionada = Clinica.fromFirestore(clinicaDoc);
            _isUsuarioRestrito = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Erro ao verificar vínculo: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _resolverConteudoDaAba(String rotaSubmenu) {
    // Como garantimos no build que esta função só roda se houver clínica selecionada,
    // o operador '!' é 100% seguro aqui e nunca causará crash.
    switch (rotaSubmenu) {
      case 'clinica_dashboard':
        return ClinicaDashboardView(clinicaContexto: _clinicaSelecionada!);

      case 'clinica_adicionar_usuario':
        return UsuariosClinicaView(
          clinicaContexto: _clinicaSelecionada!,
          chavePermissao: 'clinica_gestao',
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    // 🌐 PASSO 1 DO ADMIN: NENHUMA EMPRESA SELECIONADA
    // Exibe única e exclusivamente a lista de seleção, eliminando as abas vazias do topo!
    if (_clinicaSelecionada == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(left: 24, right: 24, top: 24),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_business_rounded,
                  color: Colors.teal.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Painel de Controle Corporativo: Selecione uma Clínica na lista abaixo para gerenciar seus operadores e visualizar o dashboard de coletas.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListaClinicasView(
              onClinicaSelected: (clinica) {
                setState(() {
                  _clinicaSelecionada = clinica;
                });
              },
            ),
          ),
        ],
      );
    }

    // 🏥 PASSO 2: CLÍNICA SELECIONADA ATIVA
    // Infla com maestria o chassi de abas dinâmicas baseado nas permissões do Firestore
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
      margin: const EdgeInsets.only(left: 24, right: 24, top: 24),
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
          if (!_isUsuarioRestrito)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _clinicaSelecionada =
                      null; // Reseta o estado e volta para a lista limpa
                });
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text(
                "Alternar Clínica",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
        ],
      ),
    );
  }
}
