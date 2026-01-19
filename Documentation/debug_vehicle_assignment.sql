-- 1. First, find your Driver ID using your email
-- Replace 'your_email@example.com' with the email you use to login
SELECT id, full_name, email, current_vehicle_id 
FROM drivers 
WHERE email = 'your_email@example.com';

-- 2. Once you have your Driver ID from the result above,
-- use it to check if any vehicle is linked to you.
-- Replace 'YOUR_DRIVER_ID_HERE' with the ID you found in step 1.
SELECT id, manufacturer, model, registration_number, assigned_driver_id
FROM vehicles 
WHERE assigned_driver_id = 'YOUR_DRIVER_ID_HERE';

-- 3. If Step 2 returns nothing, it means the database link is missing.
-- You can manually fix it by running this UPDATE command:
-- Replace 'YOUR_DRIVER_ID_HERE' with your real Driver ID
-- Replace 'TARGET_VEHICLE_registration_number' with the registration number of the car you want (e.g. 'KA-01-AB-1234')

/*
UPDATE vehicles 
SET assigned_driver_id = 'YOUR_DRIVER_ID_HERE' 
WHERE registration_number = 'TARGET_VEHICLE_registration_number';
*/
