-- Vehicle Inspection Records Table
CREATE TABLE IF NOT EXISTS public.vehicle_inspections (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id UUID NOT NULL,
  driver_id UUID NOT NULL,
  inspection_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  -- Checklist items (stored as jsonb array of objects)
  checklist_items JSONB NOT NULL,
  
  -- Summary
  items_checked INTEGER NOT NULL,
  total_items INTEGER NOT NULL,
  all_items_passed BOOLEAN NOT NULL DEFAULT FALSE,
  
  -- Additional notes
  notes TEXT NULL,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'Completed',
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  CONSTRAINT vehicle_inspections_pkey PRIMARY KEY (id),
  CONSTRAINT vehicle_inspections_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  CONSTRAINT vehicle_inspections_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_vehicle_inspections_vehicle ON public.vehicle_inspections USING btree (vehicle_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_vehicle_inspections_driver ON public.vehicle_inspections USING btree (driver_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_vehicle_inspections_date ON public.vehicle_inspections USING btree (inspection_date DESC) TABLESPACE pg_default;

-- Update trigger
CREATE TRIGGER update_vehicle_inspections_updated_at 
  BEFORE UPDATE ON vehicle_inspections 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE public.vehicle_inspections ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read inspections
CREATE POLICY "Allow authenticated users to view inspections" 
  ON public.vehicle_inspections FOR SELECT 
  TO authenticated 
  USING (true);

-- Allow drivers to create inspections for their own vehicles
CREATE POLICY "Allow drivers to create inspections" 
  ON public.vehicle_inspections FOR INSERT 
  TO authenticated 
  WITH CHECK (true);

-- Allow authenticated users to update inspections
CREATE POLICY "Allow authenticated users to update inspections" 
  ON public.vehicle_inspections FOR UPDATE 
  TO authenticated 
  USING (true);
