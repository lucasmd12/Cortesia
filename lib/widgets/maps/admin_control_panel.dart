import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_clans_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_federations_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin_manage_users_screen.dart';
import 'package:lucasbeatsfederacao/widgets/admin_notification_dialog.dart';

/// Um painel de controle flutuante com ações rápidas para o ADM,
/// projetado para ser exibido sobre a ImmersiveMapScreen.
class AdminControlPanel extends StatelessWidget {
  final VoidCallback onHide;

  const AdminControlPanel({
    super.key,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      color: Colors.black.withOpacity(0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    'Painel de Controle ADM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                    tooltip: 'Ocultar Painel',
                    onPressed: onHide,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.red, height: 12),
            // Ações rápidas mais relevantes para o mapa
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8.0),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildActionCard(
                  context,
                  'Criar Federação',
                  Icons.add_business,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminManageFederationsScreen())),
                ),
                _buildActionCard(
                  context,
                  'Gerenciar Clãs',
                  Icons.shield,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminManageClansScreen())),
                ),
                _buildActionCard(
                  context,
                  'Gerenciar Usuários',
                  Icons.people,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminManageUsersScreen())),
                ),
                _buildActionCard(
                  context,
                  'Notificação Global',
                  Icons.campaign,
                  Colors.red,
                  () => showDialog(context: context, builder: (context) => const AdminNotificationDialog()),
                ),
                // Adicione outros botões se necessário
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
