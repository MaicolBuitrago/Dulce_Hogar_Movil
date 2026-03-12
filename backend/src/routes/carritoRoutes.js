// src/routes/carritoRoutes.js
import express from "express";
import { supabase } from "../config/db.js";
import { verificarToken } from "../controller/authMiddleware.js";

const router = express.Router();

// Todas las rutas del carrito requieren token
router.use(verificarToken);

// ─────────────────────────────────────────
// Helper: obtener carrito completo con subtotales
// ─────────────────────────────────────────
async function obtenerCarritoCompleto(cedula) {
  const { data, error } = await supabase
    .from("carrito")
    .select(`
      idproducto,
      cantidad,
      producto:producto ( nombre, precio, stock )
    `)
    .eq("cedula", cedula);

  if (error) throw error;

  return (data || []).map((item) => ({
    idproducto: item.idproducto,
    cantidad: item.cantidad,
    nombre: item.producto?.nombre || "Producto no encontrado",
    precio: item.producto?.precio || 0,
    stock: item.producto?.stock || 0,
    subtotal: (item.producto?.precio || 0) * item.cantidad,
  }));
}

// ─────────────────────────────────────────
// GET /api/carrito
// ─────────────────────────────────────────
router.get("/", async (req, res) => {
  const cedula = req.usuario.id;

  try {
    const { data: carritoItems, error: errCarrito } = await supabase
      .from("carrito")
      .select("idproducto, cantidad")
      .eq("cedula", cedula);

    if (errCarrito) throw errCarrito;

    if (!carritoItems || carritoItems.length === 0) {
      return res.status(200).json([]);
    }

    const ids = carritoItems.map((i) => i.idproducto);

    const { data: productos, error: errProductos } = await supabase
      .from("producto")
      .select("idproducto, nombre, precio, descripcion, stock")
      .in("idproducto", ids);

    if (errProductos) throw errProductos;

    const { data: imagenes, error: errImagenes } = await supabase
      .from("producto_imagen")
      .select("idproducto, url")
      .in("idproducto", ids);

    if (errImagenes) throw errImagenes;

    const prodConImagenes = (productos || []).map((p) => {
      const imgs = (imagenes || []).filter((i) => i.idproducto === p.idproducto);
      return { ...p, imagenes: imgs.map((i) => i.url) };
    });

    const carrito = carritoItems.map((item) => {
      const prod = prodConImagenes.find((p) => p.idproducto === item.idproducto);
      return {
        idproducto: item.idproducto,
        nombre: prod?.nombre,
        precio: prod?.precio,
        cantidad: item.cantidad,
        subtotal: prod?.precio * item.cantidad,
        imagen_url: prod?.imagenes?.[0] || null,
      };
    });

    res.status(200).json(carrito);
  } catch (error) {
    console.error("❌ Error al obtener carrito:", error);
    res.status(500).json({ message: "Error al obtener carrito" });
  }
});

// ─────────────────────────────────────────
// POST /api/carrito/agregar
// ─────────────────────────────────────────
router.post("/agregar", async (req, res) => {
  const cedula = req.usuario.id;
  const { idproducto, cantidad } = req.body;

  if (!idproducto || !cantidad) {
    return res.status(400).json({ message: "Faltan datos: idproducto o cantidad" });
  }

  try {
    const { data: existe, error: existeError } = await supabase
      .from("carrito")
      .select("cantidad")
      .eq("cedula", cedula)
      .eq("idproducto", idproducto)
      .maybeSingle();

    if (existeError) throw existeError;

    if (existe) {
      const nuevaCantidad = existe.cantidad + cantidad;
      const { error: updateError } = await supabase
        .from("carrito")
        .update({ cantidad: nuevaCantidad })
        .eq("cedula", cedula)
        .eq("idproducto", idproducto);

      if (updateError) throw updateError;
    } else {
      const { error: insertError } = await supabase
        .from("carrito")
        .insert([{ cedula, idproducto, cantidad }]);

      if (insertError) throw insertError;
    }

    res.status(200).json({ message: "Producto agregado correctamente al carrito" });
  } catch (error) {
    console.error("❌ Error al agregar al carrito:", error.message);
    res.status(500).json({ message: "Error al agregar producto al carrito" });
  }
});

// ─────────────────────────────────────────
// PUT /api/carrito/actualizar  →  Actualiza cantidad (0 = elimina)
// ─────────────────────────────────────────
router.put("/actualizar", async (req, res) => {
  const cedula = req.usuario.id;
  const { idproducto, cantidad } = req.body;

  try {
    if (!idproducto || cantidad < 0) {
      return res.status(400).json({
        message: "Datos inválidos. Se requiere idproducto y cantidad >= 0.",
      });
    }

    // Validar stock disponible
    const { data: productoData, error: productoError } = await supabase
      .from("producto")
      .select("stock, nombre")
      .eq("idproducto", idproducto)
      .single();

    if (productoError) throw productoError;
    if (!productoData) return res.status(404).json({ message: "Producto no encontrado" });

    if (cantidad > productoData.stock) {
      return res.status(400).json({
        message: `Stock insuficiente. Solo hay ${productoData.stock} unidades de "${productoData.nombre}".`,
      });
    }

    // Si cantidad = 0 → eliminar
    if (cantidad === 0) {
      const { error: deleteError } = await supabase
        .from("carrito")
        .delete()
        .eq("idproducto", idproducto)
        .eq("cedula", cedula);

      if (deleteError) throw deleteError;

      return res.status(200).json({
        message: "Producto eliminado del carrito",
        carrito: await obtenerCarritoCompleto(cedula),
      });
    }

    // Actualizar cantidad
    const { error: errorUpdate } = await supabase
      .from("carrito")
      .update({ cantidad })
      .eq("idproducto", idproducto)
      .eq("cedula", cedula);

    if (errorUpdate) throw errorUpdate;

    const carrito = await obtenerCarritoCompleto(cedula);

    return res.status(200).json({
      message: "Cantidad actualizada correctamente",
      carrito,
      stockRestante: productoData.stock - cantidad,
    });
  } catch (error) {
    console.error("❌ Error al actualizar carrito:", error);
    return res.status(500).json({ message: "Error interno al actualizar el carrito" });
  }
});

// ─────────────────────────────────────────
// DELETE /api/carrito/eliminar/:idproducto
// ─────────────────────────────────────────
router.delete("/eliminar/:idproducto", async (req, res) => {
  const cedula = req.usuario.id;
  const { idproducto } = req.params;

  try {
    const { error, count } = await supabase
      .from("carrito")
      .delete()
      .eq("cedula", cedula)
      .eq("idproducto", idproducto)
      .select("*", { count: "exact" });

    if (error) throw error;

    if (count === 0) {
      return res.status(404).json({ message: "Producto no encontrado en el carrito" });
    }

    res.status(200).json({ message: "Producto eliminado correctamente del carrito" });
  } catch (error) {
    console.error("❌ Error al eliminar del carrito:", error.message);
    res.status(500).json({ message: "Error al eliminar producto del carrito" });
  }
});

// ─────────────────────────────────────────
// DELETE /api/carrito/vaciar
// ─────────────────────────────────────────
router.delete("/vaciar", async (req, res) => {
  const cedula = req.usuario.id;

  try {
    const { error } = await supabase
      .from("carrito")
      .delete()
      .eq("cedula", cedula);

    if (error) throw error;

    res.status(200).json({ message: "Carrito vaciado exitosamente" });
  } catch (error) {
    console.error("❌ Error al vaciar carrito:", error.message);
    res.status(500).json({ message: "Error al vaciar carrito" });
  }
});

export default router;
