class storage {
    constructor(sequelize) {
        this.sequelize = sequelize;

        let storages = require('./storages');

        this.storage = new storages(this.sequelize);
    }
}

module.exports = storage