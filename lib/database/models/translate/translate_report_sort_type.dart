enum TranslateReportSortType { translation, vote }

extension TranslateReportSortTypeExtension on TranslateReportSortType {
  String get fieldName {
    switch (this) {
      case TranslateReportSortType.translation:
        return 'translatedCount';
      case TranslateReportSortType.vote:
        return 'votedCount';
    }
  }
}
