const jwt = require('jsonwebtoken');
const { Sequelize, DataTypes, Model, DatabaseError } = require('sequelize');
const { NotFoundString, NotFoundError: NotFound } = require('../errors');
const { hash } = require('../hash');

class Storages extends Model {
}

async function init() {
    Storages.init({
        type: {
            type: DataTypes.STRING,
            allowNull: false
        },
        name: {
            type: DataTypes.STRING,
            allowNull: false
        },
        data: {
            type: DataTypes.ARRAY(DataTypes.NUMBER),
            allowNull: false
        },
        Hash: {
            type: DataTypes.STRING,
            allowNull: false
        },
        UUID: {
            type: DataTypes.UUID,
            defaultValue: Sequelize.UUIDV4,
            primaryKey: true
        }
    }, {
        sequelize: global.database.getSequelize(),
        schema: "storage",
        modelName: 'Storages'
    });
    await Storages.sync({});
}

async function CreateStorage(type, name, data) {
    await init();
    const storage = await Storages.create({
        type: type,
        name: name,
        data: data,
        Hash: hash(data)
    });
    return storage.toJSON();
}

async function GetStorage(UUID) {
    await init();
    try {
        const Storage = await Storages.findByPk(UUID);
        let StorageJson = Storage.toJSON();
        delete StorageJson.data;
        return StorageJson;
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

async function DownloadStorage(UUID, res) {
    await init();
    try {
        const Storage = await Storages.findByPk(UUID);
        return res.contentType(Storage.type).attachment(Storage.name).send(Storage.data);
    } catch (error) {
        if (error instanceof DatabaseError) {
            return NotFound(res);
        } else {
            throw error;
        }
    }
}

module.exports = { CreateStorage, GetStorage, DownloadStorage }