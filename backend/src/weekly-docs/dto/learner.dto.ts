import { Type } from 'class-transformer';
import {
  IsArray,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';
import { VIEW_MODES } from '../weekly-docs.constants';

export class ProgressDto {
  @Type(() => Number)
  @IsInt()
  @Min(0)
  sectionIndex: number;

  @IsOptional()
  @IsIn(VIEW_MODES)
  viewMode?: string;
}

export class QuizAnswerDto {
  @IsString()
  @IsNotEmpty()
  blockKey: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  option: number;
}

export class VocabFromDocumentDto {
  @IsString()
  @IsNotEmpty()
  documentId: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  blockKeys?: string[];
}
