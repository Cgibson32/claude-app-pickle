/**
 * SupabaseClient stub
 *
 * This file is ready to be activated when you connect a Supabase backend.
 *
 * ─── SETUP STEPS ─────────────────────────────────────────────────────────────
 *
 * 1. Create a Supabase project at https://supabase.com
 *
 * 2. Install the client:
 *    npm install @supabase/supabase-js
 *
 * 3. Add to .env:
 *    VITE_SUPABASE_URL=https://your-project.supabase.co
 *    VITE_SUPABASE_ANON_KEY=your-anon-key
 *
 * 4. Uncomment the import and createClient call below.
 *
 * 5. In each Repository, set USE_SUPABASE = true to route reads/writes
 *    to Supabase instead of localStorage.
 *
 * ─── DATABASE SCHEMA ─────────────────────────────────────────────────────────
 *
 * Run this SQL in the Supabase SQL editor:
 *
 *   -- Profiles table
 *   CREATE TABLE profiles (
 *     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
 *     name TEXT,
 *     level TEXT,
 *     frequency TEXT,
 *     struggles TEXT[],
 *     technical_weaknesses TEXT[],
 *     mental_weaknesses TEXT[],
 *     goals TEXT[],
 *     player_type TEXT,
 *     format TEXT,
 *     onboarding_completed_at TIMESTAMPTZ,
 *     created_at TIMESTAMPTZ DEFAULT NOW(),
 *     updated_at TIMESTAMPTZ DEFAULT NOW()
 *   );
 *
 *   -- Sessions table
 *   CREATE TABLE sessions (
 *     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
 *     date TIMESTAMPTZ NOT NULL,
 *     game_type TEXT,
 *     pre_play_mood TEXT,
 *     energy_level INT,
 *     technical_intent TEXT,
 *     mental_intent TEXT,
 *     rating INT,
 *     skill_focus TEXT,
 *     went_well TEXT,
 *     improve_focus TEXT,
 *     highlights TEXT,
 *     ahamoment TEXT,
 *     coach_cue TEXT,
 *     patience_score INT,
 *     patience_notes TEXT,
 *     emotions_score INT,
 *     emotions_notes TEXT,
 *     communication_score INT,
 *     is_post_play_complete BOOLEAN DEFAULT FALSE,
 *     created_at TIMESTAMPTZ DEFAULT NOW(),
 *     updated_at TIMESTAMPTZ DEFAULT NOW()
 *   );
 *
 *   -- Intentions table
 *   CREATE TABLE intentions (
 *     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 *     user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
 *     date DATE NOT NULL,
 *     theme TEXT,
 *     performance TEXT,
 *     mental TEXT,
 *     joy TEXT,
 *     quote TEXT,
 *     cue TEXT,
 *     technical_focus TEXT,
 *     mental_focus TEXT,
 *     game_type TEXT,
 *     pre_play_mood TEXT,
 *     energy_level INT,
 *     created_at TIMESTAMPTZ DEFAULT NOW()
 *   );
 *
 *   -- Enable Row Level Security
 *   ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
 *   ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
 *   ALTER TABLE intentions ENABLE ROW LEVEL SECURITY;
 *
 *   -- Policies: users can only access their own data
 *   CREATE POLICY "Own data only" ON profiles FOR ALL USING (auth.uid() = user_id);
 *   CREATE POLICY "Own data only" ON sessions FOR ALL USING (auth.uid() = user_id);
 *   CREATE POLICY "Own data only" ON intentions FOR ALL USING (auth.uid() = user_id);
 *
 * ─────────────────────────────────────────────────────────────────────────────
 */

// Uncomment when ready to activate:
// import { createClient } from '@supabase/supabase-js';
// export const supabase = createClient(
//   import.meta.env.VITE_SUPABASE_URL,
//   import.meta.env.VITE_SUPABASE_ANON_KEY
// );

// Stub — replace with the real client above when ready
export const supabase = null;

/**
 * Whether Supabase is configured and active.
 * Repositories read this to decide which backend to use.
 */
export const SUPABASE_ENABLED = supabase !== null;
