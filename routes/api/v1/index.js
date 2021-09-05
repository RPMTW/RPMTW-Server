/* 根路徑 /v1 */
const router = require('express').Router();

router
    .get("/", (req, res) => res.json({
        version: "v1",
        code: 200
    }))
    .use("/auth", require('./auth')(router.expansion))
    .use("/wiki", require('./wiki')(router.expansion))

function init(expansion) {
    return Object.assign(router, expansion)
}
module.exports = init;