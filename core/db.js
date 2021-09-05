/*
    製作 by: 菘菘; 修改: 猴子
    我沒試過部要問我可不可以用
*/
const {
    Sequelize,
    DataTypes,
    Model
} = require('sequelize');
const jwt = require('jsonwebtoken');

class db {
    constructor() {
        /* this.sequelize = new Sequelize({
            host: process.env['dataBaseHost'] || "127.0.0.1",
            port: process.env['dataBasePort'] || 3306,
            username: process.env['dataBaseUser'] || "root",
            password: process.env['dataBasePassword'] || "",
            logging: (...msg) => {
                // 紀錄 sql 日誌
                console.log(msg);
            },
            database: 'guild',
            dialect: 'postgres',
        }); */
    }
}
module.exports = db