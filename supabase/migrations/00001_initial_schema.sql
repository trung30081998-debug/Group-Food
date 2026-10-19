-- Initial schema for group food ordering sessions.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    bank_code VARCHAR(20),
    bank_account_no VARCHAR(50),
    bank_account_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    merchant_name VARCHAR(255),
    menu_image_url TEXT,
    deadline TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    shipping_fee DECIMAL(12, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.session_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    member_name VARCHAR(100) NOT NULL,
    member_phone VARCHAR(20),
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    transfer_code VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.member_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_member_id UUID NOT NULL REFERENCES public.session_members(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12, 2) NOT NULL,
    note VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Keep the payment audit record if a member is removed.
    session_member_id UUID REFERENCES public.session_members(id) ON DELETE SET NULL,
    gateway_transaction_id VARCHAR(100),
    amount_transferred DECIMAL(12, 2) NOT NULL,
    transfer_content TEXT NOT NULL,
    raw_payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_host ON public.sessions(host_id);
CREATE INDEX idx_members_session ON public.session_members(session_id);
CREATE INDEX idx_members_transfer_code ON public.session_members(transfer_code);
CREATE INDEX idx_transactions_member ON public.transactions(session_member_id);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.member_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- The product supports public share links.  Application-level session codes
-- govern link distribution; these policies permit the public client to use them.
CREATE POLICY "Public can read users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Public can create users" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Public can update users" ON public.users FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Public can read sessions" ON public.sessions FOR SELECT USING (true);
CREATE POLICY "Public can create sessions" ON public.sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "Public can update sessions" ON public.sessions FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public can delete sessions" ON public.sessions FOR DELETE USING (true);

CREATE POLICY "Public can read session members" ON public.session_members FOR SELECT USING (true);
CREATE POLICY "Public can create session members" ON public.session_members FOR INSERT WITH CHECK (true);
CREATE POLICY "Public can update session members" ON public.session_members FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public can delete session members" ON public.session_members FOR DELETE USING (true);

CREATE POLICY "Public can read member items" ON public.member_items FOR SELECT USING (true);
CREATE POLICY "Public can create member items" ON public.member_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Public can update member items" ON public.member_items FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Public can delete member items" ON public.member_items FOR DELETE USING (true);

CREATE POLICY "Public can read transactions" ON public.transactions FOR SELECT USING (true);
CREATE POLICY "Public can create transactions" ON public.transactions FOR INSERT WITH CHECK (true);
CREATE POLICY "Public can update transactions" ON public.transactions FOR UPDATE USING (true) WITH CHECK (true);
