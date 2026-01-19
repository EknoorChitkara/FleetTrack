// Supabase Edge Function: delete-user
// Deletes a user from auth.users with service role key
// CASCADE will automatically delete from child tables (drivers, maintenance_personnel)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface DeleteUserRequest {
  userId: string
}

interface DeleteUserResponse {
  success: boolean
  message: string
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const requestData: DeleteUserRequest = await req.json()
    
    console.log('🗑️ [delete-user] Received request for userId:', requestData.userId)
    
    if (!requestData.userId) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Missing userId',
          error: 'userId is required'
        } as DeleteUserResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Create Supabase admin client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Delete user from auth.users
    // This will CASCADE to drivers and maintenance_personnel tables
    console.log('🔐 [delete-user] Deleting user from auth.users...')
    
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      requestData.userId
    )

    if (deleteError) {
      console.error('❌ [delete-user] Failed to delete user:', deleteError.message)
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Failed to delete user',
          error: deleteError.message
        } as DeleteUserResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log('✅ [delete-user] User deleted successfully, CASCADE removed child records')

    return new Response(
      JSON.stringify({
        success: true,
        message: `User ${requestData.userId} deleted successfully`
      } as DeleteUserResponse),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
    )

  } catch (error) {
    console.error('❌ [delete-user] Unexpected error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Internal server error',
        error: error.message
      } as DeleteUserResponse),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
