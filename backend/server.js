const express = require("express");
const http = require("http");
const socketIo = require("socket.io");
const { v4: uuidv4 } = require("uuid");

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
    if (!socket.rooms.has(room)) {
      socket.join(room);
      console.log(`Client joined room ${room}`);
    }
  });

  socket.on("sendMessage", (data) => {
    const messaggio = {
      author: {
        firstName: data.author.firstName,
        lastName: data.author.lastName,
        id: data.author.id,
      },
      text: data.text,
      id: uuidv4(),
      createdAt: Date.now(),
      roomId: data.roomId,
    };

    const messaggio1 = JSON.stringify(messaggio);
    console.log(messaggio1);

    socket.to(data.roomId).emit("messageServer", messaggio1);
  });

  socket.on("disconnect", () => {
    console.log("client disconnesso");
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, "192.168.1.118", () => {
  console.log("Server in ascolto alla porta: " + PORT);
});
