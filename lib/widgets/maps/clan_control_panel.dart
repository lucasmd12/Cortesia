import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/screens/qrr_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/tabs/members_tab.dart';
import 'package:lucasbeatsfederacao/screens/tabs/settings_tab.dart';
import 'package:lucasbeatsfederacao/widgets/clan_info_widget.dart';
import 'package:lucasbeatsfederacao/screens/clan_detail_screen.dart';

// 1. IMPORT DAS TELAS NECESSÁRIAS
import 'package:lucasbeatsfederacao/screens/clan_text_chat_screen.dart';
import 'package:lucasbeatsfederacao/screens/instaclan_feed_screen.dart';

/// Um painel de controle flutuante com ações de gerenciamento para um clã.
class ClanControlPanel extends StatelessWidget {
  final Clan clan;

  const ClanControlPanel({super.key, required this.clan});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    final bool canManage = currentUser != null &&
        ((currentUser.clanId == clan.id && (currentUser.clanRole == Role.clanLeader || currentUser.clanRole == Role.clanSubLeader)) ||
            currentUser.role == Role.admMaster);

    return Card(
      margin: const EdgeInsets.all(12.0),
      color: Colors.black.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Guarita: ${clan.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white30, height: 24),
            _buildManagementGrid(context, canManage),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid(BuildContext context, bool canManage) {
    // 2. ADIÇÃO DOS NOVOS BOTÕES E REORGANIZAÇÃO
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.only(top: 8.0),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // --- Ações de Comunidade ---
        _buildActionButton(
          context: context,
          icon: Icons.chat_bubble,
          label: 'Chat',
          targetScreen: ClanTextChatScreen(clanId: clan.id, clanName: clan.name),
          heroTag: 'chat-clan-${clan.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.photo_library,
          label: 'InstaClã',
          targetScreen: InstaClanFeedScreen(clanId: clan.id),
          heroTag: 'instaclan-clan-${clan.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.people,
          label: 'Membros',
          targetScreen: MembersTab(clanId: clan.id, clan: clan),
          heroTag: 'members-clan-${clan.id}',
        ),

        // --- Ações de Atividade ---
        _buildActionButton(
          context: context,
          icon: Icons.assignment,
          label: 'Missões',
          targetScreen: QRRListScreen(clanId: clan.id),
          heroTag: 'qrr-clan-${clan.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.visibility,
          label: 'Ver Detalhes',
          targetScreen: ClanDetailScreen(clan: clan, fromMap: true),
          heroTag: 'view-detail-clan-${clan.id}',
        ),

        // --- Ações de Gerenciamento (Condicionais) ---
        if (canManage)
          _buildActionButton(
            context: context,
            icon: Icons.admin_panel_settings,
            label: 'Painel Líder',
            targetScreen: Scaffold(appBar: AppBar(title: const Text('Painel do Líder')), body: const Center(child: Text('Funcionalidades do Líder em breve.'))),
            heroTag: 'leader-panel-${clan.id}',
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget targetScreen,
    required String heroTag,
  }) {
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
      closedBuilder: (context, openContainer) {
        return InkWell(
          onTap: openContainer,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
