import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet_route/controllers/menu_controller.dart' as custom_menu;
import 'package:vet_route/controllers/submenu_controller.dart';
import 'package:vet_route/models/submenu_item_model.dart';

class GestaoSubmenusHub extends StatefulWidget {
  const GestaoSubmenusHub({super.key});

  @override
  State<GestaoSubmenusHub> createState() => _GestaoSubmenusHubState();
}

class _GestaoSubmenusHubState extends State<GestaoSubmenusHub> {
  final custom_menu.MenuController _menuController =
      custom_menu.MenuController();
  final SubmenuController _submenuController = SubmenuController();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController(
    text: '99',
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _submenuEdicaoId;
  String? _menuPaiSelecionado;
  String _iconeSelecionado = 'subdirectory_arrow_right';
  String _paginaSelecionada = 'clinica_gestao';
  bool _isWeb = true;
  bool _isMobile = false;

  // 🔎 VARIÁVEIS DE BUSCA, ORDENAÇÃO E PAGINAÇÃO
  String _searchQuery = '';
  int _currentPage = 0;
  final int _itemsPerPage = 20; // 👈 Limite de 20 registros por página
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  final Map<String, IconData> _iconesMapeados = {
    'subdirectory_arrow_right': Icons.subdirectory_arrow_right_rounded,
    'analytics': Icons.analytics_outlined,
    'assignment': Icons.assignment_outlined,
    'payments': Icons.payments_outlined,
    'inventory': Icons.inventory_2_outlined,
    'local_hospital': Icons.local_hospital,
    'science': Icons.science,
    'motorcycle': Icons.motorcycle,
    'people_alt': Icons.people_alt_rounded,
    'route': Icons.route_rounded,
    'hail': Icons.hail_rounded,
    'dashboard': Icons.dashboard_rounded,
  };

  // 🚀 MAPEAMENTO DE ROTAS OFICIAIS DO SAAS
  final Map<String, String> _paginasMapeadas = {
    'clinica_gestao': 'Gestão da Clínica (Web)',
    'lab_dashboard': 'Dashboard do Laboratório',
    'entregador_dashboard': 'Dashboard do Entregador',
    'entregador_direcionamento_coletas': 'Direcionar Coletas (Motoboy)',
    'lab_adicionar_usuario': 'Adicionar Usuários (Laboratório)',
    'clinica_adicionar_usuario': 'Adicionar Usuários (Clínica)',
    'lab_cadastro_exames': 'Cadastro de Exames',
    'lab_cadastro_insumos': 'Cadastro de Insumos',
    'lab_gestao_rotas': 'Gestão de Rotas Fixas',
    'clinica_dashboard': 'Dashboard da Clínica (Mobile)',
    'lab_pedidos_insumos': 'Gestão de Pedidos (Insumos)',
  };

  @override
  void initState() {
    super.initState();
    _menuController.carregarMenus();
    _submenuController.carregarSubmenus();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _pesoController.dispose();
    _menuController.dispose();
    _submenuController.dispose();
    super.dispose();
  }

  String _obterNomeMenuPai(String menuId) {
    try {
      return _menuController.menus.firstWhere((m) => m.id == menuId).titulo;
    } catch (e) {
      return 'Menu Pai Externo';
    }
  }

  void _entrarModoEdicao(SubmenuItemModel submenu) {
    setState(() {
      _submenuEdicaoId = submenu.id;
      _menuPaiSelecionado = submenu.menuId;
      _tituloController.text = submenu.titulo;
      _pesoController.text = submenu.peso.toString();
      _iconeSelecionado = _iconesMapeados.containsKey(submenu.icone)
          ? submenu.icone
          : 'subdirectory_arrow_right';
      _paginaSelecionada = _paginasMapeadas.containsKey(submenu.rota)
          ? submenu.rota
          : 'clinica_gestao';
      _isWeb = submenu.isWeb;
      _isMobile = submenu.isMobile;
    });
  }

  void _limparFormulario() {
    setState(() {
      _submenuEdicaoId = null;
      _menuPaiSelecionado = null;
      _tituloController.clear();
      _pesoController.text = '99';
      _iconeSelecionado = 'subdirectory_arrow_right';
      _paginaSelecionada = 'clinica_gestao';
      _isWeb = true;
      _isMobile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditando = _submenuEdicaoId != null;

    return ListenableBuilder(
      listenable: Listenable.merge([_menuController, _submenuController]),
      builder: (context, child) {
        return SingleChildScrollView(
          // 💡 PROTEÇÃO PRINCIPAL DO RENDERFLEX
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Evita expandir pro infinito
              children: [
                const Text(
                  "Gestão de Submenus",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                // === FORMULÁRIO DE CADASTRO ===
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _menuPaiSelecionado,
                                decoration: InputDecoration(
                                  labelText: "Menu Pai",
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _menuController.menus
                                    .map(
                                      (menu) => DropdownMenuItem(
                                        value: menu.id,
                                        child: Text(menu.titulo),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _menuPaiSelecionado = val),
                                validator: (v) =>
                                    v == null ? "Selecione o Menu Pai" : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _tituloController,
                                decoration: InputDecoration(
                                  labelText: "Nome do Submenu",
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? "Insira o nome"
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _pesoController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: "Ordem",
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? "Obrigatório"
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _iconeSelecionado,
                                decoration: InputDecoration(
                                  labelText: "Ícone",
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _iconesMapeados.keys
                                    .map(
                                      (key) => DropdownMenuItem(
                                        value: key,
                                        child: Row(
                                          children: [
                                            Icon(
                                              _iconesMapeados[key],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(key),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(
                                  () => _iconeSelecionado =
                                      val ?? 'subdirectory_arrow_right',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _paginaSelecionada,
                                decoration: InputDecoration(
                                  labelText: "Ecrã de Destino",
                                  fillColor: Colors.white,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _paginasMapeadas.keys
                                    .map(
                                      (key) => DropdownMenuItem(
                                        value: key,
                                        child: Text(_paginasMapeadas[key]!),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(
                                  () => _paginaSelecionada =
                                      val ?? 'clinica_gestao',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    "Visível em:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  FilterChip(
                                    label: const Text("Web"),
                                    selected: _isWeb,
                                    onSelected: (val) =>
                                        setState(() => _isWeb = val),
                                  ),
                                  const SizedBox(width: 12),
                                  FilterChip(
                                    label: const Text("Mobile"),
                                    selected: _isMobile,
                                    onSelected: (val) =>
                                        setState(() => _isMobile = val),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (isEditando)
                              TextButton(
                                onPressed: _limparFormulario,
                                child: const Text(
                                  "Cancelar",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _processarFormulario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                              icon: Icon(
                                isEditando ? Icons.save : Icons.add,
                                color: Colors.white,
                              ),
                              label: Text(
                                isEditando ? "Guardar" : "Adicionar",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // === LISTA COM BUSCA, ORDENAÇÃO E PAGINAÇÃO ===
                _submenuController.carregando || _menuController.carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTabelaAvancada(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processarFormulario() async {
    if (_formKey.currentState!.validate() && _menuPaiSelecionado != null) {
      if (!_isWeb && !_isMobile) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Marque ao menos uma plataforma"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final titulo = _tituloController.text.trim();
      final peso = int.tryParse(_pesoController.text.trim()) ?? 99;

      if (_submenuEdicaoId == null) {
        await _submenuController.adicionarSubmenu(
          _menuPaiSelecionado!,
          titulo,
          _iconeSelecionado,
          _paginaSelecionada,
          _isWeb,
          _isMobile,
          peso,
        );
      } else {
        await _submenuController.editarSubmenu(
          _submenuEdicaoId!,
          _menuPaiSelecionado!,
          titulo,
          _iconeSelecionado,
          _paginaSelecionada,
          _isWeb,
          _isMobile,
          peso,
        );
      }
      _limparFormulario();
    }
  }

  // 🛠️ NOVO WIDGET: TABELA TOTALMENTE DINÂMICA
  Widget _buildTabelaAvancada() {
    // 1. APLICAR BUSCA (FILTRO)
    List<SubmenuItemModel> filtrados = _submenuController.submenus.where((sub) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final tituloMatch = sub.titulo.toLowerCase().contains(q);
      final rotaMatch = (_paginasMapeadas[sub.rota] ?? sub.rota)
          .toLowerCase()
          .contains(q);
      final paiMatch = _obterNomeMenuPai(sub.menuId).toLowerCase().contains(q);
      return tituloMatch || rotaMatch || paiMatch;
    }).toList();

    // 2. APLICAR ORDENAÇÃO (SORT)
    filtrados.sort((a, b) {
      int result = 0;
      switch (_sortColumnIndex) {
        case 0:
          result = a.peso.compareTo(b.peso);
          break;
        case 1:
          result = _obterNomeMenuPai(
            a.menuId,
          ).compareTo(_obterNomeMenuPai(b.menuId));
          break;
        case 2:
          result = a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
          break;
        case 5:
          String destA = _paginasMapeadas[a.rota] ?? a.rota;
          String destB = _paginasMapeadas[b.rota] ?? b.rota;
          result = destA.toLowerCase().compareTo(destB.toLowerCase());
          break;
        default:
          result = a.peso.compareTo(b.peso);
      }
      return _isAscending ? result : -result;
    });

    // 3. APLICAR PAGINAÇÃO DE 20 EM 20
    int totalItems = filtrados.length;
    int totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }

    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;

    List<SubmenuItemModel> paginados = filtrados.isNotEmpty
        ? filtrados.sublist(startIndex, endIndex)
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min, // 💡 O SEGREDO DO LAYOUT LIMPO
      children: [
        // CABEÇALHO (TÍTULO E CAIXA DE BUSCA)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Registros Encontrados: $totalItems",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            SizedBox(
              width: 350,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar Submenu, Rota ou Menu Pai...',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 0; // Se buscou algo novo, volta pra página 1
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // CORPO DA TABELA
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _isAscending,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: [
                DataColumn(
                  label: const Text(
                    'Ordem',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onSort: (col, asc) => setState(() {
                    _sortColumnIndex = col;
                    _isAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text(
                    'Menu Pai',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onSort: (col, asc) => setState(() {
                    _sortColumnIndex = col;
                    _isAscending = asc;
                  }),
                ),
                DataColumn(
                  label: const Text(
                    'Submenu',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onSort: (col, asc) => setState(() {
                    _sortColumnIndex = col;
                    _isAscending = asc;
                  }),
                ),
                const DataColumn(
                  label: Text(
                    'Ícone',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Plataforma',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataColumn(
                  label: const Text(
                    'Destino',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onSort: (col, asc) => setState(() {
                    _sortColumnIndex = col;
                    _isAscending = asc;
                  }),
                ),
                const DataColumn(
                  label: Text(
                    'Ações',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              rows: paginados.map((sub) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        sub.peso.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text(_obterNomeMenuPai(sub.menuId))),
                    DataCell(
                      Text(
                        sub.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2959),
                        ),
                      ),
                    ),
                    DataCell(
                      Icon(
                        _iconesMapeados[sub.icone] ??
                            Icons.subdirectory_arrow_right,
                        size: 20,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (sub.isWeb)
                            const Icon(
                              Icons.laptop_mac,
                              size: 16,
                              color: Colors.blue,
                            ),
                          if (sub.isWeb && sub.isMobile)
                            const SizedBox(width: 8),
                          if (sub.isMobile)
                            const Icon(
                              Icons.smartphone,
                              size: 16,
                              color: Colors.green,
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        _paginasMapeadas[sub.rota] ?? sub.rota,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blue,
                              size: 20,
                            ),
                            onPressed: () => _entrarModoEdicao(sub),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                _submenuController.excluirSubmenu(sub.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        // CONTROLES DE PAGINAÇÃO (RODAPÉ)
        if (totalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Página ${_currentPage + 1} de $totalPages",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: _currentPage > 0
                          ? const Color(0xFF1F2959)
                          : Colors.grey.shade300,
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade300,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: _currentPage < totalPages - 1
                          ? const Color(0xFF1F2959)
                          : Colors.grey.shade300,
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
