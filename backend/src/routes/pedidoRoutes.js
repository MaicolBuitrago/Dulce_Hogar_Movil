// src/routes/pedidoRoutes.js
import express from "express";
import { supabase } from "../config/db.js";
import { verificarToken } from "../controller/authMiddleware.js";

const router = express.Router();

// ─────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────
const traducirEstado = (idEstado) => {
  const estados = {
    1: "Pendiente",
    2: "Pagado",
    3: "En camino",
    4: "Entregado",
    5: "Cancelado",
  };
  return estados[idEstado] || "Desconocido";
};

const estadoTextoAId = (estadoTexto) => {
  if (typeof estadoTexto === "number") return estadoTexto;
  if (!estadoTexto) return null;

  const mapa = {
    pendiente: 1,
    pagado: 2,
    "en camino": 3,
    entregado: 4,
    cancelado: 5,
  };

  return mapa[estadoTexto.toString().trim().toLowerCase()] || null;
};

// ─────────────────────────────────────────
// GET /api/admin/pedidos  →  Listar todos los pedidos
// ─────────────────────────────────────────
router.get("/", verificarToken, async (req, res) => {
  try {
    const { data: pedidosRaw, error: pedidosError } = await supabase
      .from("pedido")
      .select("idpedido, total, fechaelaboracionpedido, idestadopedido, cedula, iddireccion")
      .order("fechaelaboracionpedido", { ascending: false });

    if (pedidosError) throw pedidosError;
    if (!pedidosRaw || pedidosRaw.length === 0) return res.status(200).json([]);

    const cedulas = [...new Set(pedidosRaw.map((p) => p.cedula).filter(Boolean))];

    let mapaUsuarios = {};
    if (cedulas.length > 0) {
      const { data: usuarios, error: usuariosError } = await supabase
        .from("usuario")
        .select("cedula, nombre, apellido, email")
        .in("cedula", cedulas);

      if (usuariosError) throw usuariosError;

      mapaUsuarios = (usuarios || []).reduce((acc, u) => {
        acc[u.cedula] = u;
        return acc;
      }, {});
    }

    const pedidos = pedidosRaw.map((p) => {
      const user = mapaUsuarios[p.cedula] || {};
      const nombreCompleto = `${user.nombre || ""} ${user.apellido || ""}`.trim();
      return {
        idpedido: p.idpedido,
        numero: `#${p.idpedido}`,
        cliente: nombreCompleto || "Sin nombre",
        direccion: p.iddireccion || "Sin dirección registrada",
        estado: traducirEstado(p.idestadopedido),
        total: Number(p.total || 0),
        fecha: p.fechaelaboracionpedido || "",
      };
    });

    res.status(200).json(pedidos);
  } catch (err) {
    console.error("❌ Error al obtener pedidos admin:", err);
    res.status(500).json({ message: "Error al obtener pedidos" });
  }
});

// ─────────────────────────────────────────
// GET /api/admin/pedidos/:id  →  Detalle de pedido
// ─────────────────────────────────────────
router.get("/:id", verificarToken, async (req, res) => {
  const { id } = req.params;

  try {
    const { data: pedidoRaw, error: pedidoError } = await supabase
      .from("pedido")
      .select("idpedido, total, fechaelaboracionpedido, idestadopedido, cedula, iddireccion")
      .eq("idpedido", id)
      .single();

    if (pedidoError) {
      if (pedidoError.code === "PGRST116") {
        return res.status(404).json({ message: "Pedido no encontrado" });
      }
      throw pedidoError;
    }

    let usuario = null;
    if (pedidoRaw.cedula) {
      const { data: userData, error: userError } = await supabase
        .from("usuario")
        .select("cedula, nombre, apellido, email, direccion, ciudad, telefono")
        .eq("cedula", pedidoRaw.cedula)
        .single();

      if (userError && userError.code !== "PGRST116") throw userError;
      usuario = userData || null;
    }

    const nombreCompleto = usuario
      ? `${usuario.nombre || ""} ${usuario.apellido || ""}`.trim()
      : "Sin nombre";

    res.status(200).json({
      idpedido: pedidoRaw.idpedido,
      numero: `#${pedidoRaw.idpedido}`,
      cliente: nombreCompleto,
      correo: usuario?.email || "",
      direccion: usuario?.direccion || pedidoRaw.iddireccion || "",
      ciudad: usuario?.ciudad || "",
      telefono: usuario?.telefono || "",
      estado: traducirEstado(pedidoRaw.idestadopedido),
      total: Number(pedidoRaw.total || 0),
      fecha: pedidoRaw.fechaelaboracionpedido || "",
    });
  } catch (err) {
    console.error("❌ Error al obtener pedido:", err);
    res.status(500).json({ message: "Error al obtener pedido" });
  }
});

// ─────────────────────────────────────────
// PATCH /api/admin/pedidos/:id/estado  →  Cambiar estado
// ─────────────────────────────────────────
router.patch("/:id/estado", verificarToken, async (req, res) => {
  const { id } = req.params;
  const { estado } = req.body;

  if (estado === undefined || estado === null) {
    return res.status(400).json({ message: "El estado es obligatorio" });
  }

  try {
    const nuevoIdEstado = typeof estado === "number" ? estado : estadoTextoAId(estado);

    if (!nuevoIdEstado) {
      return res.status(400).json({ message: "Estado no válido" });
    }

    const { data, error } = await supabase
      .from("pedido")
      .update({ idestadopedido: nuevoIdEstado })
      .eq("idpedido", id)
      .select("idpedido, idestadopedido")
      .single();

    if (error) throw error;

    res.status(200).json({
      message: "Estado actualizado correctamente",
      pedido: {
        idpedido: data.idpedido,
        idestadopedido: data.idestadopedido,
        estadoTexto: traducirEstado(data.idestadopedido),
      },
    });
  } catch (err) {
    console.error("❌ Error al actualizar estado de pedido:", err);
    res.status(500).json({ message: "Error al actualizar estado de pedido" });
  }
});

// ─────────────────────────────────────────
// GET /api/admin/estadisticas/productos-mas-vendidos
// ─────────────────────────────────────────
router.get("/estadisticas/productos-mas-vendidos", verificarToken, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from("detallepedidomm")
      .select("cantidad, idproducto, producto:producto(idproducto, nombre)");

    if (error) throw error;

    const contador = {};
    (data || []).forEach((d) => {
      const nombre = d.producto?.nombre || `Desconocido (ID: ${d.idproducto})`;
      contador[nombre] = (contador[nombre] || 0) + (d.cantidad || 0);
    });

    const top = Object.entries(contador)
      .map(([nombre, cantidad]) => ({ nombre, cantidad }))
      .sort((a, b) => b.cantidad - a.cantidad)
      .slice(0, 5);

    res.json(top);
  } catch (err) {
    console.error("❌ Error:", err.message);
    res.status(500).json({ error: "Error al obtener productos más vendidos" });
  }
});

// ─────────────────────────────────────────
// GET /api/admin/estadisticas/ventas-mensuales
// ─────────────────────────────────────────
router.get("/estadisticas/ventas-mensuales", verificarToken, async (req, res) => {
  try {
    const { data: detalles, error: errorDetalles } = await supabase
      .from("detallepedidomm")
      .select("idpedido, subtotal");

    if (errorDetalles) throw errorDetalles;

    const { data: pedidos, error: errorPedidos } = await supabase
      .from("pedido")
      .select("idpedido, fechaelaboracionpedido");

    if (errorPedidos) throw errorPedidos;

    const ventasPorMes = {};
    (detalles || []).forEach((detalle) => {
      const pedido = pedidos.find((p) => p.idpedido === detalle.idpedido);
      if (pedido) {
        const mes = new Date(pedido.fechaelaboracionpedido).toLocaleString("es-ES", {
          month: "short",
          year: "numeric",
        });
        ventasPorMes[mes] = (ventasPorMes[mes] || 0) + Number(detalle.subtotal);
      }
    });

    res.json(Object.entries(ventasPorMes).map(([mes, total]) => ({ mes, total })));
  } catch (err) {
    console.error("❌ Error al obtener ventas mensuales:", err);
    res.status(500).json({ error: "Error al obtener ventas mensuales" });
  }
});

export default router;
