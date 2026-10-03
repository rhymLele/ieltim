import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/routes/app_routes.dart';
import 'package:frontend/core/widgets/app_layout.dart';

void main() {
  int indexOf(String location) => tabIndexForLocation(allTabs, location);
  String? labelOf(String location) {
    final i = indexOf(location);
    return i < 0 ? null : allTabs[i].label;
  }

  test('tab đang chọn theo URL: trùng route hoặc tiền tố dài nhất', () {
    expect(labelOf(AppRoutes.home), 'Home');
    expect(labelOf(AppRoutes.weeklyDoc('w12-doc1')), 'Theo tuần');
    expect(labelOf(AppRoutes.weeklyDocDone('w12-doc1')), 'Theo tuần');
    expect(labelOf(AppRoutes.adminVocabularyCreate), 'Từ vựng');
    expect(labelOf(AppRoutes.adminDocumentCreate), 'Quản lý tài liệu');
    expect(labelOf(AppRoutes.adminWeeklyDocEdit('w12-doc2')), 'Tài liệu tuần');
  });

  test('không khớp tab nào → -1; tiền tố phải trọn đoạn đường dẫn', () {
    expect(indexOf('/lessons/abc'), -1);
    expect(indexOf('/weeklyx'), -1);
  });

  test('key điều hướng ổn định theo route', () {
    final weeklyDocs = allTabs.firstWhere((t) => t.route == AppRoutes.adminWeeklyDocs);
    expect(weeklyDocs.navKey, const Key('nav_admin_weekly_docs_tab'));
  });
}
