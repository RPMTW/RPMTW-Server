class db {
    constructor(sequelize) {
        this.sequelize = sequelize;

        let auth = require('./auth');
        let storage = require('./storage');

        this.auth = new auth(this.sequelize);
        this.storage = new storage(this.sequelize);
    }
}

module.exports = db