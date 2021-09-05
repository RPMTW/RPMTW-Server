/* 根路徑 /wiki */
const router = require('express').Router();

function init(expansion) {
    return Object.assign(router, expansion)
        .get("/", function (req, res) {
            res.json({
                message: "wiki",
                code: 200
            }).status(200)
        });
}
module.exports = init;