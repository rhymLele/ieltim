import {
  addDays,
  isMonday,
  streakDays,
  vnCalendarWeek,
  vnDate,
  vnHm,
} from './vn-time';

describe('vn-time', () => {
  it('ngày theo giờ Việt Nam qua mốc nửa đêm', () => {
    expect(vnDate(new Date('2026-10-04T16:59:59Z'))).toBe('2026-10-04'); // 23:59:59 VN
    expect(vnDate(new Date('2026-10-04T17:00:00Z'))).toBe('2026-10-05'); // 00:00 VN thứ Hai
    expect(vnHm(new Date('2026-10-04T23:30:00Z'))).toBe('06:30');
  });

  it('tuần lịch thứ Hai → Chủ nhật theo giờ Việt Nam', () => {
    // Chủ nhật 23:30 VN vẫn thuộc tuần bắt đầu 28/09.
    const sunday = vnCalendarWeek(new Date('2026-10-04T16:30:00Z'));
    expect(sunday.monday).toBe('2026-09-28');
    expect(sunday.start.toISOString()).toBe('2026-09-27T17:00:00.000Z');
    expect(sunday.end.toISOString()).toBe('2026-10-04T17:00:00.000Z');
    expect(vnCalendarWeek(new Date('2026-10-04T17:00:00Z')).monday).toBe(
      '2026-10-05',
    );
    expect(isMonday('2026-10-05')).toBe(true);
    expect(isMonday('2026-10-04')).toBe(false);
    expect(addDays('2026-12-29', 6)).toBe('2027-01-04');
  });

  it('streak: liên tiếp, hôm nay chưa học vẫn giữ, bỏ một ngày về 0', () => {
    expect(
      streakDays(['2026-10-01', '2026-10-02', '2026-10-03'], '2026-10-03'),
    ).toBe(3);
    expect(streakDays(['2026-10-01', '2026-10-02'], '2026-10-03')).toBe(2);
    expect(streakDays(['2026-10-01'], '2026-10-03')).toBe(0);
    expect(streakDays([], '2026-10-03')).toBe(0);
  });
});
