/* ------- DEPENDENCIES ------- */

var S = require("string");

/* ------- HELPERS ------- */

var helpers     = require("./helpers.js"),
    huaGet      = helpers.huaGet,
    huaGetJsdom = helpers.huaGetJsdom,
    resolveURL  = helpers.resolveURL,
    logCallback = helpers.logCallback,
    logError    = helpers.logError;

/* ------- CSS SELECTOR ALIASES ------- */

var aliases = {

    class: {
        "colls"     : ".hua-collections",
        "items"     : ".hua-items",
        "node-refs" : ".hua-node-references",
        "node-val"  : ".opcua-attr-node-value",
        "services"  : ".hua-services"
    },

    rel: {
        "addr-space" : "a[rel~='http://projexsys.com/hyperua/rel/address-space']",
        "app-sess"   : "a[rel~='http://projexsys.com/hyperua/rel/application-session']",
        "node"       : "a[rel~='http://projexsys.com/hyperua/rel/node']",
        "root-node"  : "a[rel~='http://projexsys.com/hyperua/rel/root-node']",
        "write-svc"  : "a[rel~='http://projexsys.com/hyperua/rel/form-write']"
    }
};

var classes = aliases.class,
    rels    = aliases.rel;

/* ------- APPLICATION ------- */

var entryURL = "http://hua-demo.projexsys.com:3000/api/",
    stepCnt  = 0;

var huaOpts = "";
// var huaOpts = "?style=false&breadcrumbs=false&navbar=false&pretty=false";

var timeLabel = "Elapsed time";

console.time(timeLabel);

huaGet(

    entryURL + huaOpts,

    function step1(baseURL, $) {
        logCallback(++stepCnt);

        console.log(baseURL);

        return function transform() {
            var sessColl = $(classes["colls"] + " " + rels["app-sess"]).first();

            return resolveURL(baseURL, sessColl.attr("href"));
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
                        }).first();

                return resolveURL(baseURL, kepSess.attr("href"));
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
                var addrSpace = $(classes["colls"] + " " + rels["addr-space"]).first();

                return resolveURL(baseURL, addrSpace.attr("href"));
            }
        );
    }

).then (

    function step4(result) {
        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {
                var rootNode = $(classes["node-refs"] + " " + rels["root-node"]).first();

                return resolveURL(baseURL, rootNode.attr("href"));
            }
        );
    }

).then (

    function step5(result) {
        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {
                var objectsNode = $(classes["node-refs"] + " " + rels["node"])
                        .filter(function (idx) {
                            return $(this).text().indexOf("Objects") !== -1;
                        }).first();

                return resolveURL(baseURL, objectsNode.attr("href"));
            }
        );
    }

).then (

    function step6(result) {
        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {
                var intouchNode = $(classes["node-refs"] + " " + rels["node"])
                        .filter(function (idx) {
                            return $(this).text().indexOf("InTouch") !== -1;
                        }).first();

                return resolveURL(baseURL, intouchNode.attr("href"));
            }
        );
    }

).then (

    function step7(result) {
        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {
                var demoFolderNode = $(classes["node-refs"] + " " + rels["node"])
                        .filter(function (idx) {
                            return $(this).text().indexOf("Demo") !== -1;
                        }).first();

                return resolveURL(baseURL, demoFolderNode.attr("href"));
            }
        );
    }

).then (

    function step8(result) {
        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {
                var outputValveNode = $(classes["node-refs"] + " " + rels["node"])
                        .filter(function (idx) {
                            return $(this).text().indexOf("OutputValve") !== -1;
                        }).first();

                return resolveURL(baseURL, outputValveNode.attr("href"));
            }
        );
    }

).then (

    function step9(result) {
        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {
                var writeForm  = $(classes["services"] + " " + rels["write-svc"]).first(),
                    valveValue = $(classes["node-val"]).text();

                return {
                    url   : resolveURL(baseURL, writeForm.attr("href")),
                    value : S(valveValue).trim().s
                };
            }
        );
    }

).then (

    function step10(result) {

        // expecting result to be: { url: ..., value: ... }

        logCallback(++stepCnt);

        console.log(result.url + "\n");
        console.log("OutputValve value:", result.value);

        return huaGetJsdom(

            result.url + huaOpts,

            function transform(window, $) {
                var form       = $("form").first(),
                    inputValue = $("#value");

                inputValue.val("true");

                // next steps: http://stackoverflow.com/questions/6263004/post-a-form-using-jsdom-and-node-js

                return "still working on it...";
            }
        );
    }

).then(

    function step11(result) {
        logCallback(++stepCnt);

        console.log(result);
    }

).then(

    function end(result) {
        console.log("\n*** completed ***\n");
    },

    logError

).done(

    function () {
        console.timeEnd(timeLabel);
        console.log();
    }

);
