part of localbooru_api;

Future<void> _settingsWriteChain = Future<void>.value();

Future<void> _writeSettingsAtomically(String path, Map raw) async {
    final String targetPath = p.join(path, "repoinfo.json");
    final File target = File(targetPath);
    final File backup = File("$targetPath.bak");
    final String encoded = const JsonEncoder.withIndent('  ').convert(raw);
    final File temp = File(
        "$targetPath.tmp-${DateTime.now().microsecondsSinceEpoch}-${encoded.hashCode.abs()}",
    );

    // Preserve the latest valid repository snapshot. This gives getRawInfo() a
    // recovery source if Windows, the process, or storage is interrupted.
    if (await target.exists()) {
        try {
            final String current = await target.readAsString();
            if (current.trim().isNotEmpty) {
                final dynamic parsed = jsonDecode(current);
                if (parsed is Map) await target.copy(backup.path);
            }
        } catch (_) {
            // Never overwrite a known-good backup with a malformed target.
        }
    }

    try {
        await temp.writeAsString(encoded, flush: true);

        // Validate the complete temporary file before it can replace the live
        // repository metadata.
        final dynamic parsedTemp = jsonDecode(await temp.readAsString());
        if (parsedTemp is! Map) {
            throw const FormatException('Repository metadata must be a JSON object');
        }

        // rename() replaces an existing file on supported platforms. Readers
        // therefore see either the old complete JSON or the new complete JSON,
        // never the zero-length/truncated state produced by writeAsString() on
        // the live file itself.
        await temp.rename(targetPath);
    } finally {
        if (await temp.exists()) {
            try {
                await temp.delete();
            } catch (_) {}
        }
    }
}

Future<void> writeSettings(String path, Map raw, {bool notify = true}) async {
    // Serialize metadata writes. Several workflows update specific tags and
    // file metadata close together; queuing avoids overlapping replacements.
    final Future<void> operation = _settingsWriteChain.then(
        (_) => _writeSettingsAtomically(path, raw),
        onError: (_, __) => _writeSettingsAtomically(path, raw),
    );

    _settingsWriteChain = operation.catchError((Object error, StackTrace stack) {
        debugPrint('[RepositoryWrite] $error');
        debugPrintStack(stackTrace: stack);
    });

    await operation;
    if (notify) booruUpdateListener.update();
}

Map<String, dynamic> rebase(Map<String, dynamic> raw) {
    // check all files
    if(raw["files"] == null) raw["files"] = defaultFileInfoJson["files"];
    List files = raw["files"];
    for(var (int index, Map file) in files.indexed) {
        //recount all ids
        file["id"] = index.toString();

        file["tags"] = (file["tags"] as String).split(" ")
            .where((tag) => tag.isNotEmpty // remove empty spaces
				&& !Metatag.isMetatag(tag) //remove any metatags on the tags
			)
            .join(" ");
        file["related"] = (file["related"] ?? []).where((e) => int.tryParse(e) != null && files.elementAtOrNull(int.parse(e)) != null).toList();

        files[index] = file as dynamic;
    }
    raw["files"] = files;

    // check specific tags
    if(raw["specificTags"] == null) {
        raw["specificTags"] = defaultFileInfoJson["specificTags"];
    } else {
        // clean empty types
        for (final type in raw["specificTags"].keys) {
            List<String> contents = List.from(raw["specificTags"][type]);
            contents = contents.where((e) => e.isNotEmpty).toList();
            raw["specificTags"][type] = contents;
        }
    }

    // check collections
    if(raw["collections"] == null) {
        raw["collections"] = defaultFileInfoJson["collections"];
    } else {
        final List<Map<String, dynamic>> collections = List<Map<String, dynamic>>.from(raw["collections"]);
        for (var (index, collection) in collections.indexed) {
            //recount collections
            collection["id"] = index.toString();

            raw["collections"][index] = collection;
        }
    }

    return raw;
}



Future<BooruImage> insertImage(PresetImage preset) async {
    final Booru booru = await getCurrentBooru();

    if(preset.image is! File) throw "Preset does not contain a file";

    // step 1: copy image
    File copiedFile;
    if(p.dirname(preset.image!.path) == p.join(booru.path, "files")) {
        debugPrint("here, ${p.dirname(preset.image!.path)} ${p.join(booru.path, "files")}");
        copiedFile = preset.image!;
    } else {
        copiedFile = await preset.image!.copy(p.join(booru.path, "files", p.basename(preset.image!.path)));
    }

    // step 2: merge tags into the repository snapshot. Older code wrote
    // repoinfo.json once per specific tag type and notified the whole UI after
    // every write. That created avoidable I/O/notification storms. Keep the
    // same data model, but persist the complete image + tag update once.
    if(preset.tags == null) throw "Preset does not contain tags";
    final Set<String> tagSet = {};
    final Map<String, List<String>> specificTagsToMerge = {};
    for (MapEntry<String, List<String>> tagType in preset.tags!.entries) {
        final values = tagType.value.where((tag) => tag.trim().isNotEmpty).toSet().toList();
        if(values.isEmpty) continue;
        tagSet.addAll(values);
        if(tagType.key != "generic") specificTagsToMerge[tagType.key] = values;
    }

    // step 3: adding to json
    Map raw = await booru.getRawInfo();
    final Map<String, dynamic> rawSpecificTags = raw["specificTags"] is Map
        ? Map<String, dynamic>.from(raw["specificTags"] as Map)
        : <String, dynamic>{};
    for (final entry in specificTagsToMerge.entries) {
        final existing = List<String>.from(rawSpecificTags[entry.key] ?? const <String>[]);
        rawSpecificTags[entry.key] = <String>{...existing, ...entry.value}.toList();
    }
    raw["specificTags"] = rawSpecificTags;

    List files = raw["files"];

    // determine id
    String id = preset.replaceID == null || int.parse(preset.replaceID!) > files.length ? "${files.length}" : preset.replaceID!;
    
    // determine rating
    final String? ratingString = switch(preset.rating) {
        Rating.safe => "safe",
        Rating.questionable => "questionable",
        Rating.explicit => "explicit",
        Rating.illegal => "illegal",
        _ => null
    };

    // map to push
    Map toPush = {
        "id": id,
        "filename": p.basename(copiedFile.path),
        "tags": tagSet.join(" "),
        if(ratingString != null) "rating": ratingString,
        "sources": preset.sources ?? [],
        "related": preset.relatedImages ?? [],
        if(preset.note != null && preset.note!.isNotEmpty) "note": preset.note
    };
    
    // find if inputed id already exists, and if no add to its latest index, otherwise replace element on that id
    int index = files.indexWhere((e) => e["id"] == id);
    if (index < 0) files.add(toPush);
    else files[index] = toPush;

    raw["files"] = files;

    await writeSettings(booru.path, raw);

    return (await booru.getImage(id))!;
}

Future<void> writeSpecificTags(Map<String, List<String>> specificTags) async {
    final Booru booru = await getCurrentBooru();

    // add to json
    var raw = await booru.getRawInfo();
    raw["specificTags"] = specificTags;

    await writeSettings(booru.path, raw);
}

Future<void> addSpecificTags(List<String> tags, {required String type}) async {
    final Booru booru = await getCurrentBooru();

    // add to json
    var raw = await booru.getRawInfo();
    final specificTagsList = raw["specificTags"][type];
    List<String> specificTags = List<String>.from(specificTagsList ?? []);

    for(String tag in tags) {
        if(!specificTags.contains(tag)) specificTags.add(tag);
    }

    raw["specificTags"][type] = specificTags;

    Map<String, List<String>> iLoveDartsTypeSystem = {};
    for(MapEntry entry in raw["specificTags"].entries) {
        iLoveDartsTypeSystem[entry.key] = List<String>.from(entry.value);
    }

    // debugPrint("before ${raw["specificTags"]} after $iLoveDartsTypeSystem");

    await writeSpecificTags(iLoveDartsTypeSystem);
}

Future removeImage(String id, {bool notify = true}) async {
    final Booru booru = await getCurrentBooru();
    final BooruImage? image = await booru.getImage(id);
    if(image == null) throw "Image $id does not exist";
    final file = File(image.path);

    // remove file association
    var raw = await booru.getRawInfo();
    List files = raw["files"];

    files.removeWhere((e) => e["id"] == id);
    raw["files"] = files;
    
    await writeSettings(booru.path, rebase(raw), notify: notify);

    // remove file
    await file.delete();

}



Future<BooruCollection> insertCollection(PresetCollection preset) async {
    final Booru booru = await getCurrentBooru();

    if(preset.pages is! List<String>) throw "Preset does not contain pages";
    if(preset.name == null) throw "Preset does not contain a name";

    Map raw = await booru.getRawInfo();
    List<Map<String, dynamic>> collections = List<Map<String, dynamic>>.from(raw["collections"]);

    // determine id
    String id = preset.id == null || int.parse(preset.id!) > collections.length ? "${collections.length}" : preset.id!;

    // map to push
    Map<String, dynamic> toPush = {
        "id": id,
        "pages": preset.pages,
        "name": preset.name
    };
    
    // find if inputed id already exists, and if no add to its latest index, otherwise replace element on that id
    int index = collections.indexWhere((e) => e["id"] == id);
    if (index < 0) collections.add(toPush);
    else collections[index] = toPush;

    raw["collections"] = collections;

    await writeSettings(booru.path, raw);

    return (await booru.getCollection(id))!;
}

Future removeCollection(CollectionID id, {bool notify = true}) async {
    final Booru booru = await getCurrentBooru();
    final collection = await booru.getCollection(id);
    if(collection == null) throw "Collection $id does not exist";

    // remove file association
    var raw = await booru.getRawInfo();
    List collections = raw["collections"];

    collections.removeWhere((e) => e["id"] == id);
    raw["collections"] = collections;
    
    await writeSettings(booru.path, rebase(raw), notify: notify);

}