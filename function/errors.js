const NotFoundString = 'Not Found';

function ParameterError(res) {
  return res.status(400).json({
    message: 'Parameter Error',
  });
}

function TokenExpiredError(res) {
  return res.status(403.17).json({
    message: 'TokenExpired',
  });
}

function UnauthorizedError(res) {
  return res.status(401).json({
    message: 'Unauthorized',
  });
}

function NotFoundError(res) {
  return res.status(404).json({
    message: NotFoundString,
  });
}

module.exports = {ParameterError, NotFoundError, NotFoundString, TokenExpiredError, UnauthorizedError};
