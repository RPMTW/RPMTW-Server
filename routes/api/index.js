/* 根路徑 /api */
const router = require('express').Router();

router.use("/v1", require('./v1'))

router.get("/", function (req, res) {
    res.json({
        message: "welcome to RPMTW Wiki API",
        code: 200
    }).status(200)
});

module.exports = router;