export const ensureHttpsUrl = (url: string) => {
  if (url.includes('https')) return url;

  if (!url.includes('http')) return `https://${url}`;

  const [, ...rest] = url.split('http');
  return `https${rest.join('')}`;
};
