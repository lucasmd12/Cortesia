import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/federation_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/immersive/parallax_scaffold.dart';
// 1. IMPORT DO NOVO WIDGET REUTILIZÁVEL
import 'package:lucasbeatsfederacao/widgets/maps/federation_control_panel.dart';


class FederationManagementScreen extends StatefulWidget {
  final String federationId;

  const FederationManagementScreen({super.key, required this.federationId});

  @override
  State<FederationManagementScreen> createState() => _FederationManagementScreenState();
}

class _FederationManagementScreenState extends State<FederationManagementScreen> {
  Federation? _federation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFederationDetails();
  }

  Future<void> _loadFederationDetails() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      final service = Provider.of<FederationService>(context, listen: false);
      final details = await service.getFederationDetails(widget.federationId);
      if (mounted) {
        setState(() {
          _federation = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Erro ao carregar detalhes da federação', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    final bool canManage = currentUser != null && (
      (currentUser.federationId == widget.federationId && currentUser.federationRole == Role.federationLeader) ||
      currentUser.role == Role.admMaster
    );

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acesso Negado')),
        body: const Center(child: Text('Você não tem permissão para gerenciar esta federação.')),
      );
    }

    return ParallaxScaffold(
      fallbackType: ParallaxBackground.sky,
      appBar: AppBar(
        title: Text(_federation?.name ?? 'Gerenciar Federação'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _federation == null
              ? const Center(child: Text('Federação não encontrada.', style: TextStyle(color: Colors.white)))
              // 2. A LÓGICA DA UI FOI SUBSTITUÍDA PELA CHAMADA AO NOVO WIDGET
              : FederationControlPanel(federation: _federation!),
    );
  }

  // 3. AS FUNÇÕES _buildManagementGrid e _buildActionButton FORAM REMOVIDAS
  //    POIS SUA LÓGICA AGORA VIVE DENTRO DO FederationControlPanel.
}
