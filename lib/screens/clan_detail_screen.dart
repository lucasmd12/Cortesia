import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/providers/map_navigation_provider.dart';
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/services/permission_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/immersive/parallax_scaffold.dart';
import 'package:lucasbeatsfederacao/screens/clan_management_screen.dart';
import 'package:lucasbeatsfederacao/screens/tabs/members_tab.dart';

// 1. IMPORT DAS TELAS NECESSÁRIAS
import 'package:lucasbeatsfederacao/screens/clan_text_chat_screen.dart';
import 'package:lucasbeatsfederacao/screens/qrr_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/instaclan_feed_screen.dart';
import 'package:lucasbeatsfederacao/screens/clan_flag_upload_screen.dart';

class ClanDetailScreen extends StatefulWidget {
  final Clan clan;
  final bool fromMap;

  const ClanDetailScreen({
    super.key,
    required this.clan,
    this.fromMap = false,
  });

  @override
  State<ClanDetailScreen> createState() => _ClanDetailScreenState();
}

class _ClanDetailScreenState extends State<ClanDetailScreen> {
  List<Clan> _clansForWar = [];
  bool _isLoadingForWar = false;
  late final PermissionService _permissionService;
  late String _currentFlagUrl;

  @override
  void initState() {
    super.initState();
    _currentFlagUrl = widget.clan.flag ?? '';
    _permissionService = Provider.of<PermissionService>(context, listen: false);
    if (_permissionService.canDeclareWar(widget.clan)) {
      _loadClansForWarDeclaration();
    }
  }

  Future<void> _loadClansForWarDeclaration() async {
    setState(() => _isLoadingForWar = true);
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      final clans = await clanService.getAllClans();
      if (mounted) {
        setState(() {
          _clansForWar = clans.where((c) => c.id != widget.clan.id).toList();
        });
      }
    } catch (e, s) {
      Logger.error("Erro ao carregar clãs para guerra:", error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _isLoadingForWar = false);
    }
  }

  void _showDeclareWarDialog() {
    // ... (código existente)
  }

  // 2. NAVEGAÇÃO PARA A TELA DE UPLOAD DE BANDEIRA
  void _navigateToFlagUpload() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClanFlagUploadScreen(
          clanId: widget.clan.id,
          clanName: widget.clan.name,
          currentFlag: _currentFlagUrl,
          onFlagUpdated: (newFlagUrl) {
            setState(() {
              _currentFlagUrl = newFlagUrl;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canManage = _permissionService.canManageClan(widget.clan);

    return ParallaxScaffold(
      customAssetPath: widget.clan.bannerImageUrl,
      fallbackType: ParallaxBackground.qrr,
      appBar: AppBar(
        title: Text(widget.clan.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.fromMap
            ? IconButton(
                icon: const Icon(Icons.arrow_downward),
                tooltip: 'Voltar ao Mapa',
                onPressed: () {
                  Provider.of<MapNavigationProvider>(context, listen: false).zoomOut();
                  Navigator.of(context).pop();
                },
              )
            : null,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(canManage),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _buildActionGrid(context, canManage),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool canManage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 80),
          // 3. TRANSFORMA A BANDEIRA EM UM BOTÃO
          GestureDetector(
            onTap: canManage ? _navigateToFlagUpload : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: _currentFlagUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                    ),
                  ),
                  placeholder: (context, url) => const CircleAvatar(radius: 60, child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const CircleAvatar(radius: 60, child: Icon(Icons.shield, size: 60)),
                ),
                if (canManage)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 40),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.clan.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10)]),
          ),
          if (widget.clan.tag != null && widget.clan.tag!.isNotEmpty)
            Text(
              '[${widget.clan.tag}]',
              style: TextStyle(fontSize: 18, color: Colors.amber.shade300, shadows: const [Shadow(blurRadius: 5)]),
            ),
          const SizedBox(height: 16),
          if (widget.clan.description != null && widget.clan.description!.isNotEmpty)
            Text(
              widget.clan.description!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), shadows: const [Shadow(blurRadius: 5)]),
            ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, bool canManage) {
    // 4. AJUSTE DO LAYOUT E ADIÇÃO DOS NOVOS BOTÕES
    return SliverGrid.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.chat_bubble,
          label: 'Chat',
          targetScreen: ClanTextChatScreen(clanId: widget.clan.id, clanName: widget.clan.name),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.assignment,
          label: 'Missões',
          targetScreen: QRRListScreen(clanId: widget.clan.id),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.photo_library,
          label: 'InstaClã',
          targetScreen: InstaClanFeedScreen(clanId: widget.clan.id),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.people,
          label: 'Membros',
          targetScreen: MembersTab(clanId: widget.clan.id, clan: widget.clan),
        ),
        if (canManage)
          _buildActionButton(
            context: context,
            icon: Icons.call,
            label: 'Chamada',
            onTap: () {
              final voipService = Provider.of<VoIPService>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final currentUser = authProvider.currentUser;
              if (currentUser != null) {
                final roomId = VoIPService.generateRoomId(prefix: 'clan', entityId: widget.clan.id);
                voipService.startVoiceCall(
                  roomId: roomId,
                  displayName: currentUser.username,
                  isAudioOnly: true,
                );
              }
            },
          ),
        if (_permissionService.canDeclareWar(widget.clan))
          _buildActionButton(
            context: context,
            icon: Icons.gavel,
            label: 'Guerra',
            onTap: _showDeclareWarDialog,
          ),
        if (canManage)
          _buildActionButton(
            context: context,
            icon: Icons.admin_panel_settings,
            label: 'Gerenciar',
            targetScreen: ClanManagementScreen(clanId: widget.clan.id),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    Widget? targetScreen,
    VoidCallback? onTap,
  }) {
    final closedBuilder = (BuildContext context, VoidCallback openContainer) {
      return InkWell(
        onTap: onTap ?? openContainer,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );
    };

    if (targetScreen != null) {
      return OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 500),
        closedColor: Colors.black.withOpacity(0.6),
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        closedElevation: 4,
        openBuilder: (context, _) => targetScreen,
        closedBuilder: closedBuilder,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: closedBuilder(context, () {}),
      );
    }
  }
}
