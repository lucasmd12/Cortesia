import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/qrr_model.dart';
import 'package:lucasbeatsfederacao/services/qrr_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/screens/qrr_detail_screen.dart';
import 'package:lucasbeatsfederacao/screens/qrr_create_screen.dart';
import 'package:lucasbeatsfederacao/screens/qrr_edit_screen.dart';
import 'package:lucasbeatsfederacao/screens/qrr_participants_screen.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/widgets/immersive/parallax_scaffold.dart';

class QRRListScreen extends StatefulWidget {
  final String? clanId;
  final String? federationId;

  const QRRListScreen({super.key, this.clanId, this.federationId});

  @override
  State<QRRListScreen> createState() => _QRRListScreenState();
}

class _QRRListScreenState extends State<QRRListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<QRRModel> _allQRRs = [];
  bool _isLoading = true;
  String? _error;
  QRRType? _selectedType;
  QRRPriority? _selectedPriority;
  QRRStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadQRRs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQRRs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        setState(() {
          _error = 'Usuário não autenticado';
          _isLoading = false;
        });
        return;
      }

      final qrrService = QRRService(Provider.of<ApiService>(context, listen: false));
      List<QRRModel> qrrs;

      if (widget.clanId != null) {
        qrrs = await qrrService.getQRRsByClan(widget.clanId!);
      } else if (widget.federationId != null) {
        Logger.warning('Funcionalidade de QRR por Federação não implementada no serviço.');
        qrrs = [];
      } else if (currentUser.role == Role.admMaster) {
        qrrs = await qrrService.getAllQRRs();
      } else if (currentUser.clanId != null) {
        qrrs = await qrrService.getQRRsByClan(currentUser.clanId!);
      } else {
        setState(() {
          _error = 'Usuário não pertence a um clã/federação e não é ADM Master';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _allQRRs = qrrs;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar QRRs', error: e);
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar QRRs: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildQRRList(List<QRRModel> qrrs, String emptyMessage) {
    if (qrrs.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    } else {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: qrrs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final qrr = qrrs[index];
          return _buildQRRCard(qrr);
        },
      );
    }
  }

  List<QRRModel> get _filteredQRRs {
    var filtered = _allQRRs;

    if (_selectedType != null) {
      filtered = filtered.where((qrr) => qrr.type == _selectedType).toList();
    }
    if (_selectedPriority != null) {
      filtered = filtered.where((qrr) => qrr.priority == _selectedPriority).toList();
    }
    if (_selectedStatus != null) {
      filtered = filtered.where((qrr) => qrr.status == _selectedStatus).toList();
    }

    return filtered;
  }

  List<QRRModel> get _activeQRRs => _filteredQRRs.where((qrr) => qrr.status.isActive).toList();
  List<QRRModel> get _pendingQRRs => _filteredQRRs.where((qrr) => qrr.status.isPending).toList();
  List<QRRModel> get _completedQRRs => _filteredQRRs.where((qrr) => qrr.status.isCompleted).toList();
  List<QRRModel> get _rulesQRRs => _filteredQRRs.where((qrr) => qrr.type == QRRType.rule).toList();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final canManageQRR = currentUser?.role == Role.admMaster ||
                        currentUser?.role == Role.leader ||
                        currentUser?.role == Role.subLeader;

    return ParallaxScaffold(
      backgroundType: ParallaxBackground.qrr,
      appBar: AppBar(
        title: const Text('Missões QRR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _loadQRRs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.redAccent,
          tabs: [
            Tab(
              text: 'Ativas',
              icon: Badge(
                label: Text('${_activeQRRs.length}'),
                child: const Icon(Icons.play_arrow),
              ),
            ),
            Tab(
              text: 'Pendentes',
              icon: Badge(
                label: Text('${_pendingQRRs.length}'),
                child: const Icon(Icons.schedule),
              ),
            ),
            Tab(
              text: 'Concluídas',
              icon: Badge(
                label: Text('${_completedQRRs.length}'),
                child: const Icon(Icons.check_circle),
              ),
            ),
            Tab(
              text: 'Regras',
              icon: Badge(
                label: Text('${_rulesQRRs.length}'),
                child: const Icon(Icons.gavel),
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: canManageQRR
          ? FloatingActionButton(
              onPressed: () => _navigateToCreateQRR(),
              backgroundColor: Colors.red.shade700,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQRRs,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildQRRList(_activeQRRs, 'Nenhuma missão ativa'),
        _buildQRRList(_pendingQRRs, 'Nenhuma missão pendente'),
        _buildQRRList(_completedQRRs, 'Nenhuma missão concluída'),
        _buildQRRList(_rulesQRRs, 'Nenhuma regra definida'),
      ],
    );
  }

  Widget _buildQRRCard(QRRModel qrr) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isParticipant = currentUser != null && qrr.userIsParticipant(currentUser.id);
    final canEdit = currentUser?.role == Role.admMaster ||
                    (currentUser?.role == Role.leader && qrr.createdBy == currentUser?.id);
    final canManageParticipants = currentUser?.role == Role.admMaster ||
                                  (currentUser?.role == Role.leader && qrr.clanId == currentUser?.clanId);


    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: qrr.priority.color.withOpacity(0.6)),
      ),
      child: InkWell(
        onTap: () => _navigateToQRRDetail(qrr),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    qrr.type.icon,
                    color: qrr.priority.color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      qrr.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: qrr.status.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: qrr.status.color),
                    ),
                    child: Text(
                      qrr.status.displayName,
                      style: TextStyle(
                        color: qrr.status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                qrr.description,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(color: Colors.white38, height: 24),
              Row(
                children: [
                  _buildInfoChip(Icons.people, '${qrr.participantCount}${qrr.maxParticipants != null ? '/${qrr.maxParticipants}' : ''}'),
                  const Spacer(),
                  _buildInfoChip(Icons.flag, qrr.priority.displayName, color: qrr.priority.color),
                  const Spacer(),
                  if (isParticipant)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                      child: const Text('Participando', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (canEdit || canManageParticipants) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canManageParticipants)
                      IconButton(
                        icon: const Icon(Icons.group, color: Colors.blueAccent),
                        onPressed: () => _navigateToQRRParticipants(qrr),
                        tooltip: 'Gerenciar Participantes',
                      ),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                        onPressed: () => _navigateToQRREdit(qrr),
                        tooltip: 'Editar QRR',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.grey[400], size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color ?? Colors.grey[300], fontSize: 12)),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<QRRType?>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [
                  const DropdownMenuItem<QRRType?>(
                    value: null,
                    child: Text('Todos os tipos'),
                  ),
                  ...QRRType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )),
                ],
                onChanged: (value) => setDialogState(() => _selectedType = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<QRRPriority?>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: [
                  const DropdownMenuItem<QRRPriority?>(
                    value: null,
                    child: Text('Todas as prioridades'),
                  ),
                  ...QRRPriority.values.map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority.displayName),
                  )),
                ],
                onChanged: (value) => setDialogState(() => _selectedPriority = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<QRRStatus?>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem<QRRStatus?>(
                    value: null,
                    child: Text('Todos os status'),
                  ),
                  ...QRRStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  )),
                ],
                onChanged: (value) => setDialogState(() => _selectedStatus = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedType = null;
                _selectedPriority = null;
                _selectedStatus = null;
              });
              _loadQRRs();
            },
            child: const Text('Limpar Filtros'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _navigateToQRRDetail(QRRModel qrr) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRRDetailScreen(qrr: qrr),
      ),
    ).then((_) => _loadQRRs());
  }

  void _navigateToCreateQRR() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRRCreateScreen(),
      ),
    ).then((_) => _loadQRRs());
  }

  void _navigateToQRREdit(QRRModel qrr) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRREditScreen(qrr: qrr),
      ),
    ).then((_) => _loadQRRs());
  }

  void _navigateToQRRParticipants(QRRModel qrr) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRRParticipantsScreen(qrr: qrr),
      ),
    ).then((_) => _loadQRRs());
  }
}
