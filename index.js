const express = require('express');
const cors = require('cors');
const app = express();
const { Sequelize } = require('sequelize');
const router = require('./routes');
const authRouter = require('./routes/auth');
const { RateLimiterMemory } = require('rate-limiter-flexible');
const storageRouter = require('./routes/storage');
const { VerifyToken } = require('./function/auth/Users');
const DataBase = require('./core/dataBase');
require('dotenv').config();

const rateLimiter = new RateLimiterMemory({ points: 3, duration: 1, blockDuration: 60 });

const sequelize = new Sequelize({
    host: process.env['dataBaseHost'],
    port: process.env['dataBasePort'],
    username: 'postgres',
    password: process.env['dataBasePassword'],
    database: 'data',
    dialect: 'postgres',
    logging: (...msg) => {
        //紀錄SQL日誌
        // console.log(msg);
    },
});

run();

async function run() {
    try {
        await sequelize.authenticate();
        global.database = new DataBase(sequelize);
        await sequelize.showAllSchemas().then(Schemas => {
            console.log(Schemas);
            if (!Schemas.every(Schema => Schema === 'auth')) {
                sequelize.createSchema('auth');
            }
            if (!Schemas.every(Schema => Schema === 'storage')) {
                sequelize.createSchema('storage');
            }
        });
        console.log('連接資料庫成功');
    } catch (error) {
        console.error('連接資料庫失敗：', error);
    }

    try {
        var init = function (req, res, next) {
            rateLimiter.consume(req.ip).then(() => {
                console.log(`new user: ${req.ip}`)
                next();
            }).catch(() => {
                return res.status(429).json({
                    message: 'Too Many Requests',
                });
            });
        };

        app.use(cors()).use(init).use(VerifyToken)
            .use("/", router)
            .use("/auth", authRouter())
            .use("/storage", storageRouter())
            .use(function (req, res, next) {
                res.json({
                    message: "Not Found"
                }).status(404);
            }).use(function (err, req, res, next) {
                console.error(err);
                res.json({
                    message: "Internal Server Error"
                }).status(500);
            });;

        app.listen(process.env['apiPort'], () => {
            console.log('RPMWiki Server Started');
        });

    } catch (error) {
        console.error('API發生未知錯誤:', error);
    }


}

module.exports = {
    sequelize
};