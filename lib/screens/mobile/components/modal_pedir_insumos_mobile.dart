import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:vet_route/controllers/pedido_insumo_controller.dart';
import 'package:vet_route/controllers/insumo_controller.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/models/insumo_model.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/models/endereco_model.dart';

class ModalPedirInsumosMobile extends StatefulWidget {
  final PedidoInsumoController controller;
  final Clinica clinicaContexto;
  final String usuarioLogado;

  const ModalPedirInsumosMobile({
    super.key,
    required this.controller,
    required this.clinicaContexto,
    required this.usuarioLogado,
  });

  @override
  State<ModalPedirInsumosMobile> createState() =>
      _ModalPedirInsumosMobileState();
}

class _ModalPedirInsumosMobileState extends State<ModalPedirInsumosMobile> {
  final InsumoController _insumoController = InsumoController();
  bool _enviando = false;
  final Map<String, int> _quantidadesSelecionadas = {};
  String? _localLabIdSelecionado;

  @override
  void initState() {
    super.initState();
    // 🔹 Mesma regra da web: carrega assim que abre
    widget.controller.carregarLaboratorios();
  }

  @override
  void dispose() {
    _insumoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.teal,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Pedir Insumos",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: Colors.grey.shade400,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFE5E5EA)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "1. Selecione o Laboratório Parceiro",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.controller.isLoadingLab,
                  builder: (context, isLoadingLab, child) {
                    if (isLoadingLab) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    return ValueListenableBuilder<List<Laboratorio>>(
                      valueListenable: widget.controller.laboratorios,
                      builder: (context, laboratorios, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _localLabIdSelecionado,
                              icon: const Icon(
                                CupertinoIcons.chevron_down,
                                size: 16,
                              ),
                              hint: Text(
                                "Toque para escolher...",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                              items: laboratorios.map((lab) {
                                return DropdownMenuItem<String>(
                                  value: lab.id,
                                  child: Text(
                                    lab.nome.isNotEmpty ? lab.nome : 'Sem nome',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _localLabIdSelecionado = val;
                                  _quantidadesSelecionadas.clear();
                                  if (val != null) {
                                    _insumoController.carregarInsumos(val);
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _localLabIdSelecionado == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Aguardando seleção do laboratório.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ValueListenableBuilder<bool>(
                    valueListenable: _insumoController.isLoading,
                    builder: (context, isLoading, child) {
                      if (isLoading) {
                        return const Center(
                          child: CupertinoActivityIndicator(radius: 16),
                        );
                      }
                      return ValueListenableBuilder<List<InsumoModel>>(
                        valueListenable: _insumoController.insumos,
                        builder: (context, insumos, child) {
                          if (insumos.isEmpty) {
                            return Center(
                              child: Text(
                                "Nenhum insumo disponível.",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: insumos.length,
                            itemBuilder: (context, index) {
                              final insumo = insumos[index];
                              final qtd =
                                  _quantidadesSelecionadas[insumo.id!] ?? 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            insumo.descricao,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${insumo.tipo} • ${insumo.tamanho} • ${insumo.volume}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              CupertinoIcons.minus_circle_fill,
                                              color: qtd > 0
                                                  ? Colors.teal
                                                  : Colors.grey.shade400,
                                              size: 24,
                                            ),
                                            onPressed: qtd > 0
                                                ? () => setState(
                                                    () =>
                                                        _quantidadesSelecionadas[insumo
                                                                .id!] =
                                                            qtd - 1,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(
                                            width: 24,
                                            child: Text(
                                              '$qtd',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              CupertinoIcons.plus_circle_fill,
                                              color: Colors.teal,
                                              size: 24,
                                            ),
                                            onPressed: () => setState(
                                              () =>
                                                  _quantidadesSelecionadas[insumo
                                                          .id!] =
                                                      qtd + 1,
                                            ),
                                          ),
                                        ],
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
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _enviando ? null : _processarPedido,
                child: _enviando
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text(
                        "Confirmar Pedido de Insumos",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processarPedido() async {
    if (_localLabIdSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecione um laboratório primeiro."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final insumosSelecionados = _insumoController.insumos.value
        .where((i) => (_quantidadesSelecionadas[i.id!] ?? 0) > 0)
        .map(
          (i) => {
            'insumoId': i.id,
            'descricao': i.descricao,
            'tipo': i.tipo,
            'quantidade': _quantidadesSelecionadas[i.id!],
          },
        )
        .toList();

    if (insumosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Adicione a quantidade de pelo menos 1 item."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final labEncontrado = widget.controller.laboratorios.value.firstWhere(
        (l) => l.id == _localLabIdSelecionado,
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
        laboratorioId: _localLabIdSelecionado!,
        laboratorioNome: labEncontrado.nome,
        usuarioSolicitante: widget.usuarioLogado,
        itens: insumosSelecionados,
      );

      if (sucesso && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pedido enviado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}
