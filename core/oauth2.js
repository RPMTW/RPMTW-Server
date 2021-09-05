const tokes = require('../env');
const fetch = require("node-fetch");
let getDiscordToken = (code, res) => {
    /* 抓取 discord Token */
    fetch(`${sets.discord.API}/oauth2/token`, {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded"
        },
        body: new URLSearchParams({
            client_id: tokes.discord.client_id,
            client_secret: tokes.discord.client_secret,
            grant_type: "authorization_code",
            scope: "identify",
            redirect_uri: tokes.discord.redirect_uri,
            code: code,
        })
    }).then(d => d.json()).then(json => {
        res.json(json)
    }).catch(error => console.log(error))
}
module.exports = {
    getDiscordToken
}