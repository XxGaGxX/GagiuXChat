var express = require("express")
var app = express();
const bodyParser = require('body-parser');
var port = 3000

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

// app.post('/', (req, res) => {
//     console.log(req.body) //visualizza il json su terminale
// })

app.listen(port, () => {
    console.log("Ascolto sulla porta " + port)
});

app.post("/submit", (req, res) => {
  console.log(req.body);
  const response = {    //creo il messaggio risposta che verra inviato al client quando quest'ultimo invierà qualcosa
    message: "Messaggio ricevuto",
    status: "success",
    data: req.body,
  };
  res.json(response);
});