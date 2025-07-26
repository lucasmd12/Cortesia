import 'package:lucasbeatsfederacao/models/clan_model.dart';

class FederationLeader {
  final String id;
  final String username;
  final String? avatar;

  FederationLeader({
    required this.id,
    required this.username,
    this.avatar,
  });

  factory FederationLeader.fromJson(Map<String, dynamic> json) {
    return FederationLeader(
      id: json["_id"] ?? json["id"] ?? "",
      username: json["username"] ?? "Unknown",
      avatar: json["avatar"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "username": username,
      "avatar": avatar,
    };
  }
}

class FederationClan {
  final String id;
  final String name;
  final String? tag;

  FederationClan({
    required this.id,
    required this.name,
    this.tag,
  });

  factory FederationClan.fromJson(Map<String, dynamic> json) {
    return FederationClan(
      id: json["_id"] ?? json["id"] ?? "",
      name: json["name"] ?? "Unknown Clan",
      tag: json["tag"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "tag": tag,
    };
  }

  Clan toClan({
    required String leaderId,
  }) {
    return Clan(
      id: id,
      name: name,
      tag: tag ?? "",
      leaderId: leaderId,
    );
  }
}

class FederationAlly {
  final String id;
  final String name;

  FederationAlly({
    required this.id,
    required this.name,
  });

  factory FederationAlly.fromJson(Map<String, dynamic> json) {
    return FederationAlly(
      id: json["_id"] ?? json["id"] ?? "",
      name: json["name"] ?? "Unknown Federation",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
    };
  }
}

class Federation {
  final String id;
  final String name;
  final String? tag;
  final FederationLeader leader;
  final List<FederationLeader> subLeaders;
  final List<FederationClan> clans;
  final int? clanCount;
  final List<FederationAlly> allies;
  final List<FederationAlly> enemies;
  final String? description;
  final String? rules;
  final bool? isPublic;
  final String? banner;
  final double? mapX;
  final double? mapY;
  final double? radius;

  Federation({
    required this.id,
    required this.name,
    this.tag,
    required this.leader,
    required this.subLeaders,
    required this.clans,
    this.clanCount,
    required this.allies,
    required this.enemies,
    this.description,
    this.isPublic,
    this.rules,
    this.banner,
    this.mapX,
    this.mapY,
    this.radius,
  });

  factory Federation.fromJson(Map<String, dynamic> json) {
    // Helper para extrair o território de forma segura
    Map<String, dynamic>? territoryData;
    if (json['territory'] is Map<String, dynamic>) {
      territoryData = json['territory'];
    }

    // Helper para extrair IDs de objetos populados ou strings
    String? _getIdFromPopulated(dynamic data) {
      if (data is String) return data;
      if (data is Map<String, dynamic>) return data["_id"] as String?;
      return null;
    }

    // Helper para processar lista de objetos populados
    List<T> _processPopulatedList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
      if (data is List) {
        return data.map((item) {
          if (item is Map<String, dynamic>) {
            return fromJson(item);
          } else if (item is String) {
            // Se for apenas um ID, cria um objeto básico
            if (T == FederationLeader) {
              return FederationLeader(id: item, username: "Unknown") as T;
            } else if (T == FederationClan) {
              return FederationClan(id: item, name: "Unknown Clan") as T;
            } else if (T == FederationAlly) {
              return FederationAlly(id: item, name: "Unknown Federation") as T;
            }
          }
          return null;
        }).whereType<T>().toList();
      }
      return [];
    }

    return Federation(
      id: json["_id"] ?? json["id"] ?? "",
      name: json["name"] ?? "Default Federation Name",
      tag: json["tag"],
      // Corrigido para lidar com 'leader' populado ou apenas o ID
      leader: (() {
        final dynamic leaderData = json["leader"];
        if (leaderData is String) {
          return FederationLeader(id: leaderData, username: "Unknown");
        } else if (leaderData is Map<String, dynamic>) {
          return FederationLeader.fromJson(leaderData);
        }
        return FederationLeader(id: "", username: "Unknown");
      })(),
      // Corrigido para lidar com 'subLeaders' populado ou apenas IDs
      subLeaders: _processPopulatedList<FederationLeader>(
        json["subLeaders"], 
        (json) => FederationLeader.fromJson(json)
      ),
      // Corrigido para lidar com 'clans' populado ou apenas IDs
      clans: _processPopulatedList<FederationClan>(
        json["clans"], 
        (json) => FederationClan.fromJson(json)
      ),
      clanCount: json["clanCount"] as int?,
      // Corrigido para lidar com 'allies' populado ou apenas IDs
      allies: _processPopulatedList<FederationAlly>(
        json["allies"], 
        (json) => FederationAlly.fromJson(json)
      ),
      // Corrigido para lidar com 'enemies' populado ou apenas IDs
      enemies: _processPopulatedList<FederationAlly>(
        json["enemies"], 
        (json) => FederationAlly.fromJson(json)
      ),
      description: json["description"],
      rules: json["rules"],
      isPublic: json['isPublic'] as bool?,
      banner: json["banner"],
      mapX: (territoryData?['mapX'] as num?)?.toDouble(),
      mapY: (territoryData?['mapY'] as num?)?.toDouble(),
      radius: (territoryData?['radius'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      if (tag != null) "tag": tag,
      "leader": leader.toJson(),
      "subLeaders": subLeaders.map((s) => s.toJson()).toList(),
      "clans": clans.map((clan) => clan.toJson()).toList(),
      if (clanCount != null) "clanCount": clanCount,
      "allies": allies.map((ally) => ally.toJson()).toList(),
      "enemies": enemies.map((enemy) => enemy.toJson()).toList(),
      if (description != null) "description": description,
      if (isPublic != null) "isPublic": isPublic,
      if (rules != null) "rules": rules,
      if (banner != null) "banner": banner,
      "territory": {
        if (mapX != null) "mapX": mapX,
        if (mapY != null) "mapY": mapY,
        if (radius != null) "radius": radius,
      },
    };
  }
}

