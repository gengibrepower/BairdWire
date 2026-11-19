export const devNonce = "bairdwire-dev";

const directives = (styleSources: string): Record<string, string> => ({
  "default-src": "'none'",
  "script-src": "'self'",
  "style-src": styleSources,
  "img-src": "'self' blob:",
  "media-src": "'self' blob:",
  "font-src": "'self'",
  "connect-src": "'self'",
  "base-uri": "'none'",
  "form-action": "'none'",
  "frame-ancestors": "'none'",
});

const serialize = (policy: Record<string, string>): string =>
  Object.entries(policy)
    .map(([name, value]) => `${name} ${value}`)
    .join("; ");

export const productionCsp = serialize(directives("'self'"));
export const developmentCsp = serialize(directives(`'self' 'nonce-${devNonce}'`));
