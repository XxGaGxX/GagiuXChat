const { text, json } = require("body-parser");
const express = require("express");
const http = require("http");
const { stringify } = require("querystring");
const socketIo = require("socket.io");
const { v4: uuidv4 } = require("uuid");
const { execSync } = require('child_process');

let roomID = 'default';
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*", // Allow all origins
  },
});

io.on("connection", (socket) => {
  console.log("Client connesso");
  socket.on("join", (room) => {
    roomID = room
    socket.join(room)
    console.log(`Client joined room ${room}`)
  })

 
  socket.on("sendMessage", (data) => {
    console.log(data.text);
    //console.log("messagio inviato :" + messaggio);


    var messaggio = {
      author: {
        firstName: data.author.firstName,
        lastName: data.author.lastName,
        id: data.author.id,
      },
      text: data.text,
      id: uuidv4(),
      createdAt: Date.now(),
    };

    messaggio = JSON.stringify(messaggio);

    socket.to(roomID).emit("messageServer", messaggio["text"]) // Send message to all connected clients
  });

  socket.on("disconnect", () => {
    console.log("client disconnesso");
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, "192.168.1.118", () => {
  console.log("Server in ascolto alla porta: " + PORT);
});
