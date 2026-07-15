import 'package:flutter/material.dart';
import 'package:vet_route/controllers/pedido_insumo_controller.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/pedido_insumo_model.dart';
import 'package:intl/intl.dart';

class GestaoPedidosInsumosLabView extends StatefulWidget {
  final Laboratorio labContexto;

  const GestaoPedidosInsumosLabView({super.key, required this.labContexto});

  @override
  State<GestaoPedidosInsumosLabView> createState() =>
      _GestaoPedidosInsumosLabViewState();
}

class _GestaoPedidosInsumosLabViewState
    extends State<GestaoPedidosInsumosLabView> {
  final PedidoInsumoController _controller = PedidoInsumoController();

  @override
  void initState() {
    super.initState();
    // 💡 CORREÇÃO: Adicionado o "!" para garantir ao Flutter Null Safety que o ID não é nulo
    _controller.escutarPedidos(widget.labContexto.id!);
  }

  Color _obterCorStatus(String status) {
    switch (status) {
      case 'Pendente':
        return Colors.orange;
      case 'Aprovado':
        return Colors.blue;
      case 'Enviado':
        return Colors.indigo;
      case 'Concluido':
        return Colors.green;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _abrirModalStatus(PedidoInsumoModel pedido) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Atualizar Status - ${pedido.clinicaNome}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selecione o novo status para este pedido:"),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  [
                    'Pendente',
                    'Aprovado',
                    'Enviado',
                    'Concluido',
                    'Cancelado',
                  ].map((status) {
                    return ChoiceChip(
                      label: Text(status),
                      selected: pedido.status == status,
                      onSelected: (selected) {
                        if (selected) {
                          _controller.alterarStatus(pedido.id, status);
                          Navigator.pop(ctx);
                        }
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.carregando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.pedidos.isEmpty) {
          return const Center(
            child: Text(
              "Nenhum pedido de insumo recebido.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Gestão de Pedidos de Clínicas",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2959),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade50,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Data',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Clínica',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Itens',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Ações',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: _controller.pedidos.map((pedido) {
                        int totalItens = pedido.itens.length;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                ).format(pedido.dataSolicitacao),
                              ),
                            ),
                            DataCell(
                              Text(
                                pedido.clinicaNome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text("$totalItens tipos de insumos")),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _obterCorStatus(
                                    pedido.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _obterCorStatus(pedido.status),
                                  ),
                                ),
                                child: Text(
                                  pedido.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _obterCorStatus(pedido.status),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              ElevatedButton.icon(
                                onPressed: () => _abrirModalStatus(pedido),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text("Atualizar"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
