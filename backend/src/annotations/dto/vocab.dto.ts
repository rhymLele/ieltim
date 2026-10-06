import { Transform, type TransformFnParams } from 'class-transformer';
import { IsOptional, IsString, Length, MaxLength } from 'class-validator';

const trim = ({ value }: TransformFnParams): unknown =>
  typeof value === 'string' ? value.trim() : value;

export class CreateVocabDto {
  @Transform(trim)
  @IsString()
  @Length(1, 120)
  text: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  meaning?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  ipa?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  example?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  partOfSpeech?: string | null;

  /** Bỏ trống → 'Sổ chung'. */
  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(60)
  deck?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  sourceDocId?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  sourceBlockKey?: string | null;
}

export class UpdateVocabDto {
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Length(1, 120)
  text?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  meaning?: string | null;

  /** `null` để xoá ví dụ. */
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  example?: string | null;

  @IsOptional()
  @Transform(trim)
  @IsString()
  @MaxLength(60)
  deck?: string | null;

  /** Từ loại / nhãn (màn Sổ từ dùng làm tag); `null` để xoá. */
  @IsOptional()
  @IsString()
  @MaxLength(20)
  partOfSpeech?: string | null;
}

export class VocabListQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(60)
  deck?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  q?: string;
}
