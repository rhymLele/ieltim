// Tự sinh tuần (không cần admin tạo tay): tuần là các tuần lịch thứ Hai → Chủ nhật nối tiếp nhau,
// số tuần tăng dần. Luôn có sẵn tuần hiện tại + `ahead` tuần tới để admin soạn trước.

import { addDays, vnCalendarWeek } from './vn-time';

export interface WeekSlot {
  number: number;
  startDate: string;
  endDate: string;
}

/** Giới hạn một lần sinh (10 năm), phòng dữ liệu ngày sai. */
const MAX_GENERATE = 520;

/**
 * Các tuần còn thiếu: nối tiếp tuần cuối (thứ Hai liên tiếp, kể cả các tuần hệ thống không chạy)
 * tới hết tuần chứa hôm nay + `ahead` tuần. Chưa có tuần nào thì bắt đầu Tuần 1 = tuần này.
 */
export function weeksToGenerate(
  last: { number: number; startDate: string } | null,
  ahead: number,
  now = new Date(),
): WeekSlot[] {
  const thisMonday = vnCalendarWeek(now).monday;
  const lastMonday = addDays(thisMonday, Math.max(0, ahead) * 7);
  let number = last?.number ?? 0;
  let start = last ? addDays(last.startDate, 7) : thisMonday;
  const out: WeekSlot[] = [];
  while (start <= lastMonday && out.length < MAX_GENERATE) {
    number++;
    out.push({ number, startDate: start, endDate: addDays(start, 6) });
    start = addDays(start, 7);
  }
  return out;
}
