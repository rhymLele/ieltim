import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { Actor } from '../weekly-docs/weekly-errors';
import { ActiveUserGuard } from './access.guards';
import {
  CreateVocabDto,
  UpdateVocabDto,
  VocabListQueryDto,
} from './dto/vocab.dto';
import { VocabService } from './vocab.service';

/** Sổ từ cá nhân (nhiều sổ). */
@Controller('me/vocab')
@UseGuards(JwtAuthGuard, ActiveUserGuard)
export class VocabController {
  constructor(private vocab: VocabService) {}

  @Post()
  create(@Body() dto: CreateVocabDto, @CurrentUser() user: Actor) {
    return this.vocab.create(user.id, dto);
  }

  @Get()
  list(@Query() query: VocabListQueryDto, @CurrentUser() user: Actor) {
    return this.vocab.list(user.id, query);
  }

  @Get('exists')
  exists(@Query('text') text: string | undefined, @CurrentUser() user: Actor) {
    return this.vocab.exists(user.id, text);
  }

  @Get('decks')
  decks(@CurrentUser() user: Actor) {
    return this.vocab.decks(user.id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateVocabDto,
    @CurrentUser() user: Actor,
  ) {
    return this.vocab.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@Param('id') id: string, @CurrentUser() user: Actor) {
    await this.vocab.remove(user.id, id);
  }
}
