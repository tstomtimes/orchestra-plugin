/**
 * Browser MCP Server
 * Safe browser automation with Playwright for AI-driven development
 *
 * Security features:
 * - Domain allowlist
 * - Operation rate limits
 * - Action logging
 * - Safe mode restrictions
 */

import express, { Request, Response } from 'express';
import { chromium, Browser, Page, BrowserContext } from 'playwright';
import fs from 'fs/promises';
import path from 'path';

const app = express();
app.use(express.json());

// Security configuration
const ALLOWED_DOMAINS = new Set([
  'localhost',
  '127.0.0.1',
  'vercel.app',
  'shopify.com',
  'myshopify.com',
  'sanity.io',
  'sanity.studio',
  'supabase.co',
  'netlify.app',
  'github.io',
  // Add your custom domains from environment
  ...(process.env.BROWSER_ALLOWED_DOMAINS?.split(',').map(d => d.trim()) || [])
]);

// Rate limiting
const operationCounts = new Map<string, { nav: number; click: number; type: number }>();
const MAX_NAV = 10;
const MAX_CLICK = 50;
const MAX_TYPE = 30;

// State
let browser: Browser | null = null;
let context: BrowserContext | null = null;
let page: Page | null = null;
const sessionId = Date.now().toString();

// Artifacts directory
const ARTIFACTS_DIR = path.join(process.cwd(), 'artifacts', 'browser', sessionId);

// Helper: Check if URL is allowed
function isUrlAllowed(url: string): boolean {
  try {
    const hostname = new URL(url).hostname.replace(/^www\./, '');
    return Array.from(ALLOWED_DOMAINS).some(domain =>
      hostname === domain || hostname.endsWith(`.${domain}`)
    );
  } catch {
    return false;
  }
}

// Helper: Check rate limits
function checkRateLimit(sessionId: string, operation: 'nav' | 'click' | 'type'): boolean {
  const counts = operationCounts.get(sessionId) || { nav: 0, click: 0, type: 0 };

  const limits = { nav: MAX_NAV, click: MAX_CLICK, type: MAX_TYPE };
  if (counts[operation] >= limits[operation]) {
    return false;
  }

  counts[operation]++;
  operationCounts.set(sessionId, counts);
  return true;
}

// Helper: Log operation
async function logOperation(operation: string, details: any) {
  await fs.mkdir(ARTIFACTS_DIR, { recursive: true });
  const logPath = path.join(ARTIFACTS_DIR, 'operations.log');
  const logEntry = `${new Date().toISOString()} [${operation}] ${JSON.stringify(details)}\n`;
  await fs.appendFile(logPath, logEntry);
}

// Initialize browser
app.post('/init', async (req: Request, res: Response) => {
  try {
    if (browser) {
      return res.json({ ok: true, message: 'Browser already initialized' });
    }

    browser = await chromium.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-dev-shm-usage']
    });

    context = await browser.newContext({
      ignoreHTTPSErrors: false,
      viewport: { width: 1280, height: 720 },
      userAgent: 'Orchestra-Plugin-Browser/1.0'
    });

    await logOperation('init', { sessionId });
    res.json({ ok: true, sessionId });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Navigate to URL
app.post('/navigate', async (req: Request, res: Response) => {
  try {
    const { url, waitUntil = 'domcontentloaded' } = req.body;

    if (!url) {
      return res.status(400).json({ error: 'URL is required' });
    }

    if (!isUrlAllowed(url)) {
      return res.status(403).json({
        error: 'Domain not allowed',
        allowedDomains: Array.from(ALLOWED_DOMAINS)
      });
    }

    if (!checkRateLimit(sessionId, 'nav')) {
      return res.status(429).json({ error: `Navigation limit (${MAX_NAV}) exceeded` });
    }

    if (!context) {
      return res.status(400).json({ error: 'Browser not initialized. Call /init first' });
    }

    if (!page) {
      page = await context.newPage();
    }

    await page.goto(url, {
      waitUntil: waitUntil as any,
      timeout: 30000
    });

    const finalUrl = page.url();
    const title = await page.title();

    await logOperation('navigate', { url, finalUrl, title });
    res.json({ ok: true, url: finalUrl, title });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Click element
app.post('/click', async (req: Request, res: Response) => {
  try {
    const { selector } = req.body;

    if (!selector) {
      return res.status(400).json({ error: 'Selector is required' });
    }

    if (!page) {
      return res.status(400).json({ error: 'No active page. Navigate first' });
    }

    if (!checkRateLimit(sessionId, 'click')) {
      return res.status(429).json({ error: `Click limit (${MAX_CLICK}) exceeded` });
    }

    await page.click(selector, { timeout: 10000 });
    await logOperation('click', { selector });
    res.json({ ok: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Type text
app.post('/type', async (req: Request, res: Response) => {
  try {
    const { selector, text, pressEnter = false } = req.body;

    if (!selector || !text) {
      return res.status(400).json({ error: 'Selector and text are required' });
    }

    // Security: Block sensitive patterns
    const BLOCKED_PATTERNS = [
      /password/i,
      /credit.*card/i,
      /ssn/i,
      /social.*security/i
    ];

    if (BLOCKED_PATTERNS.some(pattern => pattern.test(text) || pattern.test(selector))) {
      return res.status(403).json({ error: 'Potentially sensitive input blocked' });
    }

    if (!page) {
      return res.status(400).json({ error: 'No active page. Navigate first' });
    }

    if (!checkRateLimit(sessionId, 'type')) {
      return res.status(429).json({ error: `Type limit (${MAX_TYPE}) exceeded` });
    }

    await page.fill(selector, text, { timeout: 10000 });
    if (pressEnter) {
      await page.keyboard.press('Enter');
    }

    await logOperation('type', { selector, textLength: text.length, pressEnter });
    res.json({ ok: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Wait for selector
app.post('/wait', async (req: Request, res: Response) => {
  try {
    const { selector, timeout = 15000 } = req.body;

    if (!selector) {
      return res.status(400).json({ error: 'Selector is required' });
    }

    if (!page) {
      return res.status(400).json({ error: 'No active page. Navigate first' });
    }

    await page.waitForSelector(selector, { timeout });
    await logOperation('wait', { selector });
    res.json({ ok: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Scrape text content
app.post('/scrape', async (req: Request, res: Response) => {
  try {
    const { selector, limit = 50 } = req.body;

    if (!selector) {
      return res.status(400).json({ error: 'Selector is required' });
    }

    if (!page) {
      return res.status(400).json({ error: 'No active page. Navigate first' });
    }

    const data = await page.$$eval(
      selector,
      (elements, limit) => elements
        .map(el => (el as HTMLElement).innerText.trim())
        .filter(text => text.length > 0)
        .slice(0, limit),
      limit
    );

    await logOperation('scrape', { selector, count: data.length });
    res.json({ ok: true, data });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Take screenshot
app.post('/screenshot', async (req: Request, res: Response) => {
  try {
    const { filename = 'screenshot.png', fullPage = false } = req.body;

    if (!page) {
      return res.status(400).json({ error: 'No active page. Navigate first' });
    }

    await fs.mkdir(ARTIFACTS_DIR, { recursive: true });
    const screenshotPath = path.join(ARTIFACTS_DIR, filename);

    await page.screenshot({
      path: screenshotPath,
      fullPage
    });

    await logOperation('screenshot', { path: screenshotPath, fullPage });
    res.json({ ok: true, path: screenshotPath });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get page content
app.post('/content', async (req: Request, res: Response) => {
  try {
    if (!page) {
      return res.status(400).json({ error: 'No active page. Navigate first' });
    }

    const content = await page.content();
    const title = await page.title();
    const url = page.url();

    await logOperation('content', { url, titleLength: title.length });
    res.json({ ok: true, url, title, html: content });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Evaluate JavaScript
app.post('/evaluate', async (req: Request, res: Response) => {
  try {
    const { expression } = req.body;

    if (!expression) {
      return res.status(400).json({ error: 'Expression is required' });
    }

    // Security: Block dangerous operations
    const BLOCKED_KEYWORDS = ['delete', 'drop', 'remove', 'cookie', 'localStorage'];
    if (BLOCKED_KEYWORDS.some(keyword => expression.toLowerCase().includes(keyword))) {
      return res.status(403).json({ error: 'Expression contains blocked keywords' });
    }

    if (!page) {
      return res.status(400).json({ error: 'No active page. Navigate first' });
    }

    const result = await page.evaluate(expression);
    await logOperation('evaluate', { expression: expression.substring(0, 100) });
    res.json({ ok: true, result });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Close browser
app.post('/close', async (req: Request, res: Response) => {
  try {
    if (page) {
      await page.close();
      page = null;
    }
    if (context) {
      await context.close();
      context = null;
    }
    if (browser) {
      await browser.close();
      browser = null;
    }

    await logOperation('close', { sessionId });
    operationCounts.delete(sessionId);
    res.json({ ok: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({
    ok: true,
    browser: browser !== null,
    page: page !== null,
    sessionId,
    allowedDomains: Array.from(ALLOWED_DOMAINS)
  });
});

const PORT = process.env.BROWSER_MCP_PORT || 3030;

app.listen(PORT, () => {
  console.log(`🌐 Browser MCP Server running on port ${PORT}`);
  console.log(`📁 Artifacts directory: ${ARTIFACTS_DIR}`);
  console.log(`🔒 Allowed domains: ${Array.from(ALLOWED_DOMAINS).join(', ')}`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down browser...');
  if (browser) {
    await browser.close();
  }
  process.exit(0);
});
