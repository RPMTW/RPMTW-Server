const router = require('express').Router();

router.get("/", function (req, res) {
  res.send("is users");
});

module.exports = router;