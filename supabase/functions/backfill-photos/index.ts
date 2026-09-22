import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

function dataURLtoBytes(dataURL) {
  const comma = dataURL.indexOf(",");
  if (comma < 0) return null;
  const head = dataURL.slice(0, comma);
  const body = dataURL.slice(comma + 1);
  const isBase64 = head.includes(";base64");
  if (!isBase64) return null;
  const bin = atob(body);
  const u8 = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) u8[i] = bin.charCodeAt(i);
  return u8;
}

const PHOTO_FIELDS = [
  "beadGasketPhoto", "photoOverall", "photoDamage", "photoFrame",
  "sketchPhotos", "photoAccess", "photoHazard"
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      return new Response(JSON.stringify({ error: "Missing env" }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const sb = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: surveys, error: surveyErr } = await sb
      .from("surveys")
      .select("id, engineer_id, answers")
      .eq("status", "SUBMITTED");

    if (surveyErr) {
      return new Response(JSON.stringify({ error: surveyErr.message }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let uploaded = 0, skipped = 0, failed = 0;
    const errors = [];

    for (const survey of surveys || []) {
      const answers = survey.answers || {};
      const uid = survey.engineer_id;
      const sid = survey.id;
      if (!uid || !sid) continue;

      for (const fid of PHOTO_FIELDS) {
        const photos = answers[fid];
        if (!Array.isArray(photos) || photos.length === 0) continue;

        for (const photo of photos) {
          if (!photo || !photo.uri) continue;
          if (photo.uploadedAt) { skipped++; continue; }

          const pid = photo.id || ("p_" + sid + "_" + fid + "_" + Math.random().toString(36).slice(2, 8));
          const path = uid + "/" + sid + "/" + pid + ".jpg";
          const bytes = dataURLtoBytes(photo.uri);
          if (!bytes) { failed++; errors.push({ sid, pid, reason: "bad data url" }); continue; }

          const blob = new Blob([bytes], { type: "image/jpeg" });

          const { error: upErr } = await sb.storage
            .from("survey-photos")
            .upload(path, blob, { contentType: "image/jpeg", upsert: true });

          if (upErr) {
            failed++;
            errors.push({ sid, pid, stage: "upload", code: upErr.code, message: upErr.message });
            continue;
          }

          const { error: dbErr } = await sb.from("survey_photos").upsert({
            id: pid,
            survey_id: sid,
            engineer_id: uid,
            field_id: fid,
            storage_path: path,
            caption: photo.caption || "",
          });

          if (dbErr) {
            failed++;
            errors.push({ sid, pid, stage: "insert", code: dbErr.code, message: dbErr.message });
            continue;
          }

          uploaded++;
        }
      }
    }

    return new Response(JSON.stringify({ uploaded, skipped, failed, errors: errors.slice(0, 20) }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e && e.message || String(e) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
