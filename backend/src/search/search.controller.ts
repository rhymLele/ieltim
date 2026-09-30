import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { SearchService } from './search.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('search')
@UseGuards(JwtAuthGuard)
export class SearchController {
  constructor(private searchService: SearchService) {}

  @Get()
  search(
    @Query('q') query: string,
    @CurrentUser() user: { id: string; role: string },
  ) {
    if (!query || query.trim().length < 2) {
      return { documents: [], vocabularies: [], sentencePatterns: [], webResources: [] };
    }
    return this.searchService.search(query.trim(), user.role);
  }
}
