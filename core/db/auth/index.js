class auth {
    constructor(sequelize) {
        this.sequelize = sequelize;

        let User = require('./User');

        this.User = User(this.sequelize);
    }
}

module.exports = auth