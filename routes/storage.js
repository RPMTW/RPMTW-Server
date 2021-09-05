var router = require('express').Router();
const { ParameterError } = require('../function/errors');
const multer = require('multer');
const { CreateStorage, GetStorage, DownloadStorage } = require('../function/storage/Storages');
const upload = multer({});

function storageRouter(sequelize) {
    router.post('/create', upload.single('file'), async (req, res) => {
        try {
            let file = req.file;
            if (file == undefined) {
                return ParameterError(res);
            }
            return res.json(await CreateStorage(sequelize, file.mimetype, file.originalname, file.buffer)).status(200);
        } catch (error) {
            return ParameterError(res);
        }
    });
    router.get('/:uuid', async (req, res) => {
        let UUID = req.params.uuid;
        try {
            return res.json(await GetStorage(sequelize, UUID)).status(200);
        } catch (error) {
            return ParameterError(res);
        }
    });
    router.get('/download/:uuid', async (req, res) => {
        let UUID = req.params.uuid;
        try {
            return await DownloadStorage(sequelize, UUID, res)
        } catch (error) {
            return ParameterError(res);
        }
    });
    return router;
}

module.exports = storageRouter;