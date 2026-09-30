import { IsString, MinLength } from 'class-validator';

export class AccessKeyLoginDto {
  @IsString()
  @MinLength(1)
  key: string;
}
