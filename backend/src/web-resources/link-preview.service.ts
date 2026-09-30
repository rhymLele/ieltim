import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

export interface LinkPreview {
  title: string;
  description: string | null;
  imageUrl: string | null;
  faviconUrl: string | null;
  domain: string;
}

@Injectable()
export class LinkPreviewService {
  private readonly UA =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  constructor(private httpService: HttpService) {}

  async fetchPreview(url: string): Promise<LinkPreview> {
    const uri = this.ensureUrl(url);
    const domain = this.extractDomain(uri);

    try {
      const { data: html } = await firstValueFrom(
        this.httpService.get<string>(uri, {
          headers: { 'User-Agent': this.UA, Accept: 'text/html' },
          timeout: 8000,
          maxRedirects: 5,
          transformResponse: [(data) => data],
        }),
      );

      const title = this.extractMeta(html, 'og:title') || this.extractTitle(html) || domain;
      const description = this.extractMeta(html, 'og:description') || this.extractMeta(html, 'description');
      const imageUrl =
        this.extractMeta(html, 'og:image') || this.extractMeta(html, 'twitter:image');
      const faviconUrl = this.extractFavicon(html, uri);

      return {
        title,
        description: description || null,
        imageUrl: imageUrl || null,
        faviconUrl: faviconUrl || null,
        domain,
      };
    } catch {
      return {
        title: domain,
        description: null,
        imageUrl: null,
        faviconUrl: `https://www.google.com/s2/favicons?domain=${domain}&sz=64`,
        domain,
      };
    }
  }

  private ensureUrl(url: string): string {
    const trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    return `https://${trimmed}`;
  }

  private extractDomain(uri: string): string {
    try {
      return new URL(uri).hostname.replace(/^www\./, '');
    } catch {
      return uri;
    }
  }

  private extractMeta(html: string, property: string): string | null {
    const patterns = [
      new RegExp(`<meta[^>]+property=["']${property}["'][^>]+content=["']([^"']*)["']`, 'i'),
      new RegExp(`<meta[^>]+content=["']([^"']*)["'][^>]+property=["']${property}["']`, 'i'),
    ];
    for (const p of patterns) {
      const m = html.match(p);
      if (m?.[1]) return m[1].trim();
    }
    return null;
  }

  private extractTitle(html: string): string | null {
    const m = html.match(/<title[^>]*>([^<]*)<\/title>/i);
    return m?.[1]?.trim() || null;
  }

  private extractFavicon(html: string, pageUrl: string): string | null {
    const m = html.match(/<link[^>]+rel=["'](?:shortcut )?icon["'][^>]+href=["']([^"']*)["']/i) ||
      html.match(/<link[^>]+href=["']([^"']*)["'][^>]+rel=["'](?:shortcut )?icon["']/i);
    if (m?.[1]) {
      try {
        return new URL(m[1], pageUrl).href;
      } catch {
        return m[1];
      }
    }
    return null;
  }
}
