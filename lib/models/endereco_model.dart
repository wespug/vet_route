import 'package:google_maps_flutter/google_maps_flutter.dart';

class Endereco {
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado; // UF
  final double? latitude;
  final double? longitude;

  Endereco({
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.latitude,
    this.longitude,
  });

  LatLng? get coordenada {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  // 💡 NOVO: Getter para formatar o endereço completo de forma padronizada
  String get enderecoCompleto {
    List partes = [];
    if (logradouro.trim().isNotEmpty) partes.add(logradouro.trim());
    if (numero.trim().isNotEmpty) partes.add(numero.trim());

    String texto = partes.join(', ');
    if (bairro.trim().isNotEmpty) {
      texto += ' - ${bairro.trim()}';
    }

    return texto.isNotEmpty ? texto : 'Endereço não informado!!!!';
  }

  Map toMap() {
    return {
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Constrói o objeto Dart a partir do Map do Firebase blindado contra dados legados
  factory Endereco.fromMap(dynamic dataMap) {
    // Se vier nulo ou não for um Mapa, retorna um Endereço vazio com segurança
    if (dataMap == null || dataMap is! Map) return Endereco();

    return Endereco(
      cep: dataMap['cep']?.toString() ?? '',
      // 💡 Aceita as chaves antigas que você tinha no banco
      logradouro:
          dataMap['logradouro']?.toString() ??
          dataMap['rua']?.toString() ??
          dataMap['endereco']?.toString() ??
          dataMap['street']?.toString() ??
          '',
      numero:
          dataMap['numero']?.toString() ?? dataMap['number']?.toString() ?? '',
      complemento: dataMap['complemento']?.toString() ?? '',
      bairro:
          dataMap['bairro']?.toString() ??
          dataMap['neighborhood']?.toString() ??
          '',
      cidade: dataMap['cidade']?.toString() ?? '',
      estado: dataMap['estado']?.toString() ?? dataMap['uf']?.toString() ?? '',
      latitude: dataMap['latitude'] != null
          ? (dataMap['latitude'] as num).toDouble()
          : null,
      longitude: dataMap['longitude'] != null
          ? (dataMap['longitude'] as num).toDouble()
          : null,
    );
  }
}
