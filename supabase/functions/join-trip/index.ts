import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { share_code, display_name, emoji, color } = await req.json();

    if (!share_code || !display_name || !emoji || !color) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: trip, error: tripError } = await supabase
      .from("trips")
      .select("id")
      .eq("share_code", share_code)
      .single();

    if (tripError || !trip) {
      return new Response(JSON.stringify({ error: "Trip not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: existingMember } = await supabase
      .from("trip_members")
      .select("id")
      .eq("trip_id", trip.id)
      .eq("user_id", user.id)
      .single();

    if (existingMember) {
      return new Response(
        JSON.stringify({ error: "Already a member", trip_id: trip.id }),
        {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: emojiTaken } = await supabase
      .from("trip_members")
      .select("id")
      .eq("trip_id", trip.id)
      .eq("emoji", emoji)
      .single();

    if (emojiTaken) {
      return new Response(
        JSON.stringify({ error: "Emoji already taken in this trip" }),
        {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: colorTaken } = await supabase
      .from("trip_members")
      .select("id")
      .eq("trip_id", trip.id)
      .eq("color", color)
      .single();

    if (colorTaken) {
      return new Response(
        JSON.stringify({ error: "Color already taken in this trip" }),
        {
          status: 409,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: member, error: insertError } = await supabase
      .from("trip_members")
      .insert({
        trip_id: trip.id,
        user_id: user.id,
        display_name,
        emoji,
        color,
        role: "guest",
      })
      .select()
      .single();

    if (insertError) {
      return new Response(
        JSON.stringify({ error: insertError.message }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    return new Response(
      JSON.stringify({ trip_id: trip.id, member }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
