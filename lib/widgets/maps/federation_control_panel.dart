import 'package:lucasbeatsfederacao/screens/federation_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_clans_screen.dart';
import 'package:lucasbeatsfederacao/screens/qrr_list_screen.dart';
import 'package:lucasbeatsfederacao/screens/maps/map_editor_screen.dart';
import 'package:lucasbeatsfederacao/screens/maps/create_clan_territory_screen.dart';
/// Um painel de controle flutuante com ações de gerenciamento para uma federação.
class FederationControlPanel extends StatelessWidget {
  final Federation federation;

  const FederationControlPanel({super.key, required this.federation});

  @override
  Widget build(BuildContext context) {
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
              'Guarita: ${federation.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white30, height: 24),
            _buildManagementGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3, // Ajustado para 3 colunas
      padding: const EdgeInsets.only(top: 8.0),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // ==================== INÍCIO DA MODIFICAÇÃO ====================
        // 2. ADIÇÃO DO BOTÃO "VER DETALHES"
        _buildActionButton(
          context: context,
          icon: Icons.visibility,
          label: 'Ver Detalhes',
          // 3. CHAMADA PARA A TELA DE DETALHES PASSANDO fromMap: true
          targetScreen: FederationDetailScreen(federation: federation, fromMap: true),
          heroTag: 'view-detail-fed-${federation.id}',
        ),
        // ===================== FIM DA MODIFICAÇÃO ======================
        _buildActionButton(
          context: context,
          icon: Icons.group_work,
          label: 'Gerenciar Clãs',
          targetScreen: AdminManageClansScreen(federationId: federation.id),
          heroTag: 'manage-clans-${federation.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.add_circle_outline,
          label: 'Adicionar Clã',
          targetScreen: MapEditorScreen(
            mode: EditorMode.allocateClanByAdmin,
            federation: federation,
          ),
          heroTag: 'add-clan-to-federation-${federation.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.add_business,
          label: 'Criar Clã',
          targetScreen: CreateClanTerritoryScreen(
            federationId: federation.id,
            initialMapCoordinates: Offset(federation.mapX ?? 0, federation.mapY ?? 0), // Posição inicial no centro da federação
          ),
          heroTag: 'create-clan-in-federation-${federation.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.assignment,
          label: 'Missões (QRR)',
          targetScreen: QRRListScreen(federationId: federation.id),
          heroTag: 'qrr-federation-${federation.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.admin_panel_settings,
          label: 'Gerenciar Cargos',
          targetScreen: Scaffold(appBar: AppBar(title: const Text('Gerenciar Cargos')), body: const Center(child: Text('Tela de gerenciamento de cargos em breve.'))),
          heroTag: 'manage-roles-${federation.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.edit,
          label: 'Editar Detalhes',
          targetScreen: Scaffold(appBar: AppBar(title: const Text('Editar Federação')), body: const Center(child: Text('Tela de edição em breve.'))),
          heroTag: 'edit-federation-${federation.id}',
        ),
        _buildActionButton(
          context: context,
          icon: Icons.handshake,
          label: 'Diplomacia',
          targetScreen: Scaffold(appBar: AppBar(title: const Text('Diplomacia')), body: const Center(child: Text('Tela de diplomacia em breve.'))),
          heroTag: 'diplomacy-${federation.id}',
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
