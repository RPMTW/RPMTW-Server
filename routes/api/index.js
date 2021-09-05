/* 根路徑 /api */
const router = require('express').Router();
const rateLimit = require('express-rate-limit')

router
    /* 請球限制 2 * 60s => 80 次 */
    .use(rateLimit({
        message: "請求過多，請稍後在試",
        windowMs: 2 * 60 * 1e3,
        max: 80,
        statusCode: 429,
    }))
    .use("/v1", require('./v1'))

router.get("/", function (req, res) {
    res.json({
        message: "welcome to RPMTW Wiki API",
        code: 200
    }).status(200)
});

module.exports = router;