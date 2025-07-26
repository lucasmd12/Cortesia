import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/services/permission_service.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/providers/map_navigation_provider.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/screens/clan_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/qrr_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/federation_management_screen.dart';
import 'package:lucasbeatsfederacao/widgets/immersive/parallax_scaffold.dart';

// 1. IMPORT DAS TELAS NECESSÁRIAS
import 'package:lucasbeatsfederacao/screens/federation_text_chat_screen.dart';
import 'package:lucasbeatsfederacao/screens/clan_wars_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/federation_tag_management_screen.dart';

class FederationDetailScreen extends StatefulWidget {
  final Federation federation;
  final bool fromMap;

  const FederationDetailScreen({
    super.key,
    required this.federation,
    this.fromMap = false,
  });

  @override
  State<FederationDetailScreen> createState() => _FederationDetailScreenState();
}

class _FederationDetailScreenState extends State<FederationDetailScreen> {
  late String _currentTagUrl;

  @override
  void initState() {
    super.initState();
    _currentTagUrl = widget.federation.tag ?? '';
  }

  void _startVoiceCall() {
    final voipService = Provider.of<VoIPService>(context, listen: false);
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (currentUser != null) {
      final roomId = VoIPService.generateRoomId(prefix: 'federation', entityId: widget.federation.id);
      voipService.startVoiceCall(
        roomId: roomId,
        displayName: currentUser.username,
        isAudioOnly: true,
      );
    }
  }

  // 2. NAVEGAÇÃO PARA A TELA DE UPLOAD DA TAG
  void _navigateToTagUpload() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FederationTagManagementScreen(
          federationId: widget.federation.id,
          federationName: widget.federation.name,
          currentTag: _currentTagUrl,
          onTagUpdated: (newTagUrl) {
            setState(() {
              _currentTagUrl = newTagUrl;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissionService = Provider.of<PermissionService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    final bool canManage = permissionService.canManageFederation(widget.federation);
    final bool canViewQRR = currentUser != null &&
        (currentUser.id == widget.federation.leader.id ||
            (currentUser.role == Role.clanLeader && currentUser.federationId == widget.federation.id));

    return ParallaxScaffold(
      customAssetPath: widget.federation.banner,
      fallbackType: ParallaxBackground.sky,
      appBar: AppBar(
        title: Text(widget.federation.name),
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
      floatingActionButton: canViewQRR
          ? OpenContainer(
              transitionType: ContainerTransitionType.fadeThrough,
              transitionDuration: const Duration(milliseconds: 600),
              closedColor: Colors.transparent,
              closedElevation: 0,
              openBuilder: (context, _) => QRRListScreen(federationId: widget.federation.id),
              closedBuilder: (context, openContainer) {
                return FloatingActionButton.extended(
                  onPressed: openContainer,
                  icon: const Icon(Icons.assignment),
                  label: const Text("Missões QRR"),
                  backgroundColor: Colors.red.shade800,
                  heroTag: "qrr-fab-${widget.federation.id}",
                );
              },
            ) as FloatingActionButton? // Cast para FloatingActionButton? para resolver o erro de tipo
          : null,
    );
  }

  Widget _buildHeader(bool canManage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 80),
          // 3. TRANSFORMA A TAG EM UM BOTÃO
          GestureDetector(
            onTap: canManage ? _navigateToTagUpload : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_currentTagUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: _currentTagUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const CircleAvatar(radius: 60, child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const CircleAvatar(radius: 60, child: Icon(Icons.shield, size: 60)),
                  )
                else
                  CircleAvatar(radius: 60, child: Text(widget.federation.name.substring(0,1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold))),
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
            widget.federation.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10)]),
          ),
          const SizedBox(height: 8),
          Text(
            'Liderada por: ${widget.federation.leader.username}',
            style: TextStyle(fontSize: 16, color: Colors.amber.shade300, shadows: const [Shadow(blurRadius: 5)]),
          ),
          const SizedBox(height: 16),
          if (widget.federation.description != null && widget.federation.description!.isNotEmpty)
            Text(
              widget.federation.description!,
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
          targetScreen: FederationTextChatScreen(federationId: widget.federation.id, federationName: widget.federation.name),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.shield,
          label: 'Clãs (${widget.federation.clanCount ?? 0})',
          targetScreen: ClanListScreen(federationId: widget.federation.id),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.gavel,
          label: 'Guerras',
          targetScreen: ClanWarsListScreen(federationId: widget.federation.id),
        ),
        if (canManage)
          _buildActionButton(
            context: context,
            icon: Icons.call,
            label: 'Chamada',
            onTap: _startVoiceCall,
          ),
        if (canManage)
          _buildActionButton(
            context: context,
            icon: Icons.admin_panel_settings,
            label: 'Gerenciar',
            targetScreen: FederationManagementScreen(federationId: widget.federation.id),
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
