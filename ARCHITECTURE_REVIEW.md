Đánh giá backend và frontend — 30/09/2026

**Kết luận: cả hai chưa đạt Clean Architecture; Clean Code và mức sẵn sàng triển khai cũng chưa đạt.** Backend đang là kiến trúc phân lớp theo tính năng của NestJS; frontend chia tính năng và dùng BLoC ở một số nơi nhưng chưa tách data/domain khỏi presentation. Có lỗi chức năng và phân quyền cần sửa trước khi refactor lớn.

Phạm vi: rà soát source ứng dụng trong `backend/src`, `frontend/lib`, cấu hình, test hiện có và đối chiếu một số quy tắc trong business spec. Bao gồm thay đổi chưa commit đang có trong workspace. Không chỉnh sửa source ứng dụng, không chạy migration/seed, không khởi động backend kết nối database. Các kiểm tra tái hiện tạm đã được xóa. Báo cáo này không thay thế kiểm thử tích hợp với PostgreSQL hay kiểm thử toàn bộ luồng trên thiết bị thật.

Tiêu chí kiến trúc là hướng phụ thuộc, ranh giới trách nhiệm và khả năng kiểm thử, không phải chỉ có đủ tên thư mục. [Clean Architecture của Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) yêu cầu nghiệp vụ độc lập với chi tiết framework, UI và database. [Khuyến nghị kiến trúc Flutter](https://docs.flutter.dev/app-architecture/recommendations) cũng nhấn mạnh tách UI/data, repository abstraction và dependency injection. Không cần tạo một use case rỗng cho mọi thao tác CRUD đơn giản.

| Tiêu chí | Backend | Frontend |
|---|---|---|
| Chia module/tính năng | Có | Có |
| Nghiệp vụ độc lập hạ tầng | Chưa: nghiệp vụ gắn TypeORM và HTTP exception | Chưa: BLoC/widget gắn API/storage |
| Repository abstraction của ứng dụng | Chưa có; đang dùng Repository của TypeORM | Chưa có |
| Model/DTO tại ranh giới | Thiếu DTO cho phần lớn CRUD | JSON Map/dynamic đi thẳng tới UI |
| Dependency injection | Có Nest DI, nhưng chưa đảo phụ thuộc tại ranh giới nghiệp vụ | Phần lớn tự tạo ApiClient/storage |
| Kiểm thử nghiệp vụ | Chưa có test tương ứng | Chưa có; widget test mẫu đang fail |
| Quality checks | TypeScript pass, lint fail | Analyze và test fail |

Các phát hiện ưu tiên cao — P1 nghĩa là cần xử lý trước khi phát hành.

**1. P1 — USER có thể đọc blocks/comments của tài liệu chưa xuất bản nếu biết documentId.**

Vị trí: [document-blocks.controller.ts:22](backend/src/document-blocks/document-blocks.controller.ts#L22), [document-blocks.service.ts:14](backend/src/document-blocks/document-blocks.service.ts#L14), [comments.controller.ts:20](backend/src/comments/comments.controller.ts#L20), [comments.service.ts:13](backend/src/comments/comments.service.ts#L13).

DocumentsService có lọc PUBLISHED cho USER, nhưng các API con chỉ truy vấn theo documentId, không kiểm tra quyền đọc tài liệu cha. RolesGuard trên GET blocks không có danh sách role bắt buộc nên không áp dụng quy tắc PUBLISHED. API tạo comment cũng không kiểm tra tài liệu có tồn tại/được phép truy cập. Vì vậy ẩn tài liệu ở API danh sách không bảo vệ được nội dung bên trong.

Khắc phục: một policy/use case kiểm tra quyền đọc tài liệu, áp dụng cho detail, blocks và comments; kiểm tra parent comment thuộc cùng document. Thêm integration test USER truy cập DRAFT/ARCHIVED qua mọi endpoint liên quan. Phát hiện từ luồng source, chưa gọi HTTP vào database thật.

**2. P1 — Router tạo trang nhưng AppLayout bỏ qua child.**

Vị trí: [app_layout.dart:106](frontend/lib/core/widgets/app_layout.dart#L106), [app_layout.dart:158](frontend/lib/core/widgets/app_layout.dart#L158), [app_layout.dart:393](frontend/lib/core/widgets/app_layout.dart#L393), [app_router.dart:45](frontend/lib/core/routes/app_router.dart#L45).

ShellRoute truyền child vào AppLayout, nhưng cả layout desktop/mobile đều dựng IndexedStack riêng, không sử dụng widget.child. Vì vậy các route tạo/sửa tài liệu không hiển thị form do router tạo; deep link không quyết định trang đang hiển thị. Menu mobile gọi context.go nhưng không đổi activeIndex nên có thể vẫn ở Home.

Đã xác nhận bằng widget test tạm: truyền một Text đánh dấu làm child, widget đó không xuất hiện. Khắc phục bằng một nguồn trạng thái điều hướng: render child của router hoặc dùng shell hỗ trợ nhiều nhánh, đồng bộ tab với route. Không chỉ thêm provider để che triệu chứng.

**3. P1 — Web Resources đọc và ghi hai loại dữ liệu khác nhau.**

Vị trí: [web_resources_bloc.dart:49](frontend/lib/features/web_resources/presentation/bloc/web_resources_bloc.dart#L49), [web_resources_page.dart:97](frontend/lib/features/web_resources/presentation/views/web_resources_page.dart#L97), [web_resources_page.dart:224](frontend/lib/features/web_resources/presentation/views/web_resources_page.dart#L224).

BLoC đọc GET /documents?type=WEB_RESOURCE nhưng UI tạo/xóa /web-resources. Backend lưu Document và WebResource ở hai bảng riêng. Tạo thành công rồi reload sẽ không lấy bản ghi vừa tạo; xóa dùng ID document cho bảng web_resources; Document cũng không có trường url mà UI cần.

Khắc phục: thống nhất model, endpoint và repository của WebResource; thêm test create → reload → delete.

**4. P1 — Body không được validate thực sự và cho phép cập nhật trường nội bộ.**

Vị trí: [documents.controller.ts:51](backend/src/documents/documents.controller.ts#L51), [documents.controller.ts:57](backend/src/documents/documents.controller.ts#L57), [documents.service.ts:74](backend/src/documents/documents.service.ts#L74). Mẫu tương tự có ở vocabularies, sentence-patterns, web-resources, tags và document-blocks.

Partial<any>/object type không cung cấp DTO class để ValidationPipe thực hiện kiểm tra từng trường. Đã chạy pipe thật với metadata của DocumentsController.update: metatype là Object, body chứa title dạng số cùng id/createdBy tùy ý vẫn được giữ nguyên. Object.assign sau đó đưa các trường này vào ORM entity. Đây là lỗi bảo toàn dữ liệu ở endpoint ADMIN, không phải bằng chứng USER vượt role để gọi endpoint ADMIN.

Khắc phục: Create/Update DTO class có decorator, chỉ map trường được phép sửa; không nhận id, createdBy, createdAt từ update body. Validate enum, UUID, URL và cấu trúc block theo loại. [NestJS giải thích hạn chế metadata của interface/generic](https://docs.nestjs.com/application/validation).

**5. P1 — Save Note không tìm được NotesBloc trong dialog.**

Vị trí: [notes_page.dart:90](frontend/lib/features/notes/presentation/views/notes_page.dart#L90), [notes_page.dart:122](frontend/lib/features/notes/presentation/views/notes_page.dart#L122).

NotesBloc được cung cấp dưới route/layout, nhưng builder của showDialog dùng context của dialog trên Navigator. context.read<NotesBloc>() trong nút Save không thấy provider đó. Widget test tạm đã xác nhận exception chứa Provider<NotesBloc> sau khi nhập title và bấm Save.

Khắc phục: lấy bloc từ context trang trước showDialog rồi truyền vào callback, hoặc dùng BlocProvider.value cho dialog. Dispose các TextEditingController của dialog khi đóng.

**6. P1 có điều kiện — JWT verifier dùng khóa mặc định khi thiếu cấu hình.**

Vị trí: [jwt.strategy.ts:12](backend/src/auth/strategies/jwt.strategy.ts#L12), [auth.module.ts:20](backend/src/auth/auth.module.ts#L20).

Khi JWT_SECRET không được cấu hình, verifier dùng literal default-secret đã biết. Signer lại không dùng cùng fallback. Cấu hình thiếu có thể vừa làm login lỗi vừa khiến verifier chấp nhận token được ký bằng khóa mặc định. Chưa kiểm tra giá trị secret của môi trường đang chạy; không khẳng định hệ thống hiện tại đang dùng fallback.

Khắc phục: validate cấu hình khi khởi động, bắt buộc secret hợp lệ, dùng chung cấu hình signer/verifier và fail startup khi thiếu.

Các phát hiện P2 — cần xử lý để duy trì chất lượng và vận hành ổn định.

**7. P2 — Backend chưa có ranh giới domain/application/infrastructure.**

Vị trí: [documents.service.ts:1](backend/src/documents/documents.service.ts#L1), [document.entity.ts:1](backend/src/documents/entities/document.entity.ts#L1), [auth.service.ts:1](backend/src/auth/auth.service.ts#L1).

Service kết hợp policy PUBLISHED, xử lý nghiệp vụ, query SQL qua ORM và định dạng response. Entities hiện là persistence entities với decorator TypeORM. Các service khác còn ném HttpException trực tiếp. Đây là cấu trúc NestJS CRUD phổ biến, nhưng chưa đáp ứng mục tiêu nghiệp vụ độc lập framework/database của Clean Architecture.

Khắc phục từng feature: port repository thuộc domain/application; use case chứa policy; adapter TypeORM triển khai port; controller chuyển DTO/request và map lỗi sang HTTP. Giữ Nest module làm nơi lắp ghép dependency. Không cần refactor toàn bộ cùng lúc.

**8. P2 — Frontend thiếu data/domain boundary, DI và model có kiểu rõ ràng.**

Vị trí: [weekly_documents_bloc.dart:49](frontend/lib/features/documents/presentation/bloc/weekly_documents_bloc.dart#L49), [document_detail_bloc.dart:49](frontend/lib/features/documents/presentation/bloc/document_detail_bloc.dart#L49), [document_form_page.dart:16](frontend/lib/features/admin/documents/presentation/views/document_form_page.dart#L16), [notes_bloc.dart:57](frontend/lib/features/notes/presentation/bloc/notes_bloc.dart#L57).

BLoC tự new ApiClient/LocalNoteStorage; nhiều widget tự gọi HTTP; state chứa Map<String,dynamic> và parse JSON ở presentation. Đổi contract server buộc sửa màn hình/BLoC; mock dependency cho test cũng khó hơn. AuthBloc cho phép truyền dependency là một bước tốt nhưng chưa được áp dụng nhất quán.

Khắc phục: model/DTO và mapper trong data; repository interface; inject repository/use case vào BLoC; widget chỉ phát event và render state. LocalNote có thể trở thành domain model, tách serialization/storage ra ngoài. Chỉ thêm use case khi cần điều phối hoặc chứa nghiệp vụ.

**9. P2 — Reorder không giới hạn theo document và không atomic.**

Vị trí: [document-blocks.service.ts:42](backend/src/document-blocks/document-blocks.service.ts#L42).

documentId chỉ được dùng để đọc kết quả; update thực hiện theo từng block ID mà không kiểm tra block thuộc document. Probe với repository giả xác nhận request document-A vẫn tạo lệnh update block của document-B. Nếu một update giữa chừng lỗi, các update trước vẫn có thể đã lưu.

Khắc phục: validate tập ID, ràng buộc documentId, cập nhật trong transaction. Cần kiểm thử tích hợp tính rollback. Đây là vấn đề dữ liệu ở thao tác ADMIN, không phải vượt quyền ADMIN.

**10. P2 — Cấu hình database chưa phù hợp triển khai có dữ liệu cần bảo toàn.**

Vị trí: [app.module.ts:56](backend/src/app.module.ts#L56).

synchronize: true được bật vô điều kiện; không thấy migration trong source được kiểm tra. Startup có thể tự thay đổi schema theo entity mà không có migration được review. Khắc phục: chỉ cho phép synchronize ở môi trường phát triển phù hợp, dùng migration cho môi trường triển khai và kiểm tra cấu hình khi boot.

**11. P2 — Pagination DTO có nhưng không được dùng.**

Vị trí: [pagination-query.dto.ts:9](backend/src/common/dto/pagination-query.dto.ts#L9), [documents.controller.ts:26](backend/src/documents/documents.controller.ts#L26), [documents.service.ts:23](backend/src/documents/documents.service.ts#L23).

Controllers nhận query từng trường, bỏ qua ràng buộc Min/Max/IsInt của DTO hiện có. Transform kiểu số không đồng nghĩa validation. pageSize quá lớn hoặc page âm không bị chặn đúng tại ranh giới request. Khắc phục: Query DTO được dùng thật, giới hạn pageSize và kiểm tra enum/UUID trước khi vào service.

**12. P2 — Xử lý lỗi chưa nhất quán và có thể lộ chi tiết nội bộ.**

Vị trí: [documents.service.ts:58](backend/src/documents/documents.service.ts#L58), [all-exceptions.filter.ts:31](backend/src/common/exceptions/all-exceptions.filter.ts#L31), [web_resources_page.dart:229](frontend/lib/features/web_resources/presentation/views/web_resources_page.dart#L229).

Nhiều thao tác không tìm thấy bản ghi trả null và vẫn đi qua response success thay vì 404; frontend lại ép kiểu Map. Filter trả exception.message cho mọi Error nên lỗi ORM có thể đưa thông tin schema/constraint ra response, đồng thời chưa có logging nội bộ tại filter. Một số UI nuốt exception bằng catch (_) {} khiến người dùng không biết thao tác thất bại.

Khắc phục: lỗi nghiệp vụ có kiểu rõ ràng, mapping HTTP thống nhất, log lỗi server với request ID, trả thông báo 500 ổn định; frontend phân biệt loading/empty/error và hiển thị lỗi mutation.

**13. P2 — Auth/session và môi trường frontend chưa tập trung.**

Vị trí: [api_client.dart:10](frontend/lib/core/network/api_client.dart#L10), [api_client.dart:33](frontend/lib/core/network/api_client.dart#L33), [token_storage.dart:26](frontend/lib/core/storage/token_storage.dart#L26), [app_layout.dart:171](frontend/lib/core/widgets/app_layout.dart#L171), [jwt.strategy.ts:16](backend/src/auth/strategies/jwt.strategy.ts#L16).

ApiClient hardcode localhost, không sử dụng ApiConstants và không inject cấu hình theo môi trường. 401 chỉ xóa SharedPreferences, không thông báo AuthBloc/router. Logout trong layout cũng trực tiếp xóa storage thay vì đi qua AuthBloc. Backend validate JWT chỉ đọc payload, không kiểm tra user hiện còn active/role hiện tại; vô hiệu key chỉ ngăn login tiếp theo, không thu hồi token đã cấp, mặc định token có hạn 7 ngày.

Khắc phục: inject base URL và TokenStorage; một nguồn session state phát sự kiện hết phiên để UI/router cập nhật. Xác định rõ chính sách thu hồi token khi khóa user/key hoặc đổi role, rồi triển khai kiểm tra trạng thái/session version nếu cần vô hiệu ngay. Không coi JWT stateless tự thân là sai; điểm cần giải quyết là hành vi vô hiệu tài khoản và thời hạn có chủ đích.

**14. P2 — Local notes không được tách theo tài khoản trên cùng thiết bị.**

Vị trí: [local_note_storage.dart:44](frontend/lib/core/storage/local_note_storage.dart#L44), [token_storage.dart:31](frontend/lib/core/storage/token_storage.dart#L31).

Mọi tài khoản dùng chung local_notes; logout không đổi namespace hoặc xóa notes. Khi user A đăng xuất và user B/admin đăng nhập cùng browser/app storage, notes của A vẫn nằm trong danh sách của B. Business spec nói đây là note cá nhân và admin không đọc được. Việc không gửi server là đúng, nhưng chưa bảo đảm cách ly tài khoản tại UI/storage.

Khắc phục: namespace theo userId, chỉ tải kho của phiên hiện tại; quyết định chính sách giữ/xóa dữ liệu khi logout. Namespace tránh đọc nhầm giữa tài khoản, không phải cơ chế chống người có quyền truy cập trực tiếp thiết bị.

**15. P2 — Login quét toàn bộ access key và trả ORM entity chứa hash ở API quản trị.**

Vị trí: [access-keys.service.ts:15](backend/src/access-keys/access-keys.service.ts#L15), [access-keys.service.ts:84](backend/src/access-keys/access-keys.service.ts#L84), [access-key.entity.ts:18](backend/src/access-keys/entities/access-key.entity.ts#L18).

Mỗi login lấy toàn bộ keys/user rồi chạy bcrypt.compare tuần tự; request sai key phải thử hết N key, nên chi phí tăng theo số key. Không thấy rate limit trong source auth được kiểm tra. findAll/create/updateStatus trả AccessKey trực tiếp, bao gồm keyHash, dù màn hình quản trị không cần giá trị này.

Khắc phục: key có phần định danh public/index để tìm một bản ghi rồi verify phần secret; hạn chế tần suất login; trả response DTO chỉ có metadata cần thiết. Không thay bcrypt bằng hash nhanh cho secret ít entropy chỉ để tăng tốc.

**16. P2 — Form edit và test suite chưa bảo vệ luồng nghiệp vụ.**

Vị trí: [document_form_page.dart:34](frontend/lib/features/admin/documents/presentation/views/document_form_page.dart#L34), [vocabulary_form_page.dart:32](frontend/lib/features/admin/vocabularies/presentation/views/vocabulary_form_page.dart#L32), [widget_test.dart:14](frontend/test/widget_test.dart#L14), [app.controller.spec.ts:17](backend/src/app.controller.spec.ts#L17).

Form load gán type/status/level sau await nhưng không setState để cập nhật dropdown; study date/week cũng không được bind giá trị tải về vào TextField. Một số lỗi load bị bỏ qua. Lỗi route ở mục 2 hiện còn che các lỗi này. Các controller nhập liệu trong form không được dispose.

Backend chỉ có unit test Hello World và e2e mẫu cho route gốc; frontend vẫn kiểm tra counter của app Flutter mặc định. Chưa có test nghiệp vụ cho quyền đọc, DTO, mutation, route hoặc session. Khắc phục: test đúng hành vi thực tế, ưu tiên các lỗi đã phát hiện trước khi đặt mục tiêu coverage phần trăm.

Kết quả kiểm tra thực thi

| Kiểm tra | Kết quả |
|---|---|
| Backend `tsc --noEmit --incremental false -p tsconfig.build.json` | Pass; đây là kiểm tra kiểu, không phải chạy Nest build/server |
| Backend Jest `--runInBand` | 1 suite, 1 test pass; chỉ Hello World |
| Backend ESLint src/test, không `--fix` | 62 errors, 2 warnings; 39 lỗi prettier, 23 lỗi còn lại thuộc các rule khác |
| Flutter 3.41.8 `analyze --no-pub` | 16 issues: 3 warnings và 13 infos; gồm async BuildContext và deprecated API |
| Flutter `test --no-pub` hiện có | Fail: counter test không tìm thấy text `0` |
| Probe ValidationPipe với metadata thật | Xác nhận body sai kiểu và trường nội bộ được giữ nguyên |
| Probe reorder với repository giả | Xác nhận update không ràng buộc documentId |
| 2 widget test tạm | Cả hai pass theo kỳ vọng tái hiện lỗi: mất router child và thiếu provider trong Save Note |
| Backend e2e/PostgreSQL/build web/mobile | Chưa chạy; e2e hiện import AppModule dùng cấu hình DB và synchronize |

Test tạm pass ở đây nghĩa là đã chứng minh lỗi đang tồn tại, không phải tính năng đã đúng. Không gọi `npm run lint` vì script đó có `--fix`; review không tự sửa source.

Thứ tự cải thiện đề xuất

1. Sửa P1: quyền đọc API con, router/layout, WebResource contract, DTO và Save Note; bắt buộc cấu hình JWT.
2. Bổ sung test hồi quy cho các luồng này; đưa lint/analyze và test về trạng thái pass. Sau đó thêm integration test trên database riêng cho quyền truy cập và transaction.
3. Refactor một feature mẫu, phù hợp nhất là WebResource hoặc Documents: backend controller → use case → repository port, adapter TypeORM triển khai port; frontend widget → BLoC → repository/use case, data layer xử lý Dio và JSON. Dùng DI để lắp ghép.
4. Nhân rộng có chọn lọc; chuẩn hóa error/session/configuration, migration, pagination, bảo toàn dữ liệu và cách ly notes theo tài khoản.

Điểm tốt nên giữ: module theo tính năng, controller phần lớn ngắn, Nest DI, JWT/role guards tại nhiều endpoint, bcrypt cho access key, query tìm kiếm dùng parameter, BLoC/Equatable ở một số màn hình, các thành phần theme/storage/network đã được gom lại. Đây là nền tảng để cải thiện, nhưng chưa đủ để kết luận đã đạt Clean Architecture hoặc sẵn sàng phát hành.
