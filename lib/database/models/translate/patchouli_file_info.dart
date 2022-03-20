import "package:path/path.dart" as path;

class PatchouliFileInfo {
  final String namespace;
  final String bookName;
  final String fileFolder;
  final String fileName;

  const PatchouliFileInfo(
    this.namespace,
    this.bookName,
    this.fileFolder,
    this.fileName,
  );

  factory PatchouliFileInfo.parse(String filePath) {
    try {
      List<String> parts = path.split(filePath);
      int pbIndex = parts.indexOf("patchouli_books");

      final String fileName = path.basename(filePath);
      final String fileFolder =
          parts.sublist(pbIndex + 3, parts.length - 1).join("/");
      // final String langCode = parts[parts.length - 3];
      final String bookName = parts[pbIndex + 1];
      final String namespace = parts[pbIndex - 1];

      return PatchouliFileInfo(namespace, bookName, fileFolder, fileName);
    } catch (e) {
      throw Exception("Could not parse patchouli file path: $filePath");
    }
  }
}
