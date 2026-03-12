// src/routes/direccionRoutes.js
import express from "express";
import { supabase } from "../config/db.js";
import { verificarToken } from "../controller/authMiddleware.js";

const router = express.Router();

// Todas las rutas de direcciones requieren token
router.use(verificarToken);

// ─────────────────────────────────────────
// GET /api/direcciones  →  Listar direcciones del usuario
// ─────────────────────────────────────────
router.get("/", async (req, res) => {
  const cedula = req.usuario.id;

  try {
    const { data, error } = await supabase
      .from("direccionentrega")
      .select("iddireccion, direccion")
      .eq("cedula", cedula)
      .order("iddireccion", { ascending: true });

    if (error) throw error;

    res.status(200).json(data || []);
  } catch (error) {
    console.error("❌ Error al obtener direcciones:", error.message);
    res.status(500).json({ message: "Error al obtener direcciones" });
  }
});

// ─────────────────────────────────────────
// POST /api/direcciones  →  Agregar dirección
// ─────────────────────────────────────────
router.post("/", async (req, res) => {
  const cedula = req.usuario.id;
  const { direccion } = req.body;

  if (!direccion || !direccion.trim()) {
    return res.status(400).json({ message: "La dirección es obligatoria." });
  }

  try {
    const { data, error } = await supabase
      .from("direccionentrega")
      .insert([{ cedula, direccion: direccion.trim() }])
      .select("iddireccion, direccion")
      .single();

    if (error) throw error;

    res.status(201).json({
      message: "Dirección agregada correctamente.",
      direccion: data,
    });
  } catch (error) {
    console.error("❌ Error al agregar dirección:", error.message);
    res.status(500).json({ message: "Error al agregar dirección" });
  }
});

// ─────────────────────────────────────────
// PUT /api/direcciones/:id  →  Editar dirección
// ─────────────────────────────────────────
router.put("/:id", async (req, res) => {
  const cedula = req.usuario.id;
  const { id } = req.params;
  const { direccion } = req.body;

  if (!direccion || !direccion.trim()) {
    return res.status(400).json({ message: "La dirección es obligatoria." });
  }

  try {
    // Verificar que la dirección pertenece al usuario
    const { data: existente, error: errorExiste } = await supabase
      .from("direccionentrega")
      .select("iddireccion")
      .eq("iddireccion", id)
      .eq("cedula", cedula)
      .maybeSingle();

    if (errorExiste) throw errorExiste;
    if (!existente) {
      return res.status(404).json({ message: "Dirección no encontrada." });
    }

    const { data, error } = await supabase
      .from("direccionentrega")
      .update({ direccion: direccion.trim() })
      .eq("iddireccion", id)
      .eq("cedula", cedula)
      .select("iddireccion, direccion")
      .single();

    if (error) throw error;

    res.status(200).json({
      message: "Dirección actualizada correctamente.",
      direccion: data,
    });
  } catch (error) {
    console.error("❌ Error al editar dirección:", error.message);
    res.status(500).json({ message: "Error al editar dirección" });
  }
});

// ─────────────────────────────────────────
// DELETE /api/direcciones/:id  →  Eliminar dirección
// ─────────────────────────────────────────
router.delete("/:id", async (req, res) => {
  const cedula = req.usuario.id;
  const { id } = req.params;

  try {
    // Verificar que la dirección pertenece al usuario
    const { data: existente, error: errorExiste } = await supabase
      .from("direccionentrega")
      .select("iddireccion")
      .eq("iddireccion", id)
      .eq("cedula", cedula)
      .maybeSingle();

    if (errorExiste) throw errorExiste;
    if (!existente) {
      return res.status(404).json({ message: "Dirección no encontrada." });
    }

    // Verificar que no esté en uso por un pedido activo
    const { data: pedidoActivo, error: errorPedido } = await supabase
      .from("pedido")
      .select("idpedido")
      .eq("iddireccion", id)
      .in("idestadopedido", [1, 2, 3]) // pendiente, pagado, en camino
      .maybeSingle();

    if (errorPedido) throw errorPedido;
    if (pedidoActivo) {
      return res.status(409).json({
        message: "No puedes eliminar esta dirección porque tiene un pedido activo asociado.",
      });
    }

    const { error } = await supabase
      .from("direccionentrega")
      .delete()
      .eq("iddireccion", id)
      .eq("cedula", cedula);

    if (error) throw error;

    res.status(200).json({ message: "Dirección eliminada correctamente." });
  } catch (error) {
    console.error("❌ Error al eliminar dirección:", error.message);
    res.status(500).json({ message: "Error al eliminar dirección" });
  }
});

export default router;
