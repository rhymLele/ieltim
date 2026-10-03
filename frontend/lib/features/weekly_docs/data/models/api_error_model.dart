import 'package:json_annotation/json_annotation.dart';

part 'api_error_model.g.dart';

/// Thân lỗi chung của BE: `{ status: "error", message, error: <MÃ>, code: <HTTP>, data }`.
/// `data` khác nhau theo mã lỗi nên đọc riêng ([VersionConflictModel], [ValidationResultModel]).
@JsonSerializable(createToJson: false)
class ApiErrorModel {
  const ApiErrorModel({required this.message, this.error});

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) => _$ApiErrorModelFromJson(json);

  /// Mã nghiệp vụ, vd `DOC_ORDER_TAKEN`.
  final String? error;

  /// Lỗi kiểm tra DTO của BE trả mảng câu thông báo → nối thành một chuỗi.
  @_MessageConverter()
  final String message;
}

class _MessageConverter implements JsonConverter<String, Object?> {
  const _MessageConverter();

  @override
  String fromJson(Object? json) => switch (json) {
        final String text => text,
        final List<Object?> lines => lines.join('\n'),
        _ => 'Có lỗi xảy ra, thử lại sau.',
      };

  @override
  Object? toJson(String message) => message;
}
