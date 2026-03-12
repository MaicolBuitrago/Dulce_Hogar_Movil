// src/routes/router.js
// ─────────────────────────────────────────────────────────────
// Router principal — solo monta los sub-routers por dominio
// ─────────────────────────────────────────────────────────────
import express from "express";
import usuarioRoutes   from "./usuarioRoutes.js";
import productoRoutes  from "./productoRoutes.js";
import categoriaRoutes from "./categoriaRoutes.js";
import carritoRoutes   from "./carritoRoutes.js";
import favoritosRoutes from "./favoritosRoutes.js";
import pedidoRoutes    from "./pedidoRoutes.js";
import direccionRoutes from "./direccionRoutes.js";

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
router.use("/marcas",          categoriaRoutes); // marcas comparten el mismo router

// ── Carrito ───────────────────────────────────────────────────
router.use("/carrito",         carritoRoutes);

// ── Favoritos ─────────────────────────────────────────────────
router.use("/favoritos",       favoritosRoutes);

// ── Direcciones de entrega ────────────────────────────────────
router.use("/direcciones",     direccionRoutes);

// ── Pedidos (admin) ───────────────────────────────────────────
router.use("/admin/pedidos",   pedidoRoutes);
router.use("/estadisticas",    pedidoRoutes); // estadísticas comparten pedidoRoutes

export default router;
