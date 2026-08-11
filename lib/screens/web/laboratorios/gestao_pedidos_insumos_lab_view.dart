import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/laboratorio_model.dart';
// Importação do card de pedido do laboratório (ajuste o caminho se necessário)
import 'components/item_card_pedido_insumo.dart';

class GestaoPedidosInsumosHub extends StatefulWidget {
  final Laboratorio labContexto;

  const GestaoPedidosInsumosHub({super.key, required this.labContexto});

  @override
  State<GestaoPedidosInsumosHub> createState() =>
      _GestaoPedidosInsumosHubState();
}

class _GestaoPedidosInsumosHubState extends State<GestaoPedidosInsumosHub> {
  late Stream<QuerySnapshot> _pedidosStream;

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
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CABEÇALHO ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Suprimentos para Clínicas 📦",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Gestão de aprovação e envio de materiais solicitados pelas clínicas parceiras.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === BARRA DE ABAS ===
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: Colors.indigo,
                indicatorWeight: 3,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping_outlined),
                        SizedBox(width: 8),
                        Text(
                          "Em Andamento",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded),
                        SizedBox(width: 8),
                        Text(
                          "Histórico Finalizado",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // === CORPO DAS ABAS ===
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _pedidosStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.indigo),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "Erro ao carregar os pedidos de insumos.\n\nDetalhe técnico: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }

                  final todosPedidos = snapshot.data?.docs ?? [];

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

                  // Pedidos ativos (incluindo aprovação parcial e total em separação)
                  final emAndamento = todosPedidos.where((doc) {
                    final status =
                        ((doc.data() as Map<String, dynamic>)['status'] ?? '')
                            .toString()
                            .toLowerCase();
                    return [
                      'pendente',
                      'aguardando_analise',
                      'aguardando analise',
                      'em_separacao',
                      'em separação',
                      'aprovado',
                      'aprovado_parcialmente',
                      'aprovado parcialmente',
                      'aguardando_coleta',
                      'aguardando coleta',
                    ].contains(status);
                  }).toList();

                  // Histórico de pedidos totalmente encerrados
                  final historico = todosPedidos.where((doc) {
                    final status =
                        ((doc.data() as Map<String, dynamic>)['status'] ?? '')
                            .toString()
                            .toLowerCase();
                    return [
                      'entregue',
                      'concluído',
                      'concluido',
                      'recusado',
                      'cancelado',
                    ].contains(status);
                  }).toList();

                  return TabBarView(
                    children: [
                      _construirListaPedidos(
                        emAndamento,
                        "Nenhum pedido de clínica em andamento no momento.",
                      ),
                      _construirListaPedidos(
                        historico,
                        "O histórico de pedidos de clínicas está vazio.",
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirListaPedidos(
    List<QueryDocumentSnapshot> pedidos,
    String msgVazia,
  ) {
    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              msgVazia,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return ItemCardPedidoInsumo(doc: pedidos[index]);
      },
    );
  }
}
