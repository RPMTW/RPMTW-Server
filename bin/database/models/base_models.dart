import 'dart:convert';

abstract class BaseModels {
  final String uuid;

  const BaseModels({required this.uuid});

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
