import { Type } from 'class-transformer';
import {
  IsArray,
  IsDateString,
  IsDefined,
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { SKILLS, VIEW_MODES } from '../weekly-docs.constants';

/** Tạo nháp từ template (`title`, `skill`, `template`) hoặc từ JSON có sẵn (`content`). */
export class CreateDocumentDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  week?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1, { message: 'Số thứ tự phải từ 1' })
  order?: number;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsIn(SKILLS, { message: 'Chọn kỹ năng' })
  skill?: string;

  @IsOptional()
  @IsString()
  template?: string;

  @IsOptional()
  @IsObject()
  content?: Record<string, any>;

  /** Tài liệu HTML (file 9): có thể gửi ở đây hoặc trong `content`. */
  @IsOptional()
  @IsString()
  html?: string;

  @IsOptional()
  @IsString()
  htmlFileName?: string;
}

export class SaveDocumentDto {
  @IsObject()
  content: Record<string, any>;

  @Type(() => Number)
  @IsInt()
  version: number;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsIn(SKILLS, { message: 'Chọn kỹ năng' })
  skill?: string;

  @IsOptional()
  @IsIn(VIEW_MODES)
  defaultView?: string;

  @IsOptional()
  @IsArray()
  @IsIn(VIEW_MODES, { each: true })
  allowedViews?: string[];

  @IsOptional()
  @IsString()
  html?: string;

  @IsOptional()
  @IsString()
  htmlFileName?: string;
}

export class ValidateContentDto {
  /** Object JSON, hoặc chuỗi JSON (kiểm tra cả lỗi cú pháp). */
  @IsDefined()
  content: unknown;
}

export class PublishDocumentDto {
  @IsOptional()
  @IsDateString({}, { message: 'publishAt phải là thời điểm ISO 8601' })
  publishAt?: string;
}

export class ScheduleDocumentDto {
  @IsDateString({}, { message: 'publishAt phải là thời điểm ISO 8601' })
  publishAt: string;
}

export class UnpublishDocumentDto {
  @IsOptional()
  @IsString()
  @MaxLength(200, { message: 'Lý do tối đa 200 ký tự' })
  reason?: string;
}

export class DuplicateDocumentDto {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  targetWeek: number;
}

export class ReorderItemDto {
  @IsString()
  id: string;

  @Type(() => Number)
  @IsInt()
  @Min(1, { message: 'Số thứ tự phải từ 1' })
  order: number;
}

export class ImportDocumentDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  week?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  order?: number;
}

export class ListDocumentsQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  week?: number;

  /** Một hoặc nhiều trạng thái, ngăn cách bằng dấu phẩy: `draft,scheduled`. */
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsIn(SKILLS)
  skill?: string;

  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  pageSize?: number;
}

export class ExportQueryDto {
  /** Tài liệu PUBLISHED có bản nháp sửa đổi: tải bản phát hành (`live`) hay bản nháp (`draft`). */
  @IsOptional()
  @IsIn(['live', 'draft'])
  source?: 'live' | 'draft';
}
