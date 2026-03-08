-- Create creator subscription plans table
CREATE TABLE IF NOT EXISTS creator_subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  benefits TEXT ARRAY,
  is_active BOOLEAN DEFAULT true,
  stripe_price_id TEXT UNIQUE,
  revenuecat_product_id TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE creator_subscription_plans ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY creator_plans_read ON creator_subscription_plans
  FOR SELECT USING (true);

CREATE POLICY creator_plans_manage ON creator_subscription_plans
  FOR ALL USING (auth.uid() = creator_id)
  WITH CHECK (auth.uid() = creator_id);

-- Create index
CREATE INDEX creator_plans_creator_idx ON creator_subscription_plans(creator_id);
CREATE INDEX creator_plans_active_idx ON creator_subscription_plans(is_active) WHERE is_active = true;

-- Create paid subscriptions table
CREATE TABLE IF NOT EXISTS paid_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscriber_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES creator_subscription_plans(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'expired', 'on_hold')),
  revenuecat_subscription_id TEXT UNIQUE,
  stripe_subscription_id TEXT UNIQUE,
  current_period_start DATE NOT NULL,
  current_period_end DATE NOT NULL,
  auto_renew BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  canceled_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(subscriber_id, plan_id)
);

-- Enable RLS
ALTER TABLE paid_subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY paid_subs_read_own ON paid_subscriptions
  FOR SELECT USING (auth.uid() = subscriber_id);

CREATE POLICY paid_subs_insert ON paid_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = subscriber_id);

CREATE POLICY paid_subs_update ON paid_subscriptions
  FOR UPDATE USING (auth.uid() = subscriber_id)
  WITH CHECK (auth.uid() = subscriber_id);

CREATE POLICY paid_subs_delete ON paid_subscriptions
  FOR DELETE USING (auth.uid() = subscriber_id);

-- Create indexes
CREATE INDEX paid_subs_subscriber_idx ON paid_subscriptions(subscriber_id);
CREATE INDEX paid_subs_plan_idx ON paid_subscriptions(plan_id);
CREATE INDEX paid_subs_status_idx ON paid_subscriptions(status);
CREATE INDEX paid_subs_active_idx ON paid_subscriptions(status, current_period_end) WHERE status = 'active';

-- Create trigger for updated_at
CREATE TRIGGER creator_plans_updated_at
  BEFORE UPDATE ON creator_subscription_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER paid_subs_updated_at
  BEFORE UPDATE ON paid_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
