const { CreateUser } = require('../function/auth/Users');
var router = require('express').Router();
const bodyParser = require('body-parser');

function authRouter(sequelize) {
    router.post('/user/create', bodyParser.json(), async (req, res) => {
        let data = req.body;
        try {
            return res.json(await CreateUser(sequelize, data.UserName, data.Email, data.Password)).status(200);
        } catch (error) {
            return res.json({
                message: "Parameter Error"
            }).status(400);
        }
    });
    return router;
}

module.exports = authRouter;