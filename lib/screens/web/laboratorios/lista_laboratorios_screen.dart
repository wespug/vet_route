import 'package:flutter/material.dart';
import 'package:vet_route/controllers/laboratorio_admin_controller.dart';
import 'package:vet_route/models/laboratorio_model.dart';
import 'package:vet_route/screens/web/admin_chassi.dart';
import 'package:vet_route/screens/web/laboratorios/cadastro_laboratorio_screen.dart';
import 'package:vet_route/screens/web/laboratorios/datalhe_laboratorio_hub.dart';

class ListaLaboratoriosScreen extends StatefulWidget {
  const ListaLaboratoriosScreen({Key? key}) : super(key: key);

  @override
  State<ListaLaboratoriosScreen> createState() =>
      _ListaLaboratoriosScreenState();
}

class _ListaLaboratoriosScreenState extends State<ListaLaboratoriosScreen> {
  final LaboratorioAdminController _controller = LaboratorioAdminController();

  @override
  void initState() {
    super.initState();
    // MÁGICA: Inicia a busca em tempo real assim que a tela abre
    _controller.ouvirLaboratorios();
  }

  @override
  void dispose() {
    // Sempre limpe o controller quando a tela for fechada para economizar memória
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fundo mais limpo e moderno
      appBar: AppBar(
        title: const Text(
          "Gestão de Laboratórios",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),

      // REQUISITO 1: Botão flutuante para cadastrar novo laboratório
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CadastroLaboratorioScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Novo Laboratório"),
      ),

      // REQUISITO 2: Ver a lista de todos os laboratórios
      body: ValueListenableBuilder<List<Laboratorio>>(
        valueListenable: _controller.laboratorios,
        builder: (context, lista, child) {
          // Tratamento de UX: O que mostrar se não houver laboratórios?
          if (lista.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Nenhum laboratório encontrado.",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final lab = lista[index];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.biotech,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(
                    lab.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text("CNPJ: ${lab.cnpj ?? 'Não informado'}"),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) =>
                            AdminChassi(
                              titulo: 'Painel: ${lab.nome}',
                              conteudo: DetalheLaboratorioHub(laboratorio: lab),
                            ),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
