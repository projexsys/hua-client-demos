/* ------- HELPERS ------- */

var helpers     = require("./helpers.js"),
    huaGet      = helpers.huaGet,
    resolveURL  = helpers.resolveURL,
    logCallback = helpers.logCallback,
    logError    = helpers.logError;

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

/* ------- APPLICATION ------- */

var entryURL = "http://hua-demo.projexsys.com:3000/api/",
    stepCnt  = 0;

var huaOpts = "";
// var huaOpts = "?style=false&breadcrumbs=false&navbar=false&pretty=false";

console.time("toggle-valve");

huaGet(

    entryURL + huaOpts,

    function step1(baseURL, $) {

        logCallback(++stepCnt);

        console.log(baseURL);

        return function transform() {

            var sessColl = $(classes["colls"] + " " + rels["app-sess"])[0];

            return resolveURL(baseURL, sessColl.attribs.href);
        }();
    }

).then(

    function step2(result) {

        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {

                var kepSess = $(classes["items"] + " " + rels["app-sess"])
                        .filter(function (idx) {
                            return $(this).text().indexOf("KepwareSession") !== -1;
                        })[0];

                return resolveURL(baseURL, kepSess.attribs.href);
            }
        );
    }

).then(

    function step3(result) {

        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {

                var addrSpace = $(classes["colls"] + " " + rels["addr-space"])[0];

                return resolveURL(baseURL, addrSpace.attribs.href);
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

).done(

    function () {

        console.timeEnd("toggle-valve");
    }

);
