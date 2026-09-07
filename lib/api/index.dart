library localbooru_api;

import 'dart:io';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:localbooru/api/preset/index.dart';
import 'package:localbooru/api/tags/index.dart';
import 'package:localbooru/utils/constants.dart';
import 'package:localbooru/utils/listeners.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';


part 'readable.dart';
part 'writable.dart';

Booru? currentBooru;

Future<Booru> getCurrentBooru() async {
    if(currentBooru == null) {
        final prefs = await SharedPreferences.getInstance();
        final String? booruPath = prefs.getString("booruPath");
        debugPrint("Loaded booruPath with $booruPath");
        if (booruPath is! String) throw "Invalid or unset booru on settings";

        final Booru candidate = Booru(booruPath);
        final Map<String, dynamic> raw = await candidate.getRawInfo();
        if(!isValidBooruModel(raw)) {
            debugPrint("Booru is not valid. Trying to fix it");
            await writeSettings(booruPath, rebase(raw));
        }

        currentBooru = candidate;
    }

    return currentBooru!;
}

Future<void> setBooru(String path) async {
    final prefs = await SharedPreferences.getInstance();
    currentBooru = null;
    await prefs.setString("booruPath", path);
    booruUpdateListener.update();
}

Future<void> createDefaultBooruModel(String folderPath) async {
    File repoinfoFile = await File(p.join(folderPath, "repoinfo.json")).create(recursive: true);
    await repoinfoFile.writeAsString(jsonEncode(defaultFileInfoJson), flush: true);
    await Directory(p.join(folderPath, "files")).create(recursive: true);
    await Directory(p.join(folderPath, "thumbnails")).create(recursive: true);
}

bool isValidBooruModel(Map<String, dynamic> raw) {
    return raw["files"] != null &&
        raw["specificTags"] != null;
}

// bool isValidBooruRepo (String path) async {

// }