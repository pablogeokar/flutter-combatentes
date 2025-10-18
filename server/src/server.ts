import express from "express";
import http from "http";
import { WebSocketServer } from "ws";
import { GameSessionManager } from "./websocket/GameSessionManager.js";

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const PORT = process.env.PORT || 8082;

// Inicializar o gerenciador de sessões de jogo
const gameSessionManager = new GameSessionManager();

// Configurar WebSocket
wss.on("connection", (ws) => {
  gameSessionManager.handleNewConnection(ws);
});

// Iniciar servidor
server.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("Recebido SIGTERM, fechando servidor...");
  server.close(() => {
    console.log("Servidor fechado.");
    process.exit(0);
  });
});

process.on("SIGINT", () => {
  console.log("Recebido SIGINT, fechando servidor...");
  server.close(() => {
    console.log("Servidor fechado.");
    process.exit(0);
  });
});
