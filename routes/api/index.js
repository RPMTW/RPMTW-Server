/* 根路徑 /api */
const router = require('express').Router();
const rateLimit = require('express-rate-limit')

let limiter = rateLimit({
    windowMs: 1 * 60 * 1e3,
    max: 100,
    message: "請求過多，請稍後在試",
    statusCode: 429,
})

router
    .use(limiter)
    .use("/v1", require('./v1'))

router.get("/", function (req, res) {
    res.json({
        message: "welcome to RPMTW Wiki API",
        code: 200
    }).status(200)
});

module.exports = router;