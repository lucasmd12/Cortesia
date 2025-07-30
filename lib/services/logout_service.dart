import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class LogoutService {
  final ApiService _apiService = ApiService();

  /// Faz logout do usuário atual
  Future<bool> logout() async {
    try {
      Logger.info("Iniciando logout do usuário...");
      
      final response = await _apiService.post(
        "/api/auth/logout",
        {},
        requireAuth: true,
      );
      
      if (response != null && response['success'] == true) {
        Logger.info("Logout realizado com sucesso no servidor");
        return true;
      } else {
        Logger.warning("Resposta inesperada do servidor durante logout");
        return false;
      }
    } catch (e) {
      Logger.error("Erro durante logout: ${e.toString()}");
      // Mesmo com erro, consideramos o logout local como bem-sucedido
      return true;
    }
  }

  /// Faz logout de todos os dispositivos
  Future<bool> logoutAll() async {
    try {
      Logger.info("Iniciando logout de todos os dispositivos...");
      
      final response = await _apiService.post(
        "/api/auth/logout-all",
        {},
        requireAuth: true,
      );
      
      if (response != null && response['success'] == true) {
        Logger.info("Logout de todos os dispositivos realizado com sucesso");
        return true;
      } else {
        Logger.warning("Resposta inesperada do servidor durante logout de todos os dispositivos");
        return false;
      }
    } catch (e) {
      Logger.error("Erro durante logout de todos os dispositivos: ${e.toString()}");
      // Mesmo com erro, consideramos o logout local como bem-sucedido
      return true;
    }
  }

  /// Verifica se o token atual é válido
  Future<bool> verifyToken() async {
    try {
      Logger.info("Verificando validade do token...");
      
      final response = await _apiService.post(
        "/api/auth/verify-token",
        {},
        requireAuth: true,
      );
      
      if (response != null && response['valid'] == true) {
        Logger.info("Token é válido");
        return true;
      } else {
        Logger.warning("Token é inválido ou expirado");
        return false;
      }
    } catch (e) {
      Logger.error("Erro ao verificar token: ${e.toString()}");
      return false;
    }
  }

  /// Renova o token atual
  Future<String?> refreshToken() async {
    try {
      Logger.info("Renovando token...");
      
      final response = await _apiService.post(
        "/api/auth/refresh",
        {},
        requireAuth: true,
      );
      
      if (response != null && response['success'] == true && response['token'] != null) {
        final newToken = response['token'] as String;
        Logger.info("Token renovado com sucesso");
        return newToken;
      } else {
        Logger.warning("Falha ao renovar token");
        return null;
      }
    } catch (e) {
      Logger.error("Erro ao renovar token: ${e.toString()}");
      return null;
    }
  }

  /// Obtém as sessões ativas do usuário
  Future<List<Map<String, dynamic>>?> getActiveSessions() async {
    try {
      Logger.info("Obtendo sessões ativas...");
      
      final response = await _apiService.get(
        "/api/auth/active-sessions",
        requireAuth: true,
      );
      
      if (response != null && response['success'] == true && response['data'] != null) {
        final sessions = List<Map<String, dynamic>>.from(response['data']);
        Logger.info("Sessões ativas obtidas: ${sessions.length} sessões");
        return sessions;
      } else {
        Logger.warning("Falha ao obter sessões ativas");
        return null;
      }
    } catch (e) {
      Logger.error("Erro ao obter sessões ativas: ${e.toString()}");
      return null;
    }
  }

  /// Altera a senha do usuário
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      Logger.info("Alterando senha do usuário...");
      
      final response = await _apiService.put(
        "/api/auth/change-password",
        {
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        },
        requireAuth: true,
      );
      
      if (response != null && response['success'] == true) {
        Logger.info("Senha alterada com sucesso");
        return true;
      } else {
        Logger.warning("Falha ao alterar senha");
        return false;
      }
    } catch (e) {
      Logger.error("Erro ao alterar senha: ${e.toString()}");
      return false;
    }
  }
}

