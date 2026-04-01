-- ===================================================================================
-- Migration   : V11
-- Title       : Init Gamification & Billing
-- Author      : SmartEdu Telu
-- Date        : 2026-04-01
-- Description : Badges, points, subscription plans, transactions, invoices,
--               coupons and coupon usage tracking
-- ===================================================================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GAMIFICATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- -----------------------------------------------------------------------------------
-- TABLE: badges
-- Description: Achievement badges users can earn (e.g. "First Exam", "Perfect Score")
-- -----------------------------------------------------------------------------------
CREATE TABLE badges (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)    NOT NULL UNIQUE,
    description     TEXT,
    icon            TEXT,
    criteria        TEXT
);

-- -----------------------------------------------------------------------------------
-- TABLE: user_badges
-- Description: Badges awarded to users
-- -----------------------------------------------------------------------------------
CREATE TABLE user_badges (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    badge_id        UUID            NOT NULL REFERENCES badges (id) ON DELETE CASCADE,
    earned_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, badge_id)
);

CREATE INDEX idx_user_badges_user_id  ON user_badges (user_id);
CREATE INDEX idx_user_badges_badge_id ON user_badges (badge_id);

-- -----------------------------------------------------------------------------------
-- TABLE: points
-- Description: Point ledger entries per user — every earn event is a row
-- -----------------------------------------------------------------------------------
CREATE TABLE points (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    points          INT             NOT NULL,
    source          VARCHAR(100)    NOT NULL,
    source_id       UUID,
    earned_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_points_user_id   ON points (user_id);
CREATE INDEX idx_points_source    ON points (source, source_id);

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- BILLING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- -----------------------------------------------------------------------------------
-- TABLE: plans
-- Description: Subscription plans available for purchase
-- -----------------------------------------------------------------------------------
CREATE TABLE plans (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100)    NOT NULL UNIQUE,
    description     TEXT,
    price           NUMERIC(15, 2)  NOT NULL,
    duration_days   INT             NOT NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE
);

-- -----------------------------------------------------------------------------------
-- TABLE: subscriptions
-- Description: A user's active or historical subscription to a plan
-- -----------------------------------------------------------------------------------
CREATE TABLE subscriptions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    plan_id         UUID            NOT NULL REFERENCES plans (id),
    start_date      TIMESTAMPTZ     NOT NULL,
    end_date        TIMESTAMPTZ     NOT NULL,
    status          VARCHAR(50)     NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'expired', 'cancelled', 'pending')),
    CHECK (end_date > start_date)
);

CREATE INDEX idx_subscriptions_user_id  ON subscriptions (user_id);
CREATE INDEX idx_subscriptions_plan_id  ON subscriptions (plan_id);
CREATE INDEX idx_subscriptions_status   ON subscriptions (status);

-- -----------------------------------------------------------------------------------
-- TABLE: coupons
-- Description: Discount codes — percentage or fixed amount
-- -----------------------------------------------------------------------------------
CREATE TABLE coupons (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(100)    NOT NULL UNIQUE,
    type            VARCHAR(20)     NOT NULL
                        CHECK (type IN ('percentage', 'fixed')),
    value           NUMERIC(10, 2)  NOT NULL,
    min_purchase    NUMERIC(15, 2),
    max_uses        INT,
    used_count      INT             NOT NULL DEFAULT 0,
    plan_id         UUID            REFERENCES plans (id) ON DELETE SET NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    valid_from      TIMESTAMPTZ     NOT NULL,
    valid_until     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_coupons_code      ON coupons (code);
CREATE INDEX idx_coupons_plan_id   ON coupons (plan_id);

-- -----------------------------------------------------------------------------------
-- TABLE: transactions
-- Description: A payment transaction initiated by a user for a subscription
-- -----------------------------------------------------------------------------------
CREATE TABLE transactions (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    subscription_id     UUID            NOT NULL REFERENCES subscriptions (id),
    amount              NUMERIC(15, 2)  NOT NULL,
    currency            VARCHAR(10)     NOT NULL DEFAULT 'IDR',
    status              VARCHAR(50)     NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'paid', 'failed', 'refunded', 'expired')),
    payment_method      VARCHAR(100),
    payment_ref         VARCHAR(255),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transactions_user_id         ON transactions (user_id);
CREATE INDEX idx_transactions_subscription_id ON transactions (subscription_id);
CREATE INDEX idx_transactions_status          ON transactions (status);

-- -----------------------------------------------------------------------------------
-- TABLE: invoices
-- Description: Formal invoice document generated per transaction
-- -----------------------------------------------------------------------------------
CREATE TABLE invoices (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    transaction_id      UUID            NOT NULL UNIQUE REFERENCES transactions (id),
    invoice_number      VARCHAR(100)    NOT NULL UNIQUE,
    total               NUMERIC(15, 2)  NOT NULL,
    status              VARCHAR(50)     NOT NULL DEFAULT 'unpaid'
                            CHECK (status IN ('unpaid', 'paid', 'cancelled')),
    issued_at           TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    paid_at             TIMESTAMPTZ
);

CREATE INDEX idx_invoices_user_id        ON invoices (user_id);
CREATE INDEX idx_invoices_invoice_number ON invoices (invoice_number);

-- -----------------------------------------------------------------------------------
-- TABLE: coupon_usages
-- Description: Tracks each redemption of a coupon to enforce usage limits
-- -----------------------------------------------------------------------------------
CREATE TABLE coupon_usages (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    coupon_id       UUID            NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
    user_id         UUID            NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    transaction_id  UUID            NOT NULL REFERENCES transactions (id) ON DELETE CASCADE,
    used_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    UNIQUE (coupon_id, transaction_id)
);

CREATE INDEX idx_coupon_usages_coupon_id      ON coupon_usages (coupon_id);
CREATE INDEX idx_coupon_usages_user_id        ON coupon_usages (user_id);
CREATE INDEX idx_coupon_usages_transaction_id ON coupon_usages (transaction_id);
