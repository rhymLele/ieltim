import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/routes/redirect_path.dart';

void main() {
  test('accessPathFor giữ trang đích trong ?from=', () {
    expect(accessPathFor('/weekly/doc/w12-doc1'), '/access?from=%2Fweekly%2Fdoc%2Fw12-doc1');
    expect(accessPathFor('/'), '/access');
    expect(accessPathFor('/home'), '/access');
  });

  test('safeRedirectPath chỉ nhận đường dẫn nội bộ', () {
    expect(safeRedirectPath('/weekly/doc/w12-doc1'), '/weekly/doc/w12-doc1');
    expect(safeRedirectPath('/admin/weekly-docs?week=12'), '/admin/weekly-docs?week=12');
    expect(safeRedirectPath(null), isNull);
    expect(safeRedirectPath('https://evil.example'), isNull);
    expect(safeRedirectPath('//evil.example/x'), isNull);
    expect(safeRedirectPath('/access?from=/home'), isNull);
    expect(safeRedirectPath('/'), isNull);
  });
}
