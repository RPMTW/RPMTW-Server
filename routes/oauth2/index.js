/* 根路徑 /oauth2 */
const router = require('express').Router();
const oauth2 = require('../../core/oauth2')

// router = router + ((app.js).expansion)
function init(expansion) {
  return Object.assign(router, expansion)
    .get("/", function (req, res) {
      console.log(router.expansion);
      res.json({
        message: "RPMTW Wiki Oauth2 page",
        code: 200
      }).status(200)
    })
    .get("/discord/callback", function (req, res) {
      /* discord oauth2 callback */
      console.log(req.query.code);
      if (req.query.code) oauth2.getDiscordToken(req.query.code, res)
      else res.json({
        error: "",
        code: 404
      }).status(404)
    })
    .get("/google/callback", function (req, res) {
      /* google oauth2 callback */
    })
    .get("/facebook/callback", function (req, res) {
      /* facebook oauth2 callback */
      req.query.code
    })
}


module.exports = init;