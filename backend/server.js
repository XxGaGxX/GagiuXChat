var express = require("express")
var app = express();
const bodyParser = require('body-parser');
var port = 3000

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

app.post('/submit', (req, res) => {
    console.log(req.body) //visualizza il json su terminale
})
