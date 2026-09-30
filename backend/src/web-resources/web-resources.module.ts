import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WebResourcesController } from './web-resources.controller';
import { WebResourcesService } from './web-resources.service';
import { LinkPreviewService } from './link-preview.service';
import { WebResource } from './entities/web-resource.entity';

@Module({
  imports: [TypeOrmModule.forFeature([WebResource]), HttpModule],
  controllers: [WebResourcesController],
  providers: [WebResourcesService, LinkPreviewService],
  exports: [WebResourcesService],
})
export class WebResourcesModule {}
