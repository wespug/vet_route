import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/screens/mobile_home_screen.dart';
import 'package:vet_route/services/auth_service.dart';
import 'package:vet_route/controllers/permissoes_controller.dart';

// 💡 IMPORTAÇÃO DAS MODELS
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/endereco_model.dart';

// 🛡️ IMPORTAÇÃO DA DASHBOARD
import 'package:vet_route/screens/mobile/clinica_dashboard_mobile_screen.dart';

class MobileChassi extends StatefulWidget {
  const MobileChassi({super.key});

  @override
  State<MobileChassi> createState() => _MobileChassiState();
}

class _MobileChassiState extends State<MobileChassi> {
  String _nomeUsuarioLogado = "A carregar...";
  String _emailUsuarioLogado = "A carregar...";

  // 💡 Variável para armazenar o contexto da clínica real
  Clinica? _clinicaContexto;

  // 🛡️ Flag de segurança para não deixar o loading infinito
  bool _falhaDeVinculo = false;

  Widget? _conteudoAtual;
  String _tituloAtual = "Vet Route";
  String _rotaAtivaId = "";
  final List<String> _menusExpandidosIds = [];

  static const Map<String, IconData> _iconesMapeados = {
    'local_hospital': Icons.local_hospital_rounded,
    'science': Icons.science_rounded,
    'motorcycle': Icons.two_wheeler_rounded,
    'admin_panel_settings': Icons.admin_panel_settings_rounded,
    'layers': Icons.layers_rounded,
    'account_tree': Icons.account_tree_rounded,
    'people': Icons.people_alt_rounded,
    'dashboard': Icons.grid_view_rounded,
    'subdirectory_arrow_right': Icons.keyboard_arrow_right_rounded,
    'analytics': Icons.analytics_rounded,
    'assignment': Icons.assignment_rounded,
    'payments': Icons.credit_card_rounded,
    'inventory': Icons.inventory_rounded,
    'route': Icons.alt_route_rounded,
    'hail': Icons.hail_rounded,
  };

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuarioEPermissoes();
  }

  Future<void> _carregarDadosUsuarioEPermissoes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint("🐾 [MobileChassi] A iniciar carga. UID Logado: $uid");

    if (uid != null) {
      try {
        final docUsuario = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();

        debugPrint(
          "🐾 [MobileChassi] Encontrou documento do utilizador? ${docUsuario.exists}",
        );

        if (docUsuario.exists && mounted) {
          final dataUser = docUsuario.data()!;

          setState(() {
            _nomeUsuarioLogado = dataUser['nome'] ?? "Utilizador";
            _emailUsuarioLogado =
                dataUser['email'] ??
                FirebaseAuth.instance.currentUser?.email ??
                "";
          });

          // 🚀 A MÁGICA ESTÁ AQUI: Procuramos por 'vinculoId' (padrão do painel web) primeiro!
          final String? clinicaId =
              dataUser['vinculoId'] ?? dataUser['clinicaId'];
          debugPrint(
            "🐾 [MobileChassi] ID de vínculo atrelado ao utilizador: $clinicaId",
          );

          // 🛡️ BLOCO ISOLADO PARA CARREGAR A CLÍNICA
          try {
            DocumentSnapshot docClinica;
            if (clinicaId != null && clinicaId.isNotEmpty) {
              debugPrint(
                "🐾 [MobileChassi] A procurar clínica na coleção 'clinicas' com ID: $clinicaId",
              );
              docClinica = await FirebaseFirestore.instance
                  .collection('clinicas')
                  .doc(clinicaId)
                  .get();
            } else {
              debugPrint(
                "🐾 [MobileChassi] Sem vinculoId no perfil. A procurar clínica pelo UID: $uid",
              );
              docClinica = await FirebaseFirestore.instance
                  .collection('clinicas')
                  .doc(uid)
                  .get();
            }

            if (docClinica.exists && mounted) {
              debugPrint(
                "🐾 [MobileChassi] Tentando invocar Clinica.fromFirestore...",
              );
              final clinicaObj = Clinica.fromFirestore(docClinica);

              setState(() {
                _clinicaContexto = clinicaObj;
                _falhaDeVinculo = false; // Sucesso!
              });
              debugPrint(
                "✅ [MobileChassi] SUCESSO! Contexto da Clínica carregado: ${_clinicaContexto?.nome}",
              );
            } else {
              debugPrint(
                "🚨 [MobileChassi] ERRO: Clínica não existe na base de dados!",
              );
              if (mounted) setState(() => _falhaDeVinculo = true);
            }
          } catch (e, stackTrace) {
            debugPrint("🚨 [MobileChassi] ERRO FATAL AO CONVERTER CLINICA: $e");
            debugPrint(stackTrace.toString());
            if (mounted) setState(() => _falhaDeVinculo = true);
          }

          final perfilId = dataUser['perfilId'];
          if (perfilId != null) {
            await permissoesGlobais.inicializarParaUsuario(perfilId);

            if (mounted && permissoesGlobais.menusPermitidos.isNotEmpty) {
              final menusMobile = permissoesGlobais.menusPermitidos
                  .where((m) => m.isMobile == true)
                  .toList();
              if (menusMobile.isNotEmpty) {
                menusMobile.sort((a, b) => a.peso.compareTo(b.peso));
                final menuPai = menusMobile.first;
                final subs = permissoesGlobais
                    .getSubmenusDoMenu(menuPai.id)
                    .where((s) => s.isMobile == true)
                    .toList();

                setState(() {
                  if (subs.isNotEmpty) {
                    subs.sort((a, b) => a.peso.compareTo(b.peso));
                    _tituloAtual = subs.first.titulo;
                    _rotaAtivaId = subs.first.id;
                    _conteudoAtual = _obterTelaDestinoMobile(
                      subs.first.rota,
                      subs.first.titulo,
                    );
                  } else {
                    _tituloAtual = menuPai.titulo;
                    _rotaAtivaId = menuPai.id;
                    _conteudoAtual = _obterTelaDestinoMobile(
                      menuPai.rota,
                      menuPai.titulo,
                    );
                  }
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint(
          "🚨 [MobileChassi] Erro geral ao procurar dados do utilizador: $e",
        );
      }
    }
  }

  Widget _obterTelaDestinoMobile(String chaveRota, String titulo) {
    switch (chaveRota) {
      case 'clinica_dashboard':
        // 🛡️ PROTEÇÃO: Se a clínica não existir ou der erro de vinculo, mostramos ecrã amigável
        if (_falhaDeVinculo) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.link_off_rounded,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Utilizador sem Vínculo",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2959),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "A sua conta não tem uma clínica associada.\nPor favor, associe a clínica no painel Web através da 'Gestão de Utilizadores'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        // Se ainda está nulo mas não deu falha, é porque está a carregar
        if (_clinicaContexto == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF1F2959)),
                SizedBox(height: 16),
                Text(
                  "A montar contexto logístico...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ClinicaDashboardMobileScreen(
          clinicaContexto: _clinicaContexto!,
          rotaQueChamou: chaveRota,
        );
      default:
        return Container(
          color: const Color(0xFFF8F9FA),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2959).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.blur_on_rounded,
                      size: 48,
                      color: Color(0xFF1F2959),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2959),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "O layout para a rota '$chaveRota' está a ser lapidado.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  void _executarNavegacao(String titulo, String chaveRota, String idAtivo) {
    setState(() {
      _tituloAtual = titulo;
      _rotaAtivaId = idAtivo;
      _conteudoAtual = _obterTelaDestinoMobile(chaveRota, titulo);
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const corPrimariaDark = Color(0xFF1F2959);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: Text(
          _tituloAtual.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: corPrimariaDark,
            letterSpacing: 1.8,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: corPrimariaDark, size: 22),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black.withOpacity(0.04), height: 1),
        ),
      ),
      drawer: _buildDrawerSofisticado(corPrimariaDark),
      body: _conteudoAtual ?? const MobileHomeScreen(),
    );
  }

  Widget _buildDrawerSofisticado(Color corFoco) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black26,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF10163A), corFoco],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7FFFD4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: Color(0xFF7FFFD4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      "VET ROUTE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          _nomeUsuarioLogado.isNotEmpty
                              ? _nomeUsuarioLogado[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nomeUsuarioLogado,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _emailUsuarioLogado,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: permissoesGlobais,
              builder: (context, child) {
                if (permissoesGlobais.carregando) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: corFoco,
                      strokeWidth: 2,
                    ),
                  );
                }

                final menusMobile = permissoesGlobais.menusPermitidos
                    .where((m) => m.isMobile == true)
                    .toList();
                menusMobile.sort((a, b) => a.peso.compareTo(b.peso));

                if (menusMobile.isEmpty) {
                  return Center(
                    child: Text(
                      "Nenhum módulo móvel atribuído.",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: menusMobile.length,
                  itemBuilder: (context, index) {
                    final menu = menusMobile[index];
                    final submenusMobile = permissoesGlobais
                        .getSubmenusDoMenu(menu.id)
                        .where((s) => s.isMobile == true)
                        .toList();
                    submenusMobile.sort((a, b) => a.peso.compareTo(b.peso));

                    final iconData =
                        _iconesMapeados[menu.icone] ?? Icons.widgets_rounded;
                    final bool estaExpandido = _menusExpandidosIds.contains(
                      menu.id,
                    );
                    final bool menuSelecionado = _rotaAtivaId == menu.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: menuSelecionado
                                  ? corFoco.withOpacity(0.06)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              dense: true,
                              horizontalTitleGap: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              leading: Icon(
                                iconData,
                                color: menuSelecionado
                                    ? corFoco
                                    : Colors.grey.shade700,
                                size: 22,
                              ),
                              title: Text(
                                menu.titulo,
                                style: TextStyle(
                                  fontWeight: menuSelecionado
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: menuSelecionado
                                      ? corFoco
                                      : Colors.black87,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              trailing: submenusMobile.isEmpty
                                  ? null
                                  : Icon(
                                      estaExpandido
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey.shade500,
                                      size: 18,
                                    ),
                              onTap: () {
                                if (submenusMobile.isEmpty) {
                                  _executarNavegacao(
                                    menu.titulo,
                                    menu.rota,
                                    menu.id,
                                  );
                                } else {
                                  setState(
                                    () => estaExpandido
                                        ? _menusExpandidosIds.remove(menu.id)
                                        : _menusExpandidosIds.add(menu.id),
                                  );
                                }
                              },
                            ),
                          ),
                          if (submenusMobile.isNotEmpty && estaExpandido)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Column(
                                children: submenusMobile.map((sub) {
                                  final bool subSelecionado =
                                      _rotaAtivaId == sub.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      bottom: 2,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: subSelecionado
                                            ? corFoco.withOpacity(0.06)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        horizontalTitleGap: 10,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        leading: Icon(
                                          _iconesMapeados[sub.icone] ??
                                              Icons.circle_rounded,
                                          color: subSelecionado
                                              ? corFoco
                                              : Colors.grey.shade400,
                                          size: subSelecionado ? 16 : 10,
                                        ),
                                        title: Text(
                                          sub.titulo,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: subSelecionado
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: subSelecionado
                                                ? corFoco
                                                : Colors.grey.shade800,
                                          ),
                                        ),
                                        onTap: () => _executarNavegacao(
                                          sub.titulo,
                                          sub.rota,
                                          sub.id,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.black.withOpacity(0.04),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hoverColor: Colors.red.shade50,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.red.shade700,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Desligar do Sistema',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                onTap: () async {
                  permissoesGlobais.menusPermitidos.clear();
                  permissoesGlobais.submenusPermitidos.clear();
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
