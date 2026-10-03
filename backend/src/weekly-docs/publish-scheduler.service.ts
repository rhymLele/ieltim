import {
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnApplicationShutdown,
} from '@nestjs/common';
import { AdminDocumentsService } from './admin-documents.service';
import { WeeksService } from './weeks.service';

const TICK_MS = 60 * 1000;
const PURGE_EVERY_MS = 60 * 60 * 1000;

/**
 * Job mỗi phút: SCHEDULED tới giờ → PUBLISHED (file 1 mục 4); mỗi giờ tự sinh tuần tới và dọn nháp đã xoá mềm quá 30 ngày.
 * Idempotent (UPDATE … WHERE status = 'scheduled'), chạy nhiều instance cũng an toàn.
 * Tắt bằng WEEKLY_SCHEDULER=off; không chạy khi NODE_ENV=test (test gọi `tick()` trực tiếp).
 */
@Injectable()
export class PublishSchedulerService
  implements OnApplicationBootstrap, OnApplicationShutdown
{
  private readonly logger = new Logger(PublishSchedulerService.name);
  private timer?: NodeJS.Timeout;
  private running = false;
  private lastPurge = 0;

  constructor(
    private docs: AdminDocumentsService,
    private weeks: WeeksService,
  ) {}

  onApplicationBootstrap() {
    if (
      process.env.NODE_ENV === 'test' ||
      process.env.WEEKLY_SCHEDULER === 'off'
    )
      return;
    this.timer = setInterval(() => void this.tick(), TICK_MS);
    this.timer.unref();
  }

  onApplicationShutdown() {
    if (this.timer) clearInterval(this.timer);
  }

  async tick(now = new Date()) {
    if (this.running) return;
    this.running = true;
    try {
      const { published, failed } = await this.docs.runScheduledPublish(now);
      if (published.length)
        this.logger.log(`Xuất bản theo lịch: ${published.join(', ')}`);
      if (failed.length)
        this.logger.warn(
          `Hẹn giờ thất bại (còn lỗi, đã về nháp): ${failed.join(', ')}`,
        );
      if (now.getTime() - this.lastPurge >= PURGE_EVERY_MS) {
        this.lastPurge = now.getTime();
        const created = await this.weeks.ensureUpcoming(now);
        if (created.length)
          this.logger.log(`Tự sinh tuần: ${created.join(', ')}`);
        const purged = await this.docs.purgeDeleted(now);
        if (purged)
          this.logger.log(`Đã xoá hẳn ${purged} nháp quá hạn khôi phục`);
      }
    } catch (e) {
      this.logger.error(
        'Job xuất bản theo lịch lỗi',
        e instanceof Error ? e.stack : String(e),
      );
    } finally {
      this.running = false;
    }
  }
}
