const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false, slowMo: 500 });
  const page = await browser.newPage();
  
  console.log('Navigating to http://localhost:65196/#/login');
  await page.goto('http://localhost:65196/#/login');
  
  // Wait for the page to load
  await page.waitForTimeout(3000);
  
  console.log('Filling username...');
  // Adjust these selectors as per Flutter's semantic DOM. 
  // Flutter web apps using canvaskit can be tricky. We might need to click by coordinates or use semantic labels if accessibility is enabled.
  // We'll just try to type or click using basic selectors first.
  
  // A naive attempt to click first text field and type
  try {
    await page.keyboard.press('Tab');
    await page.keyboard.type('teststudent');
    await page.keyboard.press('Tab');
    await page.keyboard.type('12345');
    await page.keyboard.press('Enter');
    
    await page.waitForTimeout(5000);
    console.log('Done!');
  } catch (e) {
    console.error(e);
  }
  
  await browser.close();
})();
