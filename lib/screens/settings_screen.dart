import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucasbeatsfederacao/screens/login_screen.dart';
import 'package:lucasbeatsfederacao/screens/admin_panel_screen.dart';
import 'package:lucasbeatsfederacao/models/role_model.dart';
import 'package:lucasbeatsfederacao/screens/profile_edit_screen.dart';
// Imports adicionados para a nova funcionalidade
import 'package:lucasbeatsfederacao/services/clan_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Função para lidar com a lógica de sair do clã
  Future<void> _leaveClan() async {
    // Mostrar um diálogo de confirmação antes de prosseguir
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair do Clã'),
          content: const Text('Tem certeza de que deseja sair do seu clã atual?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    // Se o usuário não confirmar, não fazer nada
    if (confirm != true) {
      return;
    }

    // Prosseguir com a lógica de sair do clã
    try {
      final clanService = Provider.of<ClanService>(context, listen: false);
      await clanService.leaveCurrentClan();

      // Forçar a atualização do perfil do usuário para refletir a saída do clã
      await Provider.of<AuthProvider>(context, listen: false).authService.fetchUserProfile();

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Você saiu do clã com sucesso.');
      }
    } catch (e) {
      Logger.error('Erro ao sair do clã na UI', error: e);
      if (mounted) {
        // Exibe a mensagem de erro vinda do backend ou uma genérica
        CustomSnackbar.showError(context, e.toString().replaceFirst("Exception: ", ""));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          // Seção de Perfil Aprimorada
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50.0),
                      child: CachedNetworkImage(
                        imageUrl: currentUser.avatar ?? '',
                        placeholder: (context, url) => const Icon(Icons.person, size: 100),
                        errorWidget: (context, url, error) => const Icon(Icons.person, size: 100),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser.username,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Cargo: ${currentUser.role.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (currentUser.federationName != null)
                    Text(
                      'Federação: ${currentUser.federationName} ${currentUser.federationTag != null ? '(${currentUser.federationTag})' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (currentUser.clanName != null)
                    Text(
                      'Clã: ${currentUser.clanName} ${currentUser.clanTag != null ? '(${currentUser.clanTag})' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Perfil'),
                  ),
                ],
              ),
            ),
          ),

          // Acesso ao Painel ADM (se aplicável)
          if (currentUser.role == Role.admMaster)
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Acessar Painel Administrativo'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
                    ),
                  );
                },
              ),
            ),

          // ==================== INÍCIO DA MODIFICAÇÃO ====================
          // Nova seção para gerenciamento de clã, visível apenas se o usuário estiver em um.
          if (currentUser.clanId != null)
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text('Sair do Clã', style: TextStyle(color: Colors.red)),
                    onTap: _leaveClan,
                  ),
                ],
              ),
            ),
          // ===================== FIM DA MODIFICAÇÃO ======================

          // Configurações de Notificações (Placeholder)
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: ExpansionTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notificações'),
              children: const [
                ListTile(title: Text('Configurações de notificação aqui.')),
              ],
            ),
          ),

          // Configurações de Privacidade (Placeholder)
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: ExpansionTile(
              leading: const Icon(Icons.lock),
              title: const Text('Privacidade e Segurança'),
              children: const [
                ListTile(title: Text('Configurações de privacidade aqui.')),
              ],
            ),
          ),

          // Seção de Conta
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    await Provider.of<AuthProvider>(context, listen: false).logout();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Excluir Conta', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Excluir Conta'),
                          content: const Text('Tem certeza que deseja excluir sua conta? Esta ação é irreversível.'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: const Text('Excluir'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Funcionalidade de exclusão de conta a ser implementada.')),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
