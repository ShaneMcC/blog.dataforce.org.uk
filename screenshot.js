#!/usr/bin/env node

function sleep(ms) {
    ms = (ms) ? ms : 0;
    return new Promise(resolve => {setTimeout(resolve, ms);});
}

process.on('uncaughtException', (error) => {
    console.error(error);
    process.exit(1);
});

process.on('unhandledRejection', (reason, p) => {
    console.error(reason, p);
    process.exit(1);
});

const puppeteer = require('puppeteer');

if (!process.argv[2]) {
    console.error('ERROR: no url arg\n');
    process.exit(1);
}

var url = process.argv[2];

var now = new Date();

var dateStr = now.toISOString();

var width = 1280;
var height = 1024;
var delay = 1000;

var isMobile = false;

let filename = `screenshot_${width}_${height}.png`;

(async() => {

    const browser = await puppeteer.launch({
        args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-web-security'
        ]
    });

    const page = await browser.newPage();

    page.setViewport({
        width,
        height,
        isMobile
    });

    await page.goto(url, {waitUntil: 'networkidle2'});

    // Fix Some URLs to be relative not absolute
    await page.evaluate(() => {
        items = document.querySelectorAll('img');
        items.forEach((item) => {
            item.src = item.src.replace('file:///', './');
        });

        items = document.querySelectorAll('link');
        items.forEach((item) => {
            item.href = item.href.replace('file:///', './');
        });

        items = document.querySelectorAll('script');
        items.forEach((item) => {
            item.src = item.src.replace('file:///', './');
        });
    })

    await sleep(delay);

    await page.screenshot({path: `/screenshots/${filename}`, fullPage: false});

    browser.close();

    console.log(
        JSON.stringify({
            date: dateStr,
            timestamp: Math.floor(now.getTime() / 1000),
            filename,
            width,
            height
        })
    );

})();