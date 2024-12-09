const express = require("express");
const http = require("http");
const socketIo = require("socket.io");

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
    io.emit("message", data); // Send message to all connected clients
  });

  socket.on("disconnection", () => {
    console.log("client disconnesso");
  });
});

const PORT = process.env.PORT || 4500;
server.listen(PORT, "192.168.101.9", () => {
  console.log("Server in ascolto alla porta: " + PORT);
});
