import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/home/presentation/views/home_page.dart';

void main() {
  DateTime at(int hour) => DateTime(2026, 1, 1, hour);

  test('greeting follows the time of day', () {
    expect(greetingFor(at(4)), 'Good evening');
    expect(greetingFor(at(5)), 'Good morning');
    expect(greetingFor(at(11)), 'Good morning');
    expect(greetingFor(at(12)), 'Good afternoon');
    expect(greetingFor(at(17)), 'Good afternoon');
    expect(greetingFor(at(18)), 'Good evening');
    expect(greetingFor(at(23)), 'Good evening');
  });
}
