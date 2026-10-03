import { HttpException } from '@nestjs/common';

/**
 * Lỗi nghiệp vụ theo convention của project ({ statusCode, code, message }), kèm `data` khi FE cần thêm
 * (409 trả bản hiện tại, 422 trả danh sách lỗi). Mã lỗi theo file 7 mục 7.
 */
export function weeklyError(
  status: number,
  code: string,
  message: string,
  data?: unknown,
): HttpException {
  return new HttpException(
    {
      statusCode: status,
      code,
      message,
      ...(data !== undefined ? { data } : {}),
    },
    status,
  );
}

export interface Actor {
  id: string;
  role: string;
  displayName?: string;
}
