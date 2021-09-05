const router = require('express').Router();

router.get("/", function (req, res) {
  res.render("index.html", );
});

router.get("/ip", function (req, res) {
  res.send(req.headers['x-forwarded-for'] || req.connection.remoteAddress);
})

module.exports = router;