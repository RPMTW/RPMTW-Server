const { CreateUser } = require('../function/auth/Users');
var router = require('express').Router();

function authRouter(sequelize) {
    router.get('/user/create', async (req, res) => {
        res.json(await CreateUser(sequelize, "teaaast", "teaaaast", "test")).status(200);
    });
    return router;
}


module.exports = authRouter;