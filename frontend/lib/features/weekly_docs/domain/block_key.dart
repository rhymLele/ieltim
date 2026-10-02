import 'models/weekly_doc.dart';

/// Khớp khoá của một khối trong tài liệu.
///
/// Trả [DocBlock.idOrNull] nếu có; nếu không thì `"$sectionIndex-$blockIndex"`.
String blockKey(int sectionIndex, int blockIndex, DocBlock block) {
  final id = block.idOrNull;
  return (id != null && id.isNotEmpty) ? id : '$sectionIndex-$blockIndex';
}
