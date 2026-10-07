import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/laboratorio_model.dart';
import 'components/item_card_pedido_insumo.dart';
import 'package:intl/intl.dart';

class GestaoPedidosInsumosHub extends StatefulWidget {
  final Laboratorio labContexto;

  const GestaoPedidosInsumosHub({super.key, required this.labContexto});

  @override
  State<GestaoPedidosInsumosHub> createState() =>
      _GestaoPedidosInsumosHubState();
}

class _GestaoPedidosInsumosHubState extends State<GestaoPedidosInsumosHub> {
  late Stream<QuerySnapshot> _pedidosStream;

  int _selectedSegment = 0;
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    _pedidosStream = FirebaseFirestore.instance
        .collection('pedidos_insumos')
        .where('laboratorioId', isEqualTo: widget.labContexto.id)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CABEÇALHO PREMIUM ===
            const Text(
              "Suprimentos para Clínicas 📦",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Pipeline operacional: analise, separe e despache os materiais para as clínicas parceiras.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 32),

            // === BARRA DE CONTROLES (Abas + Busca) ===
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 400,
                  child: CupertinoSlidingSegmentedControl<int>(
                    backgroundColor: Colors.grey.shade300.withOpacity(0.5),
                    thumbColor: Colors.white,
                    groupValue: _selectedSegment,
                    padding: const EdgeInsets.all(4),
                    children: {
                      0: _buildSegmentText("Quadro Kanban", 0),
                      1: _buildSegmentText("Histórico Finalizado", 1),
                    },
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSegment = value);
                      }
                    },
                  ),
                ),

                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar pedido, status ou clínica...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.search,
                        color: Colors.indigo,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.indigo,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => setState(() => _termoBusca = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === CORPO DA LISTA / KANBAN ===
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _pedidosStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CupertinoActivityIndicator(radius: 14),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Erro ao carregar os pedidos.\nDetalhe técnico: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                        ),
                      ),
                    );
                  }

                  final todosPedidos = snapshot.data?.docs ?? [];

                  // Ordenação Padrão: Mais recentes primeiro
                  todosPedidos.sort((a, b) {
                    final dataA =
                        (a.data() as Map<String, dynamic>)['dataSolicitacao']
                            as Timestamp?;
                    final dataB =
                        (b.data() as Map<String, dynamic>)['dataSolicitacao']
                            as Timestamp?;
                    if (dataA == null || dataB == null) return 0;
                    return dataB.compareTo(dataA);
                  });

                  // Filtragem de Busca
                  final pedidosFiltrados = todosPedidos.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? '')
                        .toString()
                        .toLowerCase()
                        .trim();
                    final isEncerrado = [
                      'entregue',
                      'concluído',
                      'concluido',
                      'recusado',
                      'cancelado',
                    ].contains(status);

                    if (_selectedSegment == 0 && isEncerrado) return false;
                    if (_selectedSegment == 1 && !isEncerrado) return false;

                    if (_termoBusca.isNotEmpty) {
                      final termo = _termoBusca.toLowerCase();
                      final codigo = (data['codigo'] ?? '')
                          .toString()
                          .toLowerCase();
                      final clinica = (data['clinicaNome'] ?? '')
                          .toString()
                          .toLowerCase();
                      return codigo.contains(termo) ||
                          clinica.contains(termo) ||
                          status.contains(termo);
                    }
                    return true;
                  }).toList();

                  if (_selectedSegment == 0) {
                    return _construirKanbanBoard(pedidosFiltrados);
                  } else {
                    return _construirHistoricoAgrupado(
                      pedidosFiltrados,
                      "O histórico de finalizados está vazio.",
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentText(String texto, int index) {
    final isSelected = _selectedSegment == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.black87 : Colors.grey.shade600,
        ),
      ),
    );
  }

  // 💡 MÁGICA DO KANBAN: Divide os pedidos nas 3 colunas baseadas no Status
  Widget _construirKanbanBoard(List<QueryDocumentSnapshot> pedidosAtivos) {
    final novos = pedidosAtivos.where((doc) {
      final s = ((doc.data() as Map)['status'] ?? '').toString().toLowerCase();
      return s.contains('pendente') || s.contains('analise');
    }).toList();

    final emSeparacao = pedidosAtivos.where((doc) {
      final s = ((doc.data() as Map)['status'] ?? '').toString().toLowerCase();
      return s.contains('separacao') ||
          s.contains('separação') ||
          s.contains('aprovado');
    }).toList();

    final prontos = pedidosAtivos.where((doc) {
      final s = ((doc.data() as Map)['status'] ?? '').toString().toLowerCase();
      return s.contains('aguardando') ||
          s.contains('rota') ||
          s.contains('coletar') ||
          s.contains('transporte') ||
          s.contains('transito');
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn("📥 Novos Pedidos", Colors.orange.shade700, novos),
          _buildKanbanColumn(
            "📦 Em Separação",
            Colors.blue.shade700,
            emSeparacao,
          ),
          _buildKanbanColumn(
            "🛵 Pronto p/ Coleta",
            Colors.indigo.shade600,
            prontos,
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(
    String titulo,
    Color corDestaque,
    List<QueryDocumentSnapshot> pedidos,
  ) {
    return Container(
      width: 360, // 💡 Largura fixa da coluna do Kanban
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade200.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Coluna
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: corDestaque,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${pedidos.length}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lista de Tickets
          Expanded(
            child: ListView.separated(
              itemCount: pedidos.length,
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  ItemCardPedidoInsumo(doc: pedidos[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirHistoricoAgrupado(
    List<QueryDocumentSnapshot> pedidos,
    String msgVazia,
  ) {
    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.archivebox,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              msgVazia,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // 1. AGRUPAMENTO: Organizar os pedidos pelo dia de entrega
    final Map<String, List<QueryDocumentSnapshot>> grupos = {};

    for (var doc in pedidos) {
      final dataMap = doc.data() as Map<String, dynamic>;

      // Dá prioridade ao momento da entrega (fallback para data de criação nos testes antigos)
      final Timestamp? ts =
          dataMap['timestampEntrega'] as Timestamp? ??
          dataMap['dataSolicitacao'] as Timestamp?;

      final DateTime dataObj = ts?.toDate() ?? DateTime.now();
      final String chaveData = DateFormat('dd/MM/yyyy').format(dataObj);

      if (!grupos.containsKey(chaveData)) {
        grupos[chaveData] = [];
      }
      grupos[chaveData]!.add(doc);
    }

    // 2. ORDENAÇÃO DOS DIAS: Do mais recente (hoje) para o mais antigo
    final chavesOrdenadas = grupos.keys.toList()
      ..sort((a, b) {
        final dataA = DateFormat('dd/MM/yyyy').parse(a);
        final dataB = DateFormat('dd/MM/yyyy').parse(b);
        return dataB.compareTo(dataA);
      });

    // 3. RENDERIZAÇÃO: Lista de cabeçalhos com grelhas dinâmicas lá dentro
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: chavesOrdenadas.length,
      itemBuilder: (context, index) {
        final chave = chavesOrdenadas[index];
        final listaDoDia = grupos[chave]!;

        // Ordenar os cartões dentro do próprio dia (Hora exata mais recente primeiro)
        listaDoDia.sort((a, b) {
          final tsA =
              (a.data() as Map)['timestampEntrega'] as Timestamp? ??
              (a.data() as Map)['dataSolicitacao'] as Timestamp?;
          final tsB =
              (b.data() as Map)['timestampEntrega'] as Timestamp? ??
              (b.data() as Map)['dataSolicitacao'] as Timestamp?;
          if (tsA == null || tsB == null) return 0;
          return tsB.compareTo(tsA);
        });

        // Deteta se o bloco pertence a "Hoje" para ficar mais amigável
        final hojeStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
        final tituloDia = chave == hojeStr ? "Hoje, $chave" : chave;

        return Padding(
          padding: const EdgeInsets.only(bottom: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABEÇALHO DA DATA ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 20,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tituloDia,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.indigo.withOpacity(0.1),
                        ),
                      ),
                      child: Text(
                        "${listaDoDia.length} entrega(s)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- GRELHA DE CARTÕES LADO A LADO ---
              Wrap(
                spacing: 16, // Espaço horizontal entre os cartões
                runSpacing: 16, // Espaço vertical entre as linhas de cartões
                children: listaDoDia.map((doc) {
                  return SizedBox(
                    width:
                        380, // Largura restrita para caberem 2 a 3 por linha no ecrã Web
                    child: ItemCardPedidoInsumo(doc: doc),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _construirListaVertical(
    List<QueryDocumentSnapshot> pedidos,
    String msgVazia,
  ) {
    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.archivebox,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              msgVazia,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: pedidos.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ), // Mantém limitação só na lista
          child: ItemCardPedidoInsumo(doc: pedidos[index]),
        ),
      ),
    );
  }
}
