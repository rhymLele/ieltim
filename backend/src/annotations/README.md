# Module Ghi chú trên tài liệu, Sổ từ, Dịch nghĩa (`annotations`)

Ghi chú cá nhân của người học trên tài liệu theo tuần (highlight chữ, nét vẽ trên slide), Sổ từ nhiều sổ và dịch nghĩa từ / cụm đang chọn. Bảng tự tạo nhờ `synchronize: true`.

## Quy ước

- Prefix `/api`, mọi API cần đăng nhập (JWT). JSON camelCase.
- Response bọc theo `TransformInterceptor`: `{ status, message, data, code, count }`. Lỗi: `{ status: "error", message, error: <MÃ>, code: <HTTP>, data }`.
- **Tài khoản**: phải có trong bảng `users` với `status = ACTIVE`, không thì 403 `USER_INACTIVE` (áp dụng cho `/me/docs/*`, `/me/vocab/*`, `/translate`).
- **Tài liệu** (`/me/docs/:docId/*`): `docId` là mã công khai (`w12-doc2`, `w12-hw1`). Chỉ dùng được với tài liệu PUBLISHED của tuần đã mở (cùng quy tắc với API người dùng của `weekly-docs`, hàm `WeeksService.docVisible`); còn lại 403 `DOC_FORBIDDEN`, kể cả khi mã không tồn tại.
- Body của `/api/me/docs/*` nhận tới 320 KB (nét vẽ một slide tối đa 256 KB); các API khác giữ 100 KB.

## Ghi chú trên tài liệu

| Method | Path                                           | Ghi chú                                                                                                        |
| ------ | ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| GET    | `/me/docs/:docId/annotations`                  | `{ highlights: Highlight[], slides: { [slideKey]: { data, rev, docVersion } } }` của tôi (bỏ highlight đã xoá) |
| PUT    | `/me/docs/:docId/highlights/:id`               | Tạo / ghi đè, `id` là UUID do client sinh. Body bên dưới → `Highlight`                                         |
| DELETE | `/me/docs/:docId/highlights/:id`               | Xoá mềm, idempotent → 204                                                                                      |
| PUT    | `/me/docs/:docId/slides/:slideKey/annotations` | `{ data: { items: [...] }, rev, docVersion }` → `{ rev }`                                                      |

**Highlight**: `{ id, blockKey, quote, prefix, suffix, color, start, end, docVersion, createdAt, updatedAt }`.

- Body PUT: `{ blockKey (1–80), quote (1–300), prefix?, suffix?, color: yellow|green|blue|pink, start?, end?, docVersion }`. `id` trong body bị bỏ qua.
- `blockKey` là khoá khối trong JSON tài liệu, hoặc `"html"` với tài liệu HTML. `start` / `end` là offset gợi ý, có thể `null`.
- `prefix` / `suffix` là ngữ cảnh để neo lại khi tài liệu đổi: server chỉ giữ 32 ký tự cuối của `prefix`, 32 ký tự đầu của `suffix`.
- PUT là ghi đè toàn bộ (trường bỏ trống thành `null` / `''`). PUT lại highlight đã xoá thì khôi phục (giữ `createdAt`).
- `id` sai định dạng → 400 `HIGHLIGHT_ID_INVALID`; `id` đã thuộc người khác (hoặc tài liệu khác) → 404 `HIGHLIGHT_NOT_FOUND`.

**Nét vẽ theo slide** — `slideKey` khớp `^[A-Za-z0-9_-]{1,40}$` (ví dụ `0-1`, `s3`, `y2`, `doc`), sai → 400 `SLIDE_KEY_INVALID`.

- `rev` gửi lên là rev phía server mà bản sửa dựa vào (0 khi slide chưa có gì). Khớp thì lưu với `rev + 1` và trả `{ rev }` mới.
- Không khớp → 409 `ANNOTATION_CONFLICT`, `data = { data: <bản hiện tại hoặc null>, rev: <rev hiện tại, 0 nếu chưa có> }`. FE gộp / thay rồi gửi lại với rev đó.
- Điều kiện rev nằm trong câu lệnh `UPDATE … WHERE rev = :rev` (hoặc `INSERT … ON CONFLICT DO NOTHING` khi rev 0) nên hai lần lưu cùng rev chỉ một lần thành công.
- Lưu `{ items: [] }` vẫn giữ dòng (rev tăng) để máy khác thấy đã xoá hết.
- `data` không có `items` là mảng → 400 `ANNOTATION_INVALID`; JSON của `data` > 256 KB → 413 `ANNOTATION_TOO_LARGE` (body > 320 KB bị chặn trước, 413 `PAYLOAD_TOO_LARGE`).

## Sổ từ

| Method | Path                     | Ghi chú                                                                                                                                              |
| ------ | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| POST   | `/me/vocab`              | `{ text (1–120), meaning? (≤500), ipa? (≤80), example? (≤1000), partOfSpeech? (≤20), deck? (≤60), sourceDocId? (≤40), sourceBlockKey? (≤60) }` → 201 |
| GET    | `/me/vocab?deck=&q=`     | Mới nhất trước, tối đa 2000 dòng. `q`: chứa trong từ hoặc nghĩa, không phân biệt hoa / thường                                                        |
| GET    | `/me/vocab/exists?text=` | `true` / `false` (mọi sổ)                                                                                                                            |
| GET    | `/me/vocab/decks`        | `string[]`: sổ dùng gần nhất trước; luôn có `Sổ chung` (cuối nếu chưa dùng)                                                                          |
| PATCH  | `/me/vocab/:id`          | `{ text?, meaning?, example? (null để xoá), deck?, partOfSpeech? (null để xoá) }` → bản đã sửa                                                       |
| DELETE | `/me/vocab/:id`          | Xoá hẳn → 204                                                                                                                                        |

- Mục từ: `{ id, text, meaning, ipa, example, partOfSpeech, deck, sourceDocId, sourceBlockKey, createdAt }`.
- Dùng chung bảng `vocab_entries` với "Lưu từ vựng của tài liệu" (`POST /weekly/vocab/from-document`, luôn ghi vào `Sổ chung`). Cột: `word` = `text`, `word_norm` = từ chuẩn hoá, `pos` = `partOfSpeech`, `source_document_id` = `sourceDocId`; thêm cột `deck` (mặc định `Sổ chung`, dữ liệu cũ tự nhận giá trị này).
- Bỏ trùng theo (người dùng, từ chuẩn hoá, sổ): chuẩn hoá = chữ thường, bỏ khoảng trắng hai đầu, gộp khoảng trắng giữa. Ràng buộc `uq_vocab_entries_user_word_deck` thay cho `uq_vocab_entries_user_word`.
- Trùng khi thêm / sửa → 409 `VOCAB_EXISTS`, `data` = mục đã có. Không phải của tôi / không tồn tại → 404 `VOCAB_NOT_FOUND`.
- Tên sổ bỏ khoảng trắng thừa, phân biệt hoa / thường; bỏ trống → `Sổ chung`.

## Dịch nghĩa

`POST /translate` (200) `{ text (1–300), sentence? (≤600), from? = "en", to? = "vi" }` → `{ text, meaning, ipa, partOfSpeech, sentenceTranslation }` (`ipa`, `partOfSpeech`, `sentenceTranslation` có thể `null`). Hiện chỉ hỗ trợ Anh → Việt.

1. Tra `translation_cache` theo khoá `sha1(lower(trim(text)) + '|' + lower(trim(sentence ?? '')))` (dùng chung mọi người) → có thì trả ngay.
2. Chưa cấu hình `GEMINI_API_KEY` → 503 `TRANSLATE_UNAVAILABLE` ("Chưa cấu hình dịch nghĩa.").
3. Giới hạn `TRANSLATE_RATE_LIMIT_PER_HOUR` (mặc định 60) lượt không trúng cache / người / giờ (cửa sổ trượt, giữ trong bộ nhớ, một instance) → 429 `TRANSLATE_RATE_LIMIT`.
4. Song song: (a) chữ có 1–3 từ thì tra IPA (và từ loại tiếng Anh) ở `api.dictionaryapi.dev` — ưu tiên phiên âm có audio `-uk`, lỗi / 404 / quá 3 giây thì bỏ qua; (b) gọi Gemini qua REST `models/{GEMINI_MODEL}:generateContent` (mặc định `gemini-3.5-flash-lite`, khoá ở header `x-goog-api-key`), trả JSON theo schema `{ meaning, partOfSpeech, sentenceTranslation }` (`responseMimeType: application/json` + `responseJsonSchema`). Prompt bị chặn / dừng vì an toàn (`SAFETY`, `PROHIBITED_CONTENT`…) coi như model từ chối.
5. Hạn chung 6 giây tính từ lúc nhận request (`TRANSLATE_DEADLINE_MS`), không tự retry → quá hạn 504 `TRANSLATE_TIMEOUT`.
6. JSON sai schema → gọi lại một lần (vẫn trong hạn); vẫn sai, model từ chối hoặc API lỗi → 502 `TRANSLATE_FAILED`.
7. Lưu cache rồi trả. Model để trống từ loại thì lấy từ loại của từ điển (nhãn tiếng Việt).

- Chữ người dùng chỉ nằm trong tin nhắn `user`, system prompt (`systemInstruction`) cố định. Log chỉ ghi loại lỗi (`timeout`, `invalid_output`, `refusal`, `auth`, `rate_limited`, `model_not_found`, `api_500`…), không ghi chữ / câu người dùng tra.
- Gói miễn phí của Gemini API: Google được dùng nội dung gửi lên để cải thiện sản phẩm (gói trả phí thì không). Nội dung gửi đi chỉ là từ / câu trong tài liệu.
- Không có `GET /tts`: app đọc bằng TTS trên máy.

## Mã lỗi

`USER_INACTIVE`, `DOC_FORBIDDEN`, `HIGHLIGHT_ID_INVALID`, `HIGHLIGHT_NOT_FOUND`, `SLIDE_KEY_INVALID`, `ANNOTATION_INVALID`, `ANNOTATION_CONFLICT`, `ANNOTATION_TOO_LARGE`, `PAYLOAD_TOO_LARGE`,
`VOCAB_EXISTS`, `VOCAB_NOT_FOUND`, `TRANSLATE_UNAVAILABLE`, `TRANSLATE_RATE_LIMIT`, `TRANSLATE_TIMEOUT`, `TRANSLATE_FAILED`. Lỗi kiểm tra body khác: 400 (`BadRequestException`).

## Cấu hình, test

- `GEMINI_API_KEY`: khoá Gemini API (tạo ở Google AI Studio; bỏ trống → tắt dịch nghĩa, 503).
- `GEMINI_MODEL` (tuỳ chọn, mặc định `gemini-3.5-flash-lite`), ví dụ `gemini-3.8-flash` để dịch kỹ hơn.
- `TRANSLATE_RATE_LIMIT_PER_HOUR=60`, `TRANSLATE_DEADLINE_MS=6000` (chủ yếu để test).
- Unit test: `NODE_OPTIONS=--experimental-vm-modules npx jest src/annotations` (model / từ điển giả).
- Integration test cần Postgres có DB tên kết thúc bằng `_test` (test xoá sạch bảng weekly và ghi chú), model / từ điển được thay bằng bản giả:
  `DB_NAME=weekly_test WEEKLY_SCHEDULER=off npm run test:e2e -- annotations`.
