import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import cookieParser from "cookie-parser";
import helmet from "helmet";
import rateLimit from "express-rate-limit";

import router from "../routes/router.js";
import authRoutes from "../routes/authRoutes.js";
import mercadopagoRoutes from "../routes/mercadopagoRoutes.js";
import { supabase } from "./db.js";

dotenv.config();

const app = express();

app.set("trust proxy", 1);

// ══════════════════════════════════════════════════
// 1. HELMET — cabeceras HTTP de seguridad
// ══════════════════════════════════════════════════
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
    contentSecurityPolicy: false,
  })
);

// ══════════════════════════════════════════════════
// 2. CORS — solo orígenes permitidos
// ══════════════════════════════════════════════════
const ALLOWED_ORIGINS = [
  "http://localhost:8080",
  "http://localhost:49763",
  "http://localhost:5173",
  "https://dulce-hogar.vercel.app",
  "https://dulce-hogar-backend.vercel.app",
  "https://dulce-hogar-f8krtsn9m-maicols-projects-da38a8a3.vercel.app",
];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);

      if (
        ALLOWED_ORIGINS.includes(origin) ||
        origin.endsWith(".ngrok-free.app") ||
        origin.endsWith(".ngrok-free.dev") ||
        origin.endsWith(".vercel.app")
      ) {
        return callback(null, true);
      }
      return callback(new Error(`CORS bloqueado: ${origin}`));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: [
      "Content-Type",
      "Accept",
      "Cookie",
      "Authorization",
      "ngrok-skip-browser-warning",
    ],
  })
);

app.options("*", (req, res) => res.sendStatus(204));

// ══════════════════════════════════════════════════
// 3. RATE LIMIT GLOBAL
// ══════════════════════════════════════════════════
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Demasiadas peticiones, intenta más tarde." },
});

// ══════════════════════════════════════════════════
// 4. RATE LIMIT ESTRICTO — /api/login y /api/auth/*
// ══════════════════════════════════════════════════
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    message:
      "Demasiados intentos de inicio de sesión. Espera 15 minutos antes de volver a intentarlo.",
  },
});

// ══════════════════════════════════════════════════
// 5. PARSERS
// ══════════════════════════════════════════════════
app.use(cookieParser());
app.use(express.json({ limit: "2mb" }));

// ══════════════════════════════════════════════════
// 6. Inyectar cliente supabase en req
// ══════════════════════════════════════════════════
app.use((req, res, next) => {
  req.supabase = supabase;
  next();
});

// ══════════════════════════════════════════════════
// 7. RUTAS
// ══════════════════════════════════════════════════
app.use("/api/auth", authLimiter, express.json(), authRoutes);
app.use("/api/mercadopago", express.json(), mercadopagoRoutes);
app.use("/api", router);
app.use("/api/login", authLimiter);

// ══════════════════════════════════════════════════
// 8. Manejador global de errores
// ══════════════════════════════════════════════════
app.use((err, req, res, next) => {
  console.error("❌ Error no controlado:", err.message);
  res.status(err.status || 500).json({ message: "Error interno del servidor." });
});


const PORT = process.env.PORT || 4000;

// Solo escucha si NO está en Vercel
if (!process.env.VERCEL) {
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`✅ Servidor corriendo en http://0.0.0.0:${PORT}`);
  });
}

export default app;