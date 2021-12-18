const router = require('express').Router();

router.get('/', (req, res) => {
  res.status(200).json({
    message: 'Hello RPMTW World',
  });
});

router.get('/ip', function(req, res) {
  res.status(200).json({
    ip: req.ip.replace('::ffff:', '') || req.socket.remoteAddress,
  });
});

module.exports = router;
