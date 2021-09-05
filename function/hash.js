const crypto = require('crypto');

function hash(data) {
    if (data instanceof String) {
        return crypto.createHash('md5').update(data).digest('hex');
    } else {
        return crypto.createHash('md5').update(data).digest('hex');
    }
}

exports.hash = hash;