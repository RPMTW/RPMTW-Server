class DataBase {
    constructor(sequelize) {
        this.sequelize = sequelize;
    }

    getSequelize() {
        return this.sequelize;
    }
}

module.exports = DataBase