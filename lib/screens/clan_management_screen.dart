import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/immersive/parallax_scaffold.dart';
// 1. IMPORT DO NOVO WIDGET
import 'package:lucasbeatsfederacao/widgets/maps/clan_control_panel.dart';


class ClanManagementScreen extends StatefulWidget {
  final String clanId;

  const ClanManagementScreen({super.key, required this.clanId});

  @override
  State<ClanManagementScreen> createState() => _ClanManagementScreenState();
}

class _ClanManagementScreenState extends State<ClanManagementScreen> {
  Clan? _clan;
  bool _isLoadingClan = true;

  @override
  void initState() {
    super.initState();
    _loadClanDetails();
  }

  Future<void> _loadClanDetails() async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingClan = true);
      final clanService = Provider.of<ClanService>(context, listen: false);
      final clanDetails = await clanService.getClanDetails(widget.clanId);
      if (mounted) {
        setState(() {
          _clan = clanDetails;
          _isLoadingClan = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar detalhes do clã', error: e);
      if (mounted) {
        setState(() {
          _isLoadingClan = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    final bool canAccess = currentUser != null && (
      currentUser.clanId == widget.clanId ||
      currentUser.role == Role.admMaster
    );

    if (!canAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso Negado')),
        body: const Center(child: Text('Você não tem permissão para ver esta página.')),
      );
    }

    return ParallaxScaffold(
      customAssetPath: _clan?.bannerImageUrl,
      fallbackType: ParallaxBackground.qrr,
      appBar: AppBar(
        title: Text(_clan?.name ?? 'Gerenciamento do Clã'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoadingClan
          ? const Center(child: CircularProgressIndicator())
          : _clan == null
              ? const Center(child: Text('Clã não encontrado.', style: TextStyle(color: Colors.white)))
              // 2. SUBSTITUIÇÃO DA LÓGICA DA UI PELA CHAMADA AO NOVO WIDGET
              : ClanControlPanel(clan: _clan!),
    );
  }

  // 3. AS FUNÇÕES _buildManagementGrid e _buildActionButton FORAM REMOVIDAS
  //    POIS SUA LÓGICA AGORA VIVE DENTRO DO ClanControlPanel.
}
