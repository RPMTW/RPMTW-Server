import "dart:async";

import "package:dotenv/dotenv.dart";
import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/models/auth/auth_code_.dart";
import "package:rpmtw_server/database/models/auth/ban_info.dart";
import "package:rpmtw_server/database/models/comment/comment.dart";
import "package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_message.dart";
import "package:rpmtw_server/database/models/index_fields.dart";
import "package:rpmtw_server/database/models/minecraft/minecraft_mod.dart";
import "package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart";
import "package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart";
import "package:rpmtw_server/database/models/model_field.dart";
import "package:rpmtw_server/database/models/translate/glossary.dart";
import "package:rpmtw_server/database/models/translate/mod_source_info.dart";
import "package:rpmtw_server/database/models/translate/source_file.dart";
import "package:rpmtw_server/database/models/translate/source_text.dart";
import "package:rpmtw_server/database/models/translate/translation.dart";
import "package:rpmtw_server/database/models/translate/translation_vote.dart";
import "package:rpmtw_server/data/user_view_count_filter.dart";
import "package:rpmtw_server/utilities/utility.dart";

import "../utilities/data.dart";
import "models/auth/user.dart";
import "models/base_models.dart";
import "models/storage/storage.dart";

class DataBase {
  static late Db _mongoDB;
  static late DataBase _instance;
  static DataBase get instance => _instance;
  Db get db => _mongoDB;
  GridFS get gridFS => GridFS(DataBase.instance.db);

  DataBase() {
    try {
      startTimer();
    } catch (e, stack) {
      logger.e(e, null, stack);
    }
  }

  static late List<DbCollection> collectionList;

  static Future<DataBase> _open() async {
    collectionList = [];

    List<String> collectionNameList = [
      User.collectionName,
      Storage.collectionName,
      AuthCode.collectionName,
      MinecraftMod.collectionName,
      BanInfo.collectionName,
      MinecraftVersionManifest.collectionName,
      WikiChangeLog.collectionName,
      CosmicChatMessage.collectionName,
      Translation.collectionName,
      TranslationVote.collectionName,
      SourceText.collectionName,
      ModSourceInfo.collectionName,
      SourceFile.collectionName,
      Glossary.collectionName,
      Comment.collectionName,
    ];

    List<List<IndexField>> indexFields = [
      User.indexFields,
      Storage.indexFields,
      AuthCode.indexFields,
      MinecraftMod.indexFields,
      BanInfo.indexFields,
      MinecraftVersionManifest.indexFields,
      WikiChangeLog.indexFields,
      CosmicChatMessage.indexFields,
      Translation.indexFields,
      TranslationVote.indexFields,
      SourceText.indexFields,
      ModSourceInfo.indexFields,
      SourceFile.indexFields,
      Glossary.indexFields,
      Comment.indexFields,
    ];

    List<String?> collections = await _mongoDB.getCollectionNames();
    Future<void> checkCollection(String name, List<IndexField> indexFields,
        {bool needCreateIndex = false}) async {
      if (!collections.contains(name)) {
        await _mongoDB.createCollection(name);
        await _mongoDB.createIndex(name,
            key: "uuid", name: "uuid", unique: true);
      }

      if (needCreateIndex) {
        for (IndexField field in indexFields) {
          await _mongoDB.createIndex(name,
              key: field.name, name: field.name, unique: field.unique);
        }
      }
    }

    for (String name in collectionNameList) {
      DbCollection collection = _mongoDB.collection(name);

      List<Map<String, dynamic>> indexes = await collection.getIndexes();
      List<String> indexFieldsName =
          indexes.map((index) => index["name"] as String).toList();
      List<IndexField> _indexFields =
          indexFields[collectionNameList.indexOf(name)];
      await checkCollection(name, _indexFields,
          needCreateIndex: !collections.contains(name) ||
              _indexFields
                  .any((field) => !indexFieldsName.contains(field.name)));
      collectionList.add(collection);
    }

    return DataBase();
  }

  static Future<void> init() async {
    String url;

    if (kTestMode) {
      url = "mongodb://127.0.0.1:27017/test";
    } else {
      url = env["DATA_BASE_URL"] ?? "mongodb://127.0.0.1:27017/rpmtw_data";
    }

    _mongoDB = await Db.create(url);
    await _mongoDB.open();
    if (kTestMode) {
      await _mongoDB.drop(); // Drop test database
    }
    _instance = await DataBase._open();
    loggerNoStack.i("Successfully connected to the database");
  }

  DbCollection getCollection<T extends DBModel>([String? runtimeType]) {
    Map<String, DbCollection> modelTypeMap = {
      "User": collectionList[0],
      "Storage": collectionList[1],
      "AuthCode": collectionList[2],
      "MinecraftMod": collectionList[3],
      "BanInfo": collectionList[4],
      "MinecraftVersionManifest": collectionList[5],
      "WikiChangeLog": collectionList[6],
      "CosmicChatMessage": collectionList[7],
      "Translation": collectionList[8],
      "TranslationVote": collectionList[9],
      "SourceText": collectionList[10],
      "ModSourceInfo": collectionList[11],
      "SourceFile": collectionList[12],
      "Glossary": collectionList[13],
      "Comment": collectionList[14],
    };

    return modelTypeMap[runtimeType ?? T.toString()]!;
  }

  T getModelByMap<T extends DBModel>(Map<String, dynamic> map) {
    Map<String, T Function(Map<String, dynamic>)> modelTypeMap = {
      "User": User.fromMap,
      "Storage": Storage.fromMap,
      "AuthCode": AuthCode.fromMap,
      "MinecraftMod": MinecraftMod.fromMap,
      "BanInfo": BanInfo.fromMap,
      "MinecraftVersionManifest": MinecraftVersionManifest.fromMap,
      "WikiChangeLog": WikiChangeLog.fromMap,
      "CosmicChatMessage": CosmicChatMessage.fromMap,
      "Translation": Translation.fromMap,
      "TranslationVote": TranslationVote.fromMap,
      "SourceText": SourceText.fromMap,
      "ModSourceInfo": ModSourceInfo.fromMap,
      "SourceFile": SourceFile.fromMap,
      "Glossary": Glossary.fromMap,
      "Comment": Comment.fromMap,
    }.cast<String, T Function(Map<String, dynamic>)>();

    T Function(Map<String, dynamic>) factory = modelTypeMap[T.toString()]!;
    return factory(map);
  }

  Future<T?> getModelByUUID<T extends DBModel>(String uuid) =>
      getModelByField<T>("uuid", uuid);

  Future<T?> getModelByField<T extends DBModel>(
      String fieldName, dynamic value) async {
    Map<String, dynamic>? map =
        await getCollection<T>().findOne(where.eq(fieldName, value));

    return map != null ? getModelByMap<T>(map) : null;
  }

  Future<T?> getModelWithSelector<T extends DBModel>(
      SelectorBuilder selector) async {
    Map<String, dynamic>? map = await getCollection<T>().findOne(selector);

    return map != null ? getModelByMap<T>(map) : null;
  }

  Future<List<T>> getModelsWithSelector<T extends DBModel>(
      SelectorBuilder selector) async {
    List<Map<String, dynamic>> maps =
        await getCollection<T>().find(selector).toList();

    return maps.map((map) => getModelByMap<T>(map)).toList();
  }

  Future<List<T>> getModelsByField<T extends DBModel>(List<ModelField> field,
      {int? limit, int? skip}) async {
    SelectorBuilder selector = SelectorBuilder();

    for (ModelField f in field) {
      selector = selector.eq(f.name, f.value);
    }

    if (limit != null) {
      selector = selector.limit(limit);
    }
    if (skip != null) {
      selector = selector.skip(skip);
    }

    List<Map<String, dynamic>>? list =
        await getCollection<T>().find(selector).toList();

    return list.map((m) => getModelByMap<T>(m)).toList();
  }

  Future<WriteResult> insertOneModel<T extends DBModel>(T model,
      {WriteConcern? writeConcern, bool? bypassDocumentValidation}) async {
    WriteResult result = await getCollection<T>(model.runtimeType.toString())
        .insertOne(model.toMap(),
            writeConcern: writeConcern,
            bypassDocumentValidation: bypassDocumentValidation);

    result.exceptionHandler(model);
    return result;
  }

  Future<WriteResult> replaceOneModel<T extends DBModel>(T model,
      {WriteConcern? writeConcern,
      CollationOptions? collation,
      String? hint,
      Map<String, Object>? hintDocument}) async {
    WriteResult result =
        await getCollection<T>(model.runtimeType.toString()).replaceOne(
      where.eq("uuid", model.uuid),
      model.toMap(),
      writeConcern: writeConcern,
      collation: collation,
      hint: hint,
      hintDocument: hintDocument,
    );

    result.exceptionHandler(model);

    return result;
  }

  Future<WriteResult> deleteOneModel<T extends DBModel>(T model,
      {WriteConcern? writeConcern,
      CollationOptions? collation,
      String? hint,
      Map<String, Object>? hintDocument}) async {
    WriteResult result =
        await getCollection<T>(model.runtimeType.toString()).deleteOne(
      where.eq("uuid", model.uuid),
      writeConcern: writeConcern,
      collation: collation,
      hint: hint,
      hintDocument: hintDocument,
    );

    result.exceptionHandler(model);

    return result;
  }

  Timer startTimer() {
    _startAllTimer(Utility.getUTCTime());
    Timer timer = Timer.periodic(Duration(hours: 1), (timer) async {
      DateTime time = Utility.getUTCTime();
      await _startAllTimer(time);
    });
    return timer;
  }

  Future<void> _startAllTimer(DateTime time) async {
    await _storageTimer(time);
    await _authCodeTimer(time);
    await _minecraftVersionManifest(time);
    ViewCountHandler.deleteFilters(time);
    await _wikiChangelogTimer(time);
    await _commentTimer(time);
  }

  Future<void> _storageTimer(DateTime time) async {
    /// 暫存檔案超過指定時間後將刪除
    /// 檔案最多暫存一天
    SelectorBuilder timeSelector = where.lte(
        "createAt", time.subtract(Duration(days: 1)).millisecondsSinceEpoch);

    SelectorBuilder selector = where
        // 檔案類型為暫存檔案
        .eq("type", StorageType.temp.name)
        .and(timeSelector)
        .or(where.eq("usageCount", 0).and(timeSelector));
    // 檔案建立時間為一天前

    List<Storage> storageList = await getCollection<Storage>()
        .find(selector)
        .map((map) => Storage.fromMap(map))
        .toList();

    for (Storage storage in storageList) {
      GridOut? gridOut = await gridFS.getFile(storage.uuid);

      /// 刪除實際的二進位檔案
      await gridOut?.fs.files.deleteOne(gridOut.data);
      await gridOut?.fs.chunks
          .deleteMany(where.eq("files_id", storage.uuid).sortBy("n"));

      /// 刪除儲存數據 model
      await storage.delete();
    }
  }

  Future<void> _authCodeTimer(DateTime time) async {
    /// 驗證碼最多暫存 30 分鐘
    SelectorBuilder selector = where.lte("expiresAt",
        time.subtract(Duration(minutes: 30)).millisecondsSinceEpoch);
    List<AuthCode> authCodeList = await getCollection<AuthCode>()
        .find(selector)
        .map((map) => AuthCode.fromMap(map))
        .toList();

    for (AuthCode authCode in authCodeList) {
      await authCode.delete();
    }
  }

  Future<void> _minecraftVersionManifest(DateTime time) async {
    /// 每天更新一次 Minecraft 版本資訊
    int timeStamp = time.subtract(Duration(days: 1)).millisecondsSinceEpoch;
    SelectorBuilder selector = where.gte("lastUpdated", timeStamp);
    DbCollection collection = getCollection<MinecraftVersionManifest>();
    List<Map<String, dynamic>> manifests =
        await collection.find(selector).toList();
    if (manifests.isEmpty) {
      ///如果為空則代表最後一次更新為一天前

      /// 刪除其他已經過期的資料
      await collection.deleteMany(where.lte("lastUpdated", timeStamp));

      ///從 Mojang API 取得 Minecraft 版本資訊
      MinecraftVersionManifest manifest =
          await MinecraftVersionManifest.getFromWeb();

      await manifest.insert();
    }
  }

  Future<void> _wikiChangelogTimer(DateTime time) async {
    /// 變更日誌超過指定時間後將刪除
    /// 變更日誌最多暫存 90 天 ( 約為三個月 )
    SelectorBuilder selector = where.lte(
        "time", time.subtract(Duration(days: 90)).millisecondsSinceEpoch);
    // 變更日誌建立時間為 90 天前

    List<WikiChangeLog> changelogs = await getCollection<WikiChangeLog>()
        .find(selector)
        .map((map) => WikiChangeLog.fromMap(map))
        .toList();

    for (WikiChangeLog log in changelogs) {
      await log.delete();
    }
  }

  /// When the comment is hidden and the time is over 7 days ( a week ), the comment will be deleted
  Future<void> _commentTimer(DateTime time) async {
    SelectorBuilder selector = where
        .lte("updatedAt",
            time.subtract(Duration(days: 7)).millisecondsSinceEpoch)
        .eq("isHidden", true);

    List<Comment> comments = await getCollection<Comment>()
        .find(selector)
        .map((map) => Comment.fromMap(map))
        .toList();

    for (Comment comment in comments) {
      await comment.delete();
    }
  }
}

class InsertModelException implements Exception {
  final String modelName;
  final String? errorMessage;

  InsertModelException(this.modelName, [this.errorMessage]);

  @override
  String toString() {
    return "InsertModelException: Failed to insert $modelName model.\n$errorMessage";
  }
}

extension WriteResultExtension on WriteResult {
  void exceptionHandler<T extends DBModel>(T model) {
    if (!success) {
      throw InsertModelException(T.toString(),
          writeError?.errmsg ?? writeConcernError?.errmsg ?? errmsg);
    }
  }
}
