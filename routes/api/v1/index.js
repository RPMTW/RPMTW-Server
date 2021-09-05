/* 根路徑 /v1 */
const router = require('express').Router();

router
    .get("/", (req, res) => res.json({
        version: "v1",
        code: 200
    }))
    .use("/auth", require('./auth')(router.db))
    .use("/wiki", require('./wiki')(router.db))

function init(db) {
    router.db = db
    return router
}
module.exports = init;