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
}
