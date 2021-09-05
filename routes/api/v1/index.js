/* 根路徑 /v1 */
const router = require('express').Router();

router
    .get("/", (req, res) => res.json({
        version: "v1",
        code: 200
    }))
    .use("/auth", require('./auth'))
    .use("/wiki", require('./wiki'))

module.exports = router;