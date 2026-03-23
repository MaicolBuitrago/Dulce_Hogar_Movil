import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import cookieParser from "cookie-parser";

import router from "../routes/router.js";
import authRoutes from "../routes/authRoutes.js";
import mercadopagoRoutes from "../routes/mercadopagoRoutes.js";
import { supabase } from "./db.js";

dotenv.config();

const app = express();

const ALLOWED_ORIGINS = [
  "http://localhost:8080",
  "http://localhost:49763",
  "http://localhost:5173",
  "https://dulce-hogar.vercel.app",
  "https://dulce-hogar-f8krtsn9m-maicols-projects-da38a8a3.vercel.app",
];

app.use(cors({
  origin: (origin, callback) => {
    if (
      !origin ||
      ALLOWED_ORIGINS.includes(origin) ||
      origin.endsWith(".ngrok-free.app") ||
      origin.endsWith(".ngrok-free.dev") ||
      origin.endsWith(".vercel.app")
    ) {
      callback(null, true);
    } else {
      callback(new Error(`CORS bloqueado: ${origin}`));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Accept", "Cookie", "Authorization", "ngrok-skip-browser-warning"],
}));

app.options("*", (req, res) => res.sendStatus(204));

app.use(cookieParser());
app.use(express.json());

app.use((req, res, next) => {
  req.supabase = supabase;
  next();
});

app.use("/api/auth", express.json(), authRoutes);
app.use("/api/mercadopago", express.json(), mercadopagoRoutes);
app.use("/api", router);

const PORT = process.env.PORT || 4000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Servidor corriendo en http://0.0.0.0:${PORT}`);
});