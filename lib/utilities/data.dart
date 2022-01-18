import 'package:dotenv/dotenv.dart';
import 'package:logger/logger.dart';

Logger logger =
    Logger(printer: PrettyPrinter(colors: false), filter: _LogFilter());

Logger loggerNoStack = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: false),
    filter: _LogFilter());

bool kTestMode = false;

class Data {
  static Future<void> init() async {
    load();
  }
}

class _LogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    /// 永遠啟用日誌輸出
    return true;
  }
}
