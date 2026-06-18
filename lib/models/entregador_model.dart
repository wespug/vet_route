import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Entregador {
  final String id;
  final String nome;
  final LatLng localizacao;
  final bool disponivel;

  Entregador({
    required this.id,
    required this.nome,
    required this.localizacao,
    required this.disponivel,
  });

  factory Entregador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geo = data['localizacao'] as GeoPoint;

    return Entregador(
      id: doc.id,
      nome: data['nome'] ?? 'Entregador',
      disponivel: data['disponivel'] ?? false,
      localizacao: LatLng(geo.latitude, geo.longitude),
    );
  }
}
