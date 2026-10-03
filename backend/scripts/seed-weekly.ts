// Seed Tài liệu theo tuần: `npm run seed:weekly` (dùng cấu hình DB của app, bảng tự tạo nhờ synchronize).
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { WeeklySeedService } from '../src/weekly-docs/weekly-seed.service';

async function main() {
  process.env.WEEKLY_SCHEDULER = 'off';
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn'],
  });
  const { created } = await app.get(WeeklySeedService).seed();
  console.log(
    created.length
      ? `Đã tạo: ${created.join(', ')}`
      : 'Dữ liệu mẫu đã có sẵn, không tạo thêm.',
  );
  await app.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
