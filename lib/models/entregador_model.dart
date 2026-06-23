import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/models/perfil_usuario.dart';

class Entregador {
  final String? id;
  final String nome;
  final String telefone;
  final String veiculo;
  final double? latitude;
  final double? longitude;

  Entregador({
    this.id,
    required this.nome,
    required this.telefone,
    required this.veiculo,
    this.latitude,
    this.longitude,
  });

  // 💡 Resolve o erro: getter 'localizacao' isn't defined
  LatLng get localizacao {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    // Retorna uma coordenada zerada (padrão) caso o entregador esteja sem GPS
    return const LatLng(0, 0);
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'telefone': telefone,
      'veiculo': veiculo,
      'perfil': PerfilUsuario.entregadores.toFirestoreString,
      'longitude': longitude,
    };
  }

  factory Entregador.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Entregador(
      id: docId,
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      veiculo: map['veiculo'] ?? '',
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
    );
  }

  // 💡 Resolve o erro: Member not found: 'Entregador.fromFirestore'
  factory Entregador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Entregador.fromMap(data, doc.id);
  }
}
