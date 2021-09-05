let errorMsg = {
    Parameter: "Parameter Error",
    NotFound: "Not Found"
}

let errors = {
    msg: errorMsg,
    Parameter: res => res.json({
        message: errorMsg.Parameter
    }).status(400),
    NotFound: res => res.json({
        message: errorMsg.NotFound
    }).status(404),
}
module.exports = errors