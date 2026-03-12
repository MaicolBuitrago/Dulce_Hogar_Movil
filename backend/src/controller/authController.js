// src/controller/authController.js
import { supabase } from "../config/db.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import brevo from "@getbrevo/brevo";
import dotenv from "dotenv";

dotenv.config();

// Configuración de Brevo
const brevoClient = new brevo.TransactionalEmailsApi();
brevoClient.authentications["apiKey"].apiKey = process.env.BREVO_API_KEY;

/**
 * POST /api/auth/recuperar
 * Envía correo de recuperación de contraseña
 */
export const enviarCorreoRecuperacion = async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: "El correo es obligatorio." });
  }

  try {
    const { data: usuarios, error: userError } = await supabase
      .from("usuario")
      .select("*")
      .eq("email", email)
      .limit(1);

    if (userError) throw userError;
    if (!usuarios || usuarios.length === 0) {
      return res.status(404).json({ message: "Usuario no encontrado" });
    }

    const user = usuarios[0];

    // Token temporal de 1 hora
    const token = jwt.sign(
      { email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${token}`;

    const sendSmtpEmail = new brevo.SendSmtpEmail();
    sendSmtpEmail.sender = {
      name: "Soporte Dulce Hogar",
      email: process.env.EMAIL_FROM,
    };
    sendSmtpEmail.to = [{ email }];
    sendSmtpEmail.subject = "Recuperación de contraseña - Dulce Hogar";
    sendSmtpEmail.htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto;">
        <h2 style="color: #5B8A6E;">Dulce Hogar — Recuperación de contraseña</h2>
        <p>Hola, <strong>${user.nombre || "usuario"}</strong>.</p>
        <p>Haz clic en el siguiente enlace para restablecer tu contraseña:</p>
        <a href="${resetUrl}"
           style="display:inline-block; padding:12px 24px; background:#5B8A6E;
                  color:white; text-decoration:none; border-radius:8px; margin:16px 0;">
          Restablecer contraseña
        </a>
        <p style="color:#888; font-size:13px;">Este enlace expirará en 1 hora.</p>
        <p style="color:#888; font-size:13px;">
          Si no solicitaste este cambio, puedes ignorar este correo.
        </p>
      </div>
    `;

    await brevoClient.sendTransacEmail(sendSmtpEmail);

    res.json({ message: "Correo de recuperación enviado correctamente" });
  } catch (error) {
    console.error("❌ Error al enviar correo:", error);

    if (error.response && error.response.status === 401) {
      return res.status(401).json({
        message: "Error de autenticación con Brevo. Verifica tu BREVO_API_KEY.",
      });
    }

    res.status(500).json({ message: "Error interno del servidor" });
  }
};

/**
 * POST /api/auth/restablecer
 * Restablece la contraseña con el token recibido
 */
export const restablecerContrasena = async (req, res) => {
  const { token, nuevaContrasena } = req.body;

  if (!token || !nuevaContrasena) {
    return res.status(400).json({ message: "Faltan datos requeridos." });
  }

  if (nuevaContrasena.length < 6) {
    return res
      .status(400)
      .json({ message: "La contraseña debe tener al menos 6 caracteres." });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const email = decoded.email;

    if (!email) {
      return res.status(400).json({ message: "Token inválido o sin correo." });
    }

    const hashedPassword = await bcrypt.hash(nuevaContrasena, 10);

    const { error: updateError } = await supabase
      .from("usuario")
      .update({ password: hashedPassword })
      .eq("email", email);

    if (updateError) throw updateError;

    res.json({ message: "Contraseña actualizada correctamente." });
  } catch (error) {
    console.error("❌ Error al restablecer contraseña:", error);
    res.status(400).json({
      message: "Token inválido, expirado o error en el proceso.",
    });
  }
};
