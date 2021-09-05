const tokes = require('../env');
const fetch = require("node-fetch");

module.exports = {
    getDiscordToken: (code, res) => {
        /* 抓取 discord Token */
        fetch("https://discord.com/api/oauth2/token?" + `client_secret=${tokes.discord.client_secret}&redirect_uri=${tokes.discord.redirect_uri}&client_id=${tokes.discord.client_id}&grant_type=authorization_code&scope=identify&code=${code}`, {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            }
        }).then(d => d.json()).then(json => {
            res.json(json)
        })
    }
}