import 'dart:convert';
import 'package:lucasbeatsfederacao/models/clan_model.dart';
import 'package:lucasbeatsfederacao/models/federation_model.dart';
import 'package:lucasbeatsfederacao/models/user_model.dart';
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/models/system_setting.dart'; // Importar o modelo SystemSetting

class AdminService {
  // O serviço agora cria sua própria instância do ApiService.
  final ApiService _apiService = ApiService();

  // Gerenciamento de Usuários
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _apiService.get('/api/admin/users');
      if (response is List) {
        return response.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Formato de resposta inválido para getAllUsers');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar todos os usuários', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<User> getUserById(String userId) async {
    try {
      final response = await _apiService.get('/api/admin/users/$userId');
      if (response is Map<String, dynamic>) {
        return User.fromJson(response);
      } else {
        throw Exception('Formato de resposta inválido para getUserById');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar usuário por ID: $userId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<User> updateUserRole(String userId, String newRole) async {
    try {
      final response = await _apiService.put('/api/admin/users/$userId/role', {'role': newRole});
      if (response is Map<String, dynamic>) {
        return User.fromJson(response);
      } else {
        throw Exception('Formato de resposta inválido para updateUserRole');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao atualizar papel do usuário: $userId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> banUser(String userId) async {
    try {
      await _apiService.post('/api/admin/users/$userId/ban', {});
      Logger.info('Usuário $userId banido com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao banir usuário: $userId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await _apiService.post('/api/admin/users/$userId/unban', {});
      Logger.info('Usuário $userId desbanido com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao desbanir usuário: $userId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Gerenciamento de Clãs
  Future<List<Clan>> getAllClans() async {
    try {
      final response = await _apiService.get('/api/admin/clans');
      if (response is List) {
        return response.map((json) => Clan.fromJson(json)).toList();
      } else {
        throw Exception('Formato de resposta inválido para getAllClans');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar todos os clãs', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Clan> createClan(Map<String, dynamic> clanData) async {
    try {
      final response = await _apiService.post('/api/admin/clans', clanData);
      if (response is Map<String, dynamic>) {
        // ✅ CORREÇÃO: Removido o json.encode desnecessário.
        return Clan.fromJson(response);
      } else {
        throw Exception('Formato de resposta inválido para createClan');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao criar clã', error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Clan> updateClan(String clanId, Map<String, dynamic> clanData) async {
    try {
      final response = await _apiService.put('/api/admin/clans/$clanId', clanData);
      if (response is Map<String, dynamic>) {
        // ✅ CORREÇÃO: Removido o json.encode desnecessário.
        return Clan.fromJson(response);
      } else {
        throw Exception('Formato de resposta inválido para updateClan');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao atualizar clã: $clanId', error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteClan(String clanId) async {
    try {
      await _apiService.delete('/api/admin/clans/$clanId');
      Logger.info('Clã $clanId deletado com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao deletar clã: $clanId', error: e.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  // Gerenciamento de Federações
  Future<List<Federation>> getAllFederations() async {
    try {
      final response = await _apiService.get('/api/admin/federations');
      if (response is List) {
        return response.map((json) => Federation.fromJson(json)).toList();
      } else {
        throw Exception('Formato de resposta inválido para getAllFederations');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar todas as federações', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Federation> createFederation(Map<String, dynamic> federationData) async {
    try {
      final response = await _apiService.post('/api/admin/federations', federationData);
      if (response is Map<String, dynamic>) {
        return Federation.fromJson(response);
      } else {
        throw Exception('Formato de resposta inválido para createFederation');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao criar federação', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Federation> updateFederation(String federationId, Map<String, dynamic> federationData) async {
    try {
      final response = await _apiService.put('/api/admin/federations/$federationId', federationData);
      if (response is Map<String, dynamic>) {
        return Federation.fromJson(response);
      } else {
        throw Exception('Formato de resposta inválido para updateFederation');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao atualizar federação: $federationId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteFederation(String federationId) async {
    try {
      await _apiService.delete('/api/admin/federations/$federationId');
      Logger.info('Federação $federationId deletada com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao deletar federação: $federationId', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> setFederationTerritory({
    required String federationId,
    required double mapX,
    required double mapY,
    required double radius,
  }) async {
    final endpoint = '/api/admin/federations/$federationId/territory';
    final body = {
      'mapX': mapX,
      'mapY': mapY,
      'radius': radius,
    };

    try {
      final response = await _apiService.put(endpoint, body, requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Territory set successfully for federation $federationId.');
      } else {
        Logger.error('Failed to set federation territory. Response: $response');
        throw Exception(response['message'] ?? 'Falha ao definir território da federação.');
      }
    } catch (e) {
      Logger.error('Error setting federation territory: $e');
      rethrow;
    }
  }

  // Gerenciamento de Configurações do Sistema
  Future<SystemSetting> getSystemSettings() async {
    try {
      final response = await _apiService.get('/api/admin/settings');
      if (response is Map<String, dynamic>) {
        return SystemSetting.fromJson(response);
      } else {
        throw Exception('Formato de resposta inválido para getSystemSettings');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar configurações do sistema', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateSystemSettings(SystemSetting settings) async {
    try {
      await _apiService.put('/api/admin/settings', settings.toJson());
      Logger.info('Configurações do sistema atualizadas com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao atualizar configurações do sistema', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSystemLogs() async {
    try {
      final response = await _apiService.get('/api/admin/logs');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else {
        throw Exception('Formato de resposta inválido para getSystemLogs');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar logs do sistema', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> clearSystemLogs() async {
    try {
      await _apiService.post('/api/admin/logs/clear', {});
      Logger.info('Logs do sistema limpos com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao limpar logs do sistema', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createSystemBackup() async {
    try {
      await _apiService.post('/api/admin/backup', {});
      Logger.info('Backup do sistema iniciado com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao criar backup do sistema', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> clearSystemCache() async {
    try {
      // ✅ CORREÇÃO: Removido o sublinhado extra.
      await _apiService.post('/api/admin/cache/clear', {});
      Logger.info('Cache do sistema limpo com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao limpar cache do sistema', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> restartServer() async {
    try {
      await _apiService.post('/api/admin/restart', {});
      Logger.info('Servidor reiniciado com sucesso.');
    } catch (e, stackTrace) {
      Logger.error('Erro ao reiniciar servidor', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await _apiService.get('/api/admin/stats');
      if (response is Map<String, dynamic>) {
        return response;
      } else {
        throw Exception('Formato de resposta inválido para getSystemStats');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar estatísticas do sistema', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final response = await _apiService.get('/api/admin/activities');
      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else {
        throw Exception('Formato de resposta inválido para getRecentActivities');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar atividades recentes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _apiService.get("/api/admin/user-stats");
      if (response is Map<String, dynamic>) {
        return response;
      } else {
        throw Exception('Formato de resposta inválido para getUserStats');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar estatísticas de usuário', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getClanFederationStats() async {
    try {
      final response = await _apiService.get("/api/admin/clan-federation-stats");
      if (response is Map<String, dynamic>) {
        return response;
      } else {
        throw Exception('Formato de resposta inválido para getClanFederationStats');
      }
    } catch (e, stackTrace) {
      Logger.error('Erro ao buscar estatísticas de clãs e federações', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Cria uma nova federação com território no mapa (apenas ADM).
  Future<Map<String, dynamic>> createFederationWithTerritory({
    required String name,
    String? tag,
    String? leaderUsername,
    required double mapX,
    required double mapY,
    required double radius,
    String? color,
  }) async {
    const String endpoint = '/api/admin/federations/create-with-territory';
    final body = {
      'name': name,
      'tag': tag,
      'leaderUsername': leaderUsername,
      'mapX': mapX,
      'mapY': mapY,
      'radius': radius,
      'color': color,
    };

    try {
      final response = await _apiService.post(endpoint, body, requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Federação com território criada com sucesso.');
        return {'success': true, 'msg': response['msg'] ?? 'Federação criada com sucesso!'};
      } else {
        Logger.error('Falha ao criar federação com território. Resposta: $response');
        return {'success': false, 'msg': response['msg'] ?? 'Falha ao criar federação.'};
      }
    } catch (e) {
      Logger.error('Erro ao criar federação com território: $e');
      return {'success': false, 'msg': 'Erro interno ao criar federação: ${e.toString()}'};
    }
  }

  /// Cria um novo clã com território dentro de uma federação (apenas ADM).
  Future<Map<String, dynamic>> createClanWithTerritory({
    required String name,
    required String tag,
    required String federationId,
    String? leaderUsername,
    required double mapX,
    required double mapY,
    required double radius,
  }) async {
    const String endpoint = '/api/admin/clans/create-with-territory';
    final body = {
      'name': name,
      'tag': tag,
      'federationId': federationId,
      'leaderUsername': leaderUsername,
      'mapX': mapX,
      'mapY': mapY,
      'radius': radius,
    };

    try {
      final response = await _apiService.post(endpoint, body, requireAuth: true);
      if (response != null && response['success'] == true) {
        Logger.info('Clã com território criado com sucesso.');
        return {'success': true, 'msg': response['msg'] ?? 'Clã criado com sucesso!'};
      } else {
        Logger.error('Falha ao criar clã com território. Resposta: $response');
        return {'success': false, 'msg': response['msg'] ?? 'Falha ao criar clã.'};
      }
    } catch (e) {
      Logger.error('Erro ao criar clã com território: $e');
      return {'success': false, 'msg': 'Erro interno ao criar clã: ${e.toString()}'};
    }
  }
}
