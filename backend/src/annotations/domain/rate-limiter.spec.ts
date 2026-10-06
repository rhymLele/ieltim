import { SlidingWindowLimiter } from './rate-limiter';

describe('SlidingWindowLimiter', () => {
  it('đủ giới hạn thì chặn, cửa sổ trượt qua thì cho lại', () => {
    const l = new SlidingWindowLimiter(2, 1000);
    expect(l.take('u', 0)).toBe(true);
    expect(l.take('u', 500)).toBe(true);
    expect(l.take('u', 900)).toBe(false);
    expect(l.take('v', 900)).toBe(true); // tính riêng từng người
    expect(l.take('u', 1001)).toBe(true); // lần lúc 0 đã ra khỏi cửa sổ
    expect(l.take('u', 1200)).toBe(false);
  });
});
