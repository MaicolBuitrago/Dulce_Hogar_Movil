import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import cookieParser from "cookie-parser";

import router from "../routes/router.js";
import authRoutes from "../routes/authRoutes.js";
import stripeRoutes from "../routes/stripeRoutes.js";
import { supabase } from "./db.js";

dotenv.config();

const app = express();

app.use(cookieParser());
app.use(cors());   
app.use(express.json());

app.use((req, res, next) => {
  req.supabase = supabase;
  next();
});

app.use("/api/auth", express.json(), authRoutes);
app.use("/api/stripe", express.json(), stripeRoutes);
app.use("/api", router);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`✅ Servidor corriendo en http://localhost:${PORT}`);
});