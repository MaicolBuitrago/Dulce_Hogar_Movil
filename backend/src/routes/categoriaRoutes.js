import express from "express";
import { supabase } from "../config/db.js";

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
    res.status(500).json({ message: "Error al obtener categorías" });
  }
});

// ─────────────────────────────────────────
// GET /api/categorias/:idcategoria/productos
// ─────────────────────────────────────────
router.get("/:idcategoria/productos", async (req, res) => {
  const { idcategoria } = req.params;
  
  const idCat = parseInt(idcategoria, 10);
  
  if (isNaN(idCat)) {
    return res.status(400).json({ message: "ID de categoría inválido" });
  }

  try {
    const { data: categoria, error: catError } = await supabase
      .from("categoria")
      .select("idcategoria, descripcionCategoria")
      .eq("idcategoria", idCat)
      .single();
      
    if (catError || !categoria) {
      return res.status(404).json({ message: "Categoría no encontrada" });
    }

    const { data: productos, error } = await supabase
      .from("producto")
      .select(`
        idproducto, nombre, precio, stock, descripcion,
        idcategoria, activo,
        producto_imagen (url)
      `)
      .eq("idcategoria", idCat)
      .eq("activo", true)
      .order("nombre", { ascending: true });

    if (error) throw error;

    const resultado = (productos || []).map((p) => ({
      idproducto: p.idproducto,
      nombre: p.nombre,
      precio: p.precio,
      stock: p.stock,
      descripcion: p.descripcion,
      idcategoria: p.idcategoria,
      imagenes: p.producto_imagen?.map((img) => img.url) ?? [],
      activo: p.activo,
    }));

    res.status(200).json(resultado);
  } catch (err) {
    console.error("❌ Error al obtener productos por categoría:", err);
    res.status(500).json({ message: "Error al obtener productos" });
  }
});

export default router;