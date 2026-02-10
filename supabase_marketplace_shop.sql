-- =====================================================
-- SMART FARM MARKETPLACE SHOP DATABASE SCHEMA
-- Poultry Supply Shop for Farmers
-- =====================================================

-- Drop existing tables if they exist (cleanup old sales request system)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;
DROP TABLE IF EXISTS delivery_zones CASCADE;
DROP TABLE IF EXISTS pickup_locations CASCADE;

-- =====================================================
-- PRODUCT CATEGORIES TABLE
-- =====================================================
CREATE TABLE product_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PRODUCTS TABLE
-- =====================================================
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES product_categories(id) ON DELETE RESTRICT,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  unit VARCHAR(50) NOT NULL, -- kg, liters, pieces, bags, bottles
  images TEXT[], -- Array of image URLs
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- DELIVERY ZONES TABLE
-- =====================================================
CREATE TABLE delivery_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  state_name VARCHAR(100) NOT NULL UNIQUE,
  delivery_fee DECIMAL(10, 2) NOT NULL CHECK (delivery_fee >= 0),
  estimated_days VARCHAR(50), -- e.g., "2-3 days"
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- PICKUP LOCATIONS TABLE
-- =====================================================
CREATE TABLE pickup_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_name VARCHAR(200) NOT NULL,
  address TEXT NOT NULL,
  state VARCHAR(100),
  phone VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ORDERS TABLE
-- =====================================================
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_number VARCHAR(50) UNIQUE NOT NULL,
  
  -- Fulfillment details
  fulfillment_type VARCHAR(20) NOT NULL CHECK (fulfillment_type IN ('pickup', 'delivery')),
  pickup_location_id UUID REFERENCES pickup_locations(id),
  delivery_zone_id UUID REFERENCES delivery_zones(id),
  delivery_address TEXT,
  
  -- Pricing
  subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
  delivery_fee DECIMAL(10, 2) DEFAULT 0 CHECK (delivery_fee >= 0),
  total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
  
  -- Payment
  payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash', 'online')),
  payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_reference VARCHAR(100),
  paid_at TIMESTAMP WITH TIME ZONE,
  
  -- Order status
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  
  -- Tracking
  notes TEXT,
  admin_notes TEXT,
  confirmed_at TIMESTAMP WITH TIME ZONE,
  shipped_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  cancelled_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ORDER ITEMS TABLE
-- =====================================================
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  
  -- Snapshot of product details at time of purchase
  product_name VARCHAR(200) NOT NULL,
  price_at_purchase DECIMAL(10, 2) NOT NULL CHECK (price_at_purchase >= 0),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit VARCHAR(50) NOT NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE pickup_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Admin email allowlist for marketplace management
CREATE TABLE IF NOT EXISTS admin_emails (
  email TEXT PRIMARY KEY,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE admin_emails ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage admin emails" ON admin_emails
  FOR ALL USING (auth.role() = 'service_role');

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM admin_emails
    WHERE email = auth.jwt()->>'email'
      AND is_active = true
  );
$$ LANGUAGE sql STABLE;

-- Product Categories: Public read, admin write
CREATE POLICY "Anyone can view active categories" ON product_categories
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage categories" ON product_categories
  FOR ALL USING (is_admin());

-- Products: Public read active, admin write
CREATE POLICY "Anyone can view active products" ON products
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage products" ON products
  FOR ALL USING (is_admin());

-- Delivery Zones: Public read active, admin write
CREATE POLICY "Anyone can view active delivery zones" ON delivery_zones
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage delivery zones" ON delivery_zones
  FOR ALL USING (is_admin());

-- Pickup Locations: Public read active, admin write
CREATE POLICY "Anyone can view active pickup locations" ON pickup_locations
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage pickup locations" ON pickup_locations
  FOR ALL USING (is_admin());

-- Orders: Users see own orders, admins see all
CREATE POLICY "Users can view their own orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own orders" ON orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pending orders" ON orders
  FOR UPDATE USING (
    auth.uid() = user_id AND status = 'pending'
  );

CREATE POLICY "Admins can view all orders" ON orders
  FOR SELECT USING (is_admin());

CREATE POLICY "Admins can update all orders" ON orders
  FOR UPDATE USING (is_admin());

-- Order Items: Access follows order access
CREATE POLICY "Users can view their order items" ON order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert order items for their orders" ON order_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all order items" ON order_items
  FOR SELECT USING (is_admin());

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_product_categories_updated_at BEFORE UPDATE ON product_categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_delivery_zones_updated_at BEFORE UPDATE ON delivery_zones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pickup_locations_updated_at BEFORE UPDATE ON pickup_locations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCTION TO GENERATE ORDER NUMBER
-- =====================================================
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
  NEW.order_number := 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('order_number_seq')::TEXT, 6, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS order_number_seq;

CREATE TRIGGER set_order_number BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION generate_order_number();

-- =====================================================
-- SEED DATA - DEFAULT CATEGORIES
-- =====================================================
INSERT INTO product_categories (name, description, display_order) VALUES
  ('Feed', 'Poultry feed and grains', 1),
  ('Medication', 'Vaccines, antibiotics, and treatments', 2),
  ('Vitamins & Supplements', 'Vitamins, minerals, and growth supplements', 3),
  ('Equipment', 'Feeders, drinkers, and farm equipment', 4),
  ('Disinfectants', 'Cleaning and disinfection supplies', 5);

-- =====================================================
-- SAMPLE PICKUP LOCATION
-- =====================================================
INSERT INTO pickup_locations (location_name, address, state, phone) VALUES
  ('Smart Farm Main Store', '123 Farm Road, Ikeja', 'Lagos', '+234-800-FARM-001');

-- =====================================================
-- SAMPLE DELIVERY ZONES (Nigerian States)
-- =====================================================
INSERT INTO delivery_zones (state_name, delivery_fee, estimated_days) VALUES
  ('Lagos', 2000.00, '1-2 days'),
  ('Ogun', 2500.00, '2-3 days'),
  ('Oyo', 3000.00, '2-3 days'),
  ('Abuja', 3500.00, '3-4 days'),
  ('Kano', 4000.00, '4-5 days');

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================
COMMENT ON TABLE orders IS 'Customer orders for poultry supplies';
COMMENT ON TABLE products IS 'Poultry products available for purchase';
COMMENT ON TABLE product_categories IS 'Product categorization';
COMMENT ON TABLE delivery_zones IS 'States covered for delivery with fees';
COMMENT ON TABLE pickup_locations IS 'Physical locations for order pickup';
