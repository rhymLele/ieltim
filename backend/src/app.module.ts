import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { User } from './users/entities/user.entity';
import { AccessKeysModule } from './access-keys/access-keys.module';
import { AccessKey } from './access-keys/entities/access-key.entity';
import { DocumentsModule } from './documents/documents.module';
import { Document } from './documents/entities/document.entity';
import { DocumentBlocksModule } from './document-blocks/document-blocks.module';
import { DocumentBlock } from './document-blocks/entities/document-block.entity';
import { VocabulariesModule } from './vocabularies/vocabularies.module';
import { Vocabulary } from './vocabularies/entities/vocabulary.entity';
import { Collocation } from './vocabularies/entities/collocation.entity';
import { SentencePatternsModule } from './sentence-patterns/sentence-patterns.module';
import { SentencePattern } from './sentence-patterns/entities/sentence-pattern.entity';
import { TagsModule } from './tags/tags.module';
import { Tag } from './tags/entities/tag.entity';
import { IeltsContextsModule } from './ielts-contexts/ielts-contexts.module';
import { IeltsContext } from './ielts-contexts/entities/ielts-context.entity';
import { CommentsModule } from './comments/comments.module';
import { Comment } from './comments/entities/comment.entity';
import { WebResourcesModule } from './web-resources/web-resources.module';
import { WebResource } from './web-resources/entities/web-resource.entity';
import { SearchModule } from './search/search.module';
import { LessonsModule } from './lessons/lessons.module';
import { LessonVocabulary } from './lessons/entities/lesson-vocabulary.entity';
import { LessonSentencePattern } from './lessons/entities/lesson-sentence-pattern.entity';
import { TheoryBlock } from './lessons/entities/theory-block.entity';
import { Practice } from './lessons/entities/practice.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get('DB_HOST'),
        port: config.get<number>('DB_PORT', 5432),
        username: config.get('DB_USER'),
        password: config.get('DB_PASSWORD'),
        database: config.get('DB_NAME'),
        entities: [
          User,
          AccessKey,
          Document,
          DocumentBlock,
          Vocabulary,
          Collocation,
          SentencePattern,
          Tag,
          IeltsContext,
          Comment,
          WebResource,
          LessonVocabulary,
          LessonSentencePattern,
          TheoryBlock,
          Practice,
        ],
        synchronize: true,
      }),
    }),
    AuthModule,
    UsersModule,
    AccessKeysModule,
    DocumentsModule,
    DocumentBlocksModule,
    VocabulariesModule,
    SentencePatternsModule,
    TagsModule,
    IeltsContextsModule,
    CommentsModule,
    WebResourcesModule,
    SearchModule,
    LessonsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
