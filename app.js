const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const engine = require('consolidate');

let app = express();

app
  .engine('html', engine.swig)
  .set("views", path.join(__dirname, "views"))
  .set("view engine", "html")

  .use(express.static(path.join(__dirname, "public")))

  /* routes */
  .use("/", require("./routes/index.js"))
  .use("/users", require("./routes/users.js"))

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