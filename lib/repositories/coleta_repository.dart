import '../models/coleta_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../models/entregador_model.dart';

abstract class ColetaRepository {
  Future<List<Coleta>> buscarColetasNoRadar();
  Stream<List<Coleta>> streamColetasNoRadar();
  Stream<List<Coleta>> streamColetasPorEntregador(String entregadorId);
  Future<void> solicitarColeta(Coleta novaColeta);
  Future<Clinica> obterClinicaLogada();
  Future<Laboratorio> obterLaboratorioPadrao();
  Future<List<Entregador>> obterEntregadoresAtivos();

  /// Atualiza o status de um pedido/coleta no banco de dados
  Future<void> atualizarStatusColeta(String coletaId, String novoStatus);
}
