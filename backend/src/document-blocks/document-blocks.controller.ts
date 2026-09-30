import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { DocumentBlocksService } from './document-blocks.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { BlockType } from '../common/enums/block-type.enum';

@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class DocumentBlocksController {
  constructor(private blocksService: DocumentBlocksService) {}

  @Get('documents/:documentId/blocks')
  findByDocument(@Param('documentId') documentId: string) {
    return this.blocksService.findByDocumentId(documentId);
  }

  @Post('documents/:documentId/blocks')
  @Roles('ADMIN')
  create(
    @Param('documentId') documentId: string,
    @Body() body: { blockType: BlockType; position: number; data: Record<string, any> },
  ) {
    return this.blocksService.create({ documentId, ...body });
  }

  @Patch('document-blocks/:id')
  @Roles('ADMIN')
  update(
    @Param('id') id: string,
    @Body() body: Partial<{ blockType: BlockType; position: number; data: Record<string, any> }>,
  ) {
    return this.blocksService.update(id, body);
  }

  @Delete('document-blocks/:id')
  @Roles('ADMIN')
  remove(@Param('id') id: string) {
    return this.blocksService.remove(id);
  }

  @Patch('documents/:documentId/blocks/reorder')
  @Roles('ADMIN')
  reorder(@Param('documentId') documentId: string, @Body() body: { orderedIds: string[] }) {
    return this.blocksService.reorder(documentId, body.orderedIds);
  }
}
