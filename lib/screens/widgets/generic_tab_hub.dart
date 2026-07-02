import 'package:flutter/material.dart';

// 💡 MODELO DE DADOS DA ABA
class TabItemModel {
  final String titulo;
  final Widget conteudo;

  TabItemModel({required this.titulo, required this.conteudo});
}

// 💡 O WIDGET MESTRE REUTILIZÁVEL
class GenericTabHub extends StatefulWidget {
  final List<TabItemModel> abas;

  const GenericTabHub({super.key, required this.abas});

  @override
  State<GenericTabHub> createState() => _GenericTabHubState();
}

class _GenericTabHubState extends State<GenericTabHub> {
  int _indiceAbaAtual = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.abas.isEmpty) {
      return const Center(child: Text("Nenhuma aba configurada."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. BARRA DE SUBMENUS HORIZONTAL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(widget.abas.length, (index) {
                final aba = widget.abas[index];
                final isSelecionada = _indiceAbaAtual == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _indiceAbaAtual = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelecionada
                            ? const Color(0xFF007BFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        aba.titulo,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelecionada
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelecionada
                              ? Colors.white
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 2. ÁREA DE CONTEÚDO CENTRAL DINÂMICA
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            // Renderiza o Widget correspondente à aba clicada de forma isolada
            child: widget.abas[_indiceAbaAtual].conteudo,
          ),
        ),
      ],
    );
  }
}
