import express from "express";

const router = express.Router();

/* =========================================================
   GET - LISTAR PROMOCIONES ACTIVAS (para la app móvil)
   RUTA CORRECTA: /api/promociones
========================================================= */
router.get("/", async (req, res) => {  // ← CAMBIADO: "/promociones" → "/"
  try {
    const ahora = new Date().toISOString();

    const { data, error } = await req.supabase
      .from("promociones")
      .select(`
        idpromocion,
        nombre,
        descripcion,
        tipo_descuento,
        valor_descuento,
        scope,
        idproducto,
        idcategoria,
        fecha_inicio,
        fecha_fin,
        activo_manual
      `)
      .eq("activo_manual", true)
      .lte("fecha_inicio", ahora)
      .gte("fecha_fin", ahora)
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Error al listar promociones:", error);
      return res.status(500).json({ message: "Error al listar promociones." });
    }

    return res.json(data || []);
  } catch (err) {
    console.error("Error inesperado al listar promociones:", err);
    return res.status(500).json({ message: "Error interno del servidor." });
  }
});

/* =========================================================
   GET - PROMOCIONES POR PRODUCTO
   RUTA CORRECTA: /api/promociones/producto/:idproducto
========================================================= */
router.get("/producto/:idproducto", async (req, res) => {  // ← CAMBIADO
  try {
    const { idproducto } = req.params;
    const ahora = new Date().toISOString();

    const { data: promocionProducto, error: errorProducto } = await req.supabase
      .from("promociones")
      .select(`
        idpromocion,
        nombre,
        descripcion,
        tipo_descuento,
        valor_descuento,
        scope,
        fecha_inicio,
        fecha_fin
      `)
      .eq("scope", "producto")
      .eq("idproducto", Number(idproducto))
      .eq("activo_manual", true)
      .lte("fecha_inicio", ahora)
      .gte("fecha_fin", ahora)
      .maybeSingle();

    if (errorProducto) {
      console.error("Error al buscar promoción por producto:", errorProducto);
    }

    if (!promocionProducto) {
      const { data: producto, error: errorProductoCat } = await req.supabase
        .from("producto")
        .select("idcategoria")
        .eq("idproducto", Number(idproducto))
        .single();

      if (!errorProductoCat && producto?.idcategoria) {
        const { data: promocionCategoria, error: errorCategoria } = await req.supabase
          .from("promociones")
          .select(`
            idpromocion,
            nombre,
            descripcion,
            tipo_descuento,
            valor_descuento,
            scope,
            fecha_inicio,
            fecha_fin
          `)
          .eq("scope", "categoria")
          .eq("idcategoria", producto.idcategoria)
          .eq("activo_manual", true)
          .lte("fecha_inicio", ahora)
          .gte("fecha_fin", ahora)
          .maybeSingle();

        if (promocionCategoria) {
          return res.json(promocionCategoria);
        }
      }
    }

    return res.json(promocionProducto || null);
  } catch (err) {
    console.error("Error al obtener promoción por producto:", err);
    return res.status(500).json({ message: "Error interno del servidor." });
  }
});

/* =========================================================
   GET - PROMOCIONES POR CATEGORÍA
   RUTA CORRECTA: /api/promociones/categoria/:idcategoria
========================================================= */
router.get("/categoria/:idcategoria", async (req, res) => {  // ← CAMBIADO
  try {
    const { idcategoria } = req.params;
    const ahora = new Date().toISOString();

    const { data, error } = await req.supabase
      .from("promociones")
      .select(`
        idpromocion,
        nombre,
        descripcion,
        tipo_descuento,
        valor_descuento,
        scope,
        fecha_inicio,
        fecha_fin
      `)
      .eq("scope", "categoria")
      .eq("idcategoria", Number(idcategoria))
      .eq("activo_manual", true)
      .lte("fecha_inicio", ahora)
      .gte("fecha_fin", ahora)
      .maybeSingle();

    if (error) {
      console.error("Error al obtener promoción por categoría:", error);
      return res.status(500).json({ message: "Error al obtener promoción." });
    }

    return res.json(data || null);
  } catch (err) {
    console.error("Error inesperado:", err);
    return res.status(500).json({ message: "Error interno del servidor." });
  }
});

/* =========================================================
   GET - PROMOCIONES GLOBALES
   RUTA CORRECTA: /api/promociones/globales
========================================================= */
router.get("/globales", async (req, res) => {  // ← CAMBIADO
  try {
    const ahora = new Date().toISOString();

    const { data, error } = await req.supabase
      .from("promociones")
      .select(`
        idpromocion,
        nombre,
        descripcion,
        tipo_descuento,
        valor_descuento,
        scope,
        fecha_inicio,
        fecha_fin
      `)
      .eq("scope", "global")
      .eq("activo_manual", true)
      .lte("fecha_inicio", ahora)
      .gte("fecha_fin", ahora)
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Error al obtener promociones globales:", error);
      return res.status(500).json({ message: "Error al obtener promociones." });
    }

    return res.json(data || []);
  } catch (err) {
    console.error("Error inesperado:", err);
    return res.status(500).json({ message: "Error interno del servidor." });
  }
});

export default router;