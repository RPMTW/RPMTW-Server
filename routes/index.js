const router = require('express').Router();

router.get('/', (req, res) => {
  res.json({
    message: 'Hello RPMTW World',
  }).status(200);
});

router.get('/ip', function(req, res) {
  res.json({
    ip: req.ip.replace('::ffff:', '') || req.socket.remoteAddress,
  }).status(200);
});

module.exports = router;
