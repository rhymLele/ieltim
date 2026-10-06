import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { isUUID } from 'class-validator';
import { Repository } from 'typeorm';
import { Status } from '../common/enums/status.enum';
import { User } from '../users/entities/user.entity';
import { WeeklyDocument } from '../weekly-docs/entities/weekly-document.entity';
import { WeeksService } from '../weekly-docs/weeks.service';
import { type Actor, weeklyError } from '../weekly-docs/weekly-errors';

/** Chỉ tài khoản còn trong bảng `users` với trạng thái ACTIVE mới dùng được (đặt sau JwtAuthGuard). */
@Injectable()
export class ActiveUserGuard implements CanActivate {
  constructor(@InjectRepository(User) private users: Repository<User>) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const id = ctx.switchToHttp().getRequest<{ user?: Actor }>().user?.id;
    const active =
      typeof id === 'string' &&
      isUUID(id) &&
      (await this.users.exists({ where: { id, status: Status.ACTIVE } }));
    if (!active)
      throw weeklyError(403, 'USER_INACTIVE', 'Tài khoản không còn hoạt động.');
    return true;
  }
}

/**
 * Tài liệu trong `:docId` phải là tài liệu người dùng đang xem được (PUBLISHED, tuần đã mở),
 * không thì 403 `DOC_FORBIDDEN` (kể cả khi không tồn tại).
 */
@Injectable()
export class VisibleDocGuard implements CanActivate {
  constructor(
    @InjectRepository(WeeklyDocument) private docs: Repository<WeeklyDocument>,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const docId = ctx
      .switchToHttp()
      .getRequest<{ params?: Record<string, string> }>().params?.docId;
    const doc =
      docId && docId.length <= 40
        ? await this.docs.findOne({
            where: { id: docId },
            relations: { weekRef: true },
          })
        : null;
    if (!WeeksService.docVisible(doc))
      throw weeklyError(
        403,
        'DOC_FORBIDDEN',
        'Bạn không có quyền với tài liệu này.',
      );
    return true;
  }
}
