// ─────────────────────────────────────────────────────────────
// Router principal — solo monta los sub-routers por dominio
// ─────────────────────────────────────────────────────────────
import express from "express";
import usuarioRoutes   from "./usuarioRoutes.js";
import productoRoutes  from "./productoRoutes.js";
import categoriaRoutes from "./categoriaRoutes.js";
import carritoRoutes   from "./carritoRoutes.js";
import favoritosRoutes from "./favoritosRoutes.js";
import pedidoRoutes      from "./pedidoRoutes.js";
import misPedidosRoutes  from "./misPedidosRoutes.js";
import direccionRoutes  from "./direccionRoutes.js";
import resenasRoutes   from "./resenasRoutes.js";

const router = express.Router();

// ── Health check ──────────────────────────────────────────────
router.get("/ping", (req, res) => {
  res.json({ ok: true, mensaje: "Router principal funcionando" });
});

// ── Autenticación y usuarios ──────────────────────────────────
router.post("/login",          (req, res, next) => usuarioRoutes(req, res, next));
router.use("/usuario",         usuarioRoutes);

// ── Productos ─────────────────────────────────────────────────
router.use("/productos",       productoRoutes);

// ── Categorías y marcas ───────────────────────────────────────
router.use("/categorias",      categoriaRoutes);
router.use("/marcas",          categoriaRoutes); 

// ── Carrito ───────────────────────────────────────────────────
router.use("/carrito",         carritoRoutes);

// ── Favoritos ─────────────────────────────────────────────────
router.use("/favoritos",       favoritosRoutes);

// ── Direcciones de entrega ────────────────────────────────────
router.use("/direcciones",     direccionRoutes);

// ── Pedidos (admin) ───────────────────────────────────────────
router.use("/admin/pedidos",   pedidoRoutes);
router.use("/estadisticas",    pedidoRoutes);

// ── Pedidos (cliente) ─────────────────────────────────────────
router.use("/pedidos/mis-pedidos", misPedidosRoutes);

// ── Refresh token ─────────────────────────────────────────────
router.post("/refresh", (req, res, next) => usuarioRoutes(req, res, next));

// ── Reseñas y calificaciones ───────────────────────────────────
router.use("/resenas", resenasRoutes);

export default router;