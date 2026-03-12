// src/routes/stripeRoutes.js
import express from "express";
import Stripe from "stripe";
import dotenv from "dotenv";
import { supabase } from "../config/db.js";

dotenv.config();

const router = express.Router();
export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// ─────────────────────────────────────────
// POST /api/stripe/create-checkout-session
// ─────────────────────────────────────────
router.post("/create-checkout-session", async (req, res) => {
  try {
    const {
      source = "producto",
      iddireccion = null,
      productos = [],
    } = req.body;

    if (!productos || productos.length === 0) {
      return res.status(400).json({ error: "No hay productos en la compra." });
    }

    const line_items = productos.map((producto) => ({
      price_data: {
        currency: "cop",
        product_data: {
          name: producto.nombre,
          description: `ID: ${producto.id}`,
        },
        unit_amount: Math.round(producto.precio * 100),
      },
      quantity: producto.cantidad || 1,
    }));

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: ["card"],
      invoice_creation: { enabled: true },
      success_url: `${process.env.FRONTEND_URL}/checkout/forma-entrega/pago/exitoso?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.FRONTEND_URL}/checkout/forma-entrega/pago`,
      billing_address_collection: "required",
      line_items,
      metadata: {
        source,
        iddireccion: iddireccion ? iddireccion.toString() : null,
        productos: JSON.stringify(productos),
      },
    });

    console.log("✅ Sesión Stripe creada:", session.id);
    res.json({ url: session.url });
  } catch (error) {
    console.error("❌ Error creando sesión Stripe:", error);
    res.status(500).json({ error: "No se pudo crear la sesión de pago." });
  }
});

// ─────────────────────────────────────────
// GET /api/stripe/factura/:sessionId
// ─────────────────────────────────────────
router.get("/factura/:sessionId", async (req, res) => {
  try {
    const session = await stripe.checkout.sessions.retrieve(
      req.params.sessionId
    );

    if (!session.invoice) {
      return res
        .status(404)
        .json({ message: "La factura aún no está disponible." });
    }

    const factura = await stripe.invoices.retrieve(session.invoice);
    res.json({ url: factura.invoice_pdf });
  } catch (error) {
    console.error("❌ Error obteniendo factura:", error);
    res.status(500).json({ message: "Error al obtener la factura." });
  }
});

// ─────────────────────────────────────────
// POST /api/stripe/pedido/confirmar
// ─────────────────────────────────────────
router.post("/pedido/confirmar", async (req, res) => {
  try {
    const { session_id } = req.body;

    if (!session_id) {
      return res.status(400).json({ error: "session_id es requerido." });
    }

    const session = await stripe.checkout.sessions.retrieve(session_id, {
      expand: ["line_items"],
    });

    const total = session.amount_total / 100;
    const email = session.customer_details?.email;
    const source = session.metadata?.source || "producto";
    const iddireccion = session.metadata?.iddireccion
      ? Number(session.metadata.iddireccion)
      : null;

    let productosMetadata = [];
    try {
      productosMetadata = session.metadata?.productos
        ? JSON.parse(session.metadata.productos)
        : [];
    } catch {
      console.error("❌ Error parseando productos del metadata.");
    }

    if (!email) {
      return res
        .status(400)
        .json({ error: "Email no encontrado en la sesión." });
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
      .insert([{
        fechaelaboracionpedido: new Date(),
        idestadopedido: 2, // Pagado
        cedula,
        total,
        iddireccion,
      }])
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

      // El trigger tr_control_stock descuenta el stock automáticamente
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
    res.status(500).json({ error: "Error al confirmar pedido: " + error.message });
  }
});

export default router;
