/* 根路徑 /wiki */
const router = require('express').Router();

router.get("/", function (req, res) {
    res.json({
        message: "wiki",
        code: 200
    }).status(200)
});

function init(expansion) {
    return Object.assign(router, expansion)
}
module.exports = init;