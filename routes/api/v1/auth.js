/* 根路徑 /auth */
const router = require('express').Router();

/* 用戶類 */
router.post("/user/create", function (req, res) {
    /* 創建帳號 */
});

router.get("/user/@me", function (req, res) {
    /* 獲取用戶資料 */
    res.json({
        method: "get"
    })
}).post("/user/@me", function (req, res) {
    /* 修改用戶資料 */
    res.json({
        method: "post"
    })
}).delete("/user/@me", function (req, res) {
    /* 刪除帳戶 */
    res.json({
        method: "delete"
    })
})

function init(expansion) {
    return Object.assign(router, expansion)
}
module.exports = init;