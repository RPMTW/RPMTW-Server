const { CreateUser, GetUser } = require('../function/auth/Users');
var router = require('express').Router();
const bodyParser = require('body-parser');
const { ParameterError } = require('../function/errors');

function authRouter(sequelize) {
    router.post('/user/create', bodyParser.json(), async (req, res) => {
        let data = req.body;
        try {
            return res.json(await CreateUser(sequelize, data.UserName, data.Email, data.Password, data.AvatarStorageUUID)).status(200);
        } catch (error) {
            console.log(error);
            return ParameterError(res);
        }
    });
    router.get('/user/:uuid', async (req, res) => {
        let UUID = req.params.uuid;
        try {
            return res.json(await GetUser(sequelize, UUID)).status(200);
        } catch (error) {
            return ParameterError(res);
        }
    });
    return router;
}

module.exports = authRouter;