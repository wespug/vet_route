import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/controllers/insumo_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/insumo_model.dart';

class ModalPedirInsumos extends StatefulWidget {
  final ChamadoColetaController controller;
  final Clinica clinicaContexto;
  final String usuarioLogado;

  const ModalPedirInsumos({
    super.key,
    required this.controller,
    required this.clinicaContexto,
    required this.usuarioLogado,
  });

  @override
  State<ModalPedirInsumos> createState() => _ModalPedirInsumosState();
}

class _ModalPedirInsumosState extends State<ModalPedirInsumos> {
  final InsumoController insumoController = InsumoController();
  bool enviando = false;
  final Map<String, int> quantidadesSelecionadas = {};
  String? localLabIdSelecionado;

  @override
  void dispose() {
    insumoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.inventory_2_rounded, color: Colors.teal),
          SizedBox(width: 10),
          Text(
            "Solicitar Insumos ao Laboratório",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Escolha o laboratório parceiro e os materiais desejados.",
                style: TextStyle(color: Colors.teal, fontSize: 13, height: 1.3),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: widget.controller.laboratorios,
              builder: (context, laboratorios, child) {
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: laboratorios.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['id'] as String,
                      child: Text(item['nome'] as String),
                    );
                  }).toList(),
                  value: localLabIdSelecionado,
                  hint: const Text("Selecione um laboratório"),
                  onChanged: (val) {
                    setState(() {
                      localLabIdSelecionado = val;
                      if (val != null) {
                        quantidadesSelecionadas.clear();
                        insumoController.carregarInsumos(val);
                      }
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: localLabIdSelecionado == null
                  ? const Center(
                      child: Text(
                        "Selecione um laboratório para ver os insumos disponíveis.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ValueListenableBuilder<bool>(
                      valueListenable: insumoController.isLoading,
                      builder: (context, isLoading, child) {
                        if (isLoading)
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.teal,
                            ),
                          );
                        return ValueListenableBuilder<List<InsumoModel>>(
                          valueListenable: insumoController.insumos,
                          builder: (context, insumos, child) {
                            if (insumos.isEmpty)
                              return const Center(
                                child: Text(
                                  "Nenhum insumo cadastrado neste laboratório.",
                                ),
                              );
                            return ListView.separated(
                              itemCount: insumos.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final insumo = insumos[index];
                                final qtd =
                                    quantidadesSelecionadas[insumo.id] ?? 0;
                                return ListTile(
                                  title: Text(
                                    insumo.descricao,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${insumo.tipo} • ${insumo.tamanho} • ${insumo.volume}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: qtd > 0
                                            ? () => setState(
                                                () =>
                                                    quantidadesSelecionadas[insumo
                                                            .id!] =
                                                        qtd - 1,
                                              )
                                            : null,
                                      ),
                                      Text(
                                        '$qtd',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.teal,
                                        ),
                                        onPressed: () => setState(
                                          () =>
                                              quantidadesSelecionadas[insumo
                                                      .id!] =
                                                  qtd + 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: enviando ? null : () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: enviando
              ? null
              : () async {
                  if (localLabIdSelecionado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Selecione o Laboratório!")),
                    );
                    return;
                  }
                  final insumosSelecionados = insumoController.insumos.value
                      .where((i) => (quantidadesSelecionadas[i.id!] ?? 0) > 0)
                      .map(
                        (i) => {
                          'insumoId': i.id,
                          'descricao': i.descricao,
                          'tipo': i.tipo,
                          'quantidade': quantidadesSelecionadas[i.id!],
                        },
                      )
                      .toList();

                  if (insumosSelecionados.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Selecione ao menos 1 item!"),
                      ),
                    );
                    return;
                  }
                  setState(() => enviando = true);
                  try {
                    final labInfo = widget.controller.laboratorios.value
                        .firstWhere(
                          (l) => l['id'] == localLabIdSelecionado,
                          orElse: () => {'nome': 'Laboratório Parceiro'},
                        );
                    await FirebaseFirestore.instance
                        .collection('pedidos_insumos')
                        .add({
                          'clinicaId': widget.clinicaContexto.id,
                          'clinicaNome': widget.clinicaContexto.nome,
                          'laboratorioId': localLabIdSelecionado,
                          'laboratorioNome': labInfo['nome'],
                          'status': 'Pendente',
                          'dataSolicitacao': FieldValue.serverTimestamp(),
                          'historico': [
                            {
                              'status': 'Pendente',
                              'data': DateTime.now().toIso8601String(),
                              'observacao':
                                  'Pedido de insumos realizado por: ${widget.usuarioLogado}',
                            },
                          ],
                          'itens': insumosSelecionados,
                        });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pedido enviado com sucesso!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Erro ao salvar pedido WEB: $e");
                    setState(() => enviando = false);
                  }
                },
          child: enviando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Confirmar Pedido",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
