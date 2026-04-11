import express from "express";
import { supabase } from "../config/db.js";
import { verificarToken } from "../controller/authMiddleware.js";

const router = express.Router();

// ── Helper: texto del estado ──────────────────────────────────
const traducirEstado = (id) => {
  const estados = {
    1: "Pendiente",
    2: "Pagado",
    3: "En camino",
    4: "Entregado",
    5: "Cancelado",
  };
  return estados[id] || "Desconocido";
};

// ── Helper: color del badge según estado ─────────────────────
// Lo usará Flutter para pintar el chip de estado
const colorEstado = (id) => {
  const colores = {
    1: "warning",   // Pendiente   → amarillo
    2: "info",      // Pagado      → azul
    3: "primary",   // En camino   → verde
    4: "success",   // Entregado   → verde oscuro
    5: "error",     // Cancelado   → rojo
  };
  return colores[id] || "default";
};

// ─────────────────────────────────────────────────────────────
// GET /api/pedidos/mis-pedidos
// Lista todos los pedidos del usuario autenticado
// ─────────────────────────────────────────────────────────────
router.get("/", verificarToken, async (req, res) => {
  // verificarToken pone la cédula en req.usuario.id
  const cedula = req.usuario?.id;

  if (!cedula) {
    return res.status(401).json({ message: "No autenticado" });
  }

  try {
    const { data: pedidos, error } = await supabase
      .from("pedido")
      .select("idpedido, total, fechaelaboracionpedido, idestadopedido, iddireccion")
      .eq("cedula", cedula)
      .order("fechaelaboracionpedido", { ascending: false });

    if (error) throw error;

    if (!pedidos || pedidos.length === 0) {
      return res.status(200).json([]);
    }

    // Para cada pedido, sacar cuántos productos tiene (para el subtítulo de la card)
    const ids = pedidos.map((p) => p.idpedido);

    const { data: detalles, error: detallesError } = await supabase
      .from("detallepedidomm")
      .select("idpedido, cantidad")
      .in("idpedido", ids);

    if (detallesError) throw detallesError;

    // Agrupar detalles por pedido
    const conteoPorPedido = (detalles || []).reduce((acc, d) => {
      acc[d.idpedido] = (acc[d.idpedido] || 0) + (d.cantidad || 0);
      return acc;
    }, {});

    const respuesta = pedidos.map((p) => ({
      idpedido:    p.idpedido,
      numero:      `#${p.idpedido}`,
      fecha:       p.fechaelaboracionpedido || "",
      total:       Number(p.total || 0),
      estado:      traducirEstado(p.idestadopedido),
      colorEstado: colorEstado(p.idestadopedido),
      totalItems:  conteoPorPedido[p.idpedido] || 0,
      iddireccion: p.iddireccion,
    }));

    res.status(200).json(respuesta);
  } catch (err) {
    console.error("❌ Error al obtener mis pedidos:", err.message);
    res.status(500).json({ message: "Error al obtener tus pedidos" });
  }
});

// ─────────────────────────────────────────────────────────────
// GET /api/pedidos/mis-pedidos/:id
// Detalle de un pedido específico con la lista de productos
// Solo permite ver pedidos que le pertenecen al usuario
// ─────────────────────────────────────────────────────────────
router.get("/:id", verificarToken, async (req, res) => {
  const cedula   = req.usuario?.id;
  const idpedido = parseInt(req.params.id, 10);

  if (!cedula) {
    return res.status(401).json({ message: "No autenticado" });
  }

  if (isNaN(idpedido)) {
    return res.status(400).json({ message: "ID de pedido inválido" });
  }

  try {
    // 1. Verificar que el pedido existe Y pertenece al usuario
    const { data: pedido, error: pedidoError } = await supabase
      .from("pedido")
      .select("idpedido, total, fechaelaboracionpedido, idestadopedido, iddireccion, cedula")
      .eq("idpedido", idpedido)
      .eq("cedula", cedula)
      .maybeSingle();

    if (pedidoError) throw pedidoError;

    if (!pedido) {
      return res.status(404).json({ message: "Pedido no encontrado" });
    }

    // 2. Obtener los items del pedido (sin join — evita problemas de FK en Supabase)
    const { data: detalles, error: detallesError } = await supabase
      .from("detallepedidomm")
      .select("iddetalle, cantidad, subtotal, idproducto")
      .eq("idpedido", idpedido);

    if (detallesError) throw detallesError;

    // 3. Buscar los datos de cada producto por separado
    //    (más robusto que el join — funciona aunque Supabase no tenga la FK en su cache)
    let productos = [];
    if (detalles && detalles.length > 0) {
      const idsProductos = [...new Set(detalles.map((d) => d.idproducto))];

      // Traer datos del producto y su primera imagen desde producto_imagen
      const { data: productosData, error: productosError } = await supabase
        .from("producto")
        .select("idproducto, nombre, precio")
        .in("idproducto", idsProductos);

      if (productosError) throw productosError;

      // Traer la primera imagen de cada producto desde la tabla producto_imagen
      const { data: imagenesData } = await supabase
        .from("producto_imagen")
        .select("idproducto, url")
        .in("idproducto", idsProductos);

      // Mapa producto_id → primera url de imagen
      const mapaImagenes = (imagenesData || []).reduce((acc, img) => {
        if (!acc[img.idproducto]) acc[img.idproducto] = img.url;
        return acc;
      }, {});

      // Mapa producto_id → datos del producto
      const mapaProductos = (productosData || []).reduce((acc, p) => {
        acc[p.idproducto] = p;
        return acc;
      }, {});

      productos = detalles.map((d) => {
        const prod = mapaProductos[d.idproducto] || {};
        return {
          iddetalle:  d.iddetalle,
          idproducto: d.idproducto,
          nombre:     prod.nombre  || "Producto sin nombre",
          precio:     Number(prod.precio || 0),
          cantidad:   d.cantidad,
          subtotal:   Number(d.subtotal  || 0),
          imagen:     mapaImagenes[d.idproducto] || null,
        };
      });
    }

    // 4. Obtener la dirección de entrega si existe
    let direccionTexto = "Sin dirección registrada";
    if (pedido.iddireccion) {
      const { data: dir } = await supabase
        .from("direccionentrega")
        .select("direccion")
        .eq("iddireccion", pedido.iddireccion)
        .maybeSingle();

      if (dir?.direccion) direccionTexto = dir.direccion;
    }

    res.status(200).json({
      idpedido:    pedido.idpedido,
      numero:      `#${pedido.idpedido}`,
      fecha:       pedido.fechaelaboracionpedido || "",
      total:       Number(pedido.total || 0),
      estado:      traducirEstado(pedido.idestadopedido),
      colorEstado: colorEstado(pedido.idestadopedido),
      direccion:   direccionTexto,
      productos,
    });
  } catch (err) {
    console.error("❌ Error al obtener detalle del pedido:", err.message);
    res.status(500).json({ message: "Error al obtener el detalle del pedido" });
  }
});

export default router;