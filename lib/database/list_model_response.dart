import 'package:rpmtw_server/database/db_model.dart';

class ListModelResponse {
  final List<Map<String, dynamic>> data;
  final int limit;
  final int skip;

  int get total => data.length;

  const ListModelResponse._(this.data, this.limit, this.skip);

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'limit': limit,
      'skip': skip,
      'total': total,
    };
  }

  static ListModelResponse fromModel<T extends DBModel>(
      List<T> model, int limit, int skip) {
    return ListModelResponse._(
        model.map((e) => e.outputMap()).toList(), limit, skip);
  }
}
