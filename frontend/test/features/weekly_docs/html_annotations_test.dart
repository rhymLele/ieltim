import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/di/service_locator.dart';
import 'package:frontend/core/services/logger_service.dart';
import 'package:frontend/core/widgets/annotate/annotate.dart';
import 'package:frontend/features/annotate/data/datasources/fake_annotate_remote_datasource.dart';
import 'package:frontend/features/annotate/data/repositories/annotate_repository_impl.dart';
import 'package:frontend/features/annotate/domain/repositories/annotate_repository.dart';
import 'package:frontend/features/vocab/data/repositories/fake_vocab_repository.dart';
import 'package:frontend/features/vocab/domain/repositories/vocab_repository.dart';
import 'package:frontend/features/weekly_docs/domain/entities/weekly_doc.dart';
import 'package:frontend/features/weekly_docs/domain/rules/doc_templates.dart';
import 'package:frontend/features/weekly_docs/presentation/widgets/annotate/html_reader_annotations.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _swatch(HighlightColor color) =>
    find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).color == color.color);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    registerSingleton<LoggerService>(LoggerService(Logger(level: Level.off)));
    registerSingleton<VocabRepository>(FakeVocabRepository());
    registerSingleton<AnnotateRepository>(
      AnnotateRepositoryImpl(remote: FakeAnnotateRemoteDataSource(latency: Duration.zero), currentUserId: () async => 'u1', saveDelay: Duration.zero),
    );
  });
  tearDown(resetSingletons);

  testWidgets('hộp thoại đè lên file HTML: mở thì chuột đi xuyên iframe tới hộp thoại; tô, đổi màu, bỏ highlight', (tester) async {
    final doc = WeeklyDoc.fromJson(
      (deepCopyJson(sampleReadingDoc()) as Map<String, dynamic>)
        ..['template'] = 'html'
        ..['sections'] = <dynamic>[]
        ..['html'] = '<p>Cities tackle pollution.</p>',
    );
    late BuildContext host;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          host = context;
          return const SizedBox.expand();
        }),
      ),
    ));
    final ann = HtmlReaderAnnotations(doc: doc, docVersion: 1, hostContext: () => host);
    addTearDown(ann.dispose);
    final sent = <Map<String, Object?>>[];
    final passthrough = <bool>[];
    ann.bridge.attach(send: sent.add, setPassthrough: passthrough.add);
    await tester.pump();

    const rect = {'x': 300.0, 'y': 300.0, 'w': 80.0, 'h': 20.0};
    // Bôi đen trong file → hộp thoại; chuột phải tới được hộp thoại (iframe pointer-events: none).
    ann.onMessage({'type': 'selection', 'text': 'tackle', 'sentence': 'Cities tackle pollution.', 'prefix': 'Cities ', 'suffix': ' pollution.', 'start': 7, 'rect': rect});
    await tester.pump();
    expect(find.byType(SelectionActionsCard), findsOneWidget);
    expect(passthrough.last, isTrue);

    await tester.tap(_swatch(HighlightColor.yellow));
    await tester.pump();
    expect(find.byType(SelectionActionsCard), findsNothing);
    expect(passthrough.last, isFalse, reason: 'đóng hộp thoại thì trả chuột lại cho file');
    final applied = sent.lastWhere((c) => c['type'] == 'applyHighlights');
    final id = ((applied['items']! as List).single as Map)['id'] as String;
    expect(sent.last['type'], 'clearSelection');

    // Bấm vào chữ đã tô: file báo highlightTap rồi selectionCleared ngay sau đó → hộp thoại vẫn mở.
    ann.onMessage({'type': 'highlightTap', 'id': id, 'rect': rect});
    ann.onMessage({'type': 'selectionCleared'});
    await tester.pump();
    expect(find.byType(SelectionActionsCard), findsOneWidget);
    expect(passthrough.last, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(sent.any((c) => c['type'] == 'removeHighlight' && c['id'] == id), isTrue);
    expect(find.byType(SelectionActionsCard), findsNothing);
    expect(passthrough.last, isFalse);

    // Bỏ chọn trong file thì hộp thoại của vùng bôi đen đóng.
    ann.onMessage({'type': 'selection', 'text': 'pollution', 'start': 14, 'rect': rect});
    await tester.pump();
    ann.onMessage({'type': 'selectionCleared'});
    await tester.pump();
    expect(find.byType(SelectionActionsCard), findsNothing);
    expect(passthrough.last, isFalse);
    await tester.pump(const Duration(seconds: 1)); // lưu lên BE giả (hẹn giờ 0s) chạy xong
  });
}
