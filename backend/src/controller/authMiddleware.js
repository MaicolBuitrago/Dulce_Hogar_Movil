// src/controller/authMiddleware.js
import jwt from "jsonwebtoken";
import dotenv from "dotenv";

dotenv.config();

/**
 * Middleware que verifica el JWT
 * Puede venir desde:
 * 1. Header Authorization: Bearer TOKEN (Flutter / API)
 * 2. Cookie httpOnly "token" (Web)
 */
export const verificarToken = (req, res, next) => {
  let token = null;

  // 1️⃣ Revisar header Authorization (Flutter)
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    token = authHeader.split(" ")[1];
  }

  // 2️⃣ Si no existe, revisar cookie (Web)
  if (!token && req.cookies?.token) {
    token = req.cookies.token;
  }

  // 3️⃣ Si no hay token
  if (!token) {
    return res.status(401).json({
      message: "No autorizado. Token no encontrado.",
    });
  }

  try {
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || "clave_secreta_segura"
    );

    req.usuario = decoded; // { id: cedula, rol, iat, exp }

    next();
  } catch (error) {
    console.error("❌ Token inválido:", error.message);
    return res.status(403).json({
      message: "Token inválido o expirado.",
    });
  }
};

/**
 * Middleware que verifica que el usuario sea administrador
 */
export const soloAdmin = (req, res, next) => {
  if (!req.usuario || req.usuario.rol !== "administrador") {
    return res.status(403).json({
      message: "Acceso denegado. Se requiere rol de administrador.",
    });
  }
  next();
};