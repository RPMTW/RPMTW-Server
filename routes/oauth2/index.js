/* 根路徑 /oauth2 */
const router = require('express').Router();
const oauth2 = require('../../core/oauth2')
const tokes = require('../../env');

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
      if (req.query.code)
        fetch(`https://rear-end.a102009102009.repl.co/discord/oauth/auth?code=${req.query.code}`, {
          method: "GET",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded"
          },
        }).then(d => {
          console.log(d);
          return d.json()
        }).then(json => {
          res.json(json)
        }).catch(error => console.log(error))
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