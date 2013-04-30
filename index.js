/* ------- DEPENDENCIES ------- */

var HTTP = require("q-io/http"),
    Q    = require("q");
S    = require("string");

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

var steps = [

    function step1(result) {

        console.time(timeLabel);

        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {
                var sessColl = $(classes["colls"] + " " + rels["app-sess"]).first();

                return resolveURL(baseURL, sessColl.attr("href"));
            }

        );
    },

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
    },

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
    },

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
    },

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
    },

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
    },

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
    },

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
    },

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
    },

    function step10(result) {
        logCallback(++stepCnt);

        // expecting result to be: { url: ..., value: ... }

        console.log(result.url + "\n");
        console.log("OutputValve value: ", result.value);

        return huaGetJsdom(

            result.url + huaOpts,

            function transform(window, $) {
                var form       = $("form").first(),
                    inputValue = $("#value");

                if (result.value === "true") {
                    inputValue.val("false");
                } else {
                    inputValue.val("true");
                }

                var formData   = form.serialize(),
                    formURL    = resolveURL(window, form.attr("action")),
                    formType   = form.attr("enctype") || "application/x-www-form-urlencoded",
                    formMethod = form.attr("method");

                var reqObj = HTTP.normalizeRequest({
                    url: formURL
                });

                reqObj.body   = [formData];
                reqObj.method = formMethod;

                reqObj.headers["Content-Type"] = formType;

                return HTTP.request(reqObj)
                    .then(

                        function (respObj) {
                            // HyperUA always redirects after a successful POST
                            if (respObj.status !== 303) {
                                throw new Error("HTTP POST to HyperUA failed");
                            }

                            var headers = respObj.headers,
                                redirectURL = headers.location;

                            return resolveURL(formURL, redirectURL);
                        }

                    );
            }
        );
    },

    function step11(result) {
        logCallback(++stepCnt);

        console.log(result);

        return huaGet(

            result + huaOpts,

            function transform(baseURL, $) {
                var valveValue = $(classes["node-val"]).text();

                return {
                    value : S(valveValue).trim().s
                };
            }
        );
    },

    function step12(result) {
        logCallback(++stepCnt);

        // expecting result to be: { url: ..., value: ... }

        console.log("OutputValve toggled to value: ", result.value);
    }

];

steps
    .reduce(Q.when, Q.resolve(entryURL))

    .then(

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
