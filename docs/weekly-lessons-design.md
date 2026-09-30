# Weekly Lessons Module - Complete Design

## 1. Business Flow

### Core Flow
```
Admin creates a Week plan:
  → For each day (Mon-Sun), creates 1-N lessons
  → Each lesson is built from reusable components:
      - Vocabulary (shared across lessons)
      - Sentence Patterns (shared across lessons)
      - Theory blocks (lesson-specific)
      - Practice questions (lesson-specific)
  → Admin publishes the week
  → Users see published lessons organized by week/day
```

### Lesson Lifecycle
```
DRAFT → PUBLISHED → ARCHIVED
  ↑         |
  └─────────┘ (unpublish back to draft)
```

### User Journey
```
User opens app → Sees current week's lessons by day
  → Clicks a lesson → Sees structured content:
      Overview (description + stats)
      Vocabulary (cards with collocations, add local note)
      Sentence Patterns (cards with examples, add local note)
      Theory (read blocks)
      Practice (interactive questions)
      Notes (all local notes for this lesson)
```

---

## 2. User Stories

### Admin
- As an admin, I want to create a lesson for a specific day so I can plan weekly content
- As an admin, I want to add vocabulary items to a lesson so students learn relevant words
- As an admin, I want to reuse existing vocabulary in multiple lessons without duplication
- As an admin, I want to reorder vocabulary/patterns/theory blocks within a lesson
- As an admin, I want to duplicate a lesson to quickly create a similar one
- As an admin, I want to publish/unpublish a lesson to control visibility
- As an admin, I want to add practice questions to test student understanding

### User
- As a user, I want to see this week's lessons organized by day
- As a user, I want to see vocabulary with definitions, examples, and collocations
- As a user, I want to add personal notes to vocabulary/patterns/theory (local only)
- As a user, I want to search across all content (lessons, vocabulary, patterns)
- As a user, I want to filter lessons by level, topic, or IELTS context
- As a user, I want to do practice questions within a lesson

---

## 3. Acceptance Criteria

### Create Lesson
- [ ] Admin can create lesson with title, description, studyDate, level, topics, contexts
- [ ] Lesson starts as DRAFT
- [ ] Study date must be a valid date within a week
- [ ] Week number is auto-calculated from studyDate

### Add Vocabulary to Lesson
- [ ] Admin can search existing vocabulary or create new inline
- [ ] Adding existing vocabulary creates a mapping, NOT a duplicate
- [ ] Position can be set for ordering
- [ ] Same vocabulary can appear in multiple lessons

### Lesson Detail (User View)
- [ ] Shows all sections: Overview, Vocabulary, Patterns, Theory, Practice
- [ ] Vocabulary cards show: term, level badge, definition, example, collocations
- [ ] Each vocabulary card has "[+ Note]" button
- [ ] Theory blocks render by type (heading, paragraph, bulletList, callout)
- [ ] Practice shows question + optional suggested answer (toggle)
- [ ] Summary bar shows counts per section

### Local Notes
- [ ] Notes stored ONLY in frontend (IndexedDB/localStorage)
- [ ] Note linked to referenceId + referenceType
- [ ] Inline input on card (no navigation)
- [ ] Notes tab shows all notes with search + filter
- [ ] Clicking note navigates to source lesson + highlights item
- [ ] Admin CANNOT see user notes (no API endpoint for notes)

### Search
- [ ] Single search endpoint returns grouped results
- [ ] Searches: lesson title, vocab term/definition, pattern, theory, topics, contexts
- [ ] Results grouped by type: Vocabulary, Sentence Pattern, Lesson

### Permissions
- [ ] USER can only GET (list, detail)
- [ ] ADMIN can POST, PATCH, DELETE, PUBLISH
- [ ] Backend enforces (not just frontend hiding)

---

## 4. Database Design

### Entity Relationship Diagram (text)

```
weeks (implicit via weekNumber on lessons)
  └── lessons (1:N per week)
        ├── lesson_vocabularies (M:N → vocabularies) [position]
        ├── lesson_sentence_patterns (M:N → sentence_patterns) [position]
        ├── lesson_theory_blocks (1:N) [position]
        └── lesson_practice (1:N) [position]

vocabularies
  ├── collocations (1:N)
  ├── vocabulary_topics (M:N → tags)
  └── vocabulary_contexts (M:N → ielts_contexts)

sentence_patterns
  ├── sentence_pattern_topics (M:N → tags)
  └── sentence_pattern_contexts (M:N → ielts_contexts)

tags (topics)
ielts_contexts (lookup: Writing Task 1, Speaking Part 1, etc.)
comments (on lessons)
```

### Tables

#### lessons (repurpose existing `documents` table with type=LESSON)
```sql
-- Already exists as `documents`. We'll add:
ALTER TABLE documents ADD COLUMN level VARCHAR(10);
ALTER TABLE documents ADD COLUMN day_of_week SMALLINT; -- 1=Mon, 7=Sun
```

#### lesson_vocabularies (NEW)
```sql
CREATE TABLE lesson_vocabularies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  vocabulary_id UUID NOT NULL REFERENCES vocabularies(id) ON DELETE CASCADE,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(lesson_id, vocabulary_id)
);
CREATE INDEX idx_lv_lesson ON lesson_vocabularies(lesson_id);
CREATE INDEX idx_lv_vocab ON lesson_vocabularies(vocabulary_id);
```

#### lesson_sentence_patterns (NEW)
```sql
CREATE TABLE lesson_sentence_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  sentence_pattern_id UUID NOT NULL REFERENCES sentence_patterns(id) ON DELETE CASCADE,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(lesson_id, sentence_pattern_id)
);
CREATE INDEX idx_lsp_lesson ON lesson_sentence_patterns(lesson_id);
CREATE INDEX idx_lsp_pattern ON lesson_sentence_patterns(sentence_pattern_id);
```

#### lesson_theory_blocks (NEW)
```sql
CREATE TABLE lesson_theory_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL, -- 'heading' | 'paragraph' | 'bullet_list' | 'callout'
  content TEXT NOT NULL,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_lt_lesson ON lesson_theory_blocks(lesson_id);
```

#### lesson_practice (NEW)
```sql
CREATE TABLE lesson_practice (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL, -- 'short_answer' | 'fill_blank' | 'writing_prompt' | 'speaking_question'
  question TEXT NOT NULL,
  suggested_answer TEXT,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_lp_lesson ON lesson_practice(lesson_id);
```

#### vocabulary_topics (NEW)
```sql
CREATE TABLE vocabulary_topics (
  vocabulary_id UUID NOT NULL REFERENCES vocabularies(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (vocabulary_id, tag_id)
);
```

#### vocabulary_contexts (NEW)
```sql
CREATE TABLE vocabulary_contexts (
  vocabulary_id UUID NOT NULL REFERENCES vocabularies(id) ON DELETE CASCADE,
  context_id UUID NOT NULL REFERENCES ielts_contexts(id) ON DELETE CASCADE,
  PRIMARY KEY (vocabulary_id, context_id)
);
```

#### sentence_pattern_topics (NEW)
```sql
CREATE TABLE sentence_pattern_topics (
  sentence_pattern_id UUID NOT NULL REFERENCES sentence_patterns(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (sentence_pattern_id, tag_id)
);
```

#### sentence_pattern_contexts (NEW)
```sql
CREATE TABLE sentence_pattern_contexts (
  sentence_pattern_id UUID NOT NULL REFERENCES sentence_patterns(id) ON DELETE CASCADE,
  context_id UUID NOT NULL REFERENCES ielts_contexts(id) ON DELETE CASCADE,
  PRIMARY KEY (sentence_pattern_id, context_id)
);
```

---

## 5. TypeORM Entities (not Prisma - project uses TypeORM)

All entities will follow the existing pattern with explicit column types.

---

## 6. NestJS Module Architecture

```
src/
├── lessons/                    (repurpose documents module for lesson-specific logic)
│   ├── lessons.module.ts
│   ├── lessons.controller.ts
│   ├── lessons.service.ts
│   ├── dto/
│   │   ├── create-lesson.dto.ts
│   │   ├── update-lesson.dto.ts
│   │   └── query-lessons.dto.ts
│   └── entities/
│       └── lesson.entity.ts    (extends/aliases Document)

├── lesson-vocabularies/        (NEW)
│   ├── lesson-vocabularies.module.ts
│   ├── lesson-vocabularies.controller.ts
│   ├── lesson-vocabularies.service.ts
│   └── entities/
│       └── lesson-vocabulary.entity.ts

├── lesson-sentence-patterns/   (NEW)
│   ├── lesson-sentence-patterns.module.ts
│   ├── lesson-sentence-patterns.controller.ts
│   ├── lesson-sentence-patterns.service.ts
│   └── entities/
│       └── lesson-sentence-pattern.entity.ts

├── theory-blocks/              (NEW)
│   ├── theory-blocks.module.ts
│   ├── theory-blocks.controller.ts
│   ├── theory-blocks.service.ts
│   └── entities/
│       └── theory-block.entity.ts

├── practice/                   (NEW)
│   ├── practice.module.ts
│   ├── practice.controller.ts
│   ├── practice.service.ts
│   └── entities/
│       └── practice.entity.ts

├── vocabularies/               (existing - extend with topics, contexts)
├── sentence-patterns/          (existing - extend with topics, contexts)
├── tags/                       (existing)
├── ielts-contexts/             (existing)
└── search/                     (extend for cross-content search)
```

---

## 7. API Specification

### Lessons
| Method | Route | Role | Description |
|--------|-------|------|-------------|
| GET | `/lessons` | ALL | List lessons (filter: week, level, topic, context, status) |
| GET | `/lessons/:id` | ALL | Full lesson detail with all sections |
| POST | `/lessons` | ADMIN | Create lesson |
| PATCH | `/lessons/:id` | ADMIN | Update lesson metadata |
| DELETE | `/lessons/:id` | ADMIN | Delete lesson |
| POST | `/lessons/:id/publish` | ADMIN | Publish |
| POST | `/lessons/:id/duplicate` | ADMIN | Duplicate lesson |

### Lesson Content
| Method | Route | Role | Description |
|--------|-------|------|-------------|
| GET | `/lessons/:id/vocabularies` | ALL | Get vocabulary for lesson |
| POST | `/lessons/:id/vocabularies` | ADMIN | Add vocab to lesson |
| PATCH | `/lessons/:id/vocabularies/reorder` | ADMIN | Reorder |
| DELETE | `/lessons/:id/vocabularies/:vocabularyId` | ADMIN | Remove from lesson |
| GET | `/lessons/:id/sentence-patterns` | ALL | Get patterns |
| POST | `/lessons/:id/sentence-patterns` | ADMIN | Add pattern |
| PATCH | `/lessons/:id/sentence-patterns/reorder` | ADMIN | Reorder |
| DELETE | `/lessons/:id/sentence-patterns/:patternId` | ADMIN | Remove |
| GET | `/lessons/:id/theory` | ALL | Get theory blocks |
| POST | `/lessons/:id/theory` | ADMIN | Add theory block |
| PATCH | `/lessons/:id/theory/:blockId` | ADMIN | Update block |
| PATCH | `/lessons/:id/theory/reorder` | ADMIN | Reorder |
| DELETE | `/lessons/:id/theory/:blockId` | ADMIN | Delete block |
| GET | `/lessons/:id/practice` | ALL | Get practice |
| POST | `/lessons/:id/practice` | ADMIN | Add practice |
| PATCH | `/lessons/:id/practice/:id` | ADMIN | Update |
| DELETE | `/lessons/:id/practice/:id` | ADMIN | Delete |

### Search
| Method | Route | Role | Description |
|--------|-------|------|-------------|
| GET | `/search?q=term&types=lesson,vocabulary,pattern` | ALL | Cross-content search |

### Key Response Shapes

#### GET /lessons/:id (full detail)
```json
{
  "status": "success",
  "data": {
    "id": "uuid",
    "title": "Environment & Climate Change",
    "description": "...",
    "studyDate": "2026-09-29",
    "weekNumber": 40,
    "dayOfWeek": 1,
    "level": "B1",
    "topics": [{"id": "uuid", "name": "Environment"}],
    "contexts": [{"id": "uuid", "name": "Writing Task 2"}],
    "status": "PUBLISHED",
    "vocabulary": [
      {
        "id": "uuid",
        "term": "renewable energy",
        "definition": "...",
        "vietnameseMeaning": "năng lượng tái tạo",
        "example": "...",
        "level": "B1",
        "collocations": [{"phrase": "renewable energy sources", "example": "..."}],
        "topics": [{"name": "Environment"}],
        "contexts": [{"name": "Writing Task 2"}]
      }
    ],
    "sentencePatterns": [
      {
        "id": "uuid",
        "pattern": "One of the main reasons is that + clause",
        "meaning": "...",
        "example": "...",
        "level": "B1"
      }
    ],
    "theory": [
      {"id": "uuid", "type": "heading", "content": "When do we use...?", "position": 0},
      {"id": "uuid", "type": "bullet_list", "content": "Experiences\nActions...", "position": 1}
    ],
    "practice": [
      {"id": "uuid", "type": "short_answer", "question": "...", "suggestedAnswer": "..."}
    ],
    "summary": {
      "vocabularyCount": 12,
      "patternCount": 6,
      "theoryCount": 3,
      "practiceCount": 5
    }
  }
}
```

#### GET /search?q=environment
```json
{
  "status": "success",
  "data": {
    "lessons": [{"id": "uuid", "title": "Environment & Climate Change"}],
    "vocabulary": [{"id": "uuid", "term": "renewable energy", "matchedField": "definition"}],
    "sentencePatterns": [{"id": "uuid", "pattern": "One possible solution is to..."}],
    "total": 5
  }
}
```

---

## 8. Flutter Architecture

```
features/
└── weekly_lessons/
    ├── data/
    │   ├── lesson_datasource.dart
    │   ├── lesson_dto.dart
    │   └── lesson_mapper.dart
    ├── domain/
    │   ├── lesson.dart
    │   ├── vocabulary_item.dart
    │   ├── sentence_pattern_item.dart
    │   ├── theory_block.dart
    │   ├── practice_question.dart
    │   └── lesson_repository.dart (abstract)
    └── presentation/
        ├── bloc/
        │   ├── lessons_bloc.dart
        │   ├── lesson_detail_bloc.dart
        │   └── events/ + states/
        ├── views/
        │   ├── weekly_lessons_page.dart     (week overview by day)
        │   ├── lesson_detail_page.dart      (full lesson view)
        │   └── lesson_builder_page.dart     (admin builder)
        └── widgets/
            ├── week_day_card.dart
            ├── lesson_summary_bar.dart
            ├── vocabulary_card.dart
            ├── sentence_pattern_card.dart
            ├── theory_block_widget.dart
            ├── practice_question_widget.dart
            ├── local_note_input.dart
            └── lesson_section_header.dart

└── notes/
    ├── data/
    │   └── local_note_repository.dart   (IndexedDB abstraction)
    ├── domain/
    │   └── local_note.dart
    └── presentation/
        ├── bloc/
        │   └── notes_bloc.dart
        ├── views/
        │   └── notes_page.dart
        └── widgets/
            └── note_card.dart
```

---

## 9. Screen List

| Screen | Route | Role | Description |
|--------|-------|------|-------------|
| Weekly Overview | `/weekly` | ALL | Week selector + day grid with lessons |
| Lesson Detail | `/lessons/:id` | ALL | Full structured lesson view |
| Lesson Builder | `/lessons/:id/builder` | ADMIN | Create/edit lesson content |
| Lesson Create | `/lessons/new` | ADMIN | Create lesson form |
| Notes | `/notes` | ALL | All local notes with search/filter |
| Search | `/search` | ALL | Cross-content search results |

---

## 10. Widget/Component Breakdown

### Weekly Overview Page
```
WeeklyLessonsPage
├── WeekSelector (horizontal chips or dropdown)
├── DayGrid (7 columns on desktop, scroll on mobile)
│   └── DayCard (for each Mon-Sun)
│       ├── DayHeader ("Monday 29/09")
│       └── LessonChip (per lesson, shows title + level badge)
└── EmptyState (if no lessons)
```

### Lesson Detail Page
```
LessonDetailPage
├── LessonHeader
│   ├── Title
│   ├── Date + Level badge + Topic badges + Context badges
│   └── [Lesson Note] button
├── SummaryBar (Vocab: 12 | Patterns: 6 | Theory: 3 | Practice: 5)
├── Section: Overview
│   └── Description text
├── Section: Vocabulary
│   └── VocabularyCard (per item)
│       ├── Term + Level badge
│       ├── Definition
│       ├── Example (italic)
│       ├── Collocations (chips)
│       └── [+ Note] / [Edit Note] button
├── Section: Sentence Patterns
│   └── SentencePatternCard (per item)
│       ├── Pattern (monospace, highlighted)
│       ├── Meaning
│       ├── Example
│       └── [+ Note] button
├── Section: Theory
│   └── TheoryBlockWidget (per block, rendered by type)
│       ├── heading → large bold text
│       ├── paragraph → regular text
│       ├── bullet_list → bullet items
│       └── callout → bordered colored box
├── Section: Practice
│   └── PracticeQuestionWidget (per question)
│       ├── Question text
│       ├── [Show Answer] toggle (if suggestedAnswer exists)
│       └── Type badge
└── Section: Notes (local)
    └── All notes for this lesson
```

### Lesson Builder Page (Admin)
```
LessonBuilderPage
├── LessonMetaForm (title, desc, date, level, topics, contexts)
├── ContentSections (vertical, each collapsible)
│   ├── VocabularySection
│   │   ├── [Add Vocabulary] button → search dialog
│   │   └── List of VocabularyCard (draggable, with edit/delete)
│   ├── SentencePatternSection
│   │   ├── [Add Pattern] button → search dialog
│   │   └── List of PatternCard (draggable, with edit/delete)
│   ├── TheorySection
│   │   ├── [Add Block] dropdown (heading/paragraph/bullet/callout)
│   │   └── List of TheoryBlockEditor (editable, draggable)
│   └── PracticeSection
│       ├── [Add Question] dropdown (type)
│       └── List of PracticeEditor (editable, draggable)
└── BottomActions
    ├── [Save Draft]
    ├── [Preview]
    └── [Publish]
```

### Notes Page
```
NotesPage
├── SearchBar
├── FilterChips (All | Lesson | Vocabulary | Pattern | Theory)
└── NoteCardList
    └── NoteCard
        ├── Reference label (term/pattern/lesson title)
        ├── Note content
        ├── Timestamp
        └── [Delete] button
```

---

## 11. State Management Design

### Blocs
| Bloc | Events | States |
|------|--------|--------|
| `LessonsBloc` | LoadWeek, LoadLessons, Filter | Loading, Loaded(List<Lesson>), Error |
| `LessonDetailBloc` | LoadLesson(id), AddVocab, RemoveVocab, AddTheory, ... | Loading, Loaded(LessonDetail), Error |
| `LessonBuilderBloc` | LoadForEdit, SaveDraft, Publish, AddSection, RemoveSection, Reorder | Draft, Saving, Published, Error |
| `NotesBloc` | LoadAll, AddNote, UpdateNote, DeleteNote, Search, Filter | NotesList, Loading, Error |

### Local Note Architecture
```dart
// Using sqflite_web or IndexedDB via a package
// For Flutter Web: use `indexed_db` package or `sqflite_common_ffi_web`

abstract class LocalNoteRepository {
  Future<List<LocalNote>> getAllNotes();
  Future<List<LocalNote>> getNotesByReference(String refId, RefType type);
  Future<void> saveNote(LocalNote note);
  Future<void> updateNote(LocalNote note);
  Future<void> deleteNote(String id);
  Future<List<LocalNote>> searchNotes(String query);
}
```

For MVP on Flutter Web, use `localStorage` via `shared_preferences` with JSON serialization (simpler than IndexedDB, sufficient for MVP).

---

## 12. Local Note Architecture

### Storage
- `shared_preferences` with JSON-encoded notes under key `local_notes`
- Format: `List<Map<String, dynamic>>`
- Each note: `{id, referenceId, referenceType, content, createdAt, updatedAt}`

### Flow
```
User taps [+ Note] on a vocabulary card
  → Inline note input appears below the card
  → User types note
  → Taps [Save]
  → NotesBloc.AddNote(referenceId, referenceType, content)
  → LocalNoteRepository.saveNote()
  → SharedPreferences write
  → UI updates (inline input becomes [Edit Note] button)
```

### Notes Tab
```
NotesBloc loads all notes from LocalNoteRepository
  → Filter by type (chips)
  → Search by content
  → Display NoteCard list
  → Tap note → navigate to source lesson → scroll to item → flash highlight
```

---

## 13. Edge Cases

| Case | Handling |
|------|----------|
| Lesson with no content | Show empty state per section: "No vocabulary added yet" |
| Vocabulary deleted from DB but still in mapping | Cascade delete removes mapping; lesson detail skips missing |
| Same vocab added twice to same lesson | UNIQUE constraint prevents; return 409 |
| Search with no results | Show "No results for 'query'" |
| Note reference to deleted item | Keep note but show "Original item deleted" |
| Week with no lessons | Show empty day cards |
| User tries to access unpublished lesson | 403 or redirect (BE enforces) |
| Admin deletes lesson with notes | Notes remain (they're local, referenceId just becomes orphaned) |
| Duplicate lesson with same-day content | Gets new ID, same mappings to shared entities |
| Reorder with concurrent edits | Last write wins (MVP) |
| Very long vocabulary list | Virtualized list (ListView.builder) |
| Image/emoji in theory content | MVP: plain text only, no rich text |

---

## 14. MVP Implementation Order

### Phase 1: Backend Foundation (Days 1-2)
1. Create new entities: `LessonVocabulary`, `LessonSentencePattern`, `TheoryBlock`, `Practice`
2. Create mapping entities: `VocabularyTopic`, `VocabularyContext`, `SentencePatternTopic`, `SentencePatternContext`
3. Add columns to documents: `level`, `dayOfWeek`
4. Create modules + services + controllers for each
5. Implement `GET /lessons/:id` (full detail endpoint with all sections joined)
6. Implement CRUD for lesson content (vocab mapping, theory, practice)
7. Implement `POST /lessons/:id/duplicate`
8. Extend search endpoint for cross-content

### Phase 2: Frontend - User View (Days 3-4)
9. Create domain models (Lesson, VocabularyItem, etc.)
10. Create `LessonsBloc` + `LessonDetailBloc`
11. Build Weekly Overview page (week selector + day grid)
12. Build Lesson Detail page (all sections)
13. Build VocabularyCard, SentencePatternCard, TheoryBlock, Practice widgets
14. Add grid background to app

### Phase 3: Frontend - Admin Builder (Days 5-6)
15. Build Lesson Create form
16. Build Lesson Builder page (sections with add/edit/reorder)
17. Implement "Add Vocabulary" search dialog
18. Implement "Add Pattern" search dialog
19. Theory block editor
20. Practice editor
21. Save Draft / Publish actions

### Phase 4: Local Notes (Day 7)
22. Create `LocalNoteRepository` (SharedPreferences-based)
23. Create `NotesBloc`
24. Build inline note input widget
25. Add [+ Note] to vocabulary cards, pattern cards, theory blocks, lesson header
26. Build Notes page (search + filter + list)
27. Implement tap-to-navigate + highlight

### Phase 5: Search + Polish (Day 8)
28. Build search page with grouped results
29. Add filters (level, topic, context)
30. Grid background + visual polish
31. Responsive adjustments
32. Test end-to-end flows

---

## Grid Background Spec

```dart
// Applied to main content area behind cards
// 32px squares, burgundy lines at very low opacity
// Canvas: #FFF9F2 (already the app background)
// Lines: #800020 at ~8% opacity (0.08)

CustomPaint(
  painter: GridBackgroundPainter(
    gridSpacing: 32,
    lineColor: Color(0xFF800020).withOpacity(0.08),
  ),
)
```

Cards remain solid white (`Colors.white`) or cream (`#FFF9F2`) above the grid.
