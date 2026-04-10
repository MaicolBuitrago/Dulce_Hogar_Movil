// src/controller/authMiddleware.js
import jwt from "jsonwebtoken";
import dotenv from "dotenv";

dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET + "_refresh";

/**
 * Middleware que verifica el JWT de acceso.
 * Fuentes (por prioridad):
 *  1. Header Authorization: Bearer TOKEN  (Flutter / mobile)
 *  2. Cookie httpOnly "token"             (Web)
 *
 * Devuelve 401 con campo "expired: true" cuando el token expiró,
 * para que el cliente pueda intentar un refresh automático.
 */
export const verificarToken = (req, res, next) => {
  let token = null;

  // 1️⃣  Header Authorization (Flutter)
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    token = authHeader.split(" ")[1];
  }

  // 2️⃣  Cookie httpOnly (Web)
  if (!token && req.cookies?.token) {
    token = req.cookies.token;
  }

  // 3️⃣  Sin token
  if (!token) {
    return res.status(401).json({
      message: "No autorizado. Inicia sesión para continuar.",
      expired: false,
    });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.usuario = decoded; // { id: cedula, rol, iat, exp }
    next();
  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({
        message: "Tu sesión ha expirado. Por favor vuelve a iniciar sesión.",
        expired: true,
      });
    }
    return res.status(403).json({
      message: "Token inválido.",
      expired: false,
    });
  }
};

/**
 * Middleware que verifica que el usuario sea administrador.
 */
export const soloAdmin = (req, res, next) => {
  if (!req.usuario || req.usuario.rol !== "administrador") {
    return res.status(403).json({
      message: "Acceso denegado. Se requiere rol de administrador.",
    });
  }
  next();
};

/**
 * Genera un access token (corta vida) y un refresh token (larga vida).
 */
export const generarTokens = (payload) => {
  const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: "1h" });
  const refreshToken = jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: "7d" });
  return { accessToken, refreshToken };
};

/**
 * Verifica un refresh token.
 * Devuelve el payload decodificado o null si es inválido/expirado.
 */
export const verificarRefreshToken = (token) => {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET);
  } catch {
    return null;
  }
};