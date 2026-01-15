-- 1. Alerts Table
CREATE TABLE IF NOT EXISTS public.maintenance_alerts (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('System', 'Emergency')),
    user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Maintenance Tasks - Add Missing Columns (Safe for existing data)
ALTER TABLE public.maintenance_tasks ADD COLUMN IF NOT EXISTS vehicle_registration_number TEXT;
ALTER TABLE public.maintenance_tasks ADD COLUMN IF NOT EXISTS task_type TEXT DEFAULT 'Scheduled';
ALTER TABLE public.maintenance_tasks ADD COLUMN IF NOT EXISTS labor_hours DOUBLE PRECISION DEFAULT 0;
ALTER TABLE public.maintenance_tasks ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.maintenance_tasks ADD COLUMN IF NOT EXISTS paused_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.maintenance_tasks ADD COLUMN IF NOT EXISTS failed_reason TEXT;
ALTER TABLE public.maintenance_tasks ADD COLUMN IF NOT EXISTS repair_description TEXT;
ALTER TABLE public.maintenance_tasks ADD COLUMN IF NOT EXISTS description TEXT;

-- 3. Summary View
DROP VIEW IF EXISTS public.maintenance_summary;
CREATE OR REPLACE VIEW public.maintenance_summary AS
SELECT 
    COUNT(*) FILTER (WHERE status = 'Completed' AND completed_date >= date_trunc('month', now())) AS completed_tasks_this_month,
    COALESCE(AVG(EXTRACT(EPOCH FROM (completed_date - started_at)) / 3600) FILTER (WHERE status = 'Completed'), 0) AS average_completion_time_hours
FROM public.maintenance_tasks;

-- 4. Enable Security
ALTER TABLE public.maintenance_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_tasks ENABLE ROW LEVEL SECURITY;

-- 5. Policies (Only if they don't exist)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'maintenance_alerts') THEN
        CREATE POLICY "Allow authenticated read alerts" ON public.maintenance_alerts FOR SELECT TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'maintenance_tasks') THEN
        CREATE POLICY "Allow authenticated read tasks" ON public.maintenance_tasks FOR SELECT TO authenticated USING (true);
        CREATE POLICY "Allow authenticated update tasks" ON public.maintenance_tasks FOR UPDATE TO authenticated USING (true);
    END IF;
END $$;
