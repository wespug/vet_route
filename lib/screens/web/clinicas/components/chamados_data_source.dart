import 'package:flutter/material.dart';
import 'package:vet_route/models/chamado_coleta_model.dart';
import 'package:vet_route/models/clinica_model.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_detalhes_coleta.dart';
import 'package:vet_route/screens/web/clinicas/modal/modal_detalhes_insumo.dart';
import 'package:vet_route/screens/web/laboratorios/util/status_pedido_helper.dart';

class ChamadosDataSource extends DataTableSource {
  final BuildContext context;
  final List<ChamadoColetaModel> chamados;
  final Clinica clinicaContexto;
  final String usuarioLogado;

  ChamadosDataSource({
    required this.context,
    required this.chamados,
    required this.clinicaContexto,
    required this.usuarioLogado,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= chamados.length) return null;
    final chamado = chamados[index];

    final String dataFormatada =
        "${chamado.dataAgendamento.day.toString().padLeft(2, '0')}/${chamado.dataAgendamento.month.toString().padLeft(2, '0')}/${chamado.dataAgendamento.year}";

    final corStatus = StatusPedidoHelper.obterCorStatus(chamado.status);
    final corFundoStatus = StatusPedidoHelper.obterCorFundoStatus(
      chamado.status,
    );
    final labelStatus = StatusPedidoHelper.obterLabelStatus(chamado.status);

    final bool isInsumo = chamado.laboratorioId.startsWith('INSUMO_');

    IconData iconeTipo;
    Color corTipo;
    Color corFundoTipo;

    if (isInsumo) {
      iconeTipo = Icons.inventory_2_rounded;
      corTipo = Colors.teal;
      corFundoTipo = Colors.teal.shade50;
    } else if (chamado.isEmergencia) {
      iconeTipo = Icons.flash_on_rounded;
      corTipo = Colors.redAccent.shade700;
      corFundoTipo = Colors.red.shade50;
    } else {
      iconeTipo = Icons.motorcycle_rounded;
      corTipo = Colors.indigo;
      corFundoTipo = Colors.indigo.shade50;
    }

    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: corFundoTipo,
              shape: BoxShape.circle,
            ),
            child: Icon(iconeTipo, color: corTipo, size: 20),
          ),
        ),
        DataCell(
          Text(
            chamado.laboratorioNome,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
        ),
        DataCell(Text(dataFormatada)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: corFundoStatus,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: corStatus.withOpacity(0.4)),
            ),
            child: Text(
              labelStatus,
              style: TextStyle(
                color: corStatus,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
            onPressed: () {
              if (isInsumo) {
                showDialog(
                  context: context,
                  builder: (_) => ModalDetalhesInsumo(
                    chamado: chamado,
                    clinicaContexto: clinicaContexto,
                    usuarioLogado: usuarioLogado,
                    obterCorStatus: StatusPedidoHelper.obterCorStatus,
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => ModalDetalhesColeta(
                    chamado: chamado,
                    clinicaContexto: clinicaContexto,
                    usuarioLogado: usuarioLogado,
                    obterCorStatus: StatusPedidoHelper.obterCorStatus,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => chamados.length;
  @override
  int get selectedRowCount => 0;
}
