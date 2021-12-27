import 'package:dotenv/dotenv.dart';
import 'package:logger/logger.dart';

Logger get logger => Data._logger;

class Data {
  static late Logger _logger;

  static Future<void> init() async {
    load();
    _logger = Logger();
  }
}
