# FleetTrack - User Creation Flow

Both ways now work the same - users must verify their email before being added to `public.users` and `drivers` table.

---

## 📊 Complete Flow Diagram

```
╔════════════════════════════════════════════════════════════════════╗
║                       TWO WAYS TO CREATE USERS                      ║
╠════════════════════════════════════════════════════════════════════╣
║                                                                     ║
║  WAY 1: Supabase Dashboard          WAY 2: Fleet Manager App        ║
║  ┌─────────────────────┐           ┌─────────────────────┐         ║
║  │ Admin creates user  │           │ Fleet Manager adds  │         ║
║  │ in Dashboard        │           │ driver via iOS app  │         ║
║  └──────────┬──────────┘           └──────────┬──────────┘         ║
║             │                                  │                    ║
║             │ Set metadata:                    │ Calls RPC:         ║
║             │ role, full_name                  │ create_fleet_      ║
║             │                                  │ user_rpc()         ║
║             ▼                                  ▼                    ║
║  ┌──────────────────────────────────────────────────────┐          ║
║  │                     auth.users                        │          ║
║  │               (email_confirmed_at = NULL)             │          ║
║  └──────────────────────────┬───────────────────────────┘          ║
║                             │                                       ║
║                             │ User receives verification email      ║
║                             │ User clicks link in email             ║
║                             ▼                                       ║
║  ┌──────────────────────────────────────────────────────┐          ║
║  │                 EMAIL VERIFIED ✅                     │          ║
║  │           (email_confirmed_at = NOW())                │          ║
║  └──────────────────────────┬───────────────────────────┘          ║
║                             │                                       ║
║                             │ TRIGGER: sync_verified_user_to_public ║
║                             ▼                                       ║
║  ┌──────────────────────────────────────────────────────┐          ║
║  │                    public.users                       │          ║
║  │                   (role = 'Driver')                   │          ║
║  └──────────────────────────┬───────────────────────────┘          ║
║                             │                                       ║
║                             │ TRIGGER: sync_public_user_to_driver   ║
║                             ▼                                       ║
║  ┌──────────────────────────────────────────────────────┐          ║
║  │                      drivers                          │          ║
║  │                (status = 'Available')                 │          ║
║  │              (other fields = NULL/default)            │          ║
║  └──────────────────────────────────────────────────────┘          ║
║                             │                                       ║
║                             ▼                                       ║
║                    ✅ USER CAN NOW LOGIN                            ║
║                    ✅ DRIVER CAN RECEIVE TRIPS                      ║
║                                                                     ║
╚════════════════════════════════════════════════════════════════════╝
```

---

## 🔧 Setup Instructions

### Step 1: Run SQL Scripts in Supabase SQL Editor

Run these in order:

1. **`create-user-rpc.sql`** - RPC function for Fleet Manager app
2. **`complete-user-sync-flow.sql`** - All triggers for automatic sync

### Step 2: Verify Triggers are Installed

```sql
SELECT tgname, tgrelid::regclass 
FROM pg_trigger 
WHERE tgname LIKE 'trigger_sync%' 
ORDER BY tgname;
```

Expected result:
- `trigger_sync_public_user_role_change` on `users`
- `trigger_sync_public_user_to_driver` on `users`
- `trigger_sync_verified_user` on `auth.users`

---

## 📱 Fleet Manager App Usage

When Fleet Manager adds a driver:

1. **Enter driver details** in the Add Driver form
2. **Submit** → RPC creates user in `auth.users`
3. **Verification email sent** automatically
4. **Console shows**:
   - ✅ User created
   - 📧 Verification email sent
   - 🔑 Temporary password (share this with driver!)

### What the Driver Does:

1. Receives verification email
2. Clicks the verification link
3. Email is verified → triggers fire → driver record created
4. Logs in with email + temporary password
5. (Optional) Changes password in profile

---

## 🔍 Verification Queries

```sql
-- Check all tables for a specific user
SELECT 'auth.users' as source, id, email, 
       CASE WHEN email_confirmed_at IS NULL THEN 'NOT VERIFIED' ELSE 'VERIFIED' END as status
FROM auth.users WHERE email = 'driver@example.com'
UNION ALL
SELECT 'public.users', id, email, role::text FROM public.users WHERE email = 'driver@example.com'
UNION ALL  
SELECT 'drivers', id, email, status::text FROM drivers WHERE email = 'driver@example.com';
```

---

## 📁 SQL Files Reference

| File | Purpose |
|------|---------|
| `create-user-rpc.sql` | RPC function called by Fleet Manager app |
| `complete-user-sync-flow.sql` | Triggers for auth→public→drivers sync |
| `sync-users-to-drivers.sql` | Manual sync utility |
| `fix-login-error.sql` | Fixes for login issues |

---

## ⚠️ Troubleshooting

### User not appearing in public.users?
- Check if email is verified: `SELECT email_confirmed_at FROM auth.users WHERE email = '...'`
- If NULL, user hasn't verified email yet

### User not appearing in drivers?
- Check if public.users exists: `SELECT * FROM public.users WHERE email = '...'`
- Check role is 'Driver': `SELECT role FROM public.users WHERE email = '...'`

### Login error: "Database error granting user"?
- Run `fix-login-error.sql` to fix trigger issues
- Delete and recreate the user

### Verification email not received?
- Check spam folder
- Resend via: Supabase Dashboard → Authentication → Users → Resend confirmation
