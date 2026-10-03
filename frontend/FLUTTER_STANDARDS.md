# Flutter Coding Standards — [Tên team/dự án]

> **Lưu ý:** đây là form dùng chung (template) — dòng tiêu đề để `[Tên team/dự án]` trống có chủ đích, mỗi team/dự án tự điền tên riêng khi áp dụng.
>
> Trạng thái: **CONFIRMED v2.1** — toàn bộ mục 1–20 đã được leader chốt chính thức.
> Phạm vi: áp dụng cho **code mới**. Code cũ không bắt buộc refactor ngay, nhưng khi sửa lớn nên đưa dần về chuẩn này (xem lộ trình mục 5, 6).
> **Ngoài phạm vi tài liệu này** (sẽ viết thành tài liệu riêng): localization (i18n), theming/dark mode, CI/CD pipeline.

---

## 1. Quyết định đã chốt

| Hạng mục | Chuẩn chính thức |
|---|---|
| Kiến trúc | Clean Architecture (data / domain / presentation) cho mọi feature mới |
| State management | GetX (Controller + Binding) |
| Quy mô team | >15 dev → chuẩn phải rõ ràng + có enforcement tự động (lint, CI, PR checklist), không dựa vào review thủ công |
| Lint | `very_good_analysis` |

---

## 2. Cấu trúc thư mục

```
lib/
├── core/
│   ├── constants/          # app constants, env keys
│   ├── errors/              # Failure, AppException
│   ├── network/             # Dio client, interceptors
│   ├── theme/                # colors, text styles, theme data
│   ├── utils/                # extensions, formatters, validators
│   └── widgets/              # widget dùng chung toàn app
├── routes/
│   ├── app_pages.dart        # GetPage list
│   └── app_routes.dart       # route name constants
├── features/
│   └── <feature_name>/
│       ├── data/
│       │   ├── models/            # DTO, fromJson/toJson
│       │   ├── datasources/       # remote_datasource.dart, local_datasource.dart
│       │   └── repositories/      # XxxRepositoryImpl implements domain repository
│       ├── domain/
│       │   ├── entities/          # pure Dart object, không phụ thuộc package ngoài
│       │   ├── repositories/      # abstract interface
│       │   └── usecases/          # 1 class = 1 hành động nghiệp vụ
│       └── presentation/
│           ├── controllers/       # GetxController — chỉ chứa state + gọi usecase
│           ├── bindings/          # GetxBinding — khai báo DI cho route
│           ├── pages/             # 1 file = 1 màn hình (Scaffold)
│           └── widgets/           # widget riêng của feature, không share ra ngoài
├── app.dart
└── main.dart
```

**TODO: Vẽ thêm cây thư mục với trường hợp đặc biệt**

**Quy tắc layer:**
- `presentation` chỉ được gọi `domain` (không gọi thẳng `data`).
- `domain` không import bất kỳ package Flutter/GetX/Dio nào — giữ pure Dart để dễ unit test.
- `data` implement interface được định nghĩa ở `domain/repositories`.

**Quy tắc UseCase (`domain/usecases/`):** mỗi UseCase chỉ có **đúng 1 public method thực thi duy nhất**, đặt tên **`call()` hoặc `execute()`** (chọn 1 trong 2, dùng nhất quán trong toàn project — không lẫn cả 2 tên trong cùng codebase). Cần hành động khác — dù nhỏ hay liên quan tới đâu — phải tạo UseCase mới, không thêm public method thứ 2. `call()` tận dụng được cú pháp gọi như hàm của Dart (`await GetOrderDetailUseCase(params)`); `execute()` rõ nghĩa hơn với người chưa quen quy ước `call()` của Dart nhưng phải gọi qua `.execute(params)`. UseCase chỉ phụ thuộc `Repository` interface qua constructor, không giữ state giữa các lần gọi, không throw exception ra ngoài (luôn trả `Result<T>`, xem mục 6).

---

=> Chốt execute()

## 3. State management — GetX

- **Controller**: 1 controller / 1 page (hoặc 1 nhóm màn hình liên quan chặt). Không nhét logic gọi API trực tiếp trong controller — controller gọi `UseCase`, `UseCase` gọi `Repository`.
- **Binding**: mỗi route có 1 `Binding` riêng, dùng `Get.lazyPut()` (không dùng `Get.put()` trực tiếp trong widget) để tránh giữ instance không cần thiết.
- **DI**: dùng cơ chế built-in của GetX (`Get.put` / `Get.lazyPut` / `Get.find`) qua Binding — không mix thêm `get_it` để tránh 2 nguồn DI song song.
- Đặt tên: `XxxController`, `XxxBinding`.
- Cấm dùng `Get.find()` trực tiếp trong widget tree (`build()`). Chỉ được gọi trong `Controller`, hoặc đúng 1 lần khi khởi tạo widget qua `GetView<XxxController>`/`GetBuilder<XxxController>` — không rải `Get.find()` trong các widget con lồng nhau. Vi phạm rule này chặn merge PR (đưa vào checklist mục 9).

---

## 4. Naming convention

| Đối tượng | Quy tắc | Ví dụ |
|---|---|---|
| File | `snake_case.dart` | `order_detail_page.dart` |
| Class / Widget | `PascalCase` | `OrderDetailPage` |
| Controller | `PascalCase` + hậu tố `Controller` | `OrderDetailController` |
| Binding | `PascalCase` + hậu tố `Binding` | `OrderDetailBinding` |
| UseCase | `PascalCase` + hậu tố `UseCase` | `GetOrderDetailUseCase` |
| Repository interface (domain) | `PascalCase` + hậu tố `Repository` | `OrderRepository` |
| Repository implementation (data) | + hậu tố `RepositoryImpl` | `OrderRepositoryImpl` |
| Biến / hàm | `camelCase` | `orderList`, `fetchOrders()` |
| Biến private | `_camelCase` | `_isLoading` |
| Hằng số | `camelCase` (theo Dart style hiện hành, **không** dùng `SCREAMING_SNAKE_CASE`) | `defaultTimeout` |
| Route name | `camelCase`, khai báo tập trung ở `app_routes.dart` | `Routes.orderDetail` |

### Đặt tên có ý nghĩa (không chỉ đúng case)

Đúng case (bảng trên) là điều kiện cần, chưa đủ — tên còn phải **diễn tả đúng vai trò/nội dung**:

- Tên hàm là **động từ + đối tượng**, mô tả đúng hành động (`fetchOrderDetail()`, `calculateDiscount()`) — không đặt tên mơ hồ (`handle()`, `process()`, `doWork()`).
- Biến/hàm boolean bắt đầu bằng `is`/`has`/`should`/`can` (`isLoading`, `hasError`, `shouldRetry`) — tránh tên phủ định gây khó đọc khi phải viết `!isNotLoading`.
- Không dùng tên viết tắt tuỳ ý (`odId`, `usr`, `tmp2`) trừ viết tắt đã chuẩn hoá toàn ngành (`id`, `url`, `http`) — ưu tiên rõ nghĩa hơn ngắn gọn.
- Không đặt tên theo số thứ tự khi nội dung khác nhau (`data1`, `data2`, `temp`, `temp2`) — 2 biến khác nội dung thì tên phải phản ánh sự khác biệt (`pendingOrders`, `completedOrders`), không chỉ đánh số.
- Tên phải khớp đúng kiểu/số lượng dữ liệu: biến chứa `List`/`Map` dùng tên số nhiều hoặc hậu tố rõ tập hợp (`orderList`, `orderById`), biến đơn lẻ dùng số ít (`order`).
- Reject khi tên không phản ánh đúng nội dung thực tế (vd biến tên `isLoading` nhưng lưu message lỗi) — đây là lỗi che giấu ý định, dễ gây bug khi người khác đọc nhầm.

---

## 5. Lint — very_good_analysis

`pubspec.yaml`:
```yaml
dev_dependencies:
  very_good_analysis: ^latest
```

`analysis_options.yaml`:
```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  errors:
    # tuỳ chỉnh nếu rule nào quá strict với codebase hiện tại
    # public_member_api_docs: ignore
```

Chuyển sang `very_good_analysis` theo lộ trình dần (không siết toàn bộ codebase ngay để tránh chặn cứng release):

| Giai đoạn | Mốc thời gian | Phạm vi enforcement |
|---|---|---|
| Giai đoạn 1 | Q3 2026 (ngay khi công bố chuẩn) | CI chỉ chặn merge nếu file/dòng **mới hoặc bị sửa** trong PR vi phạm `very_good_analysis` (diff-based lint check). Code cũ chưa sửa không bị chặn. |
| Giai đoạn 2 | Q4 2026 | Dọn warning ở `core/` và `shared widgets` trước (nền tảng dùng chung, rủi ro thấp, ảnh hưởng nhiều). |
| Giai đoạn 3 | Q1–Q2 2027 | Dọn dần theo `features/`, ưu tiên feature đang active development trước, feature ít đụng tới để sau. |
| Giai đoạn 4 | Q3 2027 | Gỡ bỏ diff-based exception, bắt buộc `very_good_analysis` pass toàn bộ codebase. |

Cách làm kỹ thuật cho Giai đoạn 1: dùng action/script diff lint (vd `dart analyze` kết hợp `git diff --name-only <base>...HEAD` để chỉ lọc warning trong file thay đổi) chạy trong CI, fail job nếu có warning nằm trên dòng bị sửa.

---

## 6. Error handling

Dùng sealed class `Result<T>` (Dart 3, không cần thêm package `dartz`):

```dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}
```

- `UseCase` luôn trả về `Future<Result<T>>`, không throw exception ra ngoài `data` layer.
- `Controller` dùng `switch` (pattern matching Dart 3) để xử lý `Success`/`Failure`, set state tương ứng (loading/error/data).
- `AppException` định nghĩa ở `core/errors/`, phân loại: `NetworkException`, `ServerException`, `CacheException`, `UnknownException`.

Lộ trình dài hạn — vì migrate error handling có rủi ro thay đổi hành vi (khác với lint chỉ là style), không đặt deadline cứng theo quý mà theo nguyên tắc "chạm là dọn":

| Giai đoạn | Áp dụng khi nào | Yêu cầu |
|---|---|---|
| Giai đoạn 1 (ngay từ bây giờ) | Mọi `UseCase`/`Controller` **mới** | Bắt buộc dùng `Result<T>`, không throw exception ra khỏi `data` layer |
| Giai đoạn 2 (liên tục, không giới hạn quý) | PR chạm vào `UseCase`/`Repository` cũ đang dùng try-catch trần hoặc throw trực tiếp | Bắt buộc chuyển đổi luôn sang `Result<T>` trong chính PR đó (boy-scout rule) trước khi merge |
| Giai đoạn 3 (mốc dài hạn, cùng Q3 2027 với lint Giai đoạn 4 ở mục 5) | Rà soát toàn bộ | Kiểm kê `domain/usecases` còn sót chưa migrate, lên kế hoạch dọn dứt điểm phần còn lại |

---

## 7. Networking

Dùng `Dio` làm HTTP client chuẩn:
- 1 `DioClient` singleton ở `core/network/`, cấu hình base URL, timeout, interceptor (log, auth token, refresh token).
- Mỗi feature có 1 `XxxRemoteDataSource` nhận `Dio` qua constructor injection (không tạo `Dio()` mới rải rác).

```dart
// core/network/dio_client.dart
class DioClient {
  DioClient(this._dio) {
    _dio.options
      ..baseUrl = ApiConstants.baseUrl
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 15);
    _dio.interceptors.addAll([AuthInterceptor(), LoggingInterceptor()]);
  }

  final Dio _dio;
  Dio get instance => _dio;
}
```

Model tầng `data` dùng `json_serializable` (không viết `fromJson`/`toJson` tay):

```yaml
dependencies:
  json_annotation: ^latest
dev_dependencies:
  json_serializable: ^latest
  build_runner: ^latest
```

Cấm dùng `dynamic` cho field trong model — mọi field phải khai báo kiểu cụ thể (kể cả field lồng nhau, list, map). Nếu API trả về cấu trúc không ổn định, tạo `sealed class`/union type riêng để biểu diễn các trường hợp, không dùng `dynamic`/`Map<String, dynamic>` làm kiểu field.

```dart
// SAI — cấm
@JsonSerializable()
class OrderModel {
  final dynamic metadata; // ❌ dynamic field
}

// ĐÚNG
@JsonSerializable()
class OrderModel {
  final int id;
  final String status;
  final OrderMetadataModel metadata; // kiểu cụ thể, có model riêng
}
```

Vote sau: cần team nghiên cứu.

Enforcement: bật `strict-raw-types` và `strict-inference` trong `analysis_options.yaml` (đã có sẵn trong `very_good_analysis`) + thêm vào PR checklist (mục 9) — reviewer chặn merge nếu thấy `dynamic` trong model tầng `data`.

---

## 8. Testing baseline

Vì hiện gần như chưa có test, đề xuất lộ trình tăng dần thay vì ép 100% ngay (dễ gây phản ứng và làm chậm release):

| Layer | Yêu cầu cho code MỚI |
|---|---|
| `domain/usecases` | **Bắt buộc** unit test (pure Dart, dễ test nhất, ROI cao nhất) |
| `presentation/controllers` | **Bắt buộc** unit test cho logic quan trọng (xử lý success/error, không cần test UI) |
| `data/repositories` | Khuyến khích, bắt buộc nếu có logic mapping/transform phức tạp |
| Widget test | Khuyến khích cho `core/widgets` (shared), chưa bắt buộc cho page cụ thể ở giai đoạn đầu |

Coverage target: +10%/quý, tính từ baseline hiện tại (~0%):

| Mốc | Coverage tối thiểu |
|---|---|
| Q3 2026 (hiện tại) | Baseline — bắt đầu đo, chưa yêu cầu % |
| Q4 2026 | 10% |
| Q1 2027 | 20% |
| Q2 2027 | 30% |
| Q3 2027 | 40% |

Đo bằng `flutter test --coverage` + `lcov`, publish report trong CI, hiển thị badge/số liệu trong PR (vd qua Codecov hoặc script nội bộ). Coverage tính trên toàn repo, nhưng ưu tiên tăng ở `domain/usecases` và `presentation/controllers` trước vì đây là nơi bắt buộc test theo bảng trên.

UI/E2E test với Maestro:
- Tester viết test case (mô tả bước nghiệp vụ) → dùng AI để sinh Maestro flow (`.yaml`) dựa trên test case đó.
- Maestro flow lưu tại `maestro/<feature>/<flow_name>.yaml`.
- Điều kiện tiên quyết: mọi widget có thể tương tác (button, input, list item, tab...) trong các luồng chính phải có `Key` ổn định, đặt tên theo convention `Key('<feature>_<widget>_<action>')` — ví dụ `Key('login_email_field')`, `Key('checkout_submit_button')`. Maestro định vị phần tử qua Key này, không dựa vào text/vị trí (dễ vỡ khi đổi UI/copy).

Lộ trình gắn Key (làm dần, không bắt buộc phủ toàn bộ app ngay):

| Giai đoạn | Phạm vi | Yêu cầu |
|---|---|---|
| Giai đoạn 1 (ngay từ bây giờ) | Widget mới thuộc luồng chính (login, checkout, thanh toán, luồng core khác của dự án) | Bắt buộc gắn Key theo convention |
| Giai đoạn 2 (liên tục) | PR chạm vào màn hình cũ ngoài luồng chính | Khuyến khích gắn Key, không bắt buộc |
| Giai đoạn 3 (dài hạn) | Rà soát toàn bộ | Đủ Key để Maestro cover hết các luồng chính, không còn luồng quan trọng thiếu Key |

**Tên `Key` dùng chung gốc định danh với event monitoring (mục 10):** cùng 1 chuỗi `<feature>_<widget>_<action>` được dùng làm (1) giá trị `Key(...)` cho Maestro, (2) tên event monitoring/analytics, (3) message breadcrumb Sentry — để dev/tester/người xem dashboard monitoring tham chiếu đúng cùng 1 điểm khi debug, không phải suy đoán Key nào khớp với event nào.

---

## 9. Git commit & branch convention

- Branch: `feature/<mô-tả-ngắn>`, `fix/<mô-tả-ngắn>`, `hotfix/<mô-tả-ngắn>`, `chore/<mô-tả-ngắn>` — kebab-case, có thể kèm ticket id: `feature/PROJ-123-order-detail`.
- Commit message theo Conventional Commits: `<type>(<scope>): <mô tả>`, `type` ∈ {`feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `style`, `perf`}.
  ```
  feat(order): add order detail screen
  fix(auth): handle expired token on refresh
  ```
- Agent AI khi tạo commit/PR phải tuân theo format này (áp dụng cho cả commit do agent tự sinh).

---

## 10. Logging, crash reporting & theo dõi luồng người dùng (flow monitoring)

- Dùng package `logger` (đã dùng sẵn trong dự án) thay cho `print()`. Level: `debug` / `info` / `warning` / `error`.
- Release build: gửi `warning`/`error` lên **Sentry**, không log `debug`/`info` ra console production.
- Cấm log dữ liệu nhạy cảm (token, password, PII) — trùng với PR checklist mục 17.
- Bắt buộc có **log flow** cho các luồng chức năng chính của dự án (vd: đăng nhập, đặt hàng, thanh toán...) — log tại các điểm mốc quan trọng (bắt đầu luồng, mỗi bước xử lý chính, kết quả thành công/thất bại), kèm mã định danh luồng (`flowId`/`requestId`) để dễ trace trên Sentry khi debug production. Danh sách "luồng chính" do lead từng dự án xác định cụ thể.

### 10.1 Theo dõi luồng người dùng (monitor luồng, không chỉ crash)

Mục tiêu: với mỗi luồng chính, phải thấy được **hành trình người dùng đi tới đâu, drop ở bước nào** trên dashboard monitoring — không chỉ biết app crash ở đâu.

**Qua 1 service tập trung, không gọi trực tiếp SDK monitoring rải rác:**

```dart
// core/services/analytics_service.dart
class AnalyticsService {
  void logFlowStart(String flowName, {String? flowId}) { /* Firebase Analytics / Sentry breadcrumb */ }
  void logFlowStep(String flowName, String step, {String? flowId}) { /* ... */ }
  void logFlowSuccess(String flowName, {String? flowId}) { /* ... */ }
  void logFlowFailure(String flowName, String reason, {String? flowId}) { /* ... */ }
  void logScreenView(String routeName) { /* Sentry breadcrumb category: navigation */ }
}
```

Đăng ký/lấy qua `registerSingleton`/`getSingleton` như mọi singleton service khác (mục 21.1) — không gọi `FirebaseAnalytics.instance.logEvent(...)`/`Sentry.addBreadcrumb(...)` trực tiếp trong Controller/Page. Lý do: đổi/thêm provider monitoring (Firebase Analytics, Crashlytics, Sentry) sau này chỉ sửa 1 file, không phải sửa mọi call site; đồng thời cho phép mock `AnalyticsService` khi viết unit test cho Controller mà không cần khởi tạo SDK thật.

**Tên event/flow tập trung khai báo, không hardcode string rải rác** (cùng nguyên tắc với `AppColors` ở mục 17):

```dart
// core/analytics/analytics_events.dart
class AnalyticsEvents {
  const AnalyticsEvents._();
  static const String checkoutStart = 'checkout_start';
  static const String checkoutSubmitButtonTap = 'checkout_submit_button_tap';
  static const String checkoutSuccess = 'checkout_success';
  static const String checkoutFailure = 'checkout_failure';
}
```

**Mỗi luồng chính bắt buộc bắn tối thiểu 4 mốc**, dùng cùng `flowId` với log ở logger/Sentry (đoạn trên) để trace chéo giữa Analytics và Sentry khi debug production:
1. Bắt đầu luồng (`logFlowStart`).
2. Mỗi bước quan trọng (`logFlowStep`) — vd chọn phương thức thanh toán, xác nhận địa chỉ.
3. Thành công (`logFlowSuccess`).
4. Thất bại kèm lý do (`logFlowFailure`) — lý do lấy từ `AppException`/`Result.Failure`, không log message lỗi thô chưa phân loại.

**Không bắn event/breadcrumb trong Widget/`build()`** — side-effect trong `build()` là anti-pattern (cùng lý do cấm `Get.find()` trong `build()`, mục 3). Chỉ gọi từ Controller (khi xử lý hành động người dùng) hoặc từ route observer/Binding (khi chuyển màn hình).

**Không quét được đầy đủ bằng script** (khác biệt hành vi nghiệp vụ, mốc nào là "luồng chính") — nhưng lời gọi SDK monitoring trực tiếp ngoài `analytics_service.dart` quét được, xem R16 ở `check_flutter_standards.sh`/`.ps1`.

### 10.2 Cấu hình & vệ sinh dữ liệu Sentry

Rule ở mục 10.1 quy định **cách gọi** Sentry (qua `AnalyticsService`). Mục này quy định **cách cấu hình** SDK Sentry — thiếu phần này thì dù gọi đúng chỗ, dữ liệu trên dashboard vẫn vô dụng hoặc rò rỉ PII:

- **Không hardcode DSN trong source code** — truyền qua `--dart-define=SENTRY_DSN=...` khác nhau theo build flavor (dev/staging/prod), cùng nguyên tắc với API key ở mục 14.
- **Tag `environment`** (`dev`/`staging`/`production`) khi `Sentry.init` — không để lỗi từ build test/QA lẫn vào dashboard production, tránh làm sai số liệu defect/debt ở `DEBT_CRITERIA.md`.
- **Bắt buộc set `release`/`dist` khớp version + build number của app** (`options.release = 'app@$version+$buildNumber'`) — đây là điều kiện để luồng xác nhận defect/debt ở `DEBT_CRITERIA.md` mục 6.4 hoạt động được ("xác nhận không còn lỗi mới cùng signature sau khi release" — không tag release thì không biết lỗi thuộc bản nào).
- **Upload debug symbols mỗi lần release** (Android: mapping file R8/ProGuard; iOS: dSYM) qua CI/CD (`sentry-cli`/plugin Sentry cho Flutter) — thiếu bước này, stacktrace trên Sentry ở release build (đã obfuscate theo mục 14) không đọc được, làm luồng defect/debt vô dụng trên thực tế.
- **`beforeSend`/`beforeBreadcrumb` phải scrub dữ liệu nhạy cảm** (token, password, số điện thoại, email, PII khác) trước khi gửi lên Sentry — Sentry tự động đính kèm context (request, extra, breadcrumb) nên chỉ tự giác "không log PII" ở code (mục 10, 14) chưa đủ, phải chặn thêm ở tầng cấu hình SDK làm lớp bảo vệ thứ 2.
- **User context gắn ID ẩn danh, không gắn PII** — `scope.setUser(SentryUser(id: hashedUserId))`, không set `email`/`username` thật lên scope.
- **`tracesSampleRate` giữ mức thấp ở production** (vd 0.1–0.2) để kiểm soát chi phí/quota — riêng lỗi (`error`) luôn capture 100%, không sample lỗi.
- **Breadcrumb category theo convention cố định**: `navigation` (chuyển màn hình), `user-action` (tap button/submit), `http` (gọi API), `flow` (mốc luồng nghiệp vụ ở mục 10.1) — không tự đặt category tuỳ ý, để dễ filter trên dashboard.
- Toàn bộ cấu hình trên khai báo tập trung ở 1 file khởi tạo (vd `core/monitoring/sentry_config.dart`, gọi từ `main.dart`), không rải `Sentry.init`/cấu hình ở nhiều nơi.

**Không quét được bằng script** — cần review thủ công qua `flutter-reviewer`: DSN hardcode, thiếu tag `environment`/`release`, thiếu scrub PII trong `beforeSend`, thiếu upload symbols trong CI/CD, sample rate không hợp lý.

---

## 11. Chính sách thêm package/dependency mới

Trước khi thêm package mới vào `pubspec.yaml`, kiểm tra:
1. Pub Points / Popularity / Likes trên pub.dev.
2. Maintenance: có cập nhật trong ~6 tháng gần nhất, hỗ trợ Dart 3/null-safety.
3. License tương thích (MIT/BSD/Apache — tránh GPL/copyleft).
4. Được **lead dự án** duyệt riêng trong PR nếu là package **mới** (không áp dụng cho version bump thông thường).

Agent AI không được tự ý thêm package mới; nếu đề xuất, phải nêu rõ tên package + lý do chọn trong output để người review quyết định.

---

## 12. Kỷ luật null-safety

- Hạn chế tối đa bang operator `!`. Ưu tiên `?.`, `??`, hoặc kiểm tra `if (x != null)` tường minh.
- `late` chỉ dùng khi chắc chắn được khởi tạo trước khi truy cập (vd trong `onInit()`/`initState()`); nếu không chắc, chuyển field thành nullable thay vì ép `late`.
- `very_good_analysis` chưa có rule cấm `!` tuyệt đối → kiểm tra qua PR review, đưa vào checklist mục 17.

---

## 13. Performance & widget best practices

- Dùng `const` constructor bất cứ khi nào có thể (`const Text(...)`, `const SizedBox(...)`).
- Danh sách nhiều item: dùng `ListView.builder`/`GridView.builder`, không dùng `ListView(children: [...])` cho danh sách dài/không giới hạn.
- Cung cấp `key` cho item trong list có thể đổi thứ tự/bị xoá.
- Dùng `Obx`/`GetBuilder(id: ...)` đúng phạm vi biến cần lắng nghe, tránh rebuild toàn bộ màn hình khi chỉ 1 phần state đổi.

### Cách tách widget lớn thành widget con

**Nguyên tắc: tách thành class widget riêng (`extends StatelessWidget`), không tách thành method `Widget _buildXxx()`.**

Lý do: method `_buildXxx()` vẫn chạy lại mỗi lần `build()` của cha chạy — không có Element riêng nên Flutter không thể bỏ qua rebuild phần đó. Tách thành class riêng thì:
- Có thể khai báo `const` → Flutter bỏ qua rebuild hoàn toàn nếu input không đổi.
- Có Element/State riêng trong widget tree → khoanh vùng rebuild hẹp hơn khi dùng `Obx`/`GetBuilder(id:)` bọc đúng widget đó.
- Test riêng được bằng `testWidgets` mà không cần dựng cả màn hình cha.

**Khi nào tách:**
1. `build()` của widget vượt quá ~150–200 dòng.
2. Một phần UI lặp lại ở nhiều nơi (list item, card, section).
3. Một phần UI chỉ cần lắng nghe 1 phần nhỏ của Controller — tách ra để bọc riêng `Obx`/`GetBuilder(id:)`, không để cả màn hình rebuild theo.
4. Một phần UI có nhiều điều kiện hiển thị phức tạp → tách để dễ đọc và test độc lập.

**Đặt ở đâu:** widget dùng riêng trong 1 feature → `presentation/widgets/` của feature đó; dùng chung nhiều feature → `core/widgets/`. Tên `PascalCase` mô tả rõ vai trò (`OrderSummaryCard`, `CheckoutSubmitButton`), không đặt tên chung chung (`Widget1`, `PartOfScreen`).

```dart
// SAI — method trả về Widget, không hưởng lợi const/rebuild-skip,
// vẫn chạy lại mỗi lần OrderDetailPage.build() chạy
class OrderDetailPage extends GetView<OrderDetailController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [_buildHeader(), _buildOrderList()],
      ),
    );
  }

  Widget _buildHeader() => const Text('Order Detail');
  Widget _buildOrderList() => Obx(() => ListView.builder(...));
}

// ĐÚNG — tách thành widget class riêng
class OrderDetailPage extends GetView<OrderDetailController> {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          OrderDetailHeader(), // const — không rebuild lại khi cha rebuild
          OrderList(),
        ],
      ),
    );
  }
}

class OrderDetailHeader extends StatelessWidget {
  const OrderDetailHeader({super.key});

  @override
  Widget build(BuildContext context) => const Text('Order Detail');
}
```

---

## 14. Bảo mật cơ bản

- Không hardcode API key/secret trong source code — dùng `--dart-define` hoặc file config không commit (`.env` + `.gitignore`).
- Token/credential lưu bằng `flutter_secure_storage`, không dùng `SharedPreferences` cho dữ liệu nhạy cảm.
- Bật code obfuscation cho bản release: `flutter build ... --obfuscate --split-debug-info=<path>`.
- Không log token/password/PII ra console (liên kết mục 10).

---

## 15. Quy ước asset & code generation

- Đặt asset theo loại: `assets/images/`, `assets/icons/`, `assets/fonts/`.
- Tên file asset `snake_case`, mô tả rõ nội dung (`ic_order_success.svg`), không đặt tên chung chung (`image1.png`).
- Dùng package nội bộ chung **`sds_gen`** để sinh reference type-safe cho asset (không dùng `flutter_gen` hay tự viết cách generate riêng lẻ từng dự án) — đảm bảo mọi dự án Flutter trong công ty dùng chung 1 cơ chế generate, dễ bảo trì và đồng bộ khi `sds_gen` cập nhật.
- File generated bởi `sds_gen`/`build_runner`: commit vào git để tránh lỗi thiếu bước generate khi checkout/build local.

---

## 16. Dartdoc cho public API

- Bắt buộc viết doc comment `///` cho: public method trong `UseCase`, public interface trong `domain/repositories`.
- Không bắt buộc cho `Controller`/`Widget` nội bộ, trừ khi logic đủ phức tạp cần giải thích.
- Nội dung comment nêu mục đích, tham số đặc biệt, trường hợp lỗi trả về — không diễn giải lại tên hàm đã tự rõ nghĩa.

---

## 17. Màu sắc (Color)

Cấm hardcode `Color(0xFF...)`/`Colors.xxx` trực tiếp trong `Page`/`Widget`. Mọi màu phải khai báo qua **1 file const tập trung** — `Page`/`Widget` chỉ được tham chiếu, không tự định nghĩa giá trị màu riêng.

```dart
// core/theme/app_colors.dart
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF6C757D);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color neutral = Color(0xFF9E9E9E);
}
```

```dart
// SAI
Container(color: Colors.blue)
Text('Lỗi', style: TextStyle(color: Color(0xFFE53935)))

// ĐÚNG
Container(color: AppColors.primary)
Text('Lỗi', style: TextStyle(color: AppColors.error))
```

- File `AppColors` là nơi **duy nhất** được phép khai báo giá trị `Color(0x...)`/`Colors.xxx` thô.
- Không áp dụng lộ trình dần như lint (mục 5) — rule này áp dụng ngay cho code mới, không có ngoại lệ.
- Thiết kế theming/dark mode đầy đủ (biến đổi theo theme sáng/tối) nằm ngoài phạm vi tài liệu này, xem `FLUTTER_THEMING.md` (mục 20) — mục này chỉ yêu cầu tối thiểu: không hardcode rải rác, tập trung 1 nguồn.

## 18. Điều hướng giữa màn hình (Navigation)

Bắt buộc dùng **route đặt tên** (`Get.toNamed(Routes.xxx)`) để điều hướng — cấm `Navigator.push(...)` và `Get.to(() => XxxPage())` (khởi tạo widget trực tiếp).

```dart
// SAI
Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(id: id)));
Get.to(() => OrderDetailPage(id: id));

// ĐÚNG
Get.toNamed(Routes.orderDetail, arguments: id);
```

- Route phải khai báo tập trung ở `app_routes.dart` (tên route) và `app_pages.dart` (`GetPage` + `Binding`) — đúng theo cấu trúc thư mục ở mục 2.
- Lý do: khởi tạo widget trực tiếp (`Get.to(() => XxxPage())`) bỏ qua `Binding` của route đó — DI qua `Get.lazyPut()` khai báo trong `Binding` có thể không được gọi đúng lúc, gây lỗi `Get.find()` không tìm thấy Controller.
- Ngoại lệ duy nhất: dialog/bottom sheet cục bộ (`showDialog`, `showModalBottomSheet`, `Get.dialog`, `Get.bottomSheet`) không bắt buộc route đặt tên vì không phải điều hướng giữa 2 màn hình độc lập.

## 19. Definition of Done / PR checklist

- [ ] Đúng cấu trúc thư mục & layer (mục 2)
- [ ] Đặt tên đúng convention (mục 4)
- [ ] `flutter analyze` pass với `very_good_analysis` trên file/dòng thay đổi trong PR (mục 5)
- [ ] Không gọi `Get.find()` rải rác trong widget tree, chỉ trong Controller (mục 3)
- [ ] Model tầng `data` không có field kiểu `dynamic`, dùng `json_serializable` (mục 7)
- [ ] Có unit test cho UseCase + logic quan trọng trong Controller (mục 8)
- [ ] Widget quan trọng trong luồng chính có `Key` theo convention, cùng gốc định danh với event monitoring, sẵn sàng cho Maestro (mục 8)
- [ ] Error được xử lý qua `Result<T>`, không để exception rơi tự do lên UI (mục 6)
- [ ] Commit message theo Conventional Commits, branch đúng convention (mục 9)
- [ ] Không có `print()` còn sót lại, dùng `logger`, không log dữ liệu nhạy cảm (mục 10, 14)
- [ ] Luồng chức năng chính có log tại các điểm mốc quan trọng + bắn đủ 4 mốc event monitoring (start/step/success/failure) qua `AnalyticsService`, không gọi SDK monitoring trực tiếp (mục 10)
- [ ] Nếu PR đụng tới cấu hình Sentry: không hardcode DSN, có tag `environment`/`release`+`dist`, có scrub PII ở `beforeSend`/`beforeBreadcrumb`, breadcrumb đúng category convention (mục 10.2)
- [ ] Package mới (nếu có) đã nêu lý do chọn và được duyệt riêng (mục 11)
- [ ] Không lạm dụng `!`, `late` chỉ dùng khi chắc chắn khởi tạo trước (mục 12)
- [ ] Áp dụng `const`, `ListView.builder`, tách widget hợp lý khi có thể (mục 13)
- [ ] Không hardcode secret, token dùng `flutter_secure_storage` (mục 14)
- [ ] Asset đặt tên đúng convention, dùng reference generated thay vì hardcode path (mục 15)
- [ ] Public method trong `UseCase`/`domain/repositories` có dartdoc (mục 16)
- [ ] Không hardcode `Color`/`Colors.xxx` trong Page/Widget, mọi màu tham chiếu qua `AppColors` (mục 17)
- [ ] Điều hướng giữa màn hình dùng `Get.toNamed(Routes.xxx)`, không `Navigator.push`/`Get.to(() => Widget())` (mục 18)
- [ ] Singleton đăng ký/lấy qua `registerSingleton<T>()`/`getSingleton<T>()` (`core/di/service_locator.dart`), không gọi `Get.put`/`Get.find` trực tiếp, không viết singleton cổ điển; factory constructor không side-effect, có test từng nhánh; mixin có ràng buộc `on <Type>`, dùng chung >= 2 nơi, có dartdoc giải thích lý do (mục 21)
- [ ] Tên hàm/biến diễn tả đúng nội dung, không mơ hồ/đánh số (mục 4); `// TODO` có tên người + nội dung cụ thể; comment-out code có lý do giữ lại rõ ràng; không có logic trùng lặp vi phạm DRY (mục 22)
- [ ] Nếu có dùng Hive: đúng layer `data`, `TypeAdapter` generate bằng `build_runner`, `typeId` không trùng, không lưu dữ liệu nhạy cảm (mục 23)
- [ ] Mô tả PR nêu rõ: mục đích, cách test, ảnh hưởng tới màn hình/luồng nào

---

## 20. Tài liệu liên quan (viết riêng sau)

- `FLUTTER_I18N.md` — quy ước localization/i18n
- `FLUTTER_THEMING.md` — theming, dark mode, design token
- `FLUTTER_CICD.md` — CI/CD pipeline, build flavor, release process

---

## 21. Singleton, Factory, Mixin — quy định dùng pattern

Nguyên tắc chung: mọi pattern dưới đây phải phục vụ đúng vai trò kiến trúc (mục 2), không dùng để "chia file" hay "tiện tay" khi đã có cách làm đúng chuẩn khác.

### 21.1 Singleton

Chỉ dùng cho service hạ tầng cần đúng 1 instance sống suốt vòng đời app (`DioClient` — mục 7, `LoggerService`, `LocalStorageService`, `AnalyticsService`...). **Không** dùng cho bất cứ thứ gì giữ UI state — đó là việc của Controller.

**Bắt buộc triển khai qua GetX DI, cấm singleton kiểu Dart cổ điển; và bắt buộc đi qua 2 hàm wrapper riêng — không gọi trực tiếp `Get.put`/`Get.find` cho service ở bất kỳ đâu khác:**

```dart
// core/di/service_locator.dart — nơi DUY NHẤT được gọi Get.put/Get.find cho singleton service
void registerSingleton<T>(T instance) => Get.put<T>(instance, permanent: true);
T getSingleton<T>() => Get.find<T>();
```

```dart
// SAI — singleton cổ điển, không mock được khi test, global state ẩn
class LoggerService {
  LoggerService._internal();
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
}

// SAI — gọi Get.put/Get.find trực tiếp ở nơi khác ngoài service_locator.dart
Get.put<LoggerService>(LoggerService(), permanent: true); // ❌ lộ trực tiếp GetX ra ngoài
Get.find<LoggerService>().log('...'); // ❌

// ĐÚNG — đăng ký/lấy đều qua wrapper
class LoggerService {
  void log(String message) { /* ... */ }
}

// core/bindings/initial_binding.dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    registerSingleton<LoggerService>(LoggerService());
  }
}

// nơi cần dùng
getSingleton<LoggerService>().log('...');
```

Lý do bắt buộc đi qua wrapper thay vì gọi `Get.put`/`Get.find` trực tiếp:
- Tách rõ 2 khái niệm dễ nhầm: `Get.find<XxxController>()` trong `GetView`/`GetBuilder` (mục 3) là DI cho Controller theo route — khác hoàn toàn lookup 1 singleton service hạ tầng. Gọi chung `Get.find` cho cả 2 khiến review khó phân biệt "đây là Controller hay Service".
- Đổi cơ chế DI sau này (vd sang `get_it`) chỉ cần sửa 2 hàm trong `service_locator.dart`, không phải sửa mọi call site.
- Chỉ đúng 1 file được gọi `Get.put`/`Get.find` cho service → **script quét được chính xác** mọi lời gọi trực tiếp ở nơi khác (xem R15 ở `check_flutter_standards.sh`/`.ps1`).

Lý do bắt buộc qua DI (không viết singleton cổ điển): test cần thay bằng mock (`registerSingleton<LoggerService>(MockLoggerService())`) — singleton cổ điển với constructor private không inject được, luôn dùng instance thật kể cả trong unit test.

- Đặt ở `core/services/`, hậu tố `Service` (không phải `Controller`/`Repository`/`Manager`).
- Đăng ký (`registerSingleton<T>`) đúng 1 lần tại `InitialBinding` — nếu `registerSingleton<XxxService>` xuất hiện nhiều hơn 1 chỗ cho cùng type, đó là dấu hiệu vi phạm.
- Ngoại lệ hiếm: type hoàn toàn stateless, không phụ thuộc gì (bảng hằng số, pure function holder) có thể singleton thuần Dart — phải nêu lý do trong PR.

**Sau khi đăng ký — vẫn cấm gọi `getSingleton<XxxService>()` rải rác bên trong method/logic nghiệp vụ.** Chỉ resolve đúng 1 lần qua default value của constructor (constructor injection), giống cách `UseCase`/`Repository` nhận dependency khác — xem ví dụ đầy đủ ở `flutter-feature-builder.md` (mục Singleton). Cấm tuyệt đối gọi `getSingleton<XxxService>()` trực tiếp trong Widget/`build()` — cùng rule đã cấm với Controller (mục 3).

**Giới hạn số lượng service để tránh lạm dụng "biến gì cũng cho global":** thêm 1 singleton service mới phải nêu lý do trong PR (tương tự thêm package mới, mục 11); từ chối nếu service chứa dữ liệu nghiệp vụ đặc thù 1 feature, hoặc chỉ để né việc truyền tham số đúng cách qua constructor/Controller.

### 21.2 Factory constructor

3 cách dùng được chấp nhận, phân biệt rõ với cách bị cấm:

1. **Deserialize (`fromJson`)** — chỉ chấp nhận bản generate bởi `json_serializable` (mục 7), không viết tay.
2. **Factory mô tả trạng thái** kiểu `Result.success(value)`/`Result.failure(error)` (sealed class, mục 6) — cho phép, vì chỉ tạo instance rõ nghĩa hơn constructor thường, không side-effect.
3. **Factory chọn implementation theo điều kiện runtime** (vd `factory PaymentGateway.forProvider(String provider)`) — cho phép, với 2 điều kiện bắt buộc:
   - Chỉ chứa logic chọn/khởi tạo instance, **không gọi network/I/O/Repository/UseCase** bên trong — phải đồng bộ, thuần, giống mọi constructor khác.
   - Mỗi nhánh rẽ trong factory phải có unit test riêng — factory ẩn logic rẽ nhánh sau 1 lời gọi constructor, dễ sót nhánh khi review bằng mắt.

**Cấm tuyệt đối:** factory constructor gọi Repository/UseCase/HTTP hoặc bất kỳ side-effect nào — đó là việc của `UseCase`, không phải của constructor.

```dart
// SAI — factory gọi network bên trong constructor
factory PaymentGateway.forProvider(String provider) {
  final config = remoteConfigApi.fetchSync(provider); // ❌ side-effect trong factory
  return provider == 'momo' ? MomoGateway(config) : VnpayGateway(config);
}

// ĐÚNG — factory chỉ chọn/khởi tạo, config lấy từ tham số đã có sẵn
factory PaymentGateway.forProvider(String provider, PaymentConfig config) {
  return switch (provider) {
    'momo' => MomoGateway(config),
    'vnpay' => VnpayGateway(config),
    _ => throw ArgumentError('Unknown provider: $provider'),
  };
}
```

### 21.3 Mixin

Chi tiết đầy đủ + ví dụ chuyển đổi ở `flutter-feature-builder.md` (mục "Base Controller dùng chung toàn app"). Tóm tắt quy định:

- Chỉ tách `mixin` khi hành vi dùng chung từ **2 Controller/class trở lên** — 1 nơi dùng thì viết thẳng trong class đó, không tách "phòng khi sau này dùng lại".
- Luôn khai báo ràng buộc `on <Type>` rõ ràng (vd `mixin PaginationMixin on GetxController`) — không viết mixin không ràng buộc.
- Đặt tên `PascalCase` + hậu tố `Mixin`, đặt ở `core/controllers/mixins/` (ràng buộc `GetxController`) hoặc `core/mixins/` (ràng buộc khác).
- Không dùng `extension` để làm việc mixin nên làm (thêm field/state, override method) trên class team sở hữu — ranh giới đã chốt: `extension` chỉ cho type team không sở hữu.
- Nhiều mixin cùng định nghĩa 1 method trùng tên (`class X extends Y with A, B`) → bắt buộc comment giải thích thứ tự override (Dart lấy mixin sau cùng, class sau override class trước).
- **Mọi `mixin` mới khai báo bắt buộc có dartdoc `///` phía trên giải thích rõ lý do dùng mixin** — nêu cụ thể: (1) đang dùng chung cho những Controller/class nào (liệt kê tên), (2) vì sao không đủ điều kiện làm `extension` (cần field/override) hoặc đẩy xuống `UseCase` (là hành vi hạ tầng/lifecycle, không phải business logic). Thiếu giải thích → reviewer reject, coi như chưa đủ căn cứ để tách mixin (dễ tái diễn tình trạng tách "phòng khi sau này dùng lại" đã cấm ở trên).

  ```dart
  /// Dùng chung cho OrderDetailController, CheckoutController, HistoryController —
  /// cả 3 đều cần cancel token khi rời màn hình giữa lúc đang gọi API.
  /// Không dùng extension vì cần field `_cancelToken` (extension không thêm field được).
  mixin CancelTokenMixin on GetxController {
    CancelToken? _cancelToken;
    // ...
  }
  ```

**Quét được bằng script** (`check_flutter_standards.sh`/`.ps1`, R15): gọi `Get.put`/`Get.find` trực tiếp cho service ở ngoài `service_locator.dart`.
**Không quét được bằng script** — cần review thủ công qua `flutter-reviewer`: singleton viết theo kiểu cổ điển (`static final _instance`), factory chứa side-effect, mixin thiếu `on`.

---

## 22. Comment, TODO & nguyên tắc DRY

### 22.1 Quy chuẩn viết TODO

Mọi `// TODO` bắt buộc đủ 2 thành phần, không viết TODO trống nội dung:

```
// TODO(<tên người>): <nội dung cụ thể cần làm> — <ngày ghi nhận, tuỳ chọn>
```

```dart
// TODO(an.nv): xử lý case API trả về status 206 (partial content) khi backend hỗ trợ — 2026-08-04
```

- **Bắt buộc có tên người ghi nhận** — không viết TODO không rõ ai để lại, không ai chịu trách nhiệm theo dõi.
- **Nội dung phải cụ thể**, mô tả rõ việc cần làm — không viết TODO mơ hồ kiểu `// TODO: fix this`, `// TODO: refactor`.
- Nếu TODO là nợ kỹ thuật cố ý để lại, dùng đúng convention `// TODO(debt): <mô tả> — <người ghi nhận> — <ngày>` đã quy định ở `DEBT_CRITERIA.md` mục 4 — dùng chung cấu trúc `TODO(<người>): <nội dung>`, khác ở việc có gắn nhãn `debt` hay không.
- `FIXME`/`HACK` áp dụng cùng cấu trúc, dùng khi mức nghiêm trọng cao hơn TODO thông thường (biết là sai/tạm nhưng chưa sửa ngay).

### 22.2 Comment code bị vô hiệu hoá (comment-out code)

**Không xoá code bằng cách comment lại "để phòng khi cần"** — git history đã giữ lại code cũ; comment-out code không lý do chỉ làm rối file.

Nếu thực sự cần giữ lại (case hiếm — tạm disable logic vì đang chờ quyết định nghiệp vụ, đang A/B test...), **bắt buộc ghi rõ vì sao giữ lại thay vì xoá**, ngay phía trên đoạn comment:

```dart
// Tạm disable auto-apply voucher vì đang chờ BA xác nhận rule ưu tiên giữa
// voucher hệ thống và voucher người dùng nhập tay (xem ticket SDS-1234).
// Xoá đoạn comment này khi có quyết định chính thức, không để quá 1 sprint.
// applyVoucherAutomatically(order);
```

- Không có lý do đi kèm → reject, yêu cầu xoá thẳng (đã có git history).
- Nên có mốc thời gian/ticket theo dõi để dọn — tránh thành rác vĩnh viễn trong codebase.

### 22.3 Nguyên tắc DRY (Don't Repeat Yourself)

- Logic giống nhau xuất hiện từ **2 nơi trở lên** → tách thành hàm/class dùng chung theo đúng layer: logic nghiệp vụ → 1 `UseCase` dùng lại ở nhiều nơi (không phải UseCase gọi UseCase — mục "Nguyên tắc UseCase" ở `flutter-feature-builder.md`); hàm thuần không phụ thuộc state → `core/utils/`; UI lặp lại → widget class riêng (mục 13).
- Ngoại lệ: 2 đoạn code giống nhau **ngẫu nhiên** nhưng thuộc 2 khái niệm nghiệp vụ khác nhau, có thể tách rời logic sau này → không bắt buộc gộp chung ngay (gộp sai ngữ cảnh tạo phụ thuộc chéo giả tạo giữa 2 nghiệp vụ không liên quan) — nêu rõ lý do trong PR nếu bị hỏi vì sao không dùng chung.
- DRY áp dụng cho **logic**, không áp dụng cứng cho code trông giống nhau về cấu trúc nhưng phục vụ 2 mục đích độc lập — ưu tiên rõ ràng/độc lập hơn gộp chung gây coupling không cần thiết.

---

## 23. Hive — quy định sử dụng local storage

- Hive chỉ dùng ở tầng `data` (`data/datasources/local/`) — không import Hive ở `domain`/`presentation`, cùng nguyên tắc layer đã chốt ở mục 2.
- Mỗi feature cần cache local: 1 `XxxLocalDataSource` bọc quanh `Box<T>` của Hive — `Controller`/`UseCase` không gọi trực tiếp API của Hive (`Hive.box(...)`), chỉ qua `LocalDataSource`/`Repository` interface.
- Model lưu trong Hive dùng `TypeAdapter` **generate bằng `build_runner`** (`@HiveType`/`@HiveField`) — không tự viết `TypeAdapter` tay, không dùng field kiểu `dynamic` (đồng nhất với cấm `dynamic` ở mục 7).
- `typeId` của mỗi `@HiveType` đăng ký tập trung 1 nơi (vd `core/storage/hive_type_ids.dart`) để tránh trùng `typeId` giữa các model — trùng `typeId` gây lỗi runtime khó phát hiện qua review thường.
- **Không dùng Hive để lưu dữ liệu nhạy cảm** (token, password, PII) — Hive không mã hoá theo mặc định; dữ liệu nhạy cảm dùng `flutter_secure_storage` theo mục 14.
- Mở `Box` (`Hive.openBox`) quản lý tập trung tại `InitialBinding`/`main()`, không mở rải rác nhiều lần ở nhiều Controller cho cùng 1 box name.
- Đổi cấu trúc model có Hive (thêm/sửa/xoá field) → phải có chiến lược migration/fallback rõ ràng khi đọc dữ liệu cũ không khớp field mới — không giả định box cũ luôn đọc được với model mới.
