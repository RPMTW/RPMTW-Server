/* 根路徑 /wiki */
const error = require('../../../core/errors')
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
            return error.NotFound(res)
        })
        .get("/error/400", function (req, res) {
            return error.Parameter(res)
        })
}
module.exports = init;