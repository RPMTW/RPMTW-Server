import 'dart:convert';

import 'package:http/http.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';

class MinecraftVersionManifest {
  String latestRelease;

  String? latestSnapshot;

  List<MinecraftVersion> versions;

  MinecraftVersionManifest(this.latestRelease, this.versions,
      {this.latestSnapshot});

  factory MinecraftVersionManifest.fromMap(Map<String, dynamic> data) {
    return MinecraftVersionManifest(
        data['latest']['release'],
        (data['versions'] as List<dynamic>)
            .map((d) => MinecraftVersion.fromMap(d))
            .toList(),
        latestSnapshot: data['latest']['snapshot']);
  }

  factory MinecraftVersionManifest.fromJson(String json) {
    return MinecraftVersionManifest.fromMap(jsonDecode(json));
  }

  static Future<MinecraftVersionManifest> vanilla() async {
    String mojangMetaAPI = 'https://launchermeta.mojang.com/mc/game';
    Response response =
        await get(Uri.parse("$mojangMetaAPI/version_manifest_v2.json"));
    return MinecraftVersionManifest.fromJson(response.body);
  }
}
