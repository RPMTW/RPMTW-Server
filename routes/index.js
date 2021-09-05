const router = require('express').Router();

router.get('/', (req, res) => {
    res.json({
        message: "Hello RPMTW World",
    }).status(200);
})

module.exports = router;