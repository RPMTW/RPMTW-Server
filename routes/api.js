const router = require('express').Router();

router.get("/", function (req, res) {
  res.json({
    message: "welcome to RPMTW Wiki API",
    code: 200
  }).status(200)
});

module.exports = router;