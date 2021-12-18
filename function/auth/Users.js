const jwt = require('jsonwebtoken');
const {Sequelize, DataTypes, Model, DatabaseError} = require('sequelize');
const {NotFoundString, NotFoundError, TokenExpiredError, UnauthorizedError} = require('../errors');
const {hash} = require('../hash');

class User extends Model {
  static async Init() {
    super.init({
      UserName: {
        type: DataTypes.STRING,
        allowNull: false,
      },
      Email: {
        type: DataTypes.STRING,
        allowNull: false,
      },
      Password: {
        type: DataTypes.STRING,
        allowNull: false,
        set(value) {
          this.setDataValue('Password', hash(this.UserName + value));
        },
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
        },
      },
    }, {
      sequelize: global.database.getSequelize(),
      schema: 'auth',
      modelName: 'User',
    });
    await this.sync({});
  }
}

async function createUser(userName, email, password, avatarStorageUUID) {
  const user = await User.create({
    userName: userName,
    email: email,
    password: password,
    avatarStorageUUID: avatarStorageUUID,
  });

  const userJson = user.toJSON();
  delete userJson.Password;

  return {
    token: generateToken(userName, user.UUID),
    user: userJson,
  };
}

async function getUser(req) {
  try {
    const user = req.user;
    const userJson = user.toJSON();
    delete userJson.Password;
    return userJson;
  } catch (error) {
    if (error instanceof DatabaseError) {
      return {
        message: NotFoundString,
      };
    } else {
      throw error;
    }
  }
}

async function getUserByUUID(res, UUID) {
  try {
    await User.Init();
    const user = await User.findOne({where: {UUID: UUID}});
    const userJson = user.toJSON();
    delete userJson.Password;
    return res.json(userJson);
  } catch (error) {
    console.log(error);
    if (error instanceof DatabaseError) {
      return NotFoundError(res);
    } else {
      throw error;
    }
  }
}


function generateToken(UserName, UUID) {
  const token = jwt.sign({
    UserName: UserName,
    UUID: UUID,
    iat: Math.floor(Date.now() / 1000) - 30,
  }, process.env['tokenPrivateKey'], {expiresIn: '30days'});
  return token;
}

const verifyToken = async function(req, res, next) {
  try {
    if (req.url == '/auth/user/create') {
      return next();
    }
    await User.Init();
    const data = jwt.verify(getTokenHeader(req), process.env['tokenPrivateKey']);
    req.user = await User.findByPk(data.UUID);
    return next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {// 憑證過期
      return TokenExpiredError(res);
    } else if (error instanceof jwt.JsonWebTokenError) {// 憑證錯誤
      return UnauthorizedError(res);
    } else {
      throw error;
    }
  }
};

function getTokenHeader(req) {
  return String(req.header('Authorization')).replace('Bearer ', '');
}

module.exports = {createUser, getUser, getUserByUUID, verifyToken};
