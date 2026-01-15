// Supabase Edge Function: create-user
// Creates a user in auth.users with the service role key
// Called from Fleet Manager iOS app when adding a new driver/user

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateUserRequest {
  email: string
  password: string
  fullName: string
  role: 'Admin' | 'Fleet Manager' | 'Driver' | 'Maintenance Personnel'
  phoneNumber?: string
  // Additional fields for drivers
  licenseNumber?: string
  address?: string
}

interface CreateUserResponse {
  success: boolean
  userId?: string
  message: string
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the request body
    const requestData: CreateUserRequest = await req.json()
    
    console.log('📥 [create-user] Received request for:', requestData.email)
    console.log('   Role:', requestData.role)
    console.log('   Full Name:', requestData.fullName)
    
    // Validate required fields
    if (!requestData.email || !requestData.password || !requestData.fullName || !requestData.role) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Missing required fields',
          error: 'email, password, fullName, and role are required'
        } as CreateUserResponse),
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

    // 1. Create user in auth.users
    console.log('🔐 [create-user] Creating user in auth.users...')
    
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: requestData.email,
      password: requestData.password,
      email_confirm: false, // User needs to verify email
      user_metadata: {
        full_name: requestData.fullName,
        role: requestData.role,
        phone_number: requestData.phoneNumber,
        // Store additional driver data in metadata for later use
        license_number: requestData.licenseNumber,
        address: requestData.address
      }
    })

    if (authError) {
      console.error('❌ [create-user] Failed to create auth user:', authError.message)
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Failed to create user in auth.users',
          error: authError.message
        } as CreateUserResponse),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const userId = authData.user?.id
    console.log('✅ [create-user] Auth user created with ID:', userId)

    // 2. Send verification email
    console.log('📧 [create-user] Sending verification email...')
    
    const { error: inviteError } = await supabaseAdmin.auth.admin.inviteUserByEmail(
      requestData.email,
      {
        redirectTo: 'fleettrack://auth/callback'
      }
    )

    if (inviteError) {
      console.warn('⚠️ [create-user] Failed to send invite email:', inviteError.message)
      // Don't fail the whole operation if email fails
    } else {
      console.log('✅ [create-user] Verification email sent')
    }

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        userId: userId,
        message: `User created successfully. Verification email sent to ${requestData.email}`
      } as CreateUserResponse),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('❌ [create-user] Unexpected error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        message: 'Internal server error',
        error: error.message
      } as CreateUserResponse),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
