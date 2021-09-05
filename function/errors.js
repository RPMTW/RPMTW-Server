const NotFoundString = "Not Found";

function ParameterError(res) {
    return res.json({
        message: "Parameter Error"
    }).status(400);
}


function NotFoundError(res) {
    return res.json({
        message: NotFoundString
    }).status(404);
}

module.exports = { ParameterError, NotFound: NotFoundError, NotFoundString };