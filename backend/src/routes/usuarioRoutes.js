import express from "express";
import bcrypt from "bcryptjs";
import rateLimit, { ipKeyGenerator } from "express-rate-limit";
import { supabase } from "../config/db.js";
import {
  verificarToken,
  generarTokens,
  verificarRefreshToken,
} from "../controller/authMiddleware.js";
import dotenv from "dotenv";

dotenv.config();

const router = express.Router();

// ── Rate limit extra para login (se aplica además del authLimiter de server.js)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.body?.email || ipKeyGenerator(req), // bloquear por email + IP (IPv6 safe)
  message: {
    message:
      "Demasiados intentos. Espera 15 minutos antes de intentarlo de nuevo.",
  },
});

// ── Helpers de validación ──────────────────────────────────────────────────
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validarEmail(email) {
  return typeof email === "string" && EMAIL_RE.test(email.trim());
}

function sanitizarTexto(str) {
  if (typeof str !== "string") return "";
  return str.trim().slice(0, 200); // largo máximo, evita payloads gigantes
}

// ─────────────────────────────────────────
// POST /api/usuario  →  Registro
// ─────────────────────────────────────────
router.post("/", async (req, res) => {
  const {
    cedula,
    nombre,
    apellido,
    direccion,
    email,
    ciudad,
    contrasena,
    rol,
  } = req.body;

  // Validaciones básicas
  if (!cedula || !nombre || !email || !contrasena) {
    return res.status(400).json({
      message: "Faltan datos obligatorios (cédula, nombre, email, contraseña).",
    });
  }

  if (!validarEmail(email)) {
    return res.status(400).json({ message: "Formato de correo inválido." });
  }

  // Sanitizar inputs
  const cedulaSan = sanitizarTexto(String(cedula));
  const nombreSan = sanitizarTexto(nombre);
  const apellidoSan = sanitizarTexto(apellido || "");
  const emailSan = email.trim().toLowerCase();

  // No permitir que el cliente asigne rol "administrador"
  const rolFinal = "cliente";

  if (contrasena.length < 6 || contrasena.length > 128) {
    return res.status(400).json({
      message: "La contraseña debe tener entre 6 y 128 caracteres.",
    });
  }

  try {
    const { data: cedulaExistente, error: errorCedula } = await supabase
      .from("usuario")
      .select("cedula")
      .eq("cedula", cedulaSan)
      .limit(1);

    if (errorCedula) throw errorCedula;

    if (cedulaExistente && cedulaExistente.length > 0) {
      return res.status(409).json({ message: "La cédula ya está registrada." });
    }

    // Verificar email duplicado
    const { data: emailExistente } = await supabase
      .from("usuario")
      .select("cedula")
      .eq("email", emailSan)
      .limit(1);

    if (emailExistente && emailExistente.length > 0) {
      return res
        .status(409)
        .json({ message: "El correo ya está registrado. ¿Ya tienes cuenta?" });
    }

    const hashedPassword = await bcrypt.hash(contrasena, 12); // 12 rounds (más seguro)

    const { data, error } = await supabase
      .from("usuario")
      .insert([
        {
          cedula: cedulaSan,
          nombre: nombreSan,
          apellido: apellidoSan,
          direccion: sanitizarTexto(direccion || ""),
          email: emailSan,
          ciudad: sanitizarTexto(ciudad || ""),
          password: hashedPassword,
          rol: rolFinal,
        },
      ])
      .select("cedula, nombre, apellido, email, ciudad, rol")
      .single();

    if (error) throw error;

    res
      .status(201)
      .json({ message: "Usuario registrado correctamente", usuario: data });
  } catch (error) {
    console.error("❌ Error al registrar usuario:", error.message);
    res.status(500).json({ message: "Error al registrar usuario." });
  }
});

// ─────────────────────────────────────────
// POST /api/login  →  Login
// ─────────────────────────────────────────
router.post("/login", loginLimiter, async (req, res) => {
  const { email, contrasena } = req.body;

  if (!email || !contrasena) {
    return res
      .status(400)
      .json({ message: "Correo y contraseña son obligatorios." });
  }

  if (!validarEmail(email)) {
    return res.status(400).json({ message: "Formato de correo inválido." });
  }

  const emailSan = email.trim().toLowerCase();

  try {
    const { data: usuarios, error } = await supabase
      .from("usuario")
      .select("*")
      .eq("email", emailSan)
      .limit(1);

    if (error) throw error;

    // ⚠️ Mensaje genérico — no revelar si el usuario existe o no
    if (!usuarios || usuarios.length === 0) {
      return res
        .status(401)
        .json({ message: "Correo o contraseña incorrectos." });
    }

    const usuario = usuarios[0];

    const validPassword = await bcrypt.compare(contrasena, usuario.password);
    if (!validPassword) {
      return res
        .status(401)
        .json({ message: "Correo o contraseña incorrectos." });
    }

    const payload = { id: usuario.cedula, rol: usuario.rol };
    const { accessToken, refreshToken } = generarTokens(payload);

    // Cookie access token (Web)
    res.cookie("token", accessToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge: 60 * 60 * 1000, // 1 hora
    });

    // Cookie refresh token (Web) — solo httpOnly, no accesible desde JS
    res.cookie("refreshToken", refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 días
    });

    // Body para clientes móviles (Flutter)
    res.status(200).json({
      message: "Inicio de sesión exitoso",
      token: accessToken,
      refreshToken, // Flutter lo guarda con flutter_secure_storage
      expiresIn: 3600, // segundos — el cliente calcula cuándo refrescar
      usuario: {
        cedula: usuario.cedula,
        nombre: usuario.nombre,
        rol: usuario.rol,
      },
    });
  } catch (error) {
    console.error("❌ Error en el login:", error.message);
    res.status(500).json({ message: "Error en el servidor." });
  }
});

// ─────────────────────────────────────────
// POST /api/refresh  →  Renovar access token
// ─────────────────────────────────────────
router.post("/refresh", (req, res) => {
  // Leer refresh token desde cookie (Web) o cuerpo (Flutter)
  const rToken =
    req.cookies?.refreshToken || req.body?.refreshToken || null;

  if (!rToken) {
    return res.status(401).json({
      message: "No hay refresh token. Inicia sesión nuevamente.",
      expired: true,
    });
  }

  const decoded = verificarRefreshToken(rToken);

  if (!decoded) {
    res.clearCookie("token");
    res.clearCookie("refreshToken");
    return res.status(401).json({
      message: "Sesión inválida o expirada. Inicia sesión nuevamente.",
      expired: true,
    });
  }

  const payload = { id: decoded.id, rol: decoded.rol };
  const { accessToken, refreshToken: newRefreshToken } = generarTokens(payload);

  // Renovar cookies (Web)
  res.cookie("token", accessToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 60 * 60 * 1000,
  });
  res.cookie("refreshToken", newRefreshToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 7 * 24 * 60 * 60 * 1000,
  });

  res.status(200).json({
    token: accessToken,
    refreshToken: newRefreshToken,
    expiresIn: 3600,
  });
});

// ─────────────────────────────────────────
// POST /api/logout  →  Cerrar sesión
// ─────────────────────────────────────────
router.post("/logout", (req, res) => {
  res.clearCookie("token");
  res.clearCookie("refreshToken");
  res.status(200).json({ message: "Sesión cerrada correctamente." });
});

// ─────────────────────────────────────────
// GET /api/usuario/perfil  →  Ver perfil
// ─────────────────────────────────────────
router.get("/perfil", verificarToken, async (req, res) => {
  const cedula = req.usuario.id;

  try {
    const { data, error } = await supabase
      .from("usuario")
      .select(
        "cedula, nombre, apellido, direccion, ciudad, email, rol, telefono"
      )
      .eq("cedula", cedula)
      .maybeSingle();

    if (error) throw error;
    if (!data)
      return res.status(404).json({ message: "Usuario no encontrado." });

    res.status(200).json(data);
  } catch (error) {
    console.error("❌ Error al obtener perfil:", error.message);
    res.status(500).json({ message: "Error al obtener perfil." });
  }
});

// ─────────────────────────────────────────
// PUT /api/usuario/perfil  →  Actualizar perfil
// ─────────────────────────────────────────
router.put("/perfil", verificarToken, async (req, res) => {
  const cedula = req.usuario.id;
  const { nombre, apellido, direccion, ciudad, telefono } = req.body;

  if (!nombre || !apellido) {
    return res
      .status(400)
      .json({ message: "Nombre y apellido son obligatorios." });
  }

  try {
    const { data: usuarioExistente, error: errorSelect } = await supabase
      .from("usuario")
      .select("cedula")
      .eq("cedula", cedula)
      .limit(1);

    if (errorSelect) throw errorSelect;

    if (!usuarioExistente || usuarioExistente.length === 0) {
      return res.status(404).json({ message: "Usuario no encontrado." });
    }

    const { data, error } = await supabase
      .from("usuario")
      .update({
        nombre: sanitizarTexto(nombre),
        apellido: sanitizarTexto(apellido),
        direccion: sanitizarTexto(direccion || ""),
        ciudad: sanitizarTexto(ciudad || ""),
        telefono: sanitizarTexto(telefono || ""),
      })
      .eq("cedula", cedula)
      .select(
        "cedula, nombre, apellido, email, direccion, ciudad, rol, telefono"
      )
      .single();

    if (error) throw error;

    res
      .status(200)
      .json({ message: "Perfil actualizado correctamente.", usuario: data });
  } catch (error) {
    console.error("❌ Error al actualizar perfil:", error.message);
    res.status(500).json({ message: "Error al actualizar el perfil." });
  }
});

export default router;