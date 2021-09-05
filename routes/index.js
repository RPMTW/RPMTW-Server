const router = require('express').Router();

router.get("/", function (req, res) {
  res.render("index.html");
});

router.get("/ip", function (req, res) {
  res.json({
    ip: req.headers['x-forwarded-for'] || req.connection.remoteAddress,
    code: 200
  }).status(200)
})

module.exports = router;