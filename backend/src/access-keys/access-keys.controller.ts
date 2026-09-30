import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  UseGuards,
  Body,
} from '@nestjs/common';
import { AccessKeysService } from './access-keys.service';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { IsString, IsOptional, IsDateString, IsUUID } from 'class-validator';
import { Status } from '../common/enums/status.enum';

class CreateAccessKeyDto {
  @IsString()
  key: string;

  @IsUUID()
  userId: string;

  @IsOptional()
  @IsDateString()
  expiresAt?: string;
}

class UpdateAccessKeyStatusDto {
  @IsString()
  status: Status;
}

@Controller('access-keys')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class AccessKeysController {
  constructor(private accessKeysService: AccessKeysService) {}

  @Get()
  findAll() {
    return this.accessKeysService.findAll();
  }

  @Post()
  create(@Body() dto: CreateAccessKeyDto) {
    return this.accessKeysService.create(
      dto.userId,
      dto.key,
      dto.expiresAt ? new Date(dto.expiresAt) : undefined,
    );
  }

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body() dto: UpdateAccessKeyStatusDto) {
    return this.accessKeysService.updateStatus(id, dto.status);
  }
}
