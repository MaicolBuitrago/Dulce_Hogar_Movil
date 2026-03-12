// src/routes/favoritosRoutes.js
import express from "express";
import { supabase } from "../config/db.js";
import { verificarToken } from "../controller/authMiddleware.js";

const router = express.Router();

// Todas las rutas de favoritos requieren token
router.use(verificarToken);

// ─────────────────────────────────────────
// GET /api/favoritos
// ─────────────────────────────────────────
router.get("/", async (req, res) => {
  const cedula = req.usuario.id;

  try {
    const { data: favoritosData, error } = await supabase
      .from("favoritoproducto")
      .select(`
        idfavorito,
        fechaagregado,
        producto:producto (
          idproducto, nombre, precio, descripcion, stock
        )
      `)
      .eq("cedula", cedula)
      .order("fechaagregado", { ascending: false });

    if (error) throw error;

    if (!favoritosData || favoritosData.length === 0) {
      return res.status(200).json([]);
    }

    const productosIds = favoritosData
      .map((f) => f.producto?.idproducto)
      .filter((id) => id != null);

    const { data: imagenesData, error: errorImagenes } = await supabase
      .from("producto_imagen")
      .select("idproducto, url")
      .in("idproducto", productosIds);

    if (errorImagenes) throw errorImagenes;

    // Agrupar imágenes por producto
    const imagenesPorProducto = {};
    (imagenesData || []).forEach((img) => {
      if (!imagenesPorProducto[img.idproducto]) {
        imagenesPorProducto[img.idproducto] = [];
      }
      imagenesPorProducto[img.idproducto].push(img.url);
    });

    const favoritos = favoritosData.map((f) => ({
      idfavorito: f.idfavorito,
      fechaagregado: f.fechaagregado,
      idproducto: f.producto?.idproducto,
      nombre: f.producto?.nombre,
      precio: f.producto?.precio,
      descripcion: f.producto?.descripcion,
      stock: f.producto?.stock,
      imagenes: imagenesPorProducto[f.producto?.idproducto] || [],
      imagen: imagenesPorProducto[f.producto?.idproducto]?.[0] || null,
    }));

    res.status(200).json(favoritos);
  } catch (error) {
    console.error("❌ Error al obtener favoritos:", error.message);
    res.status(500).json({ message: "Error al obtener favoritos" });
  }
});

// ─────────────────────────────────────────
// POST /api/favoritos
// ─────────────────────────────────────────
router.post("/", async (req, res) => {
  const { idproducto } = req.body;
  const cedula = req.usuario.id;

  if (!idproducto) {
    return res.status(400).json({ message: "Falta el id del producto." });
  }

  try {
    // Verificar que el producto existe
    const { data: productoExiste, error: errorProducto } = await supabase
      .from("producto")
      .select("idproducto")
      .eq("idproducto", idproducto)
      .maybeSingle();

    if (errorProducto) throw errorProducto;
    if (!productoExiste) {
      return res.status(404).json({ message: `No existe un producto con el ID ${idproducto}.` });
    }

    // Verificar si ya está en favoritos
    const { data: existe, error: errorExiste } = await supabase
      .from("favoritoproducto")
      .select("idfavorito")
      .eq("cedula", cedula)
      .eq("idproducto", idproducto)
      .maybeSingle();

    if (errorExiste) throw errorExiste;
    if (existe) {
      return res.status(400).json({ message: "El producto ya está en favoritos." });
    }

    const { data: insertado, error: insertError } = await supabase
      .from("favoritoproducto")
      .insert([{
        fechaagregado: new Date().toISOString(),
        cedula,
        idproducto,
      }])
      .select()
      .single();

    if (insertError) throw insertError;

    res.status(201).json({
      message: "Producto agregado a favoritos correctamente.",
      favorito: insertado,
    });
  } catch (error) {
    console.error("❌ Error al agregar favorito:", error.message);
    res.status(500).json({ message: "Error interno al agregar favorito." });
  }
});

// ─────────────────────────────────────────
// DELETE /api/favoritos/:idproducto
// ─────────────────────────────────────────
router.delete("/:idproducto", async (req, res) => {
  const { idproducto } = req.params;
  const cedula = req.usuario.id;

  try {
    const { data, error } = await supabase
      .from("favoritoproducto")
      .delete()
      .eq("cedula", cedula)
      .eq("idproducto", idproducto)
      .select("*");

    if (error) throw error;

    if (!data || data.length === 0) {
      return res.status(404).json({ message: "El producto no estaba en favoritos." });
    }

    res.status(200).json({ message: "Producto eliminado de favoritos correctamente." });
  } catch (error) {
    console.error("❌ Error al eliminar favorito:", error.message);
    res.status(500).json({ message: "Error al eliminar favorito" });
  }
});

export default router;
