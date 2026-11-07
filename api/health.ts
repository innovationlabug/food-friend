import type { VercelRequest, VercelResponse } from '@vercel/node';

/**
 * Health check endpoint for Vercel Serverless Functions proxy.
 * Verifies that the serverless runtime is active without exposing any secret keys.
 */
export default function handler(req: VercelRequest, res: VercelResponse) {
  // Never expose process.env.GEMINI_API_KEY in response payloads
  const isKeyConfigured = Boolean(process.env.GEMINI_API_KEY);

  return res.status(200).json({
    status: 'ok',
    service: 'food-friend-proxy',
    configured: isKeyConfigured,
    timestamp: new Date().toISOString(),
  });
}

