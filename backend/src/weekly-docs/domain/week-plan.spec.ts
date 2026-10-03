import { weeksToGenerate } from './week-plan';

// Thứ Bảy 03/10/2026 giờ VN → tuần lịch bắt đầu thứ Hai 28/09.
const NOW = new Date('2026-10-03T05:00:00Z');

describe('weeksToGenerate', () => {
  it('chưa có tuần nào: Tuần 1 = tuần này, thêm `ahead` tuần tới', () => {
    expect(weeksToGenerate(null, 2, NOW)).toEqual([
      { number: 1, startDate: '2026-09-28', endDate: '2026-10-04' },
      { number: 2, startDate: '2026-10-05', endDate: '2026-10-11' },
      { number: 3, startDate: '2026-10-12', endDate: '2026-10-18' },
    ]);
  });

  it('nối tiếp tuần cuối, chỉ sinh phần còn thiếu', () => {
    const last = { number: 13, startDate: '2026-10-05' }; // tuần tới đã có
    expect(weeksToGenerate(last, 1, NOW)).toEqual([]);
    expect(
      weeksToGenerate(last, 3, NOW).map((w) => [w.number, w.startDate]),
    ).toEqual([
      [14, '2026-10-12'],
      [15, '2026-10-19'],
    ]);
  });

  it('hệ thống nghỉ lâu: lấp đủ các tuần ở giữa để số tuần khớp ngày', () => {
    const gap = weeksToGenerate({ number: 5, startDate: '2026-08-31' }, 0, NOW);
    expect(gap.map((w) => w.number)).toEqual([6, 7, 8, 9]);
    expect(gap[gap.length - 1].startDate).toBe('2026-09-28');
  });

  it('tuần cuối đã ở xa trong tương lai: không sinh gì', () => {
    expect(
      weeksToGenerate({ number: 40, startDate: '2027-05-03' }, 4, NOW),
    ).toEqual([]);
  });

  it('qua mốc nửa đêm Chủ nhật giờ VN thì "tuần này" đổi', () => {
    const sunday = new Date('2026-10-04T16:59:00Z'); // 23:59 Chủ nhật VN
    const monday = new Date('2026-10-04T17:00:00Z'); // 00:00 thứ Hai VN
    const last = { number: 12, startDate: '2026-09-28' };
    expect(weeksToGenerate(last, 0, sunday)).toEqual([]);
    expect(weeksToGenerate(last, 0, monday).map((w) => w.number)).toEqual([13]);
  });
});
