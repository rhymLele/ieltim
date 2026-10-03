// Thời gian nghiệp vụ theo giờ Việt Nam (Asia/Ho_Chi_Minh = UTC+7, không có giờ mùa hè).
// DB lưu UTC; mọi phép tính ngày, tuần, streak đi qua các hàm này.

const VN_OFFSET_MS = 7 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

/** Ngày theo giờ Việt Nam, dạng `YYYY-MM-DD`. */
export function vnDate(at: Date = new Date()): string {
  return new Date(at.getTime() + VN_OFFSET_MS).toISOString().slice(0, 10);
}

function parseDate(date: string): number {
  const [y, m, d] = date.split('-').map(Number);
  return Date.UTC(y, m - 1, d);
}

export function addDays(date: string, days: number): string {
  return new Date(parseDate(date) + days * DAY_MS).toISOString().slice(0, 10);
}

export function isMonday(date: string): boolean {
  return (
    /^\d{4}-\d{2}-\d{2}$/.test(date) &&
    new Date(parseDate(date)).getUTCDay() === 1
  );
}

/** Thời điểm 00:00 giờ Việt Nam của một ngày, quy về UTC. */
export function vnDayStart(date: string): Date {
  return new Date(parseDate(date) - VN_OFFSET_MS);
}

/** Tuần lịch hiện tại: thứ Hai 00:00 → thứ Hai kế tiếp 00:00 (giờ Việt Nam). */
export function vnCalendarWeek(at: Date = new Date()): {
  monday: string;
  start: Date;
  end: Date;
} {
  const today = vnDate(at);
  const sinceMonday = (new Date(parseDate(today)).getUTCDay() + 6) % 7;
  const monday = addDays(today, -sinceMonday);
  return {
    monday,
    start: vnDayStart(monday),
    end: vnDayStart(addDays(monday, 7)),
  };
}

/** `HH:mm` giờ Việt Nam (thông báo xung đột, nhật ký). */
export function vnHm(at: Date): string {
  return new Date(at.getTime() + VN_OFFSET_MS).toISOString().slice(11, 16);
}

/**
 * Streak: số ngày liên tiếp có hoạt động học, tính lùi từ hôm nay.
 * Hôm nay chưa học thì vẫn giữ streak tới hết ngày (tính lùi từ hôm qua).
 */
export function streakDays(
  activeDates: Iterable<string>,
  today: string,
): number {
  const days = new Set(activeDates);
  let day = days.has(today) ? today : addDays(today, -1);
  let streak = 0;
  while (days.has(day)) {
    streak++;
    day = addDays(day, -1);
  }
  return streak;
}
