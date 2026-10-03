import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/doc_json.dart';

/// Đọc / ghi trường `content` (JSON tài liệu admin soạn) — xem lý do giữ nguyên dạng ở [DocJson].
class DocJsonConverter implements JsonConverter<DocJson, Map<String, dynamic>> {
  const DocJsonConverter();

  @override
  DocJson fromJson(Map<String, dynamic> json) => DocJson(json);

  @override
  Map<String, dynamic> toJson(DocJson content) => Map<String, dynamic>.of(content.value);
}
