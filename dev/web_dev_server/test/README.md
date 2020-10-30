# Puppeteer Tests

These tests are running in GitHub Actions using the latest Ubuntu (currently v18.04).

Unfortunately, since the tests are using (x,y) coordinates for targeting individual components, and Puppeteer lays things out differently depending on the host, tests can fail on different platforms.

Tests are running using mocha and Puppeteer. They're executed in a browser with a set window & viewport size (i.e. 1280x800), and measurements have been taken using xScope. 

## Running the tests

```shell
npm install
npm test
```

## Debugging if tests are failing

If tests are failing, it's possible that a component has changed position, but it's also possible that it's being misplaced on the screen. 

First, try running tests in headful mode:
```javascript
browser = await puppeteer.launch({
    headless: false,
    args: [
        `--window-size=${options.width},${options.height}`
    ]
});
```

If tests are working on the current machine, but failing on GitHub actions, there might be a difference between the two platforms Chromium is running on. There are two possibilities here:

1. Install the platform (e.g. Ubuntu 18.04) in a VM, and run the tests in headful mode.
2. Use Puppeteer screenshots and take measurements from there.

    Uncomment all `page.screenshot({ path: ... })` lines in `puppeteer.js`.

    Set the steps in `puppeteer.yml` to be:
    ```yaml
    steps:
    - uses: actions/checkout@v2
    - name: Use Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v1
      with:
        node-version: ${{ matrix.node-version }}
    - run: mkdir screenshot
    - run: npm ci
    - run: npm test
    - name: Archive production artifacts
      uses: actions/upload-artifact@v2
      with:
        name: screenshots
        path: screenshot/
    ```
    This'll set GitHub actions to output all the screenshots at the end of its run. 

    Measurements can be taken from the screenshots directly, to see if something differs.

