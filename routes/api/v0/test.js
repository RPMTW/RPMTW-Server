/* 根路徑 /wiki */
var router = require('express').Router();

function init(expansion) {
    return Object.assign(router, expansion)
        .get("/", function (req, res) {
            res.json({
                message: "test",
                code: 200
            }).status(200)
        })

        .get("/error/404", function (req, res) {
            return router.error.NotFoundString(res)
        })
        .get("/error/400", function (req, res) {
            return router.error.Parameter(res)
        })
}
module.exports = init;