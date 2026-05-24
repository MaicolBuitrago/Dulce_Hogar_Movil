import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error("❌ Error: Faltan variables de entorno SUPABASE_URL o SUPABASE_KEY");
} else {
  console.log("✅ Variables de Supabase cargadas correctamente");
}

export const supabase = createClient(supabaseUrl, supabaseKey);

// Verificar conexión al iniciar (solo en local)
if (!process.env.VERCEL) {
  (async () => {
    const { error } = await supabase.from("usuario").select("count");
    if (error) {
      console.error("🔴 Error al conectar a Supabase:", error.message);
    } else {
      console.log("🟢 Conectado correctamente a Supabase (db)");
    }
  })();
}