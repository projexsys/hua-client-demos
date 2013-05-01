/* ------- DEPENDENCIES ------- */

var cheerio = require("cheerio"),
    fs      = require("fs"),
    HTTP    = require("q-io/http"),
    jsdom   = require("jsdom"),
    Q       = require("q"),
    url     = require("url");

var jquery = fs.readFileSync("./jquery-2.0.0.js").toString();

/* ------- EXPORTS ------- */

function huaGetJsdom(url, jsdomCallback) {
    var deferred = Q.defer();
    HTTP.read(url).then(
        function succ(body) {
            jsdom.env({
                html: body,
                src: [jquery],
                url: url,
                done: function (errors, window) {
                    if (errors) {
                        var e = new Error("jsdom errors");
                        e.errors = errors;
                        deferred.reject(e);
                    } else {
                        deferred.resolve(jsdomCallback(window, window.$));
                    }
                }
            });            
        },
        function fail(response) {
            var e = new Error("HTTP error");
            e.response = response;
            deferred.reject(e);
        }
    );
    return deferred.promise;
}

exports.huaGetJsdom = huaGetJsdom;

function huaGetCheerio(url, cheerioCallback) {
    var deferred = Q.defer();
    HTTP.read(url).then(
        function succ(body) {
            var $ = cheerio.load(body);
            deferred.resolve(cheerioCallback(url, $));
        },
        function fail(response) {
            var e = new Error("HTTP error");
            e.response = response;
            deferred.reject(e);
        }
    );
    return deferred.promise;
}

exports.huaGet = exports.huaGetCheerio = huaGetCheerio;

function makeStep(fn) {
    return function (result) {
        var state = result.state,
            value = result.value;

        var incStepCnt = state.stepCnt + 1;
        logCallback(incStepCnt);

        var newState = {};
        newState.stepCnt = incStepCnt;

        var timeLabel = "\nStep #" + newState.stepCnt + " completed in";
        console.time(timeLabel);

        value = fn(value);

        if (Q.isPromise(value)) {
            return value.then(
                function (result) {
                    console.timeEnd(timeLabel);
                    return {
                        state: newState,
                        value: result
                    };
                }
            );
        } else {
            console.log();
            console.timeEnd(timeLabel);
            return {
                state: newState,
                value: value
            };
        }
    };
}

exports.makeStep = makeStep;

function makeGetStep(transform) {
    return makeStep(
        function step(url) {
            console.log("GET", url);
            return huaGetCheerio(
                url,
                transform
            );
        }
    );
}

exports.makeGetStep = makeGetStep;

function resolveURL(windowORurl, toURL) {
    var fromURL;
    if (typeof windowORurl === "object") {
        fromURL = windowORurl.location.href;
    } else {
        fromURL = windowORurl;
    }
    return url.resolve(fromURL, toURL);
}

exports.resolveURL = resolveURL;

function logCallback(stepNum) {
    console.log("\n*** Step #" + stepNum + " ***\n");
}

exports.logCallback = logCallback;

function logError(err) {
    console.log("\nERROR!!! message: ", err.message, "\n");
}

exports.logError = logError;
