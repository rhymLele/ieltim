import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Comment } from './entities/comment.entity';

@Injectable()
export class CommentsService {
  constructor(
    @InjectRepository(Comment)
    private commentRepo: Repository<Comment>,
  ) {}

  async findByDocumentId(documentId: string) {
    const comments = await this.commentRepo.find({
      where: { documentId },
      order: { createdAt: 'ASC' },
    });

    const topLevel = comments.filter((c) => !c.parentId);
    const replies = comments.filter((c) => c.parentId);

    return topLevel.map((c) => ({
      ...c,
      replies: replies.filter((r) => r.parentId === c.id),
    }));
  }

  async create(data: { documentId: string; userId: string; parentId?: string; content: string }) {
    const comment = this.commentRepo.create(data);
    return this.commentRepo.save(comment);
  }

  async update(id: string, userId: string, role: string, content: string) {
    const comment = await this.commentRepo.findOne({ where: { id } });
    if (!comment) {
      throw new HttpException(
        { statusCode: 404, code: 'NOT_FOUND', message: 'Comment not found' },
        HttpStatus.NOT_FOUND,
      );
    }
    if (comment.userId !== userId && role !== 'ADMIN') {
      throw new HttpException(
        { statusCode: 403, code: 'FORBIDDEN', message: 'Can only edit own comments' },
        HttpStatus.FORBIDDEN,
      );
    }
    comment.content = content;
    return this.commentRepo.save(comment);
  }

  async remove(id: string, userId: string, role: string) {
    const comment = await this.commentRepo.findOne({ where: { id } });
    if (!comment) {
      throw new HttpException(
        { statusCode: 404, code: 'NOT_FOUND', message: 'Comment not found' },
        HttpStatus.NOT_FOUND,
      );
    }
    if (comment.userId !== userId && role !== 'ADMIN') {
      throw new HttpException(
        { statusCode: 403, code: 'FORBIDDEN', message: 'Can only delete own comments' },
        HttpStatus.FORBIDDEN,
      );
    }
    return this.commentRepo.delete(id);
  }
}
