/**
 * Giới hạn số lần theo cửa sổ trượt, giữ trong bộ nhớ (một instance). Mỗi khoá giữ mốc thời gian các lần đã tính.
 */
export class SlidingWindowLimiter {
  private hits = new Map<string, number[]>();

  constructor(
    private readonly limit: number,
    private readonly windowMs: number,
  ) {}

  /** Tính một lần cho `key`; false (không tính) nếu đã đủ `limit` lần trong cửa sổ. */
  take(key: string, now = Date.now()): boolean {
    if (this.hits.size > 10_000) this.sweep(now);
    const since = now - this.windowMs;
    const list = (this.hits.get(key) ?? []).filter((t) => t > since);
    if (list.length >= this.limit) {
      this.hits.set(key, list);
      return false;
    }
    list.push(now);
    this.hits.set(key, list);
    return true;
  }

  /** Bỏ các khoá không còn lần nào trong cửa sổ. */
  private sweep(now: number) {
    const since = now - this.windowMs;
    for (const [key, list] of this.hits) {
      if (!list.some((t) => t > since)) this.hits.delete(key);
    }
  }
}
