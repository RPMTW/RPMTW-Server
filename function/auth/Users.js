const jwt = require('jsonwebtoken');
const { Sequelize, DataTypes, Model, DatabaseError } = require('sequelize');
const { NotFoundString } = require('../errors');
const { hash } = require('../hash');

class User extends Model {

}


async function init(sequelize) {
    User.init({
        UserName: {
            type: DataTypes.STRING,
            allowNull: false
        },
        Email: {
            type: DataTypes.STRING,
            allowNull: false
        },
        Password: {
            type: DataTypes.STRING,
            allowNull: false,
            set(value) {
                this.setDataValue('Password', hash(this.UserName + value));
            }
        },
        UUID: {
            type: DataTypes.UUID,
            defaultValue: Sequelize.UUIDV4,
            primaryKey: true,
        },
        AvatarStorageUUID: {
            type: DataTypes.STRING,
            allowNull: false,
        },
        AvatarUrl: {
            type: DataTypes.VIRTUAL,
            get() {
                return `https://${process.env['dataBaseHost']}:${process.env['apiPort']}/storage/download/${this.AvatarStorageUUID}`;
            },
            set(value) {
                throw new Error('不要嘗試設定 `AvatarUrl` 的值!');
            }
        }
    }, {
        sequelize,
        schema: "auth",
        modelName: 'User'
    });
    await User.sync({});
}


async function CreateUser(sequelize, UserName, Email, Password, AvatarStorageUUID) {
    await init(sequelize);

    const user = await User.create({
        UserName: UserName,
        Email: Email,
        Password: Password,
        AvatarStorageUUID: AvatarStorageUUID,
    });

    let userJson = user.toJSON();
    delete userJson.Password;

    return {
        token: GenerateToken(UserName, Email),
        user: userJson
    };
}

async function GetUser(sequelize, UUID) {
    await init(sequelize);
    try {
        const user = await User.findByPk(UUID);
        let userJson = user.toJSON();
        delete userJson.Password;
        return userJson;
    } catch (error) {
        if (error instanceof DatabaseError) {
            return {
                message: NotFoundString
            };
        } else {
            throw error;
        }
    }
}

function GenerateToken(UserName, UUID) {
    var token = jwt.sign({
        UserName: UserName,
        UUID: UUID,
        iat: Math.floor(Date.now() / 1000) - 30
    }, process.env['tokenPrivateKey'], { expiresIn: '30days' });
    return token;
}

module.exports = {
    CreateUser, GetUser
}