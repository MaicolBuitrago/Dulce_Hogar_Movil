// src/routes/authRoutes.js
import express from "express";
import {
  enviarCorreoRecuperacion,
  restablecerContrasena,
} from "../controller/authController.js";

const router = express.Router();

// POST /api/auth/recuperar
router.post("/recuperar", enviarCorreoRecuperacion);

// POST /api/auth/restablecer
router.post("/restablecer", restablecerContrasena);

export default router;
