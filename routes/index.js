/* 根路徑 / */
const router = require('express').Router();

function init(expansion) {
  return Object.assign(router, expansion)
    .get("/ip", function (req, res) {
      res.json({
        ip: (req.headers['x-forwarded-for'] || req.connection.remoteAddress).replace("::ffff:", ""),
        code: 200
      }).status(200)
    })
    .get("/", function (req, res) {
      res.render("index.html");
    });

}
module.exports = init;