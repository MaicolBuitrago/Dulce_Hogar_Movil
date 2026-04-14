import express from "express";
import { supabase } from "../config/db.js";

const router = express.Router();

// ─────────────────────────────────────────
// GET /api/marcas
// ─────────────────────────────────────────
router.get("/", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("marca")
      .select("idmarca, descripcionMarca")
      .order("descripcionMarca", { ascending: true });

    if (error) throw error;

    res.status(200).json(data);
  } catch (err) {
    console.error("❌ Error al obtener marcas:", err.message);
    res.status(500).json({ message: "Error al obtener marcas" });
  }
});

// ─────────────────────────────────────────
// POST /api/marcas
// ─────────────────────────────────────────
router.post("/", async (req, res) => {
  try {
    const { descripcionMarca } = req.body;

    if (!descripcionMarca || !descripcionMarca.trim()) {
      return res.status(400).json({ message: "La descripción de la marca es obligatoria" });
    }

    const { data, error } = await supabase
      .from("marca")
      .insert([{ descripcionMarca: descripcionMarca.trim() }])
      .select("idmarca, descripcionMarca")
      .single();

    if (error) throw error;

    res.status(201).json(data);
  } catch (err) {
    console.error("❌ Error al crear marca:", err.message);
    res.status(500).json({ message: "Error al crear marca" });
  }
});

export default router;