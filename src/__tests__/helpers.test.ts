import { ensureHttpsUrl } from '../helpers';

describe('ensureHttpsUrl', () => {
  it('returns the same URL if it already uses https', () => {
    const url = 'https://example.com';
    expect(ensureHttpsUrl(url)).toBe(url);
  });

  it('converts an http URL to https', () => {
    const httpUrl = 'http://example.com';
    const expectedHttpsUrl = 'https://example.com';
    expect(ensureHttpsUrl(httpUrl)).toBe(expectedHttpsUrl);
  });

  it('handles URLs that contain http but not at the start', () => {
    const complexUrl = 'https://example.com?page=http://external.com';
    expect(ensureHttpsUrl(complexUrl)).toBe(complexUrl);
  });

  it('adds https to a URL lacking http or https', () => {
    const plainUrl = 'example.com';
    const expectedHttpsUrl = 'https://example.com';
    expect(ensureHttpsUrl(plainUrl)).toBe(expectedHttpsUrl);
  });
});
