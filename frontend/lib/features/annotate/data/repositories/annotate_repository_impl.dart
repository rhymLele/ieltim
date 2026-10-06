import 'dart:async';
import 'dart:convert';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/widgets/annotate/models.dart';
import '../../domain/entities/doc_annotations.dart';
import '../../domain/repositories/annotate_repository.dart';
import '../../domain/rules/slide_merge.dart';
import '../datasources/annotate_local_store.dart';
import '../datasources/annotate_remote_datasource.dart';
import '../models/annotation_models.dart';

/// Lưu lạc quan + hàng đợi trên máy: ghi vào bản trên máy ngay, [saveDelay] sau thao tác cuối thì gửi BE theo thứ tự.
/// Mất mạng / máy chủ lỗi 5xx: giữ hàng đợi, thử lại sau [retryDelay] (và khi gọi [flush]). Lỗi 4xx khác 409: bỏ thao tác.
/// Không ghi nội dung highlight / ghi chú ra log.
class AnnotateRepositoryImpl implements AnnotateRepository {
  AnnotateRepositoryImpl({
    AnnotateRemoteDataSource? remote,
    AnnotateLocalStore? local,
    Future<String?> Function()? currentUserId,
    LoggerService? logger,
    this.saveDelay = const Duration(milliseconds: 1500),
    this.retryDelay = const Duration(seconds: 20),
  })  : _remote = remote ?? AnnotateRemoteDataSource(),
        _local = local ?? AnnotateLocalStore(),
        _currentUserId = currentUserId ?? TokenStorage().getUserId,
        _logger = logger ?? getSingleton<LoggerService>();

  final AnnotateRemoteDataSource _remote;
  final AnnotateLocalStore _local;
  final Future<String?> Function() _currentUserId;
  final LoggerService _logger;
  final Duration saveDelay;
  final Duration retryDelay;

  final _merged = StreamController<SlideAnnotationsMerged>.broadcast();
  final _docs = <String, StoredDocAnnotations>{};
  List<PendingOp>? _queue;
  String? _userId;
  Timer? _saveTimer;
  Timer? _retryTimer;
  Future<void>? _draining;

  /// Các bước đọc-sửa-ghi bản trên máy chạy lần lượt: hai thao tác liền nhau (thay highlight = xoá + thêm)
  /// không đè mất nhau, và [flush] chờ các thao tác vừa gọi vào hàng đợi xong rồi mới gửi.
  Future<void> _writes = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  @override
  Stream<SlideAnnotationsMerged> get mergedSlides => _merged.stream;

  // ───────────────────────────── Đọc ─────────────────────────────

  @override
  Future<Result<DocAnnotations>> loadCached(String docId) async {
    try {
      return Success((await _doc(docId)).toEntity());
    } on Object catch (e, stackTrace) {
      _logger.warning('annotate: đọc bản trên máy thất bại', e, stackTrace);
      return const Failure(CacheException());
    }
  }

  @override
  Future<Result<DocAnnotations>> refresh(String docId) async {
    final DocAnnotationsModel server;
    try {
      server = await _remote.annotations(docId);
    } on AppException catch (e) {
      _logger.warning('annotate: tải ghi chú thất bại — ${_reason(e)}');
      return Failure(e);
    } on Object catch (e, stackTrace) {
      _logger.error('annotate: tải ghi chú gặp lỗi không xác định', e, stackTrace);
      return const Failure(UnknownException());
    }
    return _serial(() => _applyServer(docId, server));
  }

  /// Bản máy chủ phủ lên bản trên máy, giữ các thay đổi chưa gửi.
  Future<Result<DocAnnotations>> _applyServer(String docId, DocAnnotationsModel server) async {
    final local = await _doc(docId);
    final pending = (await _ops()).where((op) => op.docId == docId).toList();
    final pendingKeys = {for (final op in pending) op.key};

    // Highlight: bản máy chủ, rồi phủ các thao tác chưa gửi.
    final highlights = [
      for (final h in server.highlights.map(TextHighlight.fromJson))
        if (!pendingKeys.contains('h:$docId:${h.id}')) h,
      for (final op in pending)
        if (op is PutHighlightOp) op.highlight,
    ];
    // Slide: có thay đổi chưa gửi thì giữ bản trên máy (gửi sau, xung đột thì gộp); không thì lấy bản máy chủ.
    final slides = <String, StoredSlide>{
      for (final e in server.slides.entries)
        e.key: StoredSlide(data: SlideAnnotations.fromJson(e.value.data), rev: e.value.rev, base: SlideAnnotations.fromJson(e.value.data)),
      for (final e in local.slides.entries)
        if (pendingKeys.contains('s:$docId:${e.key}')) e.key: e.value,
    };
    final next = StoredDocAnnotations(highlights: highlights, slides: slides);
    await _saveDoc(docId, next);
    return Success(next.toEntity());
  }

  // ───────────────────────────── Ghi ─────────────────────────────

  @override
  Future<void> saveHighlight(String docId, int docVersion, TextHighlight highlight) => _serial(() async {
        final doc = await _doc(docId);
        await _saveDoc(
          docId,
          StoredDocAnnotations(highlights: [...doc.highlights.where((h) => h.id != highlight.id), highlight], slides: doc.slides),
        );
        await _enqueue(PutHighlightOp(docId, docVersion, highlight));
      });

  @override
  Future<void> deleteHighlight(String docId, String id) => _serial(() async {
        final doc = await _doc(docId);
        await _saveDoc(docId, StoredDocAnnotations(highlights: doc.highlights.where((h) => h.id != id).toList(), slides: doc.slides));
        await _enqueue(DeleteHighlightOp(docId, id));
      });

  @override
  Future<void> saveSlide(String docId, int docVersion, String slideKey, SlideAnnotations data) => _serial(() async {
        final doc = await _doc(docId);
        final old = doc.slides[slideKey];
        await _saveDoc(
          docId,
          StoredDocAnnotations(
            highlights: doc.highlights,
            slides: {...doc.slides, slideKey: StoredSlide(data: data, rev: old?.rev ?? 0, base: old?.base ?? const SlideAnnotations())},
          ),
        );
        await _enqueue(PutSlideOp(docId, docVersion, slideKey));
      });

  @override
  Future<void> flush() async {
    await _writes;
    _saveTimer?.cancel();
    await _drain();
  }

  // ───────────────────────────── Dịch ─────────────────────────────

  @override
  Future<Result<TranslationResult>> translate(String text, {String? sentence}) async {
    try {
      return Success((await _remote.translate(TranslateRequest(text: text, sentence: sentence))).toEntity());
    } on AppException catch (e) {
      _logger.warning('annotate: dịch thất bại — ${_reason(e)}');
      return Failure(e);
    } on Object catch (e, stackTrace) {
      _logger.error('annotate: dịch gặp lỗi không xác định', e, stackTrace);
      return const Failure(UnknownException());
    }
  }

  // ───────────────────────────── Hàng đợi ─────────────────────────────

  Future<void> _enqueue(PendingOp op) async {
    final ops = await _ops();
    ops
      ..removeWhere((o) => o.key == op.key)
      ..add(op);
    await _local.writeQueue(await _user(), ops);
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () => unawaited(_drain()));
  }

  Future<void> _drain() => _draining ??= _run().whenComplete(() => _draining = null);

  Future<void> _run() async {
    _retryTimer?.cancel();
    final ops = await _ops();
    var conflicts = 0;
    while (ops.isNotEmpty) {
      final op = ops.first;
      try {
        final done = await _send(op);
        conflicts = 0;
        if (done) ops.remove(op);
      } on AnnotationConflictException catch (conflict) {
        // Máy khác lưu trước: gộp rồi gửi lại với rev mới (vòng lặp gửi tiếp chính thao tác này).
        if (op is PutSlideOp) await _mergeConflict(op, conflict.current);
        if (++conflicts > 3) {
          _scheduleRetry();
          break;
        }
      } on NetworkException {
        _scheduleRetry();
        break;
      } on ServerException catch (e) {
        final status = e.statusCode ?? 0;
        if (status >= 500 || status == 429 || status == 401) {
          _scheduleRetry();
          break;
        }
        _logger.warning('annotate: bỏ thao tác ${op.runtimeType} — ${e.code}');
        ops.remove(op);
      } on Object catch (e, stackTrace) {
        _logger.error('annotate: bỏ thao tác ${op.runtimeType} vì lỗi không xác định', e, stackTrace);
        ops.remove(op);
      }
      await _local.writeQueue(await _user(), ops);
    }
  }

  /// Trả false khi slide bị sửa tiếp trong lúc gửi (giữ thao tác để gửi bản mới).
  Future<bool> _send(PendingOp op) async {
    switch (op) {
      case PutHighlightOp(:final docId, :final docVersion, :final highlight):
        await _remote.putHighlight(docId, docVersion, highlight);
        return true;
      case DeleteHighlightOp(:final docId, :final id):
        await _remote.deleteHighlight(docId, id);
        return true;
      case PutSlideOp(:final docId, :final docVersion, :final slideKey):
        final slide = (await _doc(docId)).slides[slideKey];
        if (slide == null) return true;
        final sent = slide.data.toJson();
        final rev = await _remote.putSlide(docId, slideKey, SlideSaveRequest(data: sent, rev: slide.rev, docVersion: docVersion));
        return _serial(() async {
          final doc = await _doc(docId);
          final current = doc.slides[slideKey] ?? slide;
          await _saveDoc(
            docId,
            StoredDocAnnotations(
              highlights: doc.highlights,
              slides: {...doc.slides, slideKey: StoredSlide(data: current.data, rev: rev, base: SlideAnnotations.fromJson(sent))},
            ),
          );
          return jsonEncode(current.data.toJson()) == jsonEncode(sent);
        });
    }
  }

  Future<void> _mergeConflict(PutSlideOp op, SlideStateModel server) => _serial(() async {
        final doc = await _doc(op.docId);
        final mine = doc.slides[op.slideKey] ?? const StoredSlide(data: SlideAnnotations());
        final remote = SlideAnnotations.fromJson(server.data);
        final merged = mergeSlideAnnotations(base: mine.base, local: mine.data, remote: remote);
        await _saveDoc(
          op.docId,
          StoredDocAnnotations(highlights: doc.highlights, slides: {...doc.slides, op.slideKey: StoredSlide(data: merged, rev: server.rev, base: remote)}),
        );
        _merged.add(SlideAnnotationsMerged(docId: op.docId, slideKey: op.slideKey, data: merged));
      });

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(retryDelay, () => unawaited(_drain()));
  }

  // ───────────────────────────── Bản trên máy ─────────────────────────────

  /// Đổi tài khoản thì bỏ dữ liệu đã nạp của người trước.
  Future<String> _user() async {
    final id = await _currentUserId() ?? 'anonymous';
    if (id != _userId) {
      _userId = id;
      _docs.clear();
      _queue = null;
    }
    return id;
  }

  Future<List<PendingOp>> _ops() async {
    final user = await _user();
    return _queue ??= await _local.readQueue(user);
  }

  Future<StoredDocAnnotations> _doc(String docId) async {
    final user = await _user();
    return _docs[docId] ??= await _local.read(user, docId);
  }

  Future<void> _saveDoc(String docId, StoredDocAnnotations doc) async {
    _docs[docId] = doc;
    await _local.write(await _user(), docId, doc);
  }

  static String _reason(AppException e) => e is ServerException ? e.code : e.runtimeType.toString();
}
