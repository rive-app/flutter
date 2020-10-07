const express = require('express');
const fs = require('fs');
const app = express();

app.use("/", function (req, res, next) {
    console.log(req.path);
    const path = '../../packages/editor/build/web'
    var options = {
        root: __dirname + '../../../packages/editor/build/web'
    };
    const pathString = req.path.toString();
    if (pathString.endsWith('.js')) {
        res.type('text/javascript');
    } else if (pathString.endsWith('.html')) {
        res.type('text/html');
    }
    if (fs.existsSync(path + req.path)) {
        res.sendFile(req.path, options, function (err) {
            if (err) {
                next(err);
            } else {
                next();
            }
        });
    } else {
console.log("NO EXIST", path + req.path);
        res.sendFile('/index.html', options, function (err) {
            if (err) {
                next(err);
            } else {
                next();
            }
        });
    }
});

const port = process.env.PORT || 3000;
app.listen(port, function () {
    console.log("web dev listening on port " + port + "!");
});