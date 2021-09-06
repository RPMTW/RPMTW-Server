const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const engine = require('consolidate');
require('dotenv').config();
const {
  Sequelize
} = require('sequelize');

const db = require('./core/db');

const app = express();

let expansion = {
  // 沒辦法測試的我 >_<
  /* new db(new Sequelize({
    host: process.env['dataBaseHost'] || "127.0.0.1",
    port: process.env['dataBasePort'] || 3306,
    username: 'postgres',
    password: process.env['dataBasePassword'],
    database: 'data',
    dialect: 'postgres',
    logging: (...msg) => {
      //紀錄SQL日誌
      console.log(msg);
    },
  })) */
  db: db,
};

expansion = Object.assign(expansion, {
  expansion: expansion
})

app
  .use(function (req, res, next) {
    console.log(req.headers['x-forwarded-for'] || req.connection.remoteAddress, req.method, req.path);
    next();
  })
  .use(require("cors")())
  .engine('html', engine.swig)
  .set("views", path.join(__dirname, "views"))
  .set("view engine", "html")

  .use(express.static(path.join(__dirname, "public")))

  .use("/", require("./routes/index.js")(expansion))

  .use(logger("dev"))
  .use(express.json())
  .use(express.urlencoded({
    extended: false
  }))
  .use(cookieParser())
  .use(function (req, res, next) {
    /* get 404 error */
    next(createError(404))
  })
  .use(function (err, req, res, next) {
    /* error handler */
    res.locals.message = err.message;
    res.locals.error = req.app.get("env") === "development" ? err : {};

    res.status(err.status || 500);
    console.log(err.status || 500);
    res.render("error");
  })

module.exports = app;