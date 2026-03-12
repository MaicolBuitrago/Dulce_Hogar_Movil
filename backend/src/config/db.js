// src/config/db.js
// Cliente principal — acceso a tablas (RLS activo)
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

dotenv.config();

export const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

// Verificar conexión al iniciar
(async () => {
  const { error } = await supabase.from("usuario").select("count");
  if (error) {
    console.error("🔴 Error al conectar a Supabase:", error.message);
  } else {
    console.log("🟢 Conectado correctamente a Supabase (db)");
  }
})();
