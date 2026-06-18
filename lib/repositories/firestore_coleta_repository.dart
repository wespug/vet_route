// lib/repositories/firestore_coleta_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vet_route/models/endereco_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';
import '../models/coleta_model.dart';
import 'coleta_repository.dart';

class FirestoreColetaRepository implements ColetaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Clinica> obterClinicaLogada() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Nenhum usuário autenticado no Firebase Auth!");
    }

    // 💡 LOG CIRÚRGICO DE DEBUG:
    debugPrint(
      "🔍 DEBUG: O App está procurando na coleção 'clinicas' pelo documento com ID: ${user.uid}",
    );

    final doc = await _firestore.collection('clinicas').doc(user.uid).get();

    if (!doc.exists) {
      debugPrint("❌ DEBUG: Documento ${user.uid} NÃO EXISTE no Firestore!");
      throw Exception(
        "Perfil da clínica não encontrado para o UID: ${user.uid}",
      );
    }

    return Clinica.fromFirestore(doc);
  }

  @override
  Future<Laboratorio> obterLaboratorioPadrao() async {
    // Temporariamente retorna um mock fixo para não travar a tela da Clínica.
    // Futuramente, buscaremos isso de uma coleção 'laboratorios' no Firestore!
    return Laboratorio(
      id: 'L999',
      nome: 'Laboratório Vet Route Express',
      telefone: '(11) 4444-4444',
      endereco: Endereco(
        nome: 'Lab Express',
        rua: 'Rua Augusta, 500',
        cep: '01304-000',
        cidade: 'São Paulo',
        estado: 'SP',
        pais: 'Brasil',
        coordenada: const LatLng(-23.553950, -46.651260),
      ),
    );
  }

  @override
  Future<List<Coleta>> buscarColetasNoRadar() async => [];

  @override
  Future<void> solicitarColeta(Coleta novaColeta) async {}
}
