const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  await page.goto('https://studycenter.nanoprojectdevindonesia.com/login');
  await page.fill('input[name="login"]', 'teststudent');
  await page.fill('input[name="password"]', '12345');
  await page.click('button[type="submit"]');
  
  await page.waitForTimeout(3000);
  await page.goto('https://studycenter.nanoprojectdevindonesia.com/jurnal');
  await page.waitForTimeout(2000);
  
  const html = await page.content();
  fs.writeFileSync('jurnal_web.html', html);
  
  await browser.close();
})();
