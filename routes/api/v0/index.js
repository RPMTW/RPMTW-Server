/* 根路徑 /v1 */
const router = require('express').Router();

function init(expansion) {
    return Object.assign(router, expansion)
        .get("/", (req, res) => res.json({
            version: "v0 (test)",
            code: 200
        }))
        .use("/test", require('./test')(router.expansion))
}
module.exports = init;