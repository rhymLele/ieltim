import '../../../../core/widgets/annotate/models.dart';

/// Gộp ghi chú một slide khi lưu bị 409 (máy khác lưu trước), theo `id` từng nét / chữ / ghim:
/// - có ở cả hai bản: giữ bản trên máy này (sửa chữ ghi chú ở máy này thắng);
/// - chỉ có ở một bản: [base] (bản chung lần đồng bộ trước) cũng có → bản kia đã xoá → bỏ; không có → mới thêm → giữ.
/// Thứ tự: theo bản máy chủ, rồi tới các mục chỉ máy này có.
SlideAnnotations mergeSlideAnnotations({required SlideAnnotations base, required SlideAnnotations local, required SlideAnnotations remote}) {
  final baseIds = _ids(base);
  final localItems = _itemsById(local);
  final remoteItems = _itemsById(remote);
  final merged = <Map<String, dynamic>>[];
  for (final MapEntry(key: id, value: item) in remoteItems.entries) {
    final mine = localItems[id];
    if (mine != null) {
      merged.add(mine);
    } else if (!baseIds.contains(id)) {
      merged.add(item); // máy kia mới thêm
    }
    // Còn lại: máy này đã xoá.
  }
  for (final MapEntry(key: id, value: item) in localItems.entries) {
    if (!remoteItems.containsKey(id) && !baseIds.contains(id)) merged.add(item); // máy này mới thêm
  }
  return SlideAnnotations.fromJson({'items': merged});
}

Set<String> _ids(SlideAnnotations a) => _itemsById(a).keys.toSet();

Map<String, Map<String, dynamic>> _itemsById(SlideAnnotations a) {
  final items = a.toJson()['items'] as List;
  return {for (final item in items.cast<Map<String, dynamic>>()) item['id'] as String: item};
}
