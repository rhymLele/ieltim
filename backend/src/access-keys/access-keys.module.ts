import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AccessKeysService } from './access-keys.service';
import { AccessKeysController } from './access-keys.controller';
import { AccessKey } from './entities/access-key.entity';

@Module({
  imports: [TypeOrmModule.forFeature([AccessKey])],
  controllers: [AccessKeysController],
  providers: [AccessKeysService],
  exports: [AccessKeysService],
})
export class AccessKeysModule {}
