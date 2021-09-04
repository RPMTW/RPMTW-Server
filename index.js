const express = require('express');
const cors = require("cors");
const app = express();

app
  .use(cors())
  .get('/', (req, res) => {
    res.json({
      message:"Hello RPMTW World",
      code: 200
    })
  });

app.listen(3000, () => {
  console.log('RPMWiki Server Started');
});