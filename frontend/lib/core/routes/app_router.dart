import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../storage/token_storage.dart';
import 'app_routes.dart';
import 'redirect_path.dart';
import '../../features/auth/presentation/views/access_key_page.dart';
import '../../features/home/presentation/views/home_page.dart';
import '../../features/documents/presentation/bloc/weekly_documents_bloc.dart';
import '../../features/documents/presentation/views/weekly_documents_page.dart';
import '../../features/weekly_docs/domain/entities/doc_category.dart';
import '../../features/weekly_docs/presentation/cubits/doc_complete_cubit.dart';
import '../../features/weekly_docs/presentation/pages/admin_docs_page.dart';
import '../../features/weekly_docs/presentation/pages/doc_complete_page.dart';
import '../../features/weekly_docs/presentation/pages/doc_creator_page.dart';
import '../../features/weekly_docs/presentation/pages/doc_reader_page.dart';
import '../../features/weekly_docs/presentation/pages/weeks_page.dart';
import '../../features/documents/presentation/views/document_detail_page.dart';
import '../../features/documents/presentation/views/lesson_detail_page.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/search/presentation/views/search_page.dart';
import '../../features/wordbook/presentation/bloc/wordbook_bloc.dart';
import '../../features/wordbook/presentation/views/wordbook_page.dart';
import '../../features/web_resources/presentation/bloc/web_resources_bloc.dart';
import '../../features/web_resources/presentation/views/web_resources_page.dart';
import '../../features/admin/documents/presentation/bloc/admin_documents_bloc.dart';
import '../../features/admin/documents/presentation/views/admin_documents_page.dart';
import '../../features/admin/documents/presentation/views/document_form_page.dart';
import '../../features/admin/vocabularies/presentation/views/admin_vocabularies_page.dart';
import '../../features/admin/vocabularies/presentation/views/vocabulary_form_page.dart';
import '../../features/admin/sentence_patterns/presentation/views/admin_sentence_patterns_page.dart';
import '../../features/admin/sentence_patterns/presentation/views/sentence_pattern_form_page.dart';
import '../../features/admin/tags/presentation/views/admin_tags_page.dart';
import '../../features/admin/access_keys/presentation/views/admin_access_keys_page.dart';
import '../../core/widgets/app_layout.dart';
import '../../core/widgets/not_found_page.dart';

final _tokenStorage = TokenStorage();

/// Trang cấp tab (con trực tiếp của ShellRoute): đổi tab là thay hẳn trang nên hiện ngay, không trượt /
/// mờ dần — hiệu ứng chuyển trang mặc định để lộ trang cũ trong lúc chạy. Trang con lồng bên dưới
/// (đọc tài liệu, màn soạn…) vẫn giữ hiệu ứng mở trang bình thường.
GoRouterPageBuilder _tabPage(GoRouterWidgetBuilder builder) =>
    (context, state) => NoTransitionPage<void>(key: state.pageKey, child: builder(context, state));

/// Router duy nhất của app: URL quyết định trang hiển thị (kể cả khi mở link hoặc F5).
/// Trang cần Bloc thì tạo provider ngay tại route, để mở thẳng bằng URL vẫn chạy.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.access,
  // Đường dẫn không khớp trang nào: trang 404 có nút về trang chủ.
  errorBuilder: (context, state) => NotFoundPage(path: state.uri.path),
  redirect: (context, state) async {
    final isLoggedIn = await _tokenStorage.isLoggedIn();
    final isGoingToAccess = state.matchedLocation == AppRoutes.access;

    if (!isLoggedIn && !isGoingToAccess) {
      // Giữ trang đang mở để đăng nhập xong quay lại đúng chỗ.
      return accessPathFor(state.uri.toString());
    }
    if (isLoggedIn && isGoingToAccess) {
      return safeRedirectPath(state.uri.queryParameters['from']) ?? AppRoutes.home;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.access,
      builder: (context, state) => const AccessKeyPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppLayout(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: _tabPage((context, state) => const HomePage()),
        ),
        GoRoute(
          path: AppRoutes.resources,
          pageBuilder: _tabPage(
            (context, state) => BlocProvider(
              create: (_) => WebResourcesBloc()..add(LoadResources()),
              child: const WebResourcesPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.weekly,
          pageBuilder: _tabPage((context, state) => const WeeksPage()),
          routes: [
            GoRoute(
              path: AppRoutes.weeklyDocSegment,
              builder: (context, state) => DocReaderPage(
                docId: state.pathParameters['id'] ?? '',
                initialBlock: state.uri.queryParameters['block'],
              ),
              routes: [
                GoRoute(
                  path: AppRoutes.weeklyDocDoneSegment,
                  // Kết quả hoàn thành chỉ có ngay sau khi bấm "Hoàn thành" (truyền qua extra);
                  // mở lại bằng URL / F5 thì về tài liệu.
                  redirect: (context, state) =>
                      state.extra is DocCompleteArgs ? null : AppRoutes.weeklyDoc(state.pathParameters['id'] ?? ''),
                  builder: (context, state) => switch (state.extra) {
                    final DocCompleteArgs args => DocCompletePage(args: args),
                    _ => DocReaderPage(docId: state.pathParameters['id'] ?? ''),
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.lessonPattern,
          pageBuilder: _tabPage((context, state) => LessonDetailPage(lessonId: state.pathParameters['id'] ?? '')),
        ),
        GoRoute(
          path: AppRoutes.documentPattern,
          pageBuilder: _tabPage((context, state) => DocumentDetailPage(documentId: state.pathParameters['id'] ?? '')),
        ),
        GoRoute(
          path: AppRoutes.articles,
          pageBuilder: _tabPage(
            (context, state) => BlocProvider(
              create: (_) => WeeklyDocumentsBloc(),
              child: const WeeklyDocumentsPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.wordbook,
          pageBuilder: _tabPage(
            (context, state) => BlocProvider(
              create: (_) => WordbookBloc()..add(LoadWordbook()),
              child: const WordbookPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.search,
          pageBuilder: _tabPage(
            (context, state) => BlocProvider(
              create: (_) => SearchBloc(),
              child: const SearchPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.admin,
          pageBuilder: _tabPage(
            (context, state) => BlocProvider(
              create: (_) => AdminDocumentsBloc()..add(LoadAdminDocuments()),
              child: const AdminDocumentsPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.adminDocumentCreate,
          pageBuilder: _tabPage((context, state) => const DocumentFormPage()),
        ),
        GoRoute(
          path: AppRoutes.adminDocumentEditPattern,
          pageBuilder: _tabPage((context, state) => DocumentFormPage(documentId: state.pathParameters['id'] ?? '')),
        ),
        GoRoute(
          path: AppRoutes.adminVocabularies,
          pageBuilder: _tabPage((context, state) => const AdminVocabulariesPage()),
        ),
        GoRoute(
          path: AppRoutes.adminVocabularyCreate,
          pageBuilder: _tabPage((context, state) => const VocabularyFormPage()),
        ),
        GoRoute(
          path: AppRoutes.adminVocabularyEditPattern,
          pageBuilder: _tabPage((context, state) => VocabularyFormPage(vocabularyId: state.pathParameters['id'] ?? '')),
        ),
        GoRoute(
          path: AppRoutes.adminSentencePatterns,
          pageBuilder: _tabPage((context, state) => const AdminSentencePatternsPage()),
        ),
        GoRoute(
          path: AppRoutes.adminSentencePatternCreate,
          pageBuilder: _tabPage((context, state) => const SentencePatternFormPage()),
        ),
        GoRoute(
          path: AppRoutes.adminSentencePatternEditPattern,
          pageBuilder: _tabPage((context, state) => SentencePatternFormPage(sentencePatternId: state.pathParameters['id'] ?? '')),
        ),
        GoRoute(
          path: AppRoutes.adminTags,
          pageBuilder: _tabPage((context, state) => const AdminTagsPage()),
        ),
        GoRoute(
          path: AppRoutes.adminAccessKeys,
          pageBuilder: _tabPage((context, state) => const AdminAccessKeysPage()),
        ),
        GoRoute(
          path: AppRoutes.adminWeeklyDocs,
          pageBuilder: _tabPage((context, state) => const AdminDocsPage()),
          routes: [
            GoRoute(
              path: AppRoutes.adminWeeklyDocCreateSegment,
              // Không có ?week thì màn soạn tự chọn tuần hiện tại; ?category=homework chọn sẵn loại Bài tập.
              builder: (context, state) => DocCreatorPage(
                initialWeek: int.tryParse(state.uri.queryParameters['week'] ?? '') ?? 0,
                initialCategory: DocCategory.parse(state.uri.queryParameters['category']),
              ),
            ),
            GoRoute(
              path: AppRoutes.adminWeeklyDocEditSegment,
              builder: (context, state) => DocCreatorPage(docId: state.pathParameters['id']),
            ),
            GoRoute(
              path: AppRoutes.adminWeeklyDocPreviewSegment,
              builder: (context, state) => DocReaderPage(docId: state.pathParameters['id'] ?? '', isAdminPreview: true),
            ),
          ],
        ),
      ],
    ),
  ],
);
