import {
  IsIn,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  Length,
  Min,
} from 'class-validator';
import {
  HIGHLIGHT_COLORS,
  HIGHLIGHT_QUOTE_MAX,
  type HighlightColor,
} from '../annotations.constants';

/** Body của PUT highlight. `id` nằm trên URL; `id` gửi kèm trong body bị bỏ qua (whitelist). */
export class HighlightDto {
  @IsString()
  @Length(1, 80)
  blockKey: string;

  @IsString()
  @Length(1, HIGHLIGHT_QUOTE_MAX)
  quote: string;

  /** Cắt còn 32 ký tự cuối khi lưu. */
  @IsOptional()
  @IsString()
  prefix?: string | null;

  /** Cắt còn 32 ký tự đầu khi lưu. */
  @IsOptional()
  @IsString()
  suffix?: string | null;

  @IsIn(HIGHLIGHT_COLORS)
  color: HighlightColor;

  @IsOptional()
  @IsInt()
  @Min(0)
  start?: number | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  end?: number | null;

  @IsInt()
  @Min(0)
  docVersion: number;
}

export class SlideAnnotationDto {
  /** `{ items: [...] }`, tối đa 256 KB. */
  @IsObject()
  data: { items: unknown[] };

  /** Rev phía server mà bản sửa dựa vào (0 khi slide chưa có gì). */
  @IsInt()
  @Min(0)
  rev: number;

  @IsInt()
  @Min(0)
  docVersion: number;
}
