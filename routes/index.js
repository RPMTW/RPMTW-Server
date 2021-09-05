const router = require('express').Router();

router.get("/", function (req, res) {
  console.log(req.headers['x-forwarded-for'] || req.connection.remoteAddress);
  res.render("index.html", );
});

module.exports = router;