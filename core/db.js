const {
    Sequelize
} = require('sequelize');

const sequelize = new Sequelize({
    host: process.env['dataBaseHost'] || "127.0.0.1",
    port: process.env['dataBasePort'] || 3306,
    username: process.env['dataBaseUser'] || "root",
    password: process.env['dataBasePassword'],
    dialect: 'postgres',
    logging: (...msg) => {
        // 紀錄 sql 日誌
        console.log(msg);
    },
})

class start {

}