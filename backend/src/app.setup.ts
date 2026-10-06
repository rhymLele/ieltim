import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as express from 'express';
import {
  ANNOTATION_BODY_LIMIT,
  ANNOTATION_DOC_PATH,
} from './annotations/annotations.constants';
import { AllExceptionsFilter } from './common/exceptions/all-exceptions.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import {
  ADMIN_DOC_BODY_LIMIT,
  ADMIN_DOC_PATH,
} from './weekly-docs/weekly-docs.constants';

/**
 * Cấu hình dùng chung cho main.ts và test e2e. App phải được tạo với `{ bodyParser: false }`.
 * Body mặc định giữ giới hạn 100 KB của Express; riêng API admin tài liệu theo tuần nhận tới 8 MB
 * vì tài liệu HTML được gửi nguyên chuỗi (file 9 mục 7); API ghi chú trên tài liệu nhận tới 320 KB
 * (nét vẽ một slide tối đa 256 KB).
 */
export function configureApp(app: INestApplication) {
  app.use(ADMIN_DOC_PATH, express.json({ limit: ADMIN_DOC_BODY_LIMIT }));
  app.use(ANNOTATION_DOC_PATH, express.json({ limit: ANNOTATION_BODY_LIMIT }));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new TransformInterceptor());
  app.enableCors();
  app.setGlobalPrefix('api', { exclude: ['health'] });
}
