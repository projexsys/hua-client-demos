/* ------- DEPENDENCIES ------- */

var HTTP = require("q-io/http"),
    Q    = require("q"),
    S    = require("string");

/* ------- HELPERS ------- */

var helpers     = require("./helpers.js"),
    huaGet      = helpers.huaGet,
    huaGetJsdom = helpers.huaGetJsdom,
    makeStep    = helpers.makeStep,
    makeGetStep = helpers.makeGetStep,
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

var entryURL = "http://hua-demo.projexsys.com:3000/api/";

var steps = [

    makeGetStep(
        function step1(baseURL, $) {
            var sessColl = $(classes["colls"] + " " + rels["app-sess"]).first();

            return resolveURL(baseURL, sessColl.attr("href"));
        }
    ),

    makeGetStep(
        function step2(baseURL, $) {
            var kepSess = $(classes["items"] + " " + rels["app-sess"])
                    .filter(function (idx) {
                        return $(this).text().indexOf("KepwareSession") !== -1;
                    }).first();

            return resolveURL(baseURL, kepSess.attr("href"));
        }
    ),

    makeGetStep(
        function step3(baseURL, $) {
            var addrSpace = $(classes["colls"] + " " + rels["addr-space"]).first();

            return resolveURL(baseURL, addrSpace.attr("href"));
        }
    ),

    makeGetStep(
        function step4(baseURL, $) {
            var rootNode = $(classes["node-refs"] + " " + rels["root-node"]).first();

            return resolveURL(baseURL, rootNode.attr("href"));
        }
    ),

    makeGetStep(
        function step5(baseURL, $) {
            var objectsNode = $(classes["node-refs"] + " " + rels["node"])
                    .filter(function (idx) {
                        return $(this).text().indexOf("Objects") !== -1;
                    }).first();

            return resolveURL(baseURL, objectsNode.attr("href"));
        }
    ),

    makeGetStep(
        function step6(baseURL, $) {
            var intouchNode = $(classes["node-refs"] + " " + rels["node"])
                    .filter(function (idx) {
                        return $(this).text().indexOf("InTouch") !== -1;
                    }).first();

            return resolveURL(baseURL, intouchNode.attr("href"));
        }
    ),

    makeGetStep(
        function step7(baseURL, $) {
            var demoFolderNode = $(classes["node-refs"] + " " + rels["node"])
                    .filter(function (idx) {
                        return $(this).text().indexOf("Demo") !== -1;
                    }).first();

            return resolveURL(baseURL, demoFolderNode.attr("href"));
        }
    ),

    makeGetStep(
        function step8(baseURL, $) {
            var outputValveNode = $(classes["node-refs"] + " " + rels["node"])
                    .filter(function (idx) {
                        return $(this).text().indexOf("OutputValve") !== -1;
                    }).first();

            return resolveURL(baseURL, outputValveNode.attr("href"));
        }
    ),

    makeGetStep(
        function step9(baseURL, $) {
            var writeForm  = $(classes["services"] + " " + rels["write-svc"]).first(),
                valveValue = $(classes["node-val"]).text();

            valveValue = S(valveValue).trim().s;

            console.log("\nOutputValve value:", valveValue);

            return {
                url   : resolveURL(baseURL, writeForm.attr("href")),
                value : valveValue
            };
        }
    ),

    makeStep(
        function step10(result) {
            // expecting result to be: { url: ..., value: ... }
            console.log("GET", result.url);

            return huaGetJsdom(

                result.url,

                function transform(window, $) {
                    var form       = $("form").first(),
                        inputValue = $("#value");

                    if (result.value === "true") {
                        inputValue.val("false");
                    } else if (result.value === "false") {
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

                    return {
                        reqObj  : reqObj,
                        formURL : formURL
                    };
                }
            );
        }
    ),

    makeStep(
        function step11(result) {
            // expecting result to be: { reqObj: ..., formURL: ... }
            var reqObj = result.reqObj,
                formURL = result.formURL;

            console.log("POST", formURL);

            return HTTP.request(reqObj)
                .then(

                    function (respObj) {
                        // HyperUA always redirects after a successful POST
                        if (respObj.status !== 303) {
                            throw new Error("HTTP POST to HyperUA failed");
                        }

                        var headers     = respObj.headers,
                            redirectURL = headers.location;

                        return resolveURL(formURL, redirectURL);
                    }

                );
        }
    ),

    makeGetStep(
        function step12(baseURL, $) {
            var valveValue = $(classes["node-val"]).text();

            valveValue = S(valveValue).trim().s;

            console.log("\nOutputValve toggled to value:", valveValue);
        }
    )

];

var timeLabel = "Total elapsed time";
console.time(timeLabel);

steps
    .reduce(Q.when, Q.resolve({ state: { stepCnt: 0}, value: entryURL }))

    .then(

        function end() {
            console.log("\n*** completed ***\n");
        },

        logError

    ).done(

        function () {
            console.timeEnd(timeLabel);
            console.log();
        }

    );
