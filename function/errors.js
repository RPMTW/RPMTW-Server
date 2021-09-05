const NotFoundString = "Not Found";

function ParameterError(res) {
    return res.status(400).json({
        message: "Parameter Error"
    });
}


function NotFoundError(res) {
    return res.status(400).json({
        message: NotFoundString
    });
}

module.exports = { ParameterError, NotFound: NotFoundError, NotFoundString };