import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/token_storage.dart';
import '../../features/auth/presentation/views/access_key_page.dart';
import '../../features/home/presentation/views/home_page.dart';
import '../../features/documents/presentation/views/weekly_documents_page.dart';
import '../../features/weekly_docs/presentation/views/weeks_screen.dart';
import '../../features/weekly_docs/presentation/views/doc_reader_screen.dart';
import '../../features/weekly_docs/presentation/views/doc_complete_screen.dart';
import '../../features/weekly_docs/presentation/views/admin/admin_week_docs_screen.dart';
import '../../features/weekly_docs/presentation/views/admin/doc_creator_screen.dart';
import '../../features/documents/presentation/views/document_detail_page.dart';
import '../../features/documents/presentation/views/lesson_detail_page.dart';
import '../../features/vocabulary/presentation/views/vocabulary_list_page.dart';
import '../../features/sentence_pattern/presentation/views/sentence_pattern_list_page.dart';
import '../../features/search/presentation/views/search_page.dart';
import '../../features/wordbook/presentation/views/wordbook_page.dart';
import '../../features/web_resources/presentation/views/web_resources_page.dart';
import '../../features/admin/documents/presentation/views/admin_documents_page.dart';
import '../../features/admin/documents/presentation/views/document_form_page.dart';
import '../../features/admin/vocabularies/presentation/views/admin_vocabularies_page.dart';
import '../../features/admin/vocabularies/presentation/views/vocabulary_form_page.dart';
import '../../features/admin/sentence_patterns/presentation/views/admin_sentence_patterns_page.dart';
import '../../features/admin/sentence_patterns/presentation/views/sentence_pattern_form_page.dart';
import '../../features/admin/tags/presentation/views/admin_tags_page.dart';
import '../../features/admin/access_keys/presentation/views/admin_access_keys_page.dart';
import '../../core/widgets/app_layout.dart';

final _tokenStorage = TokenStorage();

final GoRouter appRouter = GoRouter(
  initialLocation: '/access',
  redirect: (context, state) async {
    final isLoggedIn = await _tokenStorage.isLoggedIn();
    final isGoingToAccess = state.matchedLocation == '/access';

    if (!isLoggedIn && !isGoingToAccess) {
      return '/access';
    }
    if (isLoggedIn && isGoingToAccess) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/access',
      builder: (context, state) => const AccessKeyPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppLayout(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/resources',
          builder: (context, state) => const WebResourcesPage(),
        ),
        GoRoute(
          path: '/weekly',
          builder: (context, state) => const WeeksScreen(),
        ),
        GoRoute(
          path: '/weekly/doc/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DocReaderScreen(docId: id);
          },
        ),
        GoRoute(
          path: '/weekly/complete',
          builder: (context, state) {
            final docId = state.uri.queryParameters['docId'] ?? '';
            final week = int.tryParse(state.uri.queryParameters['week'] ?? '1') ?? 1;
            return DocCompleteScreen(docId: docId, week: week);
          },
        ),
        GoRoute(
          path: '/lessons/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return LessonDetailPage(lessonId: id);
          },
        ),
        GoRoute(
          path: '/documents/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DocumentDetailPage(documentId: id);
          },
        ),
        GoRoute(
          path: '/articles',
          builder: (context, state) => const WeeklyDocumentsPage(),
        ),
        GoRoute(
          path: '/wordbook',
          builder: (context, state) => const WordbookPage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDocumentsPage(),
        ),
        GoRoute(
          path: '/admin/documents/create',
          builder: (context, state) => const DocumentFormPage(),
        ),
        GoRoute(
          path: '/admin/documents/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DocumentFormPage(documentId: id);
          },
        ),
        GoRoute(
          path: '/admin/vocabularies',
          builder: (context, state) => const AdminVocabulariesPage(),
        ),
        GoRoute(
          path: '/admin/vocabularies/create',
          builder: (context, state) => const VocabularyFormPage(),
        ),
        GoRoute(
          path: '/admin/vocabularies/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return VocabularyFormPage(vocabularyId: id);
          },
        ),
        GoRoute(
          path: '/admin/sentence-patterns',
          builder: (context, state) => const AdminSentencePatternsPage(),
        ),
        GoRoute(
          path: '/admin/sentence-patterns/create',
          builder: (context, state) => const SentencePatternFormPage(),
        ),
        GoRoute(
          path: '/admin/sentence-patterns/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return SentencePatternFormPage(sentencePatternId: id);
          },
        ),
        GoRoute(
          path: '/admin/tags',
          builder: (context, state) => const AdminTagsPage(),
        ),
        GoRoute(
          path: '/admin/access-keys',
          builder: (context, state) => const AdminAccessKeysPage(),
        ),
        GoRoute(
          path: '/admin/weekly-docs',
          builder: (context, state) => const AdminWeekDocsScreen(),
        ),
        GoRoute(
          path: '/admin/weekly-docs/create',
          builder: (context, state) => const DocCreatorScreen(),
        ),
        GoRoute(
          path: '/admin/weekly-docs/:id/edit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DocCreatorScreen(docId: id);
          },
        ),
      ],
    ),
  ],
);
