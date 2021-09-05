/* 根路徑 /wiki */
const router = require('express').Router();

router.get("/", function (req, res) {
    res.json({
        message: "wiki",
        code: 200
    }).status(200)
});

function init(db) {
    router.db = db
    return router
}
module.exports = init;