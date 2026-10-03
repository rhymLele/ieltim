import { Type } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';

export class CreateWeekDto {
  @Type(() => Number)
  @IsInt({ message: 'Số tuần phải là số nguyên' })
  @Min(1, { message: 'Số tuần phải từ 1' })
  number: number;

  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'Ngày bắt đầu có dạng YYYY-MM-DD',
  })
  startDate: string;

  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(80, { message: 'Tên tuần tối đa 80 ký tự' })
  title?: string | null;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1, { message: 'Mục tiêu chặng từ 1 đến 20' })
  @Max(20, { message: 'Mục tiêu chặng từ 1 đến 20' })
  stageGoal?: number;
}

export class UpdateWeekDto {
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, {
    message: 'Ngày bắt đầu có dạng YYYY-MM-DD',
  })
  startDate?: string;

  @IsOptional()
  @ValidateIf((_, v) => v !== null)
  @IsString()
  @MaxLength(80, { message: 'Tên tuần tối đa 80 ký tự' })
  title?: string | null;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1, { message: 'Mục tiêu chặng từ 1 đến 20' })
  @Max(20, { message: 'Mục tiêu chặng từ 1 đến 20' })
  stageGoal?: number;
}
