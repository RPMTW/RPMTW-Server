const { CreateUser, GetUser, GetUserByUUID } = require('../function/auth/Users');
var router = require('express').Router();
const bodyParser = require('body-parser');
const { ParameterError } = require('../function/errors');

function authRouter(sequelize) {
    router.post('/user/create', bodyParser.json(), async (req, res) => {
        let data = req.body;
        try {
            return res.json(await CreateUser(data.UserName, data.Email, data.Password, data.AvatarStorageUUID));
        } catch (error) {
            return ParameterError(res);
        }
    });
    router.get('/user/:uuid', async (req, res) => {
        let UUID = req.params.uuid;
        try {
            return await GetUserByUUID(res, UUID);
        } catch (error) {
            return ParameterError(res);
        }
    });
    router.get('/user', async (req, res) => {
        try {
            return res.json(await GetUser(req));
        } catch (error) {
            return ParameterError(res);
        }
    });
    return router;
}

module.exports = authRouter;