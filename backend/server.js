var express = require("express")
var app = express();
var port = 3000
// spedizione del messaggio nella porta local host
app.get("/",(req,res) => {
    res.send("Hello World")
})
// Ascolto
app.listen(port, () => {
    console.log("Server in ascolto alla porta" + port)
})