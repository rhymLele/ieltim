import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class TransformInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(
      map((data) => {
        const response = context.switchToHttp().getResponse();
        const statusCode = response.statusCode || 200;

        let count: number | null = null;
        let responseData = data;

        if (data && typeof data === 'object') {
          if (Array.isArray(data)) {
            count = data.length;
          } else if (data.data && Array.isArray(data.data)) {
            count = data.data.length;
            responseData = data;
          } else if (data.pagination) {
            count = data.pagination.total;
            responseData = data;
          }
        }

        return {
          status: 'success',
          message: statusCode < 300 ? 'Data returned successfully' : 'Request failed',
          data: responseData,
          code: statusCode,
          count,
          timestamp: new Date().toISOString(),
        };
      }),
    );
  }
}
