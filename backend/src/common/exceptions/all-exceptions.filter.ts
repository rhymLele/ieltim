import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const method = request.method;
    const url = request.url;

    let statusCode = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL_ERROR';
    let message = 'Internal server error';
    let data: unknown = null;

    if (exception instanceof HttpException) {
      statusCode = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const res = exceptionResponse as Record<string, unknown>;
        code = (res['code'] as string) || exception.name;
        message =
          (res['message'] as string) || exception.message || 'Bad request';
        // Lỗi nghiệp vụ có thể kèm dữ liệu cho FE (409 trả bản hiện tại, 422 trả danh sách lỗi).
        data = res['data'] ?? null;
      } else {
        message = exceptionResponse as string;
      }
    } else if (isClientHttpError(exception)) {
      // Lỗi 4xx của middleware Express (body-parser: body quá lớn…) giữ đúng mã thay vì thành 500.
      statusCode = exception.status;
      const tooLarge = exception.type === 'entity.too.large';
      code = tooLarge ? 'PAYLOAD_TOO_LARGE' : 'BAD_REQUEST';
      message = tooLarge ? 'Dữ liệu gửi lên quá lớn.' : exception.message;
    } else if (exception instanceof Error) {
      message = exception.message;
    }

    this.logger.error(
      `${method} ${url} → ${statusCode} [${code}]: ${message}`,
      exception instanceof Error ? exception.stack : undefined,
    );

    response.status(statusCode).json({
      status: 'error',
      message,
      data,
      code: statusCode,
      count: null,
      error: code,
      timestamp: new Date().toISOString(),
    });
  }
}

function isClientHttpError(
  e: unknown,
): e is Error & { status: number; type?: string } {
  const status = (e as { status?: unknown })?.status;
  return (
    e instanceof Error &&
    (e as { expose?: unknown }).expose === true &&
    typeof status === 'number' &&
    status >= 400 &&
    status < 500
  );
}
