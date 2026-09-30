# IELTS Knowledge Hub – Business & Functional Specification

## 1. Tổng quan

**IELTS Knowledge Hub** là một nền tảng web dùng để quản lý và chia sẻ tài liệu học IELTS theo dạng knowledge base, giao diện lấy cảm hứng từ Notion.

Hệ thống có hai nhóm người dùng chính:

- **User**: đọc tài liệu, tìm kiếm, lọc, comment, tạo note cá nhân lưu local.
- **Admin**: có toàn bộ quyền của User và thêm quyền tạo/sửa/xóa/đăng tài liệu, từ vựng, cấu trúc câu, tag và các tài nguyên học tập.

MVP sử dụng:

- **Frontend:** Flutter Web
- **Backend:** NestJS
- **Database:** PostgreSQL
- **Auth:** Access Key + JWT
- **Local note:** lưu local trên browser, không sync server
- **Hosting đề xuất:** Render

---

# PHẦN A – BUSINESS FLOW

## 2. Role & Permission

### 2.1 Role

```text
USER
ADMIN
```

### 2.2 Permission Matrix

| Chức năng | User | Admin |
|---|---:|---:|
| Nhập access key | ✅ | ✅ |
| Đăng nhập | ✅ | ✅ |
| Xem tài liệu | ✅ | ✅ |
| Search | ✅ | ✅ |
| Filter | ✅ | ✅ |
| Xem vocabulary | ✅ | ✅ |
| Xem sentence structure | ✅ | ✅ |
| Comment | ✅ | ✅ |
| Reply comment | ✅ | ✅ |
| Tạo local note | ✅ | ✅ |
| Sửa local note | ✅ | ✅ |
| Xóa local note | ✅ | ✅ |
| Tạo document | ❌ | ✅ |
| Sửa document | ❌ | ✅ |
| Archive document | ❌ | ✅ |
| Publish document | ❌ | ✅ |
| Tạo vocabulary | ❌ | ✅ |
| Sửa vocabulary | ❌ | ✅ |
| Tạo sentence pattern | ❌ | ✅ |
| Sửa sentence pattern | ❌ | ✅ |
| Quản lý tag | ❌ | ✅ |
| Quản lý access key | ❌ | ✅ |

---

# PHẦN B – FRONTEND SPECIFICATION

## 3. Design System

### 3.1 Color Palette

```text
Primary:    #800020
Secondary:  #D45060
Surface:    #F3E6D5
Background: #FFF9F2
```

### 3.2 UI Style

Phong cách tổng thể:

- Gần giống Notion
- Sidebar cố định bên trái
- Main content ở trung tâm
- Nhiều whitespace
- Border nhẹ
- Card bo góc vừa phải
- Primary color chỉ dùng cho CTA, active menu, highlight và important action
- Không dùng quá nhiều màu đỏ burgundy trên toàn màn hình

---

## 4. Routing FE

```text
/access
/home
/resources
/weekly
/weekly/:date
/documents/:id
/articles
/notes
/search

/admin
/admin/documents/create
/admin/documents/:id/edit
/admin/vocabularies/create
/admin/vocabularies/:id/edit
/admin/sentence-patterns/create
/admin/sentence-patterns/:id/edit
/admin/tags
/admin/access-keys
```

---

## 5. Screen – Access Key Login

### 5.1 Mục tiêu

Cho phép user nhập access key để xác thực role và truy cập hệ thống.

### 5.2 UI

```text
IELTS Knowledge Hub

[ Enter your access key ]

[ Continue ]
```

### 5.3 FE Flow

```text
Input key
  ↓
Validate empty
  ↓
POST /auth/access-key
  ↓
Receive accessToken + user role
  ↓
Save token locally
  ↓
Navigate /home
```

### 5.4 Validation

- Không cho submit nếu key rỗng
- Hiển thị loading khi submit
- Hiển thị lỗi nếu:
  - key không tồn tại
  - key hết hạn
  - key bị disable

---

## 6. Main Layout

### 6.1 Sidebar

```text
IELTS Knowledge Hub

Knowledge
├── Tài liệu web
├── Tài liệu theo tuần
├── Bài viết
└── Note

Admin only
├── Quản lý tài liệu
├── Từ vựng
├── Cấu trúc câu
├── Tags
└── Access Keys
```

### 6.2 User Info

Cuối sidebar hiển thị:

```text
Display name
Role
Logout
```

---

## 7. Tài liệu theo tuần

### 7.1 Mục tiêu

Hiển thị tài liệu học được nhóm theo tuần và ngày.

### 7.2 UI Flow

```text
Week Selector
  ↓
Danh sách ngày
  ↓
Document summary trong ngày
```

Ví dụ:

```text
Week 1
02/09 - 08/09

02/09
Environment & Climate Change
Vocabulary 12
Sentence 8
Comments 4
```

### 7.3 User Actions

- chọn tuần
- chọn ngày
- mở document
- search trong danh sách
- filter theo topic/tag

---

## 8. Document Detail

### 8.1 Document Structure

Document được tổ chức theo block.

Các block hỗ trợ MVP:

```text
heading
text
vocabulary
sentence_pattern
quote
link
divider
```

### 8.2 Layout

```text
Title
Metadata
Tags

Content blocks

Comments
```

### 8.3 Table of Contents

Nếu document có nhiều heading:

```text
1. Key Vocabulary
2. Useful Sentence Structures
3. Practice Examples
4. Discussion
```

---

## 9. Vocabulary UI

### 9.1 Field hiển thị

```text
Term
Definition
Vietnamese Meaning
Usage
Example
Collocations
Level
Topic Tags
IELTS Context Tags
```

### 9.2 Example

```text
renewable energy

Definition:
Energy from natural sources that can be replenished.

Vietnamese Meaning:
năng lượng tái tạo

Usage:
Used when talking about sustainable energy sources.

Example:
Using renewable energy can help reduce carbon emissions.

Collocations:
- renewable energy sources
- invest in renewable energy
- renewable energy sector

Level:
B1

Tags:
Environment
Energy

IELTS Context:
Writing Task 2
Speaking Part 3
```

---

## 10. Sentence Pattern UI

### 10.1 Fields

```text
Pattern
Meaning
Usage
Example
Level
Topic Tags
IELTS Context Tags
Function Tags
```

### 10.2 IELTS Context

```text
Writing Task 1
Writing Task 2
Speaking Part 1
Speaking Part 2
Speaking Part 3
```

### 10.3 Example

```text
There was a significant increase in + noun

Meaning:
Đã có một sự gia tăng đáng kể...

Usage:
Used to describe an upward trend.

Example:
There was a significant increase in the number of international students.

Context:
Writing Task 1

Function:
Increase
Trend
```

---

## 11. Search

### 11.1 Search Scope

Search qua:

```text
Document title
Vocabulary term
Definition
Vietnamese meaning
Example
Collocation
Sentence pattern
Tag
Topic
```

### 11.2 Search Result Groups

```text
Documents
Vocabulary
Sentence Patterns
Web Resources
```

### 11.3 Filter

```text
Level
- A2
- B1
- B2

Topic
- Environment
- Education
- Technology

IELTS Context
- Writing Task 1
- Writing Task 2
- Speaking

Type
- Document
- Vocabulary
- Sentence Pattern
- Web Resource
```

---

## 12. Comment

### 12.1 User Action

User có thể:

- tạo comment
- reply comment
- sửa comment của chính mình
- xóa comment của chính mình

Admin có thể:

- xóa bất kỳ comment nào nếu cần

### 12.2 UI

```text
Discussion

User A
Can this phrase be used in Task 2?

Admin
Yes, especially when discussing...
```

---

## 13. Local Note

### 13.1 Business Rule

Local note:

```text
Không gửi API
Không lưu PostgreSQL
Không sync giữa các device
Admin không đọc được
```

### 13.2 Note Model

```text
id
referenceId
referenceType
title
content
createdAt
updatedAt
```

`referenceType`:

```text
vocabulary
sentence_pattern
document
general
```

### 13.3 Storage

Flutter Web ưu tiên:

```text
IndexedDB
```

Có thể bọc qua local storage abstraction để dễ đổi implementation.

---

## 14. Admin – Create Vocabulary

### 14.1 Form

```text
Term *
Definition *
Vietnamese Meaning
Usage
Example
Collocations
Level
Topic Tags
IELTS Context Tags

Save Draft
Publish
```

### 14.2 Validation

Required:

```text
term
definition
level
```

---

## 15. Admin – Create Sentence Pattern

### 15.1 Form

```text
Pattern *
Meaning
Usage
Example
Level
Topic Tags
IELTS Context Tags
Function Tags

Save Draft
Publish
```

---

## 16. Admin – Create Document

### 16.1 Fields

```text
title
description
type
studyDate
week
tags
status
```

### 16.2 Document Types

```text
weekly
web_resource
article
```

### 16.3 Status

```text
DRAFT
PUBLISHED
ARCHIVED
```

### 16.4 Block Editor

Admin có thể thêm:

```text
Text
Heading
Vocabulary
Sentence Pattern
Quote
Link
Divider
```

và reorder block theo `position`.

---

# PHẦN C – BACKEND SPECIFICATION

## 17. Backend Architecture

NestJS module đề xuất:

```text
src/
├── auth/
├── users/
├── access-keys/
├── documents/
├── document-blocks/
├── vocabularies/
├── collocations/
├── sentence-patterns/
├── tags/
├── ielts-contexts/
├── comments/
├── web-resources/
├── search/
└── common/
    ├── guards/
    ├── decorators/
    ├── enums/
    ├── exceptions/
    └── interceptors/
```

---

## 18. Auth

### 18.1 API

```http
POST /auth/access-key
```

Request:

```json
{
  "key": "A8XF-92KM-PQ"
}
```

Response:

```json
{
  "accessToken": "jwt-token",
  "user": {
    "id": "uuid",
    "role": "USER"
  }
}
```

### 18.2 Business Rules

Backend phải check:

```text
key tồn tại
status = ACTIVE
expiresAt chưa hết hạn
```

Sau login:

```text
update lastUsedAt
```

### 18.3 Security

Không lưu plaintext access key.

Nên lưu:

```text
keyHash
```

và compare bằng hash.

---

## 19. Users

### users

```text
id UUID PK
display_name varchar
role enum(USER, ADMIN)
status enum(ACTIVE, DISABLED)
created_at timestamptz
updated_at timestamptz
```

---

## 20. Access Keys

### access_keys

```text
id UUID PK
key_hash varchar
user_id UUID FK
status enum(ACTIVE, DISABLED)
expires_at timestamptz nullable
last_used_at timestamptz nullable
created_at timestamptz
updated_at timestamptz
```

---

## 21. Documents

### documents

```text
id UUID PK
title varchar
description text nullable
type enum(WEEKLY, WEB_RESOURCE, ARTICLE)
status enum(DRAFT, PUBLISHED, ARCHIVED)
study_date date nullable
week_number int nullable
created_by UUID FK
created_at timestamptz
updated_at timestamptz
published_at timestamptz nullable
```

Business Rule:

```text
USER chỉ đọc status = PUBLISHED
ADMIN đọc được tất cả
```

---

## 22. Document Blocks

### document_blocks

```text
id UUID PK
document_id UUID FK
block_type enum(
  HEADING,
  TEXT,
  VOCABULARY,
  SENTENCE_PATTERN,
  QUOTE,
  LINK,
  DIVIDER
)
position int
data jsonb
created_at timestamptz
updated_at timestamptz
```

Ví dụ vocabulary block:

```json
{
  "vocabularyId": "uuid"
}
```

Ví dụ text block:

```json
{
  "content": "Today we will study..."
}
```

---

## 23. Vocabularies

### vocabularies

```text
id UUID PK
term varchar
definition text
vietnamese_meaning text nullable
usage text nullable
example text nullable
level enum(A1, A2, B1, B2, C1, C2)
status enum(DRAFT, PUBLISHED, ARCHIVED)
created_by UUID FK
created_at timestamptz
updated_at timestamptz
```

---

## 24. Collocations

### collocations

```text
id UUID PK
vocabulary_id UUID FK
phrase varchar
example text nullable
created_at timestamptz
updated_at timestamptz
```

---

## 25. Sentence Patterns

### sentence_patterns

```text
id UUID PK
pattern text
meaning text nullable
usage text nullable
example text nullable
level enum(A1, A2, B1, B2, C1, C2)
status enum(DRAFT, PUBLISHED, ARCHIVED)
created_by UUID FK
created_at timestamptz
updated_at timestamptz
```

---

## 26. Tags

### tags

```text
id UUID PK
name varchar unique
slug varchar unique
type enum(TOPIC, FUNCTION, GENERAL)
created_at timestamptz
updated_at timestamptz
```

Ví dụ:

```text
Environment
Technology
Education
Trend
Increase
Comparison
```

---

## 27. IELTS Context

### ielts_contexts

```text
id UUID PK
code varchar unique
name varchar unique
```

Seed data:

```text
WRITING_TASK_1
WRITING_TASK_2
SPEAKING_PART_1
SPEAKING_PART_2
SPEAKING_PART_3
```

---

## 28. Pivot Tables

### vocabulary_tags

```text
vocabulary_id UUID FK
tag_id UUID FK
```

### vocabulary_contexts

```text
vocabulary_id UUID FK
context_id UUID FK
```

### sentence_pattern_tags

```text
sentence_pattern_id UUID FK
tag_id UUID FK
```

### sentence_pattern_contexts

```text
sentence_pattern_id UUID FK
context_id UUID FK
```

### document_tags

```text
document_id UUID FK
tag_id UUID FK
```

---

## 29. Comments

### comments

```text
id UUID PK
document_id UUID FK
user_id UUID FK
parent_id UUID nullable FK
content text
created_at timestamptz
updated_at timestamptz
```

Business Rules:

```text
User sửa/xóa comment của chính mình
Admin có thể xóa mọi comment
parent_id dùng cho reply
```

---

## 30. Web Resources

### web_resources

```text
id UUID PK
title varchar
url text
description text nullable
thumbnail text nullable
resource_type enum(WEBSITE, PDF, VIDEO, OTHER)
status enum(DRAFT, PUBLISHED, ARCHIVED)
created_by UUID FK
created_at timestamptz
updated_at timestamptz
```

---

# PHẦN D – API CONTRACT

## 31. Auth APIs

```http
POST /auth/access-key
GET  /auth/me
POST /auth/logout
```

---

## 32. Document APIs

```http
GET    /documents
GET    /documents/:id
POST   /documents
PATCH  /documents/:id
DELETE /documents/:id
POST   /documents/:id/publish
POST   /documents/:id/archive
```

Query example:

```http
GET /documents?type=WEEKLY&week=1&status=PUBLISHED
```

---

## 33. Document Block APIs

```http
GET    /documents/:documentId/blocks
POST   /documents/:documentId/blocks
PATCH  /document-blocks/:id
DELETE /document-blocks/:id
PATCH  /documents/:documentId/blocks/reorder
```

---

## 34. Vocabulary APIs

```http
GET    /vocabularies
GET    /vocabularies/:id
POST   /vocabularies
PATCH  /vocabularies/:id
DELETE /vocabularies/:id
POST   /vocabularies/:id/publish
```

Filter:

```http
GET /vocabularies?level=B1&tag=environment&context=WRITING_TASK_2
```

---

## 35. Sentence Pattern APIs

```http
GET    /sentence-patterns
GET    /sentence-patterns/:id
POST   /sentence-patterns
PATCH  /sentence-patterns/:id
DELETE /sentence-patterns/:id
POST   /sentence-patterns/:id/publish
```

---

## 36. Comment APIs

```http
GET    /documents/:documentId/comments
POST   /documents/:documentId/comments
PATCH  /comments/:id
DELETE /comments/:id
```

---

## 37. Tags APIs

```http
GET    /tags
POST   /tags
PATCH  /tags/:id
DELETE /tags/:id
```

---

## 38. Search API

```http
GET /search?q=environment
```

Response:

```json
{
  "documents": [],
  "vocabularies": [],
  "sentencePatterns": [],
  "webResources": []
}
```

Search index scope:

```text
document title
vocabulary term
vocabulary definition
vocabulary example
collocation phrase
sentence pattern
sentence pattern example
tag name
```

MVP dùng PostgreSQL Full Text Search hoặc ILIKE.

Chưa cần Elasticsearch.

---

# PHẦN E – FRONTEND ARCHITECTURE

## 39. Flutter Folder Structure

```text
lib/
├── core/
│   ├── constants/
│   ├── network/
│   ├── routes/
│   ├── theme/
│   ├── storage/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── home/
│   ├── documents/
│   ├── vocabulary/
│   ├── sentence_pattern/
│   ├── comments/
│   ├── search/
│   ├── notes/
│   ├── web_resources/
│   └── admin/
│
└── main.dart
```

---

## 40. FE State Management

Nếu sử dụng GetX:

```text
AuthController
HomeController
DocumentController
WeeklyDocumentController
VocabularyController
SentencePatternController
SearchController
CommentController
LocalNoteController
AdminDocumentController
AdminVocabularyController
AdminSentencePatternController
```

---

## 41. Token Storage

FE lưu:

```text
accessToken
role
userId
```

Browser storage:

```text
localStorage / secure abstraction
```

Không lưu access key sau login.

---

# PHẦN F – BACKEND ARCHITECTURE

## 42. NestJS Guard

### JwtAuthGuard

Tất cả API protected phải verify JWT.

### RolesGuard

Ví dụ:

```ts
@Roles(Role.ADMIN)
@Post()
create() {}
```

Không được chỉ check role ở Flutter.

---

## 43. Global Error Format

Response lỗi thống nhất:

```json
{
  "statusCode": 400,
  "code": "INVALID_ACCESS_KEY",
  "message": "Access key is invalid",
  "timestamp": "2026-09-29T10:00:00Z"
}
```

---

## 44. Pagination

Các list API dùng:

```text
page
pageSize
```

Response:

```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

---

# PHẦN G – MVP ROADMAP

## 45. Phase 1 – Core

```text
Access Key
JWT
Role
Main Layout
Sidebar
```

## 46. Phase 2 – Learning Content

```text
Documents
Weekly Documents
Vocabulary
Sentence Patterns
Document Blocks
```

## 47. Phase 3 – Admin

```text
CRUD Documents
CRUD Vocabulary
CRUD Sentence Pattern
Tags
Publish / Draft
```

## 48. Phase 4 – Discovery

```text
Search
Filter
Tag navigation
```

## 49. Phase 5 – Interaction

```text
Comment
Reply
Local Notes
```

## 50. Phase 6 – Future

```text
Articles
AI content extraction
RAG
Quiz
Learning progress
Spaced repetition
Favorites
File upload
Teacher dashboard
```

---

# PHẦN H – BUSINESS RULES QUAN TRỌNG

## 51. Không duplicate vocabulary

Vocabulary là entity độc lập.

Document chỉ reference vocabulary.

Ví dụ:

```text
Document 29/09
├── Vocabulary #102
├── Vocabulary #110
└── Sentence Pattern #88
```

Không copy toàn bộ nội dung vocabulary vào document.

---

## 52. Published Content

User chỉ được xem:

```text
PUBLISHED
```

Admin được xem:

```text
DRAFT
PUBLISHED
ARCHIVED
```

---

## 53. Local Notes

Local notes tuyệt đối không gửi server ở MVP.

Nếu sau này muốn sync:

```text
Local Note
    ↓
Optional Cloud Sync
```

phải tách thành feature mới.

---

## 54. Access Key

Access key dùng để xác nhận user và role.

Không nên dùng một key chung cho toàn bộ user nếu hệ thống cần theo dõi comment theo từng người.

Khuyến nghị:

```text
1 access key = 1 user
```

để backend xác định:

```text
userId
role
comment owner
```

---

# PHẦN I – DEPLOYMENT

## 55. Monorepo

```text
ielts-platform/
├── frontend/
└── backend/
```

## 56. Render

Frontend:

```text
Render Static Site
Root Directory: frontend
```

Backend:

```text
Render Web Service
Root Directory: backend
```

Database:

```text
PostgreSQL
```

Có thể dùng:

```text
Render PostgreSQL
hoặc
Supabase PostgreSQL
```

---

# PHẦN J – DEFINITION OF DONE MVP

MVP được coi là hoàn thành khi:

```text
1. User nhập key và login được.
2. Backend xác định đúng USER / ADMIN.
3. User xem được tài liệu theo tuần.
4. User mở document detail được.
5. Document hiển thị vocabulary và sentence pattern.
6. User search được vocabulary / document / sentence.
7. User comment được.
8. User tạo note local được.
9. Admin tạo document được.
10. Admin tạo vocabulary được.
11. Admin tạo sentence pattern được.
12. Admin publish content được.
13. User không thể gọi API admin.
14. Draft không hiển thị cho user.
15. UI sử dụng đúng design system đã định nghĩa.
```
