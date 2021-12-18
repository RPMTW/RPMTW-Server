const router = require('express').Router();
const {ParameterError} = require('../function/errors');
const multer = require('multer');
const {CreateStorage, GetStorage, DownloadStorage} = require('../function/storage/Storages');
const upload = multer({limits: {fileSize: 10000000}}); // 限制最大檔案大小為10MB

function storageRouter() {
  router.post('/create', upload.single('file'), async (req, res) => {
    try {
      const file = req.file;
      if (file == undefined) {
        return ParameterError(res);
      }
      return res.json(await CreateStorage(file.mimetype, file.originalname, file.buffer)).status(200);
    } catch (error) {
      return ParameterError(res);
    }
  });
  router.get('/:uuid', async (req, res) => {
    const UUID = req.params.uuid;
    try {
      return res.json(await GetStorage(UUID)).status(200);
    } catch (error) {
      return ParameterError(res);
    }
  });
  router.get('/download/:uuid', async (req, res) => {
    const UUID = req.params.uuid;
    try {
      return await DownloadStorage(UUID, res);
    } catch (error) {
      return ParameterError(res);
    }
  });
  return router;
}

module.exports = storageRouter;
