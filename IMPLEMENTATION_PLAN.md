# IELTS Knowledge Hub – Implementation Plan

## Current State
- **Backend:** NestJS scaffold (chưa có module nào)
- **Frontend:** Flutter scaffold (default counter app)
- **Database:** Chưa setup

---

## PHASE 0 – Foundation Setup

### 0.1 Backend Dependencies
```bash
npm install @nestjs/config @nestjs/typeorm @nestjs/jwt @nestjs/passport passport passport-jwt typeorm pg bcrypt class-validator class-transformer uuid
npm install -D @types/passport-jwt @types/bcrypt
```

### 0.2 Frontend Dependencies
```bash
flutter pub add get http dio go_router intl shared_preferences sqflite path_provider
```
- `get` – state management
- `dio` – HTTP client
- `go_router` – routing
- `intl` – date formatting
- `shared_preferences` – token storage (localStorage trên Web)
- `sqflite` – local notes (IndexedDB trên Web)

### 0.3 Backend Folder Structure
```
backend/src/
├── main.ts
├── app.module.ts
├── auth/
│   ├── auth.module.ts
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── dto/
│   │   └── access-key.dto.ts
│   ├── guards/
│   │   └── jwt-auth.guard.ts
│   └── strategies/
│       └── jwt.strategy.ts
├── users/
│   ├── users.module.ts
│   ├── users.service.ts
│   └── entities/
│       └── user.entity.ts
├── access-keys/
│   ├── access-keys.module.ts
│   ├── access-keys.controller.ts
│   ├── access-keys.service.ts
│   ├── dto/
│   └── entities/
│       └── access-key.entity.ts
├── documents/
│   ├── documents.module.ts
│   ├── documents.controller.ts
│   ├── documents.service.ts
│   ├── dto/
│   └── entities/
│       └── document.entity.ts
├── document-blocks/
│   ├── document-blocks.module.ts
│   ├── document-blocks.controller.ts
│   ├── document-blocks.service.ts
│   ├── dto/
│   └── entities/
│       └── document-block.entity.ts
├── vocabularies/
│   ├── vocabularies.module.ts
│   ├── vocabularies.controller.ts
│   ├── vocabularies.service.ts
│   ├── dto/
│   └── entities/
│       ├── vocabulary.entity.ts
│       └── collocation.entity.ts
├── sentence-patterns/
│   ├── sentence-patterns.module.ts
│   ├── sentence-patterns.controller.ts
│   ├── sentence-patterns.service.ts
│   ├── dto/
│   └── entities/
│       └── sentence-pattern.entity.ts
├── tags/
│   ├── tags.module.ts
│   ├── tags.controller.ts
│   ├── tags.service.ts
│   ├── dto/
│   └── entities/
│       └── tag.entity.ts
├── ielts-contexts/
│   ├── ielts-contexts.module.ts
│   ├── ielts-contexts.service.ts
│   └── entities/
│       └── ielts-context.entity.ts
├── comments/
│   ├── comments.module.ts
│   ├── comments.controller.ts
│   ├── comments.service.ts
│   ├── dto/
│   └── entities/
│       └── comment.entity.ts
├── web-resources/
│   ├── web-resources.module.ts
│   ├── web-resources.controller.ts
│   ├── web-resources.service.ts
│   ├── dto/
│   └── entities/
│       └── web-resource.entity.ts
├── search/
│   ├── search.module.ts
│   ├── search.controller.ts
│   └── search.service.ts
└── common/
    ├── guards/
    │   └── roles.guard.ts
    ├── decorators/
    │   ├── roles.decorator.ts
    │   └── current-user.decorator.ts
    ├── enums/
    │   ├── role.enum.ts
    │   ├── status.enum.ts
    │   ├── document-type.enum.ts
    │   ├── block-type.enum.ts
    │   ├── level.enum.ts
    │   └── tag-type.enum.ts
    ├── exceptions/
    │   └── app-exception.filter.ts
    ├── interceptors/
    │   └── pagination.interceptor.ts
    └── dto/
        └── pagination-query.dto.ts
```

### 0.4 Frontend Folder Structure
```
frontend/lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── api_constants.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   └── api_interceptor.dart
│   ├── routes/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── storage/
│   │   ├── token_storage.dart
│   │   └── local_note_storage.dart
│   └── widgets/
│       ├── app_sidebar.dart
│       ├── app_layout.dart
│       ├── tag_chip.dart
│       └── loading_indicator.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── models/
│   │   │       └── user_model.dart
│   │   ├── domain/
│   │   │   └── auth_state.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── auth_controller.dart
│   │       └── views/
│   │           └── access_key_page.dart
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── controllers/
│   │   │   │   └── home_controller.dart
│   │   │   └── views/
│   │   │       └── home_page.dart
│   ├── documents/
│   │   ├── data/
│   │   │   ├── document_repository.dart
│   │   │   └── models/
│   │   │       ├── document_model.dart
│   │   │       └── block_model.dart
│   │   ├── domain/
│   │   │   └── document_state.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── document_controller.dart
│   │       └── views/
│   │           ├── weekly_documents_page.dart
│   │           └── document_detail_page.dart
│   ├── vocabulary/
│   │   ├── data/
│   │   │   ├── vocabulary_repository.dart
│   │   │   └── models/
│   │   │       └── vocabulary_model.dart
│   │   └── presentation/
│   │       └── views/
│   │           └── vocabulary_list_page.dart
│   ├── sentence_pattern/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── sentence_pattern_model.dart
│   │   └── presentation/
│   │       └── views/
│   │           └── sentence_pattern_list_page.dart
│   ├── comments/
│   │   ├── data/
│   │   │   ├── comment_repository.dart
│   │   │   └── models/
│   │   │       └── comment_model.dart
│   │   └── presentation/
│   │       └── views/
│   │           └── comment_section.dart
│   ├── search/
│   │   ├── data/
│   │   │   └── search_repository.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── search_controller.dart
│   │       └── views/
│   │           └── search_page.dart
│   ├── notes/
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── local_note_model.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── local_note_controller.dart
│   │       └── views/
│   │           └── notes_page.dart
│   ├── web_resources/
│   │   └── presentation/
│   │       └── views/
│   │           └── web_resources_page.dart
│   └── admin/
│       ├── documents/
│       │   └── presentation/
│       │       ├── controllers/
│       │       │   └── admin_document_controller.dart
│       │       └── views/
│       │           ├── admin_documents_page.dart
│       │           ├── document_form_page.dart
│       │           └── block_editor.dart
│       ├── vocabularies/
│       │   └── presentation/
│       │       ├── controllers/
│       │       │   └── admin_vocabulary_controller.dart
│       │       └── views/
│       │           ├── admin_vocabularies_page.dart
│       │           └── vocabulary_form_page.dart
│       ├── sentence_patterns/
│       │   └── presentation/
│       │       ├── controllers/
│       │       │   └── admin_sentence_pattern_controller.dart
│       │       └── views/
│       │           ├── admin_sentence_patterns_page.dart
│       │           └── sentence_pattern_form_page.dart
│       ├── tags/
│       │   └── presentation/
│       │       └── views/
│       │           └── admin_tags_page.dart
│       └── access_keys/
│           └── presentation/
│               └── views/
│                   └── admin_access_keys_page.dart
```

### 0.5 Database Setup
- `.env` file: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `JWT_SECRET`
- TypeORM config với `synchronize: true` (dev) / migrations (prod)
- Seed script cho `ielts_contexts` table

---

## PHASE 1 – Core (Auth + Layout)

### 1.1 Backend

| Step | Task | Files |
|------|------|-------|
| 1.1.1 | Enums: Role, Status, DocumentType, BlockType, Level, TagType | `common/enums/*.ts` |
| 1.1.2 | User entity | `users/entities/user.entity.ts` |
| 1.1.3 | AccessKey entity (keyHash, status, expiresAt, lastUsedAt) | `access-keys/entities/access-key.entity.ts` |
| 1.1.4 | UsersModule + UsersService (findById) | `users/` |
| 1.1.5 | AccessKeysModule + Service (validate key by hash) | `access-keys/` |
| 1.1.6 | JwtStrategy + JwtAuthGuard | `auth/guards/`, `auth/strategies/` |
| 1.1.7 | RolesGuard + @Roles() decorator + @CurrentUser() decorator | `common/guards/`, `common/decorators/` |
| 1.1.8 | AuthService: login by access key → generate JWT | `auth/auth.service.ts` |
| 1.1.9 | AuthController: `POST /auth/access-key`, `GET /auth/me`, `POST /auth/logout` | `auth/auth.controller.ts` |
| 1.1.10 | Global ExceptionFilter (unified error format) | `common/exceptions/` |
| 1.1.11 | Seed script: create admin user + admin access key | `scripts/seed.ts` |

### 1.2 Frontend

| Step | Task | Files |
|------|------|-------|
| 1.2.1 | App colors + theme (Notion-style, #800020 primary) | `core/theme/` |
| 1.2.2 | API client (Dio) + auth interceptor (auto-attach JWT) | `core/network/` |
| 1.2.3 | TokenStorage (shared_preferences) | `core/storage/token_storage.dart` |
| 1.2.4 | App router (GoRouter) – all routes + auth guard | `core/routes/app_router.dart` |
| 1.2.5 | AuthController (GetX) – login, logout, user state | `features/auth/` |
| 1.2.6 | AccessKeyPage – input key, validate, call API, navigate | `features/auth/presentation/views/` |
| 1.2.7 | AppLayout – sidebar + main content area | `core/widgets/app_layout.dart` |
| 1.2.8 | AppSidebar – nav items (conditional admin section) | `core/widgets/app_sidebar.dart` |
| 1.2.9 | HomePage – dashboard placeholder | `features/home/` |

### 1.3 Verification
- [ ] `POST /auth/access-key` trả về JWT + user
- [ ] Key sai → 401, key hết hạn → 403, key disabled → 403
- [ ] `GET /auth/me` với JWT trả về user info
- [ ] User không gọi được `POST /documents` (403)
- [ ] FE: nhập key → login → vào /home
- [ ] FE: sidebar hiển thị đúng theo role
- [ ] FE: logout → về /access

---

## PHASE 2 – Learning Content

### 2.1 Backend

| Step | Task | Files |
|------|------|-------|
| 2.1.1 | Tag entity + TagModule + Service (CRUD) | `tags/` |
| 2.1.2 | IeltsContext entity + Service + seed data | `ielts-contexts/` |
| 2.1.3 | Vocabulary entity + Collocation entity | `vocabularies/entities/` |
| 2.1.4 | VocabularyModule + Service (CRUD + filter) | `vocabularies/` |
| 2.1.5 | VocabularyController (GET list, GET by id, POST, PATCH, DELETE, publish) | `vocabularies/` |
| 2.1.6 | SentencePattern entity | `sentence-patterns/entities/` |
| 2.1.7 | SentencePatternModule + Service + Controller | `sentence-patterns/` |
| 2.1.8 | Document entity | `documents/entities/` |
| 2.1.9 | DocumentBlock entity (jsonb data) | `document-blocks/entities/` |
| 2.1.10 | DocumentModule + Service (CRUD + status filter) | `documents/` |
| 2.1.11 | DocumentController (list, detail, create, update, publish, archive) | `documents/` |
| 2.1.12 | DocumentBlockController (list, create, update, delete, reorder) | `document-blocks/` |
| 2.1.13 | Business rule: USER chỉ thấy PUBLISHED, ADMIN thấy tất cả | Trong query service |
| 2.1.14 | Weekly documents: `GET /documents?type=WEEKLY&week=N` group by study_date | `documents/` |
| 2.1.15 | Pagination interceptor (page, pageSize, total, totalPages) | `common/interceptors/` |

### 2.2 Frontend

| Step | Task | Files |
|------|------|-------|
| 2.2.1 | Document model + Block model (parse jsonb) | `features/documents/data/models/` |
| 2.2.2 | Vocabulary model + Collocation model | `features/vocabulary/data/models/` |
| 2.2.3 | SentencePattern model | `features/sentence_pattern/data/models/` |
| 2.2.4 | DocumentRepository (Dio calls) | `features/documents/data/` |
| 2.2.5 | VocabularyRepository | `features/vocabulary/data/` |
| 2.2.6 | DocumentController (GetX) – load documents, load detail | `features/documents/presentation/` |
| 2.2.7 | WeeklyDocumentsPage – week selector + date list + doc summary | `features/documents/presentation/views/` |
| 2.2.8 | DocumentDetailPage – render blocks (heading, text, vocab, sentence, quote, link, divider) | `features/documents/presentation/views/` |
| 2.2.9 | Table of Contents (từ headings) | `features/documents/presentation/views/` |
| 2.2.10 | Vocabulary display widget (term, definition, vi meaning, usage, example, collocations, level, tags, contexts) | `core/widgets/` |
| 2.2.11 | SentencePattern display widget | `core/widgets/` |
| 2.2.12 | TagChip widget | `core/widgets/tag_chip.dart` |
| 2.2.13 | Vocabulary list page (browse all published) | `features/vocabulary/presentation/views/` |
| 2.2.14 | Sentence Pattern list page | `features/sentence_pattern/presentation/views/` |
| 2.2.15 | Web resources page (list published web resources) | `features/web_resources/` |

### 2.3 Verification
- [ ] Admin tạo vocabulary → publish → User xem được
- [ ] Admin tạo document với blocks → publish → User mở được
- [ ] Document hiển thị đúng tất cả block types
- [ ] Weekly view: chọn tuần → thấy các ngày → thấy documents
- [ ] Vocabulary block trong document render đầy đủ fields
- [ ] User không thấy DRAFT/ARCHIVED documents
- [ ] Pagination hoạt động đúng

---

## PHASE 3 – Admin

### 3.1 Backend

| Step | Task | Files |
|------|------|-------|
| 3.1.1 | Admin guard check (tất cả admin endpoints require ADMIN role) | Guards trên controller |
| 3.1.2 | Access Key management: create, list, disable, enable | `access-keys/` |
| 3.1.3 | Tag management: CRUD | `tags/` |
| 3.1.4 | Document create with blocks (transaction: create doc + blocks) | `documents/` |
| 3.1.5 | Document update (update fields + blocks) | `documents/` |
| 3.1.6 | Block reorder API | `document-blocks/` |
| 3.1.7 | Vocabulary create/edit with collocations + tags + contexts | `vocabularies/` |
| 3.1.8 | Sentence Pattern create/edit with tags + contexts | `sentence-patterns/` |
| 3.1.9 | Publish/Archive endpoints (status transitions) | Các controllers |
| 3.1.10 | Web Resource CRUD | `web-resources/` |

### 3.2 Frontend

| Step | Task | Files |
|------|------|-------|
| 3.2.1 | AdminDocumentsPage – list all docs (all statuses) | `features/admin/documents/` |
| 3.2.2 | DocumentFormPage – title, description, type, studyDate, week, tags, status | `features/admin/documents/` |
| 3.2.3 | BlockEditor – add/reorder/delete blocks (heading, text, vocab ref, sentence ref, quote, link, divider) | `features/admin/documents/` |
| 3.2.4 | AdminVocabulariesPage – list + create/edit | `features/admin/vocabularies/` |
| 3.2.5 | VocabularyFormPage – all fields + collocations + tags + contexts | `features/admin/vocabularies/` |
| 3.2.6 | AdminSentencePatternsPage – list + create/edit | `features/admin/sentence_patterns/` |
| 3.2.7 | SentencePatternFormPage – all fields + tags + contexts + function tags | `features/admin/sentence_patterns/` |
| 3.2.8 | AdminTagsPage – CRUD tags | `features/admin/tags/` |
| 3.2.9 | AdminAccessKeysPage – create, list, disable/enable keys | `features/admin/access_keys/` |
| 3.2.10 | Publish/Archive buttons on admin views | Trong các form/list pages |

### 3.3 Verification
- [ ] Admin tạo document + blocks → save draft → không thấy ở user
- [ ] Admin publish → user thấy
- [ ] Admin archive → user không thấy
- [ ] Admin tạo vocabulary với collocations, tags, contexts
- [ ] Admin tạo sentence pattern với function tags
- [ ] Admin tạo/disable access key
- [ ] Block reorder hoạt động
- [ ] User gọi admin API → 403

---

## PHASE 4 – Discovery

### 4.1 Backend

| Step | Task | Files |
|------|------|-------|
| 4.1.1 | SearchService – ILIKE search across documents, vocabularies, sentence patterns, web resources | `search/` |
| 4.1.2 | SearchController – `GET /search?q=...&level=&tag=&context=&type=` | `search/` |
| 4.1.3 | Filter: by level, topic tag, IELTS context, type | Trong query |
| 4.1.4 | Tag navigation: `GET /tags/:slug` → list items with that tag | `tags/` |

### 4.2 Frontend

| Step | Task | Files |
|------|------|-------|
| 4.2.1 | SearchController (GetX) | `features/search/` |
| 4.2.2 | SearchPage – search bar + filter dropdowns + result groups | `features/search/` |
| 4.2.3 | Result cards (document, vocabulary, sentence pattern, web resource) | `features/search/` |
| 4.2.4 | Tag filter UI (multi-select chips) | `core/widgets/` |
| 4.2.5 | Level filter, Context filter | `core/widgets/` |

### 4.3 Verification
- [ ] Search "renewable" → thấy vocabulary + documents chứa từ đó
- [ ] Filter level=B1 → chỉ thấy B1 items
- [ ] Filter context=WRITING_TASK_2 → chỉ thấy items có context đó
- [ ] Click tag → lọc theo tag

---

## PHASE 5 – Interaction

### 5.1 Backend

| Step | Task | Files |
|------|------|-------|
| 5.1.1 | Comment entity + module + service | `comments/` |
| 5.1.2 | CommentController: list, create, update (own), delete (own/admin) | `comments/` |
| 5.1.3 | Reply support (parent_id) | Trong comment service |
| 5.1.4 | Business rule: user sửa/xóa comment của mình, admin xóa mọi comment | Guard logic |

### 5.2 Frontend

| Step | Task | Files |
|------|------|-------|
| 5.2.1 | CommentRepository + model | `features/comments/data/` |
| 5.2.2 | CommentSection widget (đặt trong DocumentDetailPage) | `features/comments/presentation/` |
| 5.2.3 | Create comment + reply UI | `features/comments/` |
| 5.2.4 | Edit/delete own comment | `features/comments/` |
| 5.2.5 | LocalNoteStorage (sqflite/IndexedDB abstraction) | `core/storage/local_note_storage.dart` |
| 5.2.6 | LocalNoteController | `features/notes/` |
| 5.2.7 | NotesPage – list, create, edit, delete local notes | `features/notes/` |
| 5.2.8 | "Add note" button in vocabulary/sentence/document detail | Trong detail widgets |

### 5.3 Verification
- [ ] User comment → thấy comment
- [ ] User reply → thấy nested reply
- [ ] User sửa comment của mình → update
- [ ] User xóa comment của mình → delete
- [ ] User không xóa được comment của người khác → 403
- [ ] Admin xóa bất kỳ comment → OK
- [ ] Local note: tạo → lưu → restart app → vẫn thấy
- [ ] Local note không gửi API (verify network)

---

## Implementation Order (Sequential)

```
PHASE 0 → PHASE 1 → PHASE 2 → PHASE 3 → PHASE 4 → PHASE 5
  (setup)  (core)   (content)  (admin)   (search)  (interaction)
```

Mỗi phase có thể chạy song song backend + frontend (frontend dùng mock data cho tới khi backend sẵn sàng).

### Estimated Tasks per Phase
| Phase | Backend Tasks | Frontend Tasks |
|-------|:---:|:---:|
| 0 | 5 | 4 |
| 1 | 11 | 9 |
| 2 | 15 | 15 |
| 3 | 10 | 10 |
| 4 | 4 | 5 |
| 5 | 4 | 8 |
| **Total** | **49** | **51** |

---

## Definition of Done (MVP)

Hoàn thành khi:
1. User nhập key → login ✓
2. Backend xác định đúng USER/ADMIN ✓
3. User xem tài liệu theo tuần ✓
4. User mở document detail ✓
5. Document hiển thị vocabulary + sentence pattern ✓
6. User search được ✓
7. User comment được ✓
8. User tạo local note ✓
9. Admin tạo document ✓
10. Admin tạo vocabulary ✓
11. Admin tạo sentence pattern ✓
12. Admin publish content ✓
13. User không gọi được admin API ✓
14. Draft không hiển thị cho user ✓
15. UI đúng design system ✓
