import 'dart:convert';

abstract class BaseModels {
  Map<String, dynamic> toMap() {
    throw UnimplementedError();
  }

  String toJson() {
    return json.encode(toMap());
  }

  Map<String, dynamic> outputMap() {
    throw UnimplementedError();
  }

  factory BaseModels.fromMap(Map<String, dynamic> map) {
    throw UnimplementedError();
  }

  factory BaseModels.fromJson(String source) {
    return BaseModels.fromMap(json.decode(source));
  }
}
