const jwt = require('jsonwebtoken');
const {DataTypes, Model, DatabaseError, UUIDV4} = require('sequelize');
const {NotFoundString, NotFoundError, TokenExpiredError, UnauthorizedError} = require('../errors');
const {hash} = require('../hash');

class User extends Model {
  static async Init() {
    super.init({
      userName: {
        type: DataTypes.STRING,
        allowNull: false,
      },
      email: {
        type: DataTypes.STRING,
        allowNull: false,
      },
      password: {
        type: DataTypes.STRING,
        allowNull: false,
        set(value) {
          this.setDataValue('password', hash(this.userName + value));
        },
      },
      UUID: {
        type: DataTypes.UUIDV4,
        defaultValue: UUIDV4,
        primaryKey: true,
      },
      avatarStorageUUID: {
        type: DataTypes.STRING,
        allowNull: false,
      },
      avatarUrl: {
        type: DataTypes.VIRTUAL,
        get() {
          return `https://${process.env['dataBaseHost']}:${process.env['apiPort']}/storage/download/${this.avatarStorageUUID}`;
        },
        set(value) {
          throw new Error('不要嘗試設定 `avatarUrl` 的值!');
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
    delete userJson.password;
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
    delete userJson.password;
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


function generateToken(userName, UUID) {
  const token = jwt.sign({
    UserName: userName,
    UUID: UUID,
    iat: Math.floor(Date.now() / 1000) - 30,
  }, process.env['tokenPrivateKey'], {expiresIn: '30days'});
  return token;
}

const verifyToken = async function(req, res, next) {
  try {
    await User.Init();
    const data = jwt.verify(getTokenHeader(req), process.env['tokenPrivateKey']);
    req.user = await User.findByPk(data.UUID);
    return next();
  } catch (error) {
    if (req.url == '/auth/user/create') {
      return next();
    } else if (error instanceof jwt.TokenExpiredError) {// 憑證過期
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
