import 'package:flutter/material.dart';
import 'package:vet_route/controllers/pedido_insumo_controller.dart';
import 'package:vet_route/controllers/insumo_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/insumo_model.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/endereco_model.dart';

class ModalPedirInsumos extends StatefulWidget {
  final PedidoInsumoController controller;
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
  void initState() {
    super.initState();
    // 🔹 Garante que os laboratórios serão carregados assim que a modal abrir
    widget.controller.carregarLaboratorios();
  }

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
            ValueListenableBuilder<bool>(
              valueListenable: widget.controller.isLoadingLab,
              builder: (context, isLoadingLab, child) {
                if (isLoadingLab) {
                  return const Center(
                    child: LinearProgressIndicator(color: Colors.teal),
                  );
                }
                return ValueListenableBuilder<List<Laboratorio>>(
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
                      items: laboratorios.map((lab) {
                        return DropdownMenuItem<String>(
                          value: lab.id,
                          child: Text(
                            lab.nome.isNotEmpty
                                ? lab.nome
                                : 'Laboratório sem nome',
                          ),
                        );
                      }).toList(),
                      value: localLabIdSelecionado,
                      hint: const Text("Selecione um laboratório"),
                      onChanged: (val) {
                        setState(() {
                          localLabIdSelecionado = val;
                          quantidadesSelecionadas.clear();
                          if (val != null) {
                            insumoController.carregarInsumos(val);
                          }
                        });
                      },
                    );
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
                        if (isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.teal,
                            ),
                          );
                        }
                        return ValueListenableBuilder<List<InsumoModel>>(
                          valueListenable: insumoController.insumos,
                          builder: (context, insumos, child) {
                            if (insumos.isEmpty) {
                              return const Center(
                                child: Text(
                                  "Nenhum insumo cadastrado neste laboratório.",
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: insumos.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final insumo = insumos[index];
                                final qtd =
                                    quantidadesSelecionadas[insumo.id!] ?? 0;
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
                    final listaLabs = widget.controller.laboratorios.value;
                    final labEncontrado = listaLabs.firstWhere(
                      (l) => l.id == localLabIdSelecionado,
                      orElse: () => Laboratorio(
                        id: '',
                        nome: 'Laboratório Parceiro',
                        email: '',
                        telefone: '',
                        cnpj: '',
                        endereco: Endereco(
                          logradouro: '',
                          numero: '',
                          bairro: '',
                          cidade: '',
                          estado: '',
                          cep: '',
                        ),
                      ),
                    );

                    final sucesso = await widget.controller.criarPedido(
                      clinicaId: widget.clinicaContexto.id!,
                      clinicaNome: widget.clinicaContexto.nome,
                      laboratorioId: localLabIdSelecionado!,
                      laboratorioNome: labEncontrado.nome,
                      usuarioSolicitante: widget.usuarioLogado,
                      itens: insumosSelecionados,
                    );

                    if (sucesso && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pedido enviado com sucesso!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint("Erro ao salvar pedido de insumos WEB: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erro ao enviar pedido: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => enviando = false);
                    }
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
