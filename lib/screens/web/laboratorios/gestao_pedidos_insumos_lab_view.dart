import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/laboratorio_model.dart';

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
    // 💡 Conecta ao Firebase uma única vez ouvindo os pedidos DESTE laboratório
    _pedidosStream = FirebaseFirestore.instance
        .collection('pedidos_insumo')
        .where('laboratorioId', isEqualTo: widget.labContexto.id)
        .orderBy('dataPedido', descending: true)
        .snapshots();
  }

  // 🎨 Dicionário Visual de Status Padrão Ouro UX
  Color _obterCorStatus(String status) {
    switch (status) {
      case 'aguardando_analise':
        return Colors.orange.shade600;
      case 'em_separacao':
        return Colors.blue.shade600;
      case 'aguardando_coleta':
        return Colors.purple.shade600;
      case 'entregue':
        return Colors.green.shade600;
      case 'recusado':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _obterLabelStatus(String status) {
    switch (status) {
      case 'aguardando_analise':
        return 'Aguardando Análise';
      case 'em_separacao':
        return 'Em Separação';
      case 'aguardando_coleta':
        return 'Aguardando Coleta';
      case 'entregue':
        return 'Entregue';
      case 'recusado':
        return 'Recusado';
      default:
        return 'Desconhecido';
    }
  }

  IconData _obterIconeStatus(String status) {
    switch (status) {
      case 'aguardando_analise':
        return Icons.pending_actions_rounded;
      case 'em_separacao':
        return Icons.inventory_2_outlined;
      case 'aguardando_coleta':
        return Icons.sports_motorsports_outlined;
      case 'entregue':
        return Icons.check_circle_outline;
      case 'recusado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 💡 Duas Abas: Andamento e Histórico
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CABEÇALHO BLINDADO CONTRA RENDERFLEX ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  // 💡 PROTEÇÃO: Obriga o texto a quebrar linha em telas menores!
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
                        "Gestão de aprovação e envio de materiais para as clínicas parceiras.",
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

            // === BARRA DE ABAS (TABS) BLINDADA ===
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
                isScrollable:
                    true, // 💡 PROTEÇÃO: Permite rolar os títulos das abas caso a tela seja pequena
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
                  // Se o Firebase estiver criando o índice, não vai quebrar, só vai ficar carregando ou mostrar msg
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
                          "Aguardando a criação do Índice no Firebase...\nIsso leva cerca de 3 minutos. Pressione F5 quando estiver pronto.\n\nDetalhe técnico: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }

                  final todosPedidos = snapshot.data?.docs ?? [];

                  // 💡 SEPARAÇÃO INTELIGENTE DAS LISTAS
                  final emAndamento = todosPedidos.where((doc) {
                    final status = doc['status'] as String;
                    return [
                      'aguardando_analise',
                      'em_separacao',
                      'aguardando_coleta',
                    ].contains(status);
                  }).toList();

                  final historico = todosPedidos.where((doc) {
                    final status = doc['status'] as String;
                    return ['entregue', 'recusado'].contains(status);
                  }).toList();

                  return TabBarView(
                    children: [
                      _construirListaPedidos(
                        emAndamento,
                        "Nenhum pedido em andamento no momento.",
                      ),
                      _construirListaPedidos(
                        historico,
                        "O histórico de pedidos está vazio.",
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

  // === CONSTRUTOR DA LISTA DE CARDS ===
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
        final doc = pedidos[index];
        final data = doc.data() as Map<String, dynamic>;

        final status = data['status'] ?? 'aguardando_analise';
        final nomeClinica = data['clinicaNome'] ?? 'Clínica Não Identificada';
        final dataPedido = data['dataPedido'] != null
            ? DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format((data['dataPedido'] as Timestamp).toDate())
            : '--/--/----';

        // Conta a quantidade de itens no array de pedido
        final List itens = data['itens'] ?? [];
        final qtdTotalItems = itens.length;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            onTap: () => _abrirGerenciadorDePedido(context, doc),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Ícone de Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _obterCorStatus(status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _obterIconeStatus(status),
                      color: _obterCorStatus(status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info Principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeClinica,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Pedido realizado em: $dataPedido",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$qtdTotalItems tipo(s) de insumo(s) solicitado(s)",
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge de Status (Oculto em telas absurdamente pequenas, ou adapta)
                  if (MediaQuery.of(context).size.width > 500) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _obterCorStatus(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _obterCorStatus(status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _obterLabelStatus(status),
                        style: TextStyle(
                          color: _obterCorStatus(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // === MODAL DE GERENCIAMENTO (O CORAÇÃO DO FLUXO UX) ===
  void _abrirGerenciadorDePedido(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final statusAtual = data['status'] as String;
    final List itens = data['itens'] ?? [];
    final String justificativaAnterior = data['justificativaLab'] ?? '';

    final formKey = GlobalKey<FormState>();
    final justificativaController = TextEditingController();

    bool isRecusando = false;
    bool isAprovandoParcial = false;
    bool salvando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    _obterIconeStatus(statusAtual),
                    color: _obterCorStatus(statusAtual),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Detalhes do Pedido - ${_obterLabelStatus(statusAtual)}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cabeçalho Clínica
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_hospital_rounded,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Solicitante: ${data['clinicaNome']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Itens Solicitados:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Lista de Itens (Visual)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: itens.map((item) {
                            return ListTile(
                              leading: const Icon(
                                Icons.vaccines,
                                color: Colors.indigo,
                              ),
                              title: Text(
                                item['nomeInsumo'] ?? 'Insumo Desconhecido',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Categoria: ${item['tipo'] ?? '-'}",
                              ),
                              trailing: Text(
                                "${item['quantidadeSolicitada']} un.",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.indigo,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Exibe Justificativa se houver histórico
                      if (justificativaAnterior.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "📌 Observação do Laboratório:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(justificativaAnterior),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 💡 FLUXO UX 1: Análise Inicial
                      if (statusAtual == 'aguardando_analise') ...[
                        Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isAprovandoParcial,
                                    activeColor: Colors.orange,
                                    onChanged: (val) {
                                      setModalState(() {
                                        isAprovandoParcial = val!;
                                        if (val) isRecusando = false;
                                      });
                                    },
                                  ),
                                  const Expanded(
                                    child: Text(
                                      "Aprovar Parcialmente (Falta de estoque)",
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: isRecusando,
                                    activeColor: Colors.red,
                                    onChanged: (val) {
                                      setModalState(() {
                                        isRecusando = val!;
                                        if (val) isAprovandoParcial = false;
                                      });
                                    },
                                  ),
                                  const Expanded(
                                    child: Text(
                                      "Recusar/Declinar Pedido Completo",
                                    ),
                                  ),
                                ],
                              ),

                              if (isAprovandoParcial || isRecusando) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: justificativaController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: isRecusando
                                        ? "Motivo da Recusa (Obrigatório)"
                                        : "Justificativa da Aprovação Parcial (Obrigatório)",
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? "Justificativa é obrigatória"
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: salvando ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Fechar",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                // Botões de Ação baseados no Status
                if (statusAtual == 'aguardando_analise')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecusando
                          ? Colors.red
                          : (isAprovandoParcial ? Colors.orange : Colors.green),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: salvando
                        ? null
                        : () async {
                            if ((isAprovandoParcial || isRecusando) &&
                                !formKey.currentState!.validate())
                              return;
                            setModalState(() => salvando = true);

                            try {
                              String novoStatus =
                                  'em_separacao'; // Aprovação total ou parcial vai para separação
                              if (isRecusando) novoStatus = 'recusado';

                              await FirebaseFirestore.instance
                                  .collection('pedidos_insumo')
                                  .doc(doc.id)
                                  .update({
                                    'status': novoStatus,
                                    'justificativaLab': justificativaController
                                        .text
                                        .trim(),
                                    'dataAtualizacao':
                                        FieldValue.serverTimestamp(),
                                  });

                              if (context.mounted) Navigator.pop(context);
                            } finally {
                              setModalState(() => salvando = false);
                            }
                          },
                    icon: salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      isRecusando
                          ? "Confirmar Recusa"
                          : (isAprovandoParcial
                                ? "Aprovar Parcial"
                                : "Aprovar Total"),
                    ),
                  ),

                // 💡 FLUXO UX 2: Caixa Fechada, libera pro Motoboy
                if (statusAtual == 'em_separacao')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: salvando
                        ? null
                        : () async {
                            setModalState(() => salvando = true);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('pedidos_insumo')
                                  .doc(doc.id)
                                  .update({
                                    'status': 'aguardando_coleta',
                                    'dataAtualizacao':
                                        FieldValue.serverTimestamp(),
                                  });
                              if (context.mounted) Navigator.pop(context);
                            } finally {
                              setModalState(() => salvando = false);
                            }
                          },
                    icon: salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.sports_motorsports_outlined,
                            size: 18,
                          ),
                    label: const Text("Liberar para Coleta"),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
