import 'dart:convert';

class CustomRole {
  final String name;
  final List<String> permissions;
  final String? color;

  CustomRole({
    required this.name,
    required this.permissions,
    this.color,
  });

  factory CustomRole.fromMap(Map<String, dynamic> map) {
    return CustomRole(
      name: map["name"] ?? "",
      permissions: List<String>.from(map["permissions"] ?? []),
      color: map["color"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "permissions": permissions,
      if (color != null) "color": color,
    };
  }
}

class Clan {
  final String id;
  final String name;
  final String tag;
  final String leaderId;
  final String? description;
  final String? bannerImageUrl;
  final String? flag;
  final List<String>? members;
  final int? memberCount;
  final List<String>? subLeaders;
  final List<String>? allies;
  final List<String>? enemies;
  final List<String>? textChannels;
  final List<String>? voiceChannels;
  final List<Map<String, dynamic>>? memberRoles;
  final List<CustomRole>? customRoles;
  final String? rules;
  final DateTime? createdAt;
  final double? mapX;
  final double? mapY;
  final double? radius;
  final String? federationId;

  Clan({
    required this.id,
    required this.name,
    required this.tag,
    required this.leaderId,
    this.description,
    this.bannerImageUrl,
    this.flag,
    this.members,
    this.memberCount,
    this.subLeaders,
    this.allies,
    this.enemies,
    this.textChannels,
    this.voiceChannels,
    this.memberRoles,
    this.customRoles,
    this.rules,
    this.createdAt,
    this.mapX,
    this.mapY,
    this.radius,
    this.federationId,
  });

  factory Clan.fromMap(Map<String, dynamic> map) {
    // Helper para extrair o território de forma segura
    Map<String, dynamic>? territoryData;
    if (map["territory"] is Map<String, dynamic>) {
      territoryData = map["territory"];
    }

    // Helper para extrair IDs de objetos populados ou strings
    String? _getIdFromPopulated(dynamic data) {
      if (data is String) return data;
      if (data is Map<String, dynamic>) return data["_id"] as String?;
      return null;
    }

    // Helper para extrair lista de IDs de objetos populados ou strings
    List<String> _getIdsListFromPopulated(dynamic data) {
      if (data is List) {
        return data.map((item) => _getIdFromPopulated(item)).whereType<String>().toList();
      }
      return [];
    }

    return Clan(
      id: map["_id"] ?? "",
      name: map["name"] ?? "",
      tag: map["tag"] ?? "",
      // Corrigido para lidar com 'leader' populado ou apenas o ID
      leaderId: _getIdFromPopulated(map["leader"]) ?? "",
      description: map["description"],
      bannerImageUrl: map["banner"],
      flag: map["flag"],
      // Corrigido para lidar com 'members' populado ou apenas IDs
      members: _getIdsListFromPopulated(map["members"]),
      memberCount: map["memberCount"] as int?,
      // Corrigido para lidar com 'subLeaders' populado ou apenas IDs
      subLeaders: _getIdsListFromPopulated(map["subLeaders"]),
      // Corrigido para lidar com 'allies' populado ou apenas IDs
      allies: _getIdsListFromPopulated(map["allies"]),
      // Corrigido para lidar com 'enemies' populado ou apenas IDs
      enemies: _getIdsListFromPopulated(map["enemies"]),
      // Corrigido para lidar com 'textChannels' populado ou apenas IDs
      textChannels: _getIdsListFromPopulated(map["textChannels"]),
      // Corrigido para lidar com 'voiceChannels' populado ou apenas IDs
      voiceChannels: _getIdsListFromPopulated(map["voiceChannels"]),
      memberRoles: map["memberRoles"] != null
          ? List<Map<String, dynamic>>.from(map["memberRoles"].map((x) => Map<String, dynamic>.from(x)))
          : null,
      customRoles: map["customRoles"] != null
          ? List<CustomRole>.from(map["customRoles"].map((x) => CustomRole.fromMap(x)))
          : null,
      rules: map["rules"],
      createdAt: map["createdAt"] != null
          ? DateTime.parse(map["createdAt"])
          : null,
      mapX: (territoryData?["mapX"] as num?)?.toDouble(),
      mapY: (territoryData?["mapY"] as num?)?.toDouble(),
      radius: (territoryData?["radius"] as num?)?.toDouble(),
      // Corrigido para lidar com 'federation' populado ou apenas o ID
      federationId: _getIdFromPopulated(map["federation"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "_id": id,
      "name": name,
      "tag": tag,
      "leader": leaderId,
      if (description != null) "description": description,
      if (bannerImageUrl != null) "banner": bannerImageUrl,
      if (flag != null) "flag": flag,
      if (members != null) "members": members,
      if (memberCount != null) "memberCount": memberCount,
      if (subLeaders != null) "subLeaders": subLeaders,
      if (allies != null) "allies": allies,
      if (enemies != null) "enemies": enemies,
      if (textChannels != null) "textChannels": textChannels,
      if (voiceChannels != null) "voiceChannels": voiceChannels,
      if (memberRoles != null) "memberRoles": memberRoles,
      if (customRoles != null) "customRoles": customRoles!.map((x) => x.toMap()).toList(),
      if (rules != null) "rules": rules,
      if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
      "territory": {
        if (mapX != null) "mapX": mapX,
        if (mapY != null) "mapY": mapY,
        if (radius != null) "radius": radius,
      },
      "federation": federationId,
    };
  }

  factory Clan.fromJson(String source) => Clan.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}


