import 'package:grammer/grammer.dart';
import 'package:intl/locale.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/list_model_response.dart';
import 'package:rpmtw_server/database/models/auth/user.dart';
import 'package:rpmtw_server/database/models/auth/user_role.dart';
import 'package:rpmtw_server/database/auth_route.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/model_field.dart';
import 'package:rpmtw_server/database/models/storage/storage.dart';
import 'package:rpmtw_server/database/models/translate/glossary.dart';
import 'package:rpmtw_server/database/models/translate/mod_source_info.dart';
import 'package:rpmtw_server/database/models/translate/source_file.dart';
import 'package:rpmtw_server/database/models/translate/source_text.dart';
import 'package:rpmtw_server/database/models/translate/translate_report_sort_type.dart';
import 'package:rpmtw_server/database/models/translate/translate_status.dart';
import 'package:rpmtw_server/database/models/translate/translation.dart';
import 'package:rpmtw_server/database/models/translate/translation_export_cache.dart';
import 'package:rpmtw_server/database/models/translate/translation_export_format.dart';
import 'package:rpmtw_server/database/models/translate/translation_vote.dart';
import 'package:rpmtw_server/database/models/translate/translator_info.dart';
import 'package:rpmtw_server/database/scripts/translate_status_script.dart';
import 'package:rpmtw_server/handler/minecraft_handler.dart';
import 'package:rpmtw_server/handler/translate_handler.dart';
import 'package:rpmtw_server/routes/api_route.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:rpmtw_server/utilities/request_extension.dart';
import 'package:shelf_router/shelf_router.dart';

class TranslateRoute extends APIRoute {
  @override
  String get routeName => 'translate';

  @override
  void router(router) {
    vote(router);
    translation(router);
    sourceText(router);
    sourceFile(router);
    modSourceInfo(router);
    glossary(router);
    translateStatus(router);
    translatorInfo(router);
    other(router);
  }

  void vote(Router router) {
    /// Get vote
    router.getRoute('/vote/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid'];
      final TranslationVote? vote = await TranslationVote.getByUUID(uuid);

      if (vote == null) {
        return APIResponse.modelNotFound<TranslationVote>();
      }

      return APIResponse.success(data: vote.outputMap());
    }, requiredFields: ['uuid']);

    /// List all translation votes by translation uuid
    router.getRoute('/vote', (req, data) async {
      final Map<String, dynamic> fields = data.fields;

      final String translationUUID = fields['translationUUID'];

      int limit =
          fields['limit'] != null ? int.tryParse(fields['limit']) ?? 50 : 50;
      final int skip =
          fields['skip'] != null ? int.tryParse(fields['skip']) ?? 0 : 0;

      // Max limit is 50
      if (limit > 50) {
        limit = 50;
      }

      final Translation? translation =
          await Translation.getByUUID(translationUUID);
      if (translation == null) {
        return APIResponse.modelNotFound<Translation>();
      }

      final List<TranslationVote> votes =
          await TranslationVote.getAllByTranslationUUID(translationUUID,
              limit: limit, skip: skip);

      return APIResponse.success(
          data: ListModelResponse.fromModel(votes, limit, skip));
    }, requiredFields: ['translationUUID']);

    /// Add translation vote
    router.postRoute('/vote', (req, data) async {
      final User user = req.user!;

      final String translationUUID = data.fields['translationUUID']!;
      final TranslationVoteType type =
          TranslationVoteType.values.byName(data.fields['type']!);

      final Translation? translation =
          await Translation.getByUUID(translationUUID);

      if (translation == null) {
        return APIResponse.modelNotFound<Translation>();
      }

      final List<TranslationVote> votes = await translation.votes;

      if (votes.any((vote) => vote.userUUID == user.uuid)) {
        return APIResponse.badRequest(message: 'You have already voted');
      }

      final TranslationVote vote = TranslationVote(
          uuid: Uuid().v4(),
          type: type,
          translationUUID: translationUUID,
          userUUID: user.uuid);

      await vote.insert();
      await TranslateHandler.updateTranslatorInfo(user.uuid, vote: true);
      return APIResponse.success(data: vote.outputMap());
    }, requiredFields: ['translationUUID', 'type'], authConfig: AuthConfig());

    /// Edit translation vote
    router.patchRoute('/vote/<uuid>', (req, data) async {
      final User user = req.user!;

      final String uuid = data.fields['uuid']!;
      final TranslationVoteType type =
          TranslationVoteType.values.byName(data.fields['type']!);

      TranslationVote? vote = await TranslationVote.getByUUID(uuid);
      if (vote == null) {
        return APIResponse.modelNotFound<TranslationVote>();
      }

      if (vote.userUUID != user.uuid) {
        return APIResponse.forbidden(message: 'You cannot edit this vote');
      }

      vote = vote.copyWith(type: type);

      await vote.update();
      return APIResponse.success(data: null);
    }, requiredFields: ['uuid', 'type'], authConfig: AuthConfig());

    /// Cancel translation vote
    router.deleteRoute('/vote/<uuid>', (req, data) async {
      final User user = req.user!;

      final String uuid = data.fields['uuid']!;

      final TranslationVote? vote = await TranslationVote.getByUUID(uuid);
      if (vote == null) {
        return APIResponse.modelNotFound<TranslationVote>();
      }

      if (vote.userUUID != user.uuid) {
        return APIResponse.badRequest(message: 'You cannot cancel this vote');
      }

      await vote.delete();

      return APIResponse.success(data: null);
    }, requiredFields: ['uuid'], authConfig: AuthConfig());
  }

  void translation(Router router) {
    /// Get translation by uuid
    router.getRoute('/translation/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      final Translation? translation = await Translation.getByUUID(uuid);

      if (translation == null) {
        return APIResponse.modelNotFound<Translation>();
      }

      return APIResponse.success(data: translation.outputMap());
    }, requiredFields: ['uuid']);

    /// List all translations by source text or target language or translator
    router.getRoute('/translation', (req, data) async {
      final Map<String, dynamic> fields = data.fields;

      final String? sourceTextUUID = fields['sourceUUID'];
      final Locale? language =
          fields['language'] != null ? Locale.parse(fields['language']) : null;
      final String? translatorUUID = fields['translatorUUID'];

      int limit =
          fields['limit'] != null ? int.tryParse(fields['limit']) ?? 50 : 50;
      final int skip =
          fields['skip'] != null ? int.tryParse(fields['skip']) ?? 0 : 0;

      // Max limit is 50
      if (limit > 50) {
        limit = 50;
      }

      final List<Translation> translations = await Translation.list(
          sourceUUID: sourceTextUUID,
          language: language,
          translatorUUID: translatorUUID,
          limit: limit,
          skip: skip);

      return APIResponse.success(
          data: ListModelResponse.fromModel(translations, limit, skip));
    });

    /// Add translation
    router.postRoute('/translation', (req, data) async {
      final User user = req.user!;

      final SourceText? sourceText =
          await SourceText.getByUUID(data.fields['sourceUUID']!);
      final Locale language = Locale.parse(data.fields['language']!);
      final String content = data.fields['content']!;

      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      if (content.isAllEmpty) {
        return APIResponse.fieldEmpty('content');
      }

      if (!TranslateHandler.supportedLanguage.contains(language)) {
        return APIResponse.badRequest(
            message: 'RPMTranslator doesn\'t support this language');
      }

      final Translation translation = Translation(
          uuid: Uuid().v4(),
          sourceUUID: sourceText.uuid,
          language: language,
          content: content,
          translatorUUID: user.uuid);

      await translation.insert();
      await TranslateHandler.updateTranslatorInfo(user.uuid, translate: true);
      return APIResponse.success(data: translation.outputMap());
    },
        requiredFields: ['sourceUUID', 'language', 'content'],
        authConfig: AuthConfig());

    /// Delete translation by uuid
    router.deleteRoute('/translation/<uuid>', (req, data) async {
      final User user = req.user!;

      final String uuid = data.fields['uuid']!;

      final Translation? translation = await Translation.getByUUID(uuid);
      if (translation == null) {
        return APIResponse.modelNotFound<Translation>();
      }

      if (translation.translatorUUID != user.uuid) {
        return APIResponse.forbidden(
            message: 'You cannot delete this translation');
      }

      await translation.delete();

      return APIResponse.success(data: null);
    }, requiredFields: ['uuid'], authConfig: AuthConfig());
  }

  void sourceText(Router router) {
    /// Get source text by uuid
    router.getRoute('/source-text/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      final SourceText? sourceText = await SourceText.getByUUID(uuid);

      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      return APIResponse.success(data: sourceText.outputMap());
    }, requiredFields: ['uuid']);

    /// List all source text by source or key
    router.getRoute('/source-text', (req, data) async {
      Map<String, dynamic> fields = data.fields;
      int limit =
          fields['limit'] != null ? int.tryParse(fields['limit']) ?? 50 : 50;
      final int skip =
          fields['skip'] != null ? int.tryParse(fields['skip']) ?? 0 : 0;

      // Max limit is 50
      if (limit > 50) {
        limit = 50;
      }

      final List<SourceText> sourceTexts = await SourceText.list(
          source: data.fields['source'],
          key: data.fields['key'],
          limit: limit,
          skip: skip);

      return APIResponse.success(
          data: ListModelResponse.fromModel(sourceTexts, limit, skip));
    });

    /// Add source text
    router.postRoute('/source-text', (req, data) async {
      final String source = data.fields['source']!;
      final List<MinecraftVersion> gameVersions =
          await MinecraftVersion.getByIDs(
              data.fields['gameVersions']!.cast<String>(),
              mainVersion: true);
      final String key = data.fields['key']!;
      final SourceTextType type =
          SourceTextType.values.byName(data.fields['type']!);

      if (source.isAllEmpty) {
        return APIResponse.fieldEmpty('source');
      }

      if (gameVersions.isEmpty) {
        return APIResponse.fieldEmpty('gameVersions');
      }

      if (key.isAllEmpty) {
        return APIResponse.fieldEmpty('key');
      }

      final SourceText sourceText = SourceText(
          uuid: Uuid().v4(),
          source: source,
          gameVersions: gameVersions,
          key: key,
          type: type);

      await sourceText.insert();
      return APIResponse.success(data: sourceText.outputMap());
    },
        requiredFields: ['source', 'gameVersions', 'key', 'type'],
        authConfig: AuthConfig(role: UserRoleType.translationManager));

    /// Edit source text by uuid
    router.patchRoute('/source-text/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      SourceText? sourceText = await SourceText.getByUUID(uuid);
      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      final String? source = data.fields['source'];
      final List<MinecraftVersion>? gameVersions =
          data.fields['gameVersions'] != null
              ? await MinecraftVersion.getByIDs(
                  data.fields['gameVersions']!.cast<String>(),
                  mainVersion: true)
              : null;
      final String? key = data.fields['key'];

      if (source != null && source.isAllEmpty) {
        return APIResponse.fieldEmpty('source');
      }

      if (gameVersions != null && gameVersions.isEmpty) {
        return APIResponse.fieldEmpty('gameVersions');
      }

      if (key != null && key.isAllEmpty) {
        return APIResponse.fieldEmpty('key');
      }

      if (source == null && gameVersions == null && key == null) {
        return APIResponse.badRequest(
            message: 'You need to provide at least one field to edit');
      }

      sourceText = sourceText.copyWith(
          source: source, gameVersions: gameVersions, key: key);

      await sourceText.update();
      return APIResponse.success(data: sourceText.outputMap());
    },
        requiredFields: ['uuid'],
        authConfig: AuthConfig(role: UserRoleType.translationManager));

    /// Delete source text by uuid
    router.deleteRoute('/source-text/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      SourceText? sourceText = await SourceText.getByUUID(uuid);
      if (sourceText == null) {
        return APIResponse.modelNotFound<SourceText>();
      }

      /// Delete all dependencies of this source text
      if (sourceText.type == SourceTextType.patchouli) {
        List<ModSourceInfo>? infos = await DataBase.instance
            .getModelsByField<ModSourceInfo>(
                [ModelField('patchouliAddons', sourceText.uuid)]);

        for (ModSourceInfo info in infos) {
          if (info.patchouliAddons != null) {
            info = info.copyWith(
                patchouliAddons: List.from(info.patchouliAddons!)
                  ..remove(sourceText.uuid));
            await info.update();
          }
        }
      }
      List<SourceFile> files = await DataBase.instance
          .getModelsByField<SourceFile>(
              [ModelField('sources', sourceText.uuid)]);

      for (SourceFile file in files) {
        file = file.copyWith(
            sources: List.from(file.sources)..remove(sourceText.uuid));
        await file.update();
      }

      await sourceText.delete();

      return APIResponse.success(data: null);
    },
        requiredFields: ['uuid'],
        authConfig: AuthConfig(role: UserRoleType.translationManager));
  }

  void sourceFile(Router router) {
    /// Get source file by uuid
    router.getRoute('/source-file/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      final SourceFile? sourceFile = await SourceFile.getByUUID(uuid);

      if (sourceFile == null) {
        return APIResponse.modelNotFound<SourceFile>();
      }

      return APIResponse.success(data: sourceFile.outputMap());
    }, requiredFields: ['uuid']);

    /// List source files by source info uuid
    router.getRoute('/source-file', (req, data) async {
      Map<String, dynamic> fields = data.fields;
      final String? modSourceInfoUUID = fields['modSourceInfoUUID'];
      int limit =
          fields['limit'] != null ? int.tryParse(fields['limit']) ?? 50 : 50;
      final int skip =
          fields['skip'] != null ? int.tryParse(fields['skip']) ?? 0 : 0;

      // Max limit is 50
      if (limit > 50) {
        limit = 50;
      }

      final List<SourceFile> files =
          await SourceFile.list(modSourceInfoUUID: modSourceInfoUUID);

      return APIResponse.success(
          data: ListModelResponse.fromModel(files, limit, skip));
    });

    /// Add source file
    router.postRoute('/source-file', (req, data) async {
      Map<String, dynamic> fields = data.fields;

      final String modSourceInfoUUID = fields['modSourceInfoUUID']!;
      final String storageUUID = fields['storageUUID']!;
      final String path = fields['path']!;
      final SourceFileType type = SourceFileType.values.byName(fields['type']!);
      final List<MinecraftVersion> gameVersions =
          await MinecraftVersion.getByIDs(
              fields['gameVersions']!.cast<String>(),
              mainVersion: true);
      final List<String>? patchouliI18nKeys =
          fields['patchouliI18nKeys'] != null
              ? fields['patchouliI18nKeys']!.cast<String>()
              : null;

      final ModSourceInfo? modSourceInfo =
          await ModSourceInfo.getByUUID(modSourceInfoUUID);

      if (modSourceInfo == null) {
        return APIResponse.modelNotFound<ModSourceInfo>();
      }

      if (gameVersions.isEmpty) {
        return APIResponse.fieldEmpty('gameVersions');
      }

      Storage? storage = await Storage.getByUUID(storageUUID);
      if (storage == null) {
        return APIResponse.modelNotFound<Storage>();
      }
      storage = storage.copyWith(
          type: StorageType.general, usageCount: storage.usageCount + 1);
      await storage.update();

      if (path.isAllEmpty) {
        return APIResponse.fieldEmpty('path');
      }

      final List<SourceText> sourceTexts;
      try {
        sourceTexts = await TranslateHandler.parseFile(
            await storage.readAsString(), type, gameVersions, path,
            patchouliI18nKeys: patchouliI18nKeys ?? []);
      } catch (e) {
        print(e);
        return APIResponse.badRequest(message: 'Failed to parse file');
      }

      final List<SourceFile> duplicateFiles =
          await DataBase.instance.getModelsByField<SourceFile>([
        ModelField('modSourceInfoUUID', modSourceInfoUUID),
        ModelField('path', path),
        ModelField('type', type.name)
      ]);

      final SourceFile file;
      if (duplicateFiles.isEmpty) {
        file = SourceFile(
            uuid: Uuid().v4(),
            modSourceInfoUUID: modSourceInfoUUID,
            storageUUID: storageUUID,
            path: path,
            type: type,
            sources: sourceTexts.map((e) => e.uuid).toList());

        await file.insert();
      } else {
        final duplicateFile = duplicateFiles.first;
        file = duplicateFile.copyWith(
            sources: List.from(duplicateFile.sources)
              ..addAll(sourceTexts.map((e) => e.uuid))
              ..toSet()
              ..toList());
        await file.update();
      }

      TranslateStatusScript.addToQueue(modSourceInfo.uuid);

      return APIResponse.success(data: file.outputMap());
    }, requiredFields: [
      'modSourceInfoUUID',
      'storageUUID',
      'path',
      'type',
      'gameVersions'
    ], authConfig: AuthConfig(role: UserRoleType.translationManager));

    /// Edit source file
    router.patchRoute('/source-file/<uuid>', (req, data) async {
      Map<String, dynamic> fields = data.fields;

      final String uuid = fields['uuid']!;

      SourceFile? sourceFile = await SourceFile.getByUUID(uuid);
      if (sourceFile == null) {
        return APIResponse.modelNotFound<SourceFile>();
      }

      final String? modSourceInfoUUID = fields['modSourceInfoUUID'];
      final String? storageUUID = fields['storageUUID'];
      final String? path = fields['path'];
      final SourceFileType? type = fields['type'] != null
          ? SourceFileType.values.byName(fields['type']!)
          : null;
      final List<MinecraftVersion>? gameVersions =
          fields['gameVersions'] != null
              ? await MinecraftVersion.getByIDs(
                  fields['gameVersions']!.cast<String>(),
                  mainVersion: true)
              : null;
      final List<String>? patchouliI18nKeys =
          fields['patchouliI18nKeys'] != null
              ? fields['patchouliI18nKeys']!.cast<String>()
              : null;

      if (path != null && path.isAllEmpty) {
        return APIResponse.fieldEmpty('path');
      }

      List<SourceText>? sourceTexts;
      if (storageUUID != null) {
        if (gameVersions == null || gameVersions.isEmpty) {
          return APIResponse.badRequest(
              message:
                  'If you want to change storage, you must provide game versions');
        }

        Storage? storage = await Storage.getByUUID(storageUUID);

        if (storage == null) {
          return APIResponse.modelNotFound<Storage>();
        }

        storage = storage.copyWith(
            type: StorageType.general, usageCount: storage.usageCount + 1);
        await storage.update();

        Storage? oldStorage = await Storage.getByUUID(sourceFile.storageUUID);
        if (oldStorage != null) {
          oldStorage = oldStorage.copyWith(
              type: StorageType.general,
              usageCount:
                  oldStorage.usageCount > 0 ? oldStorage.usageCount - 1 : 0);
          await oldStorage.update();
        }

        try {
          sourceTexts = await TranslateHandler.parseFile(
              await storage.readAsString(),
              type ?? sourceFile.type,
              gameVersions,
              path ?? sourceFile.path,
              patchouliI18nKeys: patchouliI18nKeys ?? []);
        } catch (e) {
          return APIResponse.badRequest(message: 'Failed to parse file');
        }
      }

      if (modSourceInfoUUID != null) {
        final ModSourceInfo? modSourceInfo =
            await ModSourceInfo.getByUUID(modSourceInfoUUID);

        if (modSourceInfo == null) {
          return APIResponse.modelNotFound<ModSourceInfo>();
        }

        TranslateStatusScript.addToQueue(modSourceInfoUUID);
      }

      sourceFile = sourceFile.copyWith(
          modSourceInfoUUID: modSourceInfoUUID,
          path: path,
          type: type,
          storageUUID: storageUUID,
          sources: sourceTexts != null
              ? (List.from(sourceFile.sources)
                ..addAll(sourceTexts.map((e) => e.uuid))
                ..toSet()
                ..toList())
              : null);
      await sourceFile.update();

      if (storageUUID != null) {
        (await sourceFile.storage)?.delete();
      }

      return APIResponse.success(data: sourceFile.outputMap());
    },
        requiredFields: ['uuid'],
        authConfig: AuthConfig(role: UserRoleType.translationManager));

    /// Delete source file and all source texts in it
    router.deleteRoute('/source-file/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      SourceFile? sourceFile = await SourceFile.getByUUID(uuid);
      if (sourceFile == null) {
        return APIResponse.modelNotFound<SourceFile>();
      }

      await sourceFile.delete();
      TranslateStatusScript.addToQueue(sourceFile.modSourceInfoUUID);

      return APIResponse.success(data: null);
    },
        requiredFields: ['uuid'],
        authConfig: AuthConfig(role: UserRoleType.translationManager));
  }

  void modSourceInfo(Router router) {
    /// Get mod source info by uuid
    router.getRoute('/mod-source-info/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      final ModSourceInfo? modSourceInfo = await ModSourceInfo.getByUUID(uuid);

      if (modSourceInfo == null) {
        return APIResponse.modelNotFound<ModSourceInfo>();
      }

      return APIResponse.success(data: modSourceInfo.outputMap());
    }, requiredFields: ['uuid']);

    /// List mod source info
    router.getRoute('/mod-source-info', (req, data) async {
      Map<String, dynamic> fields = data.fields;
      final String? name = fields['name'];
      final String? namespace = fields['namespace'];
      final String? modUUID = fields['modUUID'];

      int limit =
          fields['limit'] != null ? int.tryParse(fields['limit']) ?? 50 : 50;
      final int skip =
          fields['skip'] != null ? int.tryParse(fields['skip']) ?? 0 : 0;

      // Max limit is 50
      if (limit > 50) {
        limit = 50;
      }
      List<ModSourceInfo> infos = [];

      if (namespace != null) {
        final List<ModSourceInfo> results = await DataBase.instance
            .getModelsWithSelector<ModSourceInfo>(where
                .match('namespace', '(?i)$namespace')
                .limit(limit)
                .skip(skip));

        infos.addAll(results);
      } else if (name != null) {
        List<MinecraftMod> mods = await MinecraftHeader.searchMods(
            filter: name, limit: limit, skip: skip);

        for (MinecraftMod mod in mods) {
          if (infos.map((e) => e.modUUID).contains(mod.uuid)) {
            continue;
          }

          final ModSourceInfo? modSourceInfo =
              await ModSourceInfo.getByModUUID(mod.uuid);

          if (modSourceInfo != null) {
            infos.add(modSourceInfo);
          }
        }
      } else {
        final List<ModSourceInfo> results =
            await DataBase.instance.getModelsByField<ModSourceInfo>([
          if (modUUID != null) ModelField('modUUID', modUUID),
        ], limit: limit, skip: skip);

        infos.addAll(results);
      }

      return APIResponse.success(
          data: ListModelResponse.fromModel(infos, limit, skip));
    });

    /// Add mod source info
    router.postRoute('/mod-source-info', (req, data) async {
      Map<String, dynamic> fields = data.fields;
      final String? modUUID = fields['modUUID'];
      final String namespace = fields['namespace']!;
      final List<String>? patchouliAddons = fields['patchouliAddons'] != null
          ? fields['patchouliAddons']!.cast<String>()
          : null;

      if (namespace.isAllEmpty) {
        return APIResponse.fieldEmpty('namespace');
      }

      if (modUUID != null) {
        final MinecraftMod? mod = await MinecraftMod.getByUUID(modUUID);
        if (mod == null) {
          return APIResponse.modelNotFound<MinecraftMod>();
        }

        final ModSourceInfo? modSourceInfo =
            await ModSourceInfo.getByModUUID(modUUID);

        if (modSourceInfo != null) {
          return APIResponse.badRequest(
              message:
                  'This mod uuid has already been added by another mod source info');
        }
      }

      if (patchouliAddons != null) {
        for (String addonUUID in patchouliAddons) {
          SourceText? sourceText = await SourceText.getByUUID(addonUUID);
          if (sourceText == null) {
            return APIResponse.modelNotFound<SourceText>();
          }
        }
      }

      final ModSourceInfo info = ModSourceInfo(
          uuid: Uuid().v4(),
          modUUID: modUUID,
          namespace: namespace,
          patchouliAddons: patchouliAddons);

      await info.insert();
      TranslateStatusScript.addToQueue(info.uuid);

      return APIResponse.success(data: info.outputMap());
    },
        requiredFields: ['namespace'],
        authConfig: AuthConfig(role: UserRoleType.translationManager));

    /// Edit mod source info
    router.patchRoute('/mod-source-info/<uuid>', (req, data) async {
      Map<String, dynamic> fields = data.fields;
      final String uuid = fields['uuid']!;

      ModSourceInfo? modSourceInfo = await ModSourceInfo.getByUUID(uuid);
      if (modSourceInfo == null) {
        return APIResponse.modelNotFound<ModSourceInfo>();
      }

      final String? modUUID = fields['modUUID'];
      final String? namespace = fields['namespace'];
      final List<String>? patchouliAddons = fields['patchouliAddons'] != null
          ? fields['patchouliAddons']!.cast<String>()
          : null;

      if (modUUID != null) {
        final MinecraftMod? mod = await MinecraftMod.getByUUID(modUUID);
        if (mod == null) {
          return APIResponse.modelNotFound<MinecraftMod>();
        }

        final ModSourceInfo? modSourceInfo =
            await ModSourceInfo.getByModUUID(modUUID);

        if (modSourceInfo != null) {
          return APIResponse.badRequest(
              message:
                  'This mod uuid has already been added by another mod source info');
        }
      }

      if (patchouliAddons != null) {
        List<String> needCheckUUIDs = patchouliAddons
            .where((e) =>
                (modSourceInfo!.patchouliAddons?.contains(e) ?? false) == false)
            .toList();

        for (String uuid in needCheckUUIDs) {
          SourceText? sourceText = await SourceText.getByUUID(uuid);
          if (sourceText == null) {
            return APIResponse.modelNotFound<SourceText>();
          }
        }
      }

      if (namespace != null && (namespace.isAllEmpty)) {
        return APIResponse.fieldEmpty('namespace');
      }

      modSourceInfo = modSourceInfo.copyWith(
          modUUID: modUUID,
          namespace: namespace,
          patchouliAddons: patchouliAddons);

      await modSourceInfo.update();
      TranslateStatusScript.addToQueue(modSourceInfo.uuid);

      return APIResponse.success(data: modSourceInfo.outputMap());
    },
        requiredFields: ['uuid'],
        authConfig: AuthConfig(role: UserRoleType.translationManager));

    /// Delete mod source info
    router.deleteRoute('/mod-source-info/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      ModSourceInfo? modSourceInfo = await ModSourceInfo.getByUUID(uuid);
      if (modSourceInfo == null) {
        return APIResponse.modelNotFound<ModSourceInfo>();
      }

      List<SourceFile> files = await modSourceInfo.files;
      for (SourceFile file in files) {
        await file.delete();
      }

      List<String>? patchouliAddons = modSourceInfo.patchouliAddons;
      if (patchouliAddons != null) {
        for (String addonUUID in patchouliAddons) {
          SourceText? sourceText = await SourceText.getByUUID(addonUUID);
          await sourceText?.delete();
        }
      }

      await modSourceInfo.delete();
      TranslateStatusScript.addToQueue(modSourceInfo.uuid);

      return APIResponse.success(data: null);
    },
        requiredFields: ['uuid'],
        authConfig: AuthConfig(role: UserRoleType.translationManager));
  }

  void glossary(Router router) {
    /// Get glossary
    router.getRoute('/glossary/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid'];

      Glossary? glossary = await Glossary.getByUUID(uuid);
      if (glossary == null) {
        return APIResponse.modelNotFound<Glossary>();
      }

      return APIResponse.success(data: glossary.outputMap());
    }, requiredFields: ['uuid']);

    /// Add glossary
    router.postRoute('/glossary', (req, data) async {
      final String term = data.fields['term']!;
      final String translation = data.fields['translation']!;
      final String? description = data.fields['description'];
      final Locale language = Locale.parse(data.fields['language']!);
      final String? modUUID = data.fields['modUUID'];

      if (!TranslateHandler.supportedLanguage.contains(language)) {
        return APIResponse.badRequest(
            message: 'RPMTranslator doesn\'t support this language');
      }

      if (modUUID != null) {
        MinecraftMod? mod = await MinecraftMod.getByUUID(modUUID);
        if (mod == null) {
          return APIResponse.modelNotFound<MinecraftMod>();
        }
      }

      if (term.isAllEmpty) {
        return APIResponse.fieldEmpty('term');
      }

      if (translation.isAllEmpty) {
        return APIResponse.fieldEmpty('translation');
      }

      if (description != null && description.isAllEmpty) {
        return APIResponse.fieldEmpty('description');
      }

      final Glossary glossary = Glossary(
        uuid: Uuid().v4(),
        term: term,
        translation: translation,
        description: description,
        language: language,
        modUUID: modUUID,
      );

      await glossary.insert();

      return APIResponse.success(data: glossary.outputMap());
    },
        requiredFields: ['term', 'translation', 'language'],
        authConfig: AuthConfig());

    /// List glossaries
    router.getRoute('/glossary', (req, data) async {
      Map<String, dynamic> fields = data.fields;

      final Locale? language =
          fields['language'] != null ? Locale.parse(fields['language']) : null;
      final String? modUUID = fields['modUUID'];
      final String? filter = fields['filter'];
      int limit =
          fields['limit'] != null ? int.tryParse(fields['limit']) ?? 50 : 50;
      final int skip =
          fields['skip'] != null ? int.tryParse(fields['skip']) ?? 0 : 0;

      // Max limit is 50
      if (limit > 50) {
        limit = 50;
      }

      final List<Glossary> glossaries = await Glossary.list(
          language: language,
          modUUID: modUUID,
          filter: filter,
          limit: limit,
          skip: skip);

      return APIResponse.success(
          data: ListModelResponse.fromModel(glossaries, limit, skip));
    }, authConfig: AuthConfig());

    /// Edit glossary
    router.patchRoute('/glossary/<uuid>', (req, data) async {
      Map<String, dynamic> fields = data.fields;
      final String uuid = fields['uuid']!;
      Glossary? glossary = await Glossary.getByUUID(uuid);
      if (glossary == null) {
        return APIResponse.modelNotFound<Glossary>();
      }

      final String? term = fields['term'];
      final String? translation = fields['translation'];
      final String? description = fields['description'];
      late final String? modUUID;

      /// Avoid not setting modUUID to null in the request json, resulting in setting modUUID to null.
      String body = data.body;
      if (body.contains('modUUID')) {
        modUUID = fields['modUUID'];
      } else {
        modUUID = glossary.modUUID;
      }

      if (modUUID != null) {
        MinecraftMod? mod = await MinecraftMod.getByUUID(modUUID);
        if (mod == null) {
          return APIResponse.modelNotFound<MinecraftMod>();
        }
      }

      if (term != null && term.isAllEmpty) {
        return APIResponse.fieldEmpty('term');
      }

      if (translation != null && translation.isAllEmpty) {
        return APIResponse.fieldEmpty('translation');
      }

      if (description != null && description.isAllEmpty) {
        return APIResponse.fieldEmpty('description');
      }

      glossary = glossary.copyWith(
        term: term,
        translation: translation,
        description: description,
        modUUID: modUUID,
      );

      await glossary.update();

      return APIResponse.success(data: glossary.outputMap());
    }, requiredFields: ['uuid'], authConfig: AuthConfig());

    /// Delete glossary
    router.deleteRoute('/glossary/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;

      Glossary? glossary = await Glossary.getByUUID(uuid);
      if (glossary == null) {
        return APIResponse.modelNotFound<Glossary>();
      }

      await glossary.delete();

      return APIResponse.success(data: null);
    }, requiredFields: ['uuid'], authConfig: AuthConfig());

    /// Get glossaries from text
    router.getRoute('/glossary-highlight', (req, data) async {
      final String text = data.fields['text']!;
      final Locale language = Locale.parse(data.fields['language']!);

      final List<String> words =
          text.split(' ').where((w) => !w.isAllEmpty).toSet().toList();
      Map<String, Glossary> result = {};

      for (String word in words) {
        Grammer grammer = Grammer(word);

        Future<Glossary?> get(String str) async {
          List<Glossary> glossaries =
              await Glossary.list(filter: str, language: language, limit: 1);
          if (glossaries.isNotEmpty) {
            return glossaries.first;
          } else {
            return null;
          }
        }

        List<String> strings = [grammer.toSingular(), ...grammer.toPlural()];

        for (String str in strings) {
          Glossary? glossary = await get(str);
          if (glossary != null) {
            result[word] = glossary;
            break;
          }
        }
      }

      return APIResponse.success(
          data: result.map((key, value) => MapEntry(key, value.toMap())));
    }, requiredFields: ['text', 'language']);
  }

  void translateStatus(Router router) {
    /// Get translate status by mod source info
    router.getRoute('/status/<uuid>', (req, data) async {
      String infoUUID = data.fields['uuid']!;

      ModSourceInfo? info = await ModSourceInfo.getByUUID(infoUUID);
      if (info == null) {
        return APIResponse.modelNotFound<ModSourceInfo>();
      }

      TranslateStatus status =
          await TranslateHandler.updateOrCreateStatus(info);

      return APIResponse.success(data: status.outputMap());
    }, requiredFields: ['uuid']);

    /// Get global translate status
    router.getRoute('/status', (req, data) async {
      TranslateStatus? status =
          await TranslateStatus.getByModSourceInfoUUID(null);

      status ??= await TranslateHandler.updateOrCreateStatus(null);

      return APIResponse.success(data: status.outputMap());
    });
  }

  void translatorInfo(Router router) {
    /// Get translator info by uuid.
    router.getRoute('/translator-info/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;
      TranslatorInfo? info = await TranslatorInfo.getByUUID(uuid);
      if (info == null) {
        return APIResponse.modelNotFound<TranslatorInfo>();
      }

      return APIResponse.success(data: info.outputMap());
    }, requiredFields: ['uuid']);

    /// Get translator info by user uuid.
    router.getRoute('/translator-info/user/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;
      String _uuid;
      if (uuid == 'me') {
        _uuid = req.user!.uuid;
      } else {
        _uuid = uuid;
      }

      TranslatorInfo? info = await TranslatorInfo.getByUserUUID(_uuid);
      if (info == null) {
        return APIResponse.modelNotFound<TranslatorInfo>();
      }

      return APIResponse.success(data: info.outputMap());
    },
        requiredFields: ['uuid'],
        authConfig: AuthConfig(path: '/translate/translator-info/user/me'));

    /// Get translate report sort by start/end time.
    router.postRoute('/report', (req, data) async {
      Map<String, dynamic> fields = data.fields;
      final DateTime startTime = DateTime.fromMillisecondsSinceEpoch(
          fields['startTime']!,
          isUtc: true);
      final DateTime endTime =
          DateTime.fromMillisecondsSinceEpoch(fields['endTime']!, isUtc: true);
      final TranslateReportSortType sortType =
          TranslateReportSortType.values.byName(fields['sortType']!);

      int limit = fields['limit'] != null ? fields['limit'] ?? 50 : 50;
      final int skip = fields['skip'] != null ? fields['skip'] ?? 0 : 0;

      if (limit > 50) {
        limit = 50;
      }
      String fieldName = sortType.fieldName;

      AggregationPipelineBuilder pipeline = AggregationPipelineBuilder();
      pipeline.addStage(Unwind(Field(fieldName)));
      pipeline.addStage(Group(id: Field('_id'), fields: {
        'uuid': First(Field('uuid')),
        'userUUID': First(Field('userUUID')),
        'joinAt': First(Field('joinAt')),
        'translatedCount': AddToSet(Sum(Field('translatedCount'))),
        'votedCount': AddToSet(Sum(Field('votedCount'))),
        'sort_count': Sum(1)
      }));
      pipeline.addStage(Sort({'sort_count': -1}));
      pipeline.addStage(Limit(limit));
      pipeline.addStage(Skip(skip));

      /// match start/end time
      pipeline.addStage(Match(where
          .gte(fieldName, startTime.millisecondsSinceEpoch)
          .lte(fieldName, endTime.millisecondsSinceEpoch)
          .map['\$query']));

      List<TranslatorInfo> infos = (await DataBase.instance
              .getCollection<TranslatorInfo>()
              .modernAggregate(pipeline)
              .toList())
          .map((e) {
        Map<String, dynamic> _map = e;
        // TODO: Improve handling the map, this is only a temporary solution
        _map['translatedCount'] = (_map['translatedCount'] as List)..remove(0);
        _map['votedCount'] = (_map['votedCount'] as List)..remove(0);

        return TranslatorInfo.fromMap(_map);
      }).toList();

      return APIResponse.success(
          data: ListModelResponse.fromModel(infos, limit, skip));
    }, requiredFields: ['startTime', 'endTime', 'sortType']);
  }

  void other(Router router) {
    /// Export translation
    router.getRoute('/export', (req, data) async {
      final List<String> namespaces =
          data.fields['namespaces']!.toString().split(',');
      final Locale language = Locale.parse(data.fields['language']!);
      final TranslationExportFormat format =
          TranslationExportFormat.values.byName(data.fields['format']!);
      final MinecraftVersion? version =
          await MinecraftVersion.getByID(data.fields['version']!);

      if (version == null ||
          TranslateHandler.supportedVersion.contains(version.id) == false) {
        return APIResponse.badRequest(message: 'Invalid game version');
      }

      List<ModSourceInfo> infos = [];
      for (String namespace in namespaces) {
        ModSourceInfo? info = await ModSourceInfo.getByNamespace(namespace);
        if (info != null) {
          infos.add(info);
        }
      }

      Map<String, String> output = {};

      for (ModSourceInfo info in infos) {
        TranslationExportCache? _cache =
            await TranslationExportCache.getByInfos(
                info.uuid, language, format);

        if (_cache != null && !_cache.isExpired) {
          output.addAll(_cache.data);
          continue;
        }

        TranslationExportCache cache;
        if (_cache != null && _cache.isExpired) {
          cache =
              _cache.copyWith(data: {}, lastUpdated: RPMTWUtil.getUTCTime());
        } else {
          TranslationExportCache _ = TranslationExportCache(
              uuid: Uuid().v4(),
              modSourceInfoUUID: info.uuid,
              language: language,
              format: format,
              data: {},
              lastUpdated: RPMTWUtil.getUTCTime());
          await _.insert();
          cache = _;
        }

        Future<void> handleTexts(List<SourceText> texts) async {
          texts = texts.where((e) => e.gameVersions.contains(version)).toList();

          for (SourceText text in texts) {
            Translation? translation =
                await TranslateHandler.getBestTranslation(text, language);
            if (translation != null) {
              output[text.key] = translation.content;
              cache = cache.copyWith(
                  data: cache.data..[text.key] = translation.content);
            }
          }
        }

        final List<SourceFile> files = await info.files;

        if (format == TranslationExportFormat.minecraftJson) {
          List<SourceText> texts = [];
          for (SourceFile file in files) {
            (await file.sourceTexts).forEach(texts.add);
          }
          await handleTexts(texts);
        } else if (format == TranslationExportFormat.patchouli) {
          final List<SourceText>? texts = await info.patchouliAddonTexts;
          if (texts != null) {
            await handleTexts(texts);
          }
        } else if (format == TranslationExportFormat.customText) {
          List<SourceFile> customTextFiles = files
              .where((e) =>
                  e.type == SourceFileType.plainText ||
                  e.type == SourceFileType.customJson)
              .toList();

          for (SourceFile file in customTextFiles) {
            final List<SourceText> texts = (await file.sourceTexts)
                .where((e) => e.gameVersions.contains(version))
                .toList();

            Storage? sourceStorage = await file.storage;
            if (sourceStorage == null) {
              logger.e(
                  '[Export translation] Source file (${file.uuid}) storage not found.');
              continue;
            }

            String sourceContent = await sourceStorage.readAsString();
            String? translatedContent;

            for (SourceText text in texts) {
              Translation? translation =
                  await TranslateHandler.getBestTranslation(text, language);
              if (translation != null) {
                translatedContent =
                    sourceContent.replaceAll(text.source, translation.content);
              }
            }

            if (translatedContent != null) {
              output[file.path] = translatedContent;
              cache = cache.copyWith(
                  data: cache.data..[file.path] = translatedContent);
            }
          }
        }

        await cache.update();
      }

      return APIResponse.success(data: output);
    }, requiredFields: ['namespaces', 'format', 'language', 'version']);
  }
}
