-- Service Requests Table
CREATE TABLE IF NOT EXISTS public.service_requests (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL,
  driver_id UUID NOT NULL,
  service_type TEXT NOT NULL,
  preferred_date TIMESTAMPTZ NOT NULL,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'Pending', -- Pending, Approved, Completed, Cancelled
  request_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT service_requests_pkey PRIMARY KEY (id),
  CONSTRAINT service_requests_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id),
  CONSTRAINT service_requests_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id)
) TABLESPACE pg_default;

-- RLS Policies
ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert service requests (Drivers)
CREATE POLICY "Allow authenticated users to insert service requests" 
  ON public.service_requests FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

-- Allow authenticated users to view service requests (Drivers & Maintenance)
CREATE POLICY "Allow authenticated users to view service requests" 
  ON public.service_requests FOR SELECT 
  TO authenticated 
  USING (true);

-- Allow authenticated users to update service requests (Maintenance)
CREATE POLICY "Allow authenticated users to update service requests" 
  ON public.service_requests FOR UPDATE 
  TO authenticated 
  USING (true);
