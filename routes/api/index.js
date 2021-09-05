/* 根路徑 /api */
const router = require('express').Router();
const {
    RateLimiterMemory
} = require('rate-limiter-flexible')

/* 429 */
let rateLimit = new RateLimiterMemory({
    duration: 60, // 每 60s
    points: 80, // 80次請求
    blockDuration: 60, // 60s 解除
})

// router = router + ((app.js).expansion)
function init(expansion) {
    return Object.assign(router, expansion).use(function (req, res, next) {
            rateLimit.consume(req.headers['x-forwarded-for'] || req.connection.remoteAddress)
                .then(() => next())
                .catch(() => res.json({
                    message: "Too Many Requests!!!",
                    code: 429,
                }).status(429))
        })
        .use("/v0", require('./v0')(router.expansion)) // test 頁面
        .use("/v1", require('./v1')(router.expansion))

        .get("/", function (req, res) {
            console.log(router.expansion);
            res.json({
                message: "welcome to RPMTW Wiki API",
                code: 200
            }).status(200)
        });
}


module.exports = init;