const { text } = require("body-parser");
const express = require("express");
const http = require("http");
const { stringify } = require("querystring");
const socketIo = require("socket.io");
import { v4 as uuidv4 } from "uuid";


const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*", // Allow all origins
  },
});

io.on("connection", (socket) => {
  console.log("Client connesso");

  socket.on("sendMessage", (data) => {
    console.log(data);
    var messaggio = {
      author: {
        firstName: 'Server', 
        lastName: 'test',
        id : '656e2427-991f-4cc4-bb52-406e0b98bd4b'
      },
      text: data.text,
      id: uuidv4,
      createdAt: Date.now()
    }
    io.emit("messageServer", messaggio) // Send message to all connected clients
  });

  socket.on("disconnect", () => {
    console.log("client disconnesso");
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, "192.168.101.9", () => {
  console.log("Server in ascolto alla porta: " + PORT);
});
