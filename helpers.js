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

function huaGet(url, cheerioCallback) {
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

exports.huaGet = huaGet;

function resolveURL(windowORurl, toURL) {
    if (typeof windowORurl === "object") {
        return url.resolve(windowORurl.location.href, toURL);
    } else {
        return url.resolve(windowORurl, toURL);
    }
}

exports.resolveURL = resolveURL;

function logCallback(stepNum) {
    console.log("\n*** callback #" + stepNum + " ***\n");
}

exports.logCallback = logCallback;

function logError(err) {
    console.log("ERROR!!!  message: ", err.message);
}

exports.logError = logError;
