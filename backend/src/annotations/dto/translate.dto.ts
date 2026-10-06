import { Transform, type TransformFnParams } from 'class-transformer';
import { IsIn, IsOptional, IsString, Length, MaxLength } from 'class-validator';

const trim = ({ value }: TransformFnParams): unknown =>
  typeof value === 'string' ? value.trim() : value;

/** Hiện chỉ hỗ trợ Anh → Việt. */
export class TranslateDto {
  @Transform(trim)
  @IsString()
  @Length(1, 300)
  text: string;

  @IsOptional()
  @IsString()
  @MaxLength(600)
  sentence?: string | null;

  @IsOptional()
  @IsIn(['en'])
  from?: string;

  @IsOptional()
  @IsIn(['vi'])
  to?: string;
}
