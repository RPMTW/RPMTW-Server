const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const engine = require('consolidate');

const db = require('./core/db');

const app = express();

let expansion = {
  db: new db,
  error: {
    Parameter: e => e.json({
      message: "Parameter Error"
    }).status(400),
    NotFoundString: e => e.json({
      message: e.json("Not Found")
    }).status(404),
    test: "a"
  }
};
expansion.expansion = expansion;

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

  /* routes */
  .use("/", require("./routes/index.js")(expansion))
  .use("/api", require("./routes/api")(expansion))

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
    res.render("error");
  })

module.exports = app;