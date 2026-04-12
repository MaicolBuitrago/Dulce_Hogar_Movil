import express from "express";
import { MercadoPagoConfig, Preference, Payment } from "mercadopago";
import dotenv from "dotenv";
import { supabase } from "../config/db.js";

dotenv.config();

const router = express.Router();

const client = new MercadoPagoConfig({
  accessToken: process.env.MP_ACCESS_TOKEN,
});

// ─────────────────────────────────────────
// POST /api/mercadopago/create-preference
// ─────────────────────────────────────────
router.post("/create-preference", async (req, res) => {
  try {
    const {
      source = "producto",
      iddireccion = null,
      productos = [],
    } = req.body;

    if (!productos || productos.length === 0) {
      return res.status(400).json({ error: "No hay productos en la compra." });
    }

    const items = productos.map((producto) => ({
      id: String(producto.id),
      title: producto.nombre,
      quantity: producto.cantidad || 1,
      unit_price: Number(producto.precio),
      currency_id: "COP",
    }));

    const preference = new Preference(client);

    const frontendUrl = process.env.FRONTEND_URL || "";
    // auto_return solo funciona con URLs públicas. En localhost MercadoPago
    // rechaza la petición con 'invalid_auto_return', así que se omite.
    const isLocalhost =
      frontendUrl.includes("localhost") ||
      frontendUrl.includes("127.0.0.1");

    const body = {
      items,
      back_urls: {
        success: `${frontendUrl}/checkout/forma-entrega/pago/exitoso`,
        failure: `${frontendUrl}/checkout/forma-entrega/pago`,
        pending: `${frontendUrl}/checkout/forma-entrega/pago`,
      },
      ...(isLocalhost ? {} : { auto_return: "approved" }),
      metadata: {
        source,
        iddireccion: iddireccion ? iddireccion.toString() : null,
        productos: JSON.stringify(productos),
      },
    };

    const result = await preference.create({ body });

    console.log("✅ Preferencia MercadoPago creada:", result.id);
    res.json({ url: result.init_point, preference_id: result.id });
  } catch (error) {
    console.error("❌ Error creando preferencia MercadoPago:", error);
    res.status(500).json({ error: "No se pudo crear la preferencia de pago." });
  }
});

// ─────────────────────────────────────────
// POST /api/mercadopago/pedido/confirmar
// ─────────────────────────────────────────
// Llamado desde el frontend luego del redirect exitoso,
// pasando el payment_id que MercadoPago devuelve en la URL.
router.post("/pedido/confirmar", async (req, res) => {
  try {
    const { payment_id } = req.body;

    if (!payment_id) {
      return res.status(400).json({ error: "payment_id es requerido." });
    }

    // Verificar el pago con la API de MercadoPago
    const paymentClient = new Payment(client);
    const payment = await paymentClient.get({ id: payment_id });

    if (payment.status !== "approved") {
      return res.status(400).json({
        error: `El pago no fue aprobado. Estado: ${payment.status}`,
      });
    }

    const total = payment.transaction_amount;
    const email = payment.payer?.email;
    const source = payment.metadata?.source || "producto";
    const iddireccion = payment.metadata?.iddireccion
      ? Number(payment.metadata.iddireccion)
      : null;

    let productosMetadata = [];
    try {
      productosMetadata = payment.metadata?.productos
        ? JSON.parse(payment.metadata.productos)
        : [];
    } catch {
      console.error("❌ Error parseando productos del metadata.");
    }

    if (!email) {
      return res
        .status(400)
        .json({ error: "Email no encontrado en el pago." });
    }

    // Buscar usuario por email
    const { data: usuario, error: userError } = await supabase
      .from("usuario")
      .select("cedula")
      .eq("email", email)
      .single();

    if (userError || !usuario) {
      return res
        .status(400)
        .json({ error: "Usuario no encontrado para el email: " + email });
    }

    const cedula = usuario.cedula;

    // Crear pedido
    const { data: pedido, error: pedidoError } = await supabase
      .from("pedido")
      .insert([
        {
          fechaelaboracionpedido: new Date(),
          idestadopedido: 2, // Pagado
          cedula,
          total,
          iddireccion,
        },
      ])
      .select()
      .single();

    if (pedidoError) {
      console.error("❌ Error creando pedido:", pedidoError);
      return res.status(400).json({ error: pedidoError.message });
    }

    // Insertar detalles del pedido
    if (productosMetadata.length > 0) {
      const detallesInsert = productosMetadata.map((item) => ({
        idproducto: item.id,
        cantidad: item.cantidad,
        idpedido: pedido.idpedido,
        cedula,
        subtotal: item.precio * item.cantidad,
      }));

      const { error: detalleError } = await supabase
        .from("detallepedidomm")
        .insert(detallesInsert)
        .select();

      if (detalleError) {
        console.error("❌ Error insertando detalles:", detalleError);
        return res.status(400).json({ error: detalleError.message });
      }

      console.log("✅ Stock descontado por trigger automáticamente.");
    }

    // Vaciar carrito si la compra vino del carrito
    if (source === "carrito") {
      const { error: carritoError } = await supabase
        .from("carrito")
        .delete()
        .eq("cedula", cedula);

      if (carritoError) {
        console.error("❌ Error vaciando carrito:", carritoError);
      }
    }

    res.json({
      message: "Pedido registrado correctamente.",
      pedido,
      source,
      productosCount: productosMetadata.length,
    });
  } catch (error) {
    console.error("❌ Error confirmando pedido:", error);
    res
      .status(500)
      .json({ error: "Error al confirmar pedido: " + error.message });
  }
});

// ─────────────────────────────────────────
// POST /api/mercadopago/webhook
// ─────────────────────────────────────────
router.post("/webhook", async (req, res) => {
  try {
    const { type, data } = req.body;
    console.log("📩 Webhook MercadoPago:", type, data);

    if (type === "payment") {
      const paymentClient = new Payment(client);
      const payment = await paymentClient.get({ id: data.id });
      console.log("💳 Pago recibido por webhook:", payment.id, payment.status);
    }

    res.sendStatus(200);
  } catch (error) {
    console.error("❌ Error en webhook:", error);
    res.sendStatus(500);
  }
});

export default router;
