import 'package:flutter/material.dart';

class ClinicaDashboardMobile extends StatefulWidget {
  const ClinicaDashboardMobile({super.key});

  @override
  State<ClinicaDashboardMobile> createState() => _ClinicaDashboardMobileState();
}

class _ClinicaDashboardMobileState extends State<ClinicaDashboardMobile> {
  int _filtroSelecionado = 0; // 0: Todos, 1: Aguardando, 2: Em Rota

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Fundo padrão Apple iOS
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. CABEÇALHO
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Clínica Vet Route",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Painel logístico operacional",
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.teal.shade50,
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.teal,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ==========================================
                    // 2. BOTÕES DE AÇÃO (Solicitações)
                    // ==========================================
                    Row(
                      children: [
                        Expanded(
                          child: _buildAcaoBotao(
                            context,
                            titulo: "Pedir\nInsumos",
                            icone: Icons.inventory_2_rounded,
                            corBase: Colors.teal,
                            onTap: () {
                              // Ação de abrir modal de insumos
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAcaoBotao(
                            context,
                            titulo: "Coleta\nAgendada",
                            icone: Icons.calendar_month_rounded,
                            corBase: Colors.indigo,
                            onTap: () {
                              // Ação de agendar coleta
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAcaoBotao(
                      context,
                      titulo: "Solicitar Coleta de Urgência",
                      icone: Icons.flash_on_rounded,
                      corBase: Colors.redAccent,
                      isFullWidth: true,
                      onTap: () {
                        // Ação de urgência
                      },
                    ),
                    const SizedBox(height: 32),

                    // ==========================================
                    // 3. STATUS LOGÍSTICO (Motoboy & Contadores)
                    // ==========================================
                    const Text(
                      "Status da Operação",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card do Motoboy a Caminho
                    _buildMotoboyCard(),
                    const SizedBox(height: 12),

                    // Contadores
                    Row(
                      children: [
                        Expanded(
                          child: _buildContadorCard(
                            "Aguardando\nColeta",
                            "2",
                            Colors.orange.shade800,
                            Colors.orange.shade50,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildContadorCard(
                            "Pedidos\nEm Rota",
                            "3",
                            Colors.indigo,
                            Colors.indigo.shade50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ==========================================
                    // 4. HISTÓRICO E LISTAGEM DO DIA
                    // ==========================================
                    const Text(
                      "Pedidos do Dia",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFiltrosApple(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Lista Reativa (Mock visual para a estrutura)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildItemLista(),
                    );
                  },
                  childCount: 4, // Quantidade de itens de exemplo
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGETS DE COMPONENTES
  // ==========================================

  Widget _buildAcaoBotao(
    BuildContext context, {
    required String titulo,
    required IconData icone,
    required Color corBase,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: corBase,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: corBase.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icone, color: Colors.white, size: 32),
                  const SizedBox(height: 16),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMotoboyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_motorsports_rounded,
              color: Colors.orange.shade800,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Entregador a caminho",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "João Silva",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Chega em aprox. 15 min",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.indigo,
            ),
            onPressed: () {
              // Abrir mapa em tempo real
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContadorCard(
    String titulo,
    String valor,
    Color corIcone,
    Color corFundo,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: corFundo,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inbox_rounded, color: corIcone, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosApple() {
    final filtros = ["Todos", "Aguardando", "Em Rota", "Concluídos"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(filtros.length, (index) {
          final isSelected = _filtroSelecionado == index;
          return GestureDetector(
            onTap: () => setState(() => _filtroSelecionado = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.indigo : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filtros[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF636366),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildItemLista() {
    // Esse card será populado com os dados reais do Firestore
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "COLETA AGENDADA",
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                "Hoje, 16:23",
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "#XML2U",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Destino: Lab Central",
            style: TextStyle(fontSize: 14, color: Color(0xFF636366)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF2F2F7)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.two_wheeler_rounded,
                      size: 14,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Em Rota",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: Colors.indigo,
                ),
                label: const Text(
                  "Detalhes",
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
