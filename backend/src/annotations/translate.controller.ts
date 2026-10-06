import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { Actor } from '../weekly-docs/weekly-errors';
import { ActiveUserGuard } from './access.guards';
import { TranslateDto } from './dto/translate.dto';
import { TranslateService } from './translate.service';

/** Dịch nghĩa từ / cụm đang chọn trong tài liệu. */
@Controller('translate')
@UseGuards(JwtAuthGuard, ActiveUserGuard)
export class TranslateController {
  constructor(private translator: TranslateService) {}

  @Post()
  @HttpCode(200)
  translate(@Body() dto: TranslateDto, @CurrentUser() user: Actor) {
    return this.translator.translate(user.id, dto);
  }
}
