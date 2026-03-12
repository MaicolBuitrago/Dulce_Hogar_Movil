// src/routes/categoriaRoutes.js
import express from "express";
import { supabase } from "../config/db.js";
import { supabase as supabaseDB } from "../config/supabase.js";

const router = express.Router();

// ─────────────────────────────────────────
// GET /api/categorias
// ─────────────────────────────────────────
router.get("/", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("categoria")
      .select("idcategoria, descripcionCategoria")
      .order("descripcionCategoria", { ascending: true });

    if (error) throw error;

    res.status(200).json(data);
  } catch (err) {
    console.error("❌ Error al obtener categorías:", err.message);
    res.status(500).json({ message: "Error al obtener categorías", error: err.message });
  }
});

// ─────────────────────────────────────────
// POST /api/categorias
// ─────────────────────────────────────────
router.post("/", async (req, res) => {
  try {
    const { descripcionCategoria } = req.body;

    if (!descripcionCategoria || !descripcionCategoria.trim()) {
      return res.status(400).json({ message: "La descripción de la categoría es obligatoria" });
    }

    const { data, error } = await supabase
      .from("categoria")
      .insert([{ descripcionCategoria: descripcionCategoria.trim() }])
      .select("idcategoria, descripcionCategoria")
      .single();

    if (error) throw error;

    res.status(201).json(data);
  } catch (err) {
    console.error("❌ Error al crear categoría:", err.message);
    res.status(500).json({ message: "Error al crear categoría", error: err.message });
  }
});

// ─────────────────────────────────────────
// GET /api/categorias/:idcategoria/productos
// ─────────────────────────────────────────
router.get("/:idcategoria/productos", async (req, res) => {
  const { idcategoria } = req.params;

  try {
    const { data, error } = await supabaseDB
      .from("producto")
      .select(`
        idproducto, nombre, precio, stock, descripcion,
        idcategoria, activo,
        producto_imagen (url)
      `)
      .eq("idcategoria", idcategoria)
      .eq("activo", true)
      .order("nombre", { ascending: true });

    if (error) throw error;

    const productos = (data || []).map((p) => ({
      idproducto: p.idproducto,
      nombre: p.nombre,
      precio: p.precio,
      stock: p.stock,
      descripcion: p.descripcion,
      idcategoria: p.idcategoria,
      producto_imagen: p.producto_imagen || [],
      activo: p.activo,
    }));

    res.status(200).json(productos);
  } catch (err) {
    console.error("❌ Error al obtener productos por categoría:", err);
    res.status(500).json({ message: "Error al obtener productos" });
  }
});

// ─────────────────────────────────────────
// GET /api/marcas
// ─────────────────────────────────────────
router.get("/marcas/lista", async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("marca")
      .select("idmarca, descripcionMarca");

    if (error) throw error;

    res.status(200).json(data);
  } catch (err) {
    console.error("❌ Error al obtener marcas:", err.message);
    res.status(500).json({ message: "Error al obtener marcas", error: err.message });
  }
});

// ─────────────────────────────────────────
// POST /api/marcas
// ─────────────────────────────────────────
router.post("/marcas", async (req, res) => {
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
    res.status(500).json({ message: "Error al crear marca", error: err.message });
  }
});

export default router;
