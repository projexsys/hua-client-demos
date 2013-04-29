/* ------- DEPENDENCIES ------- */

var cheerio = require("cheerio"),
    fs      = require("fs"),
    HTTP    = require("q-io/http"),
    jsdom   = require("jsdom"),
    Q       = require("q"),
    url     = require("url");

var jquery = fs.readFileSync("./jquery-2.0.0.js").toString();

/* ------- HELPERS ------- */

function huaGet(url, jsdomCallback) {
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

function huaGet2(url, cheerioCallback) {
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

function resolveURL(window, toURL) {
    return url.resolve(window.location.href, toURL);
}

function resolveURL2(baseURL, toURL) {
    return url.resolve(baseURL, toURL);
}

function logCallback(stepNum) {
    console.log("\n*** callback #" + stepNum + " ***\n");
}

function logError(err) {
    console.log("ERROR!!!  message: ", err.message);
}

/* ------- SELECTOR ALIASES ------- */

var aliases = {

    class: {

        "colls": ".hua-collections",

        "items": ".hua-items"

    },

    rel: {

        "addr-space": "a[rel~='http://projexsys.com/hyperua/rel/address-space']",

        "app-sess": "a[rel~='http://projexsys.com/hyperua/rel/application-session']"

    }

};

var classes = aliases.class,
    rels    = aliases.rel;

var huaOpts = "";

// var huaOpts = "?style=false&breadcrumbs=false&navbar=false&pretty=false";

/* ------- APPLICATION ------- */

var entryURL = "http://hua-demo.projexsys.com:3000/api/",
    stepCnt  = 0;

console.time("toggle-valve");

huaGet2(

    entryURL + huaOpts,

    // function step1(window, $) {
    //     logCallback(++stepCnt);
    //     console.log(window.location.href);
    //     return function transform() {
    //         var sessColl = $(classes["colls"] + " " + rels["app-sess"])[0];
    //         return resolveURL(window, sessColl.getAttribute("href"));
    //     }();
    // }

    function step1(baseURL, $) {
        logCallback(++stepCnt);
        console.log(baseURL);
        return function transform() {
            var sessColl = $(classes["colls"] + " " + rels["app-sess"])[0];
            return resolveURL2(baseURL, sessColl.attribs.href);

        }();
    }

).then(

    function step2(result) {

        logCallback(++stepCnt);

        console.log(result);

        // return huaGet(
        //     result + huaOpts,
        //     function transform(window, $) {
        //         var kepSess = $(classes["items"] + " " + rels["app-sess"])
        //                 .filter(function (idx) {
        //                     return this.innerHTML.indexOf("KepwareSession") !== -1;
        //                 })[0];
        //         return resolveURL(window, kepSess.getAttribute("href"));
        //     }            
        // );

        return huaGet2(
            result + huaOpts,
            function transform(baseURL, $) {
                var kepSess = $(classes["items"] + " " + rels["app-sess"])
                        .filter(function (idx) {
                            return $(this).text().indexOf("KepwareSession") !== -1;
                        })[0];
                return resolveURL2(baseURL, kepSess.attribs.href);
            }
        );

    }

).then(

    function step3(result) {

        logCallback(++stepCnt);

        console.log(result);

        // return huaGet(
        //     result,
        //     function transform(window, $) {
        //         var addrSpace = $(classes["colls"] + " " + rels["addr-space"])[0];
        //         return resolveURL(window, addrSpace.getAttribute("href"));
        //     }
        // );

        return huaGet2(
            result + huaOpts,
            function transform(baseURL, $) {
                var addrSpace = $(classes["colls"] + " " + rels["addr-space"])[0];
                return resolveURL2(baseURL, addrSpace.attribs.href);
            }
        );

    }

).then (

    function step4(result) {

        logCallback(++stepCnt);

        console.log(result);

    }

).then(

    function end(result) {
        console.log("\n*** completed in " + stepCnt + " steps ***\n");
    },

    logError

).done(function () {

    console.timeEnd("toggle-valve");

});
