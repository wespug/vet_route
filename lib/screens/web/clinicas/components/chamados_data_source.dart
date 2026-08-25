import 'package:flutter/material.dart';
import 'package:vet_route/controllers/chamado_coleta_controller.dart';
import 'package:vet_route/models/item_logistica_model.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_detalhes_item_view.dart';

class ChamadosDataSource extends DataTableSource {
  final BuildContext context;
  final List<ItemLogisticaModel> itens;
  final Clinica clinicaContexto;
  final String usuarioLogado;

  ChamadosDataSource({
    required this.context,
    required this.itens,
    required this.clinicaContexto,
    required this.usuarioLogado,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= itens.length) return null;
    final item = itens[index];

    // Detecta se é urgência com base nas flags/textos do modelo
    bool isUrgencia =
        !item.isInsumo &&
        (item.nomeTipoFormatado.toLowerCase().contains('urgência') ||
            item.nomeTipoFormatado.toLowerCase().contains('urgencia') ||
            item.status.toLowerCase().contains('urgencia') ||
            item.codigo.toLowerCase().contains('urg'));

    Color corBg;
    Color corBorda;
    Color corTexto;
    IconData iconeTipo;
    String rotuloTipo;

    if (item.isInsumo) {
      // Insumo (Caixa Teal)
      corBg = Colors.teal.shade50;
      corBorda = Colors.teal.shade200;
      corTexto = Colors.teal.shade800;
      iconeTipo = Icons.inventory_2_rounded;
      rotuloTipo = 'Pedido de Insumo';
    } else if (isUrgencia) {
      // Coleta de Urgência (Raio Vermelho)
      corBg = Colors.red.shade50;
      corBorda = Colors.red.shade300;
      corTexto = Colors.red.shade800;
      iconeTipo = Icons.flash_on_rounded;
      rotuloTipo = 'Coleta de Urgência';
    } else {
      // Coleta Agendada Normal (Moto Azul)
      corBg = Colors.indigo.shade50;
      corBorda = Colors.indigo.shade200;
      corTexto = Colors.indigo.shade800;
      iconeTipo = Icons.motorcycle_rounded;
      rotuloTipo = 'Coleta Agendada';
    }

    return DataRow.byIndex(
      index: index,
      cells: [
        // Coluna Tipo
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: corBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: corBorda),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconeTipo, size: 14, color: corTexto),
                const SizedBox(width: 6),
                Text(
                  rotuloTipo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: corTexto,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Coluna Nova: Código
        DataCell(
          Text(
            "#${item.codigo}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
        // Coluna Laboratório Destino (Limpa)
        DataCell(
          Text(
            item.laboratorioNome,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        // Coluna Data
        DataCell(Text(item.formatarData(item.dataCriacao))),
        // Coluna Status
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: item.corStatus.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: item.corStatus.withOpacity(0.4)),
            ),
            child: Text(
              item.textoStatus,
              style: TextStyle(
                color: item.corStatus,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        // Coluna Ações
        DataCell(
          IconButton(
            icon: const Icon(
              Icons.visibility_outlined,
              size: 20,
              color: Colors.indigo,
            ),
            tooltip: 'Ver Detalhes e Histórico',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ModalDetalhesItemView(
                  item: item,
                  clinicaContexto: clinicaContexto,
                  usuarioLogado: usuarioLogado,
                  controller: ChamadoColetaController(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => itens.length;

  @override
  int get selectedRowCount => 0;
}
