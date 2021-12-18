const {createUser, GetUser, GetUserByUUID} = require('../function/auth/Users');
const router = require('express').Router();
const bodyParser = require('body-parser');
const {ParameterError} = require('../function/errors');

function authRouter() {
  router.post('/user/create', bodyParser.json(), async (req, res) => {
    const data = req.body;
    try {
      return res.json(await createUser(data.userName, data.email, data.password, data.avatarStorageUUID));
    } catch (error) {
      return ParameterError(res);
    }
  });
  router.get('/user/:uuid', async (req, res) => {
    const UUID = req.params.uuid;
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
