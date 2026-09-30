import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IeltsContextsService } from './ielts-contexts.service';
import { IeltsContext } from './entities/ielts-context.entity';

@Module({
  imports: [TypeOrmModule.forFeature([IeltsContext])],
  providers: [IeltsContextsService],
  exports: [IeltsContextsService],
})
export class IeltsContextsModule {}
