import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coleta_model.dart';
import '../models/clinica_model.dart';
import '../models/laboratorio_model.dart';

// O Contrato (Interface) limpo
abstract class ColetaRepository {
  Future<List<Coleta>> buscarColetasNoRadar();
  Future<void> solicitarColeta(Coleta novaColeta);
  Future<Clinica> obterClinicaLogada();
  Future<Laboratorio> obterLaboratorioPadrao();
}

// A Implementação Real (Sem Mocks)
class FirestoreColetaRepository implements ColetaRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<List<Coleta>> buscarColetasNoRadar() async {
    final snapshot = await _db
        .collection('coletas')
        .where('status', isEqualTo: 'Aguardando')
        .get();

    return snapshot.docs.map((doc) => Coleta.fromFirestore(doc)).toList();
  }

  @override
  Future<void> solicitarColeta(Coleta novaColeta) async {
    await _db.collection('coletas').add(novaColeta.toMap());
  }

  @override
  Future<Clinica> obterClinicaLogada() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Nenhum usuário autenticado encontrado.");
    }

    final doc = await _db.collection('usuarios').doc(user.uid).get();
    if (!doc.exists) {
      throw Exception("Perfil da clínica não encontrado no banco de dados.");
    }

    return Clinica.fromFirestore(doc);
  }

  @override
  Future<Laboratorio> obterLaboratorioPadrao() async {
    // Busca o primeiro laboratório cadastrado no sistema para ser o destino da coleta
    final snapshot = await _db
        .collection('usuarios')
        .where('perfil', isEqualTo: 'laboratorio')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception(
        "Nenhum laboratório cadastrado no sistema para receber a coleta.",
      );
    }

    return Laboratorio.fromFirestore(snapshot.docs.first);
  }
}
