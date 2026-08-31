-- =====================================================================
-- SQL CAMP / FINANCIAL ANALYST BOOTCAMP  --  01_schema.sql
-- ---------------------------------------------------------------------
-- Creates every table the course uses. Run this FIRST, then 02, then 03.
--
--   psql -d sqlcamp -f 01_schema.sql
--
-- Design notes for the curious student:
--   * Money is stored as NUMERIC, never FLOAT. Floats round badly and
--     a rounding error in a P&L is a career-limiting move.
--   * Table names use a prefix that tells you what kind of table it is:
--       dim_   a "dimension"  -> a list of things (companies, dates, accounts)
--       fact_  a "fact"       -> a list of events/measurements (prices, trades)
--       fs_    financial statements of listed companies
--       gl_    the internal general ledger of our own company
--       saas_  subscription business data (customers, invoices, payments)
--       pf_    portfolio data
--       raw_   deliberately messy data, used in the data-quality module
-- =====================================================================

DROP TABLE IF EXISTS raw_vendor_invoices CASCADE;
DROP TABLE IF EXISTS pf_trade CASCADE;
DROP TABLE IF EXISTS pf_holding CASCADE;
DROP TABLE IF EXISTS pf_portfolio CASCADE;
DROP TABLE IF EXISTS saas_payment CASCADE;
DROP TABLE IF EXISTS saas_invoice CASCADE;
DROP TABLE IF EXISTS saas_subscription CASCADE;
DROP TABLE IF EXISTS gl_budget CASCADE;
DROP TABLE IF EXISTS gl_journal_line CASCADE;
DROP TABLE IF EXISTS gl_headcount CASCADE;
DROP TABLE IF EXISTS fs_cash_flow CASCADE;
DROP TABLE IF EXISTS fs_balance_sheet CASCADE;
DROP TABLE IF EXISTS fs_income_statement CASCADE;
DROP TABLE IF EXISTS fact_fx_rate CASCADE;
DROP TABLE IF EXISTS fact_price CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_department CASCADE;
DROP TABLE IF EXISTS dim_account CASCADE;
DROP TABLE IF EXISTS dim_company CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

-- ---------------------------------------------------------------------
-- DIMENSIONS  (the "lists of things")
-- ---------------------------------------------------------------------

-- A calendar table. Every serious finance database has one, because the
-- financial year is almost never the calendar year and you do not want to
-- re-derive "which quarter is this?" in fifty different queries.
-- This dataset uses an April-March fiscal year (FY26 = Apr-2025 to Mar-2026).
CREATE TABLE dim_date (
    date_key         DATE PRIMARY KEY,
    year             INT  NOT NULL,
    quarter          INT  NOT NULL,          -- calendar quarter 1-4
    month            INT  NOT NULL,
    month_name       TEXT NOT NULL,
    day_of_month     INT  NOT NULL,
    day_of_week      INT  NOT NULL,          -- 1 = Monday ... 7 = Sunday
    day_name         TEXT NOT NULL,
    is_weekday       BOOLEAN NOT NULL,
    month_start_date DATE NOT NULL,
    month_end_date   DATE NOT NULL,
    is_month_end     BOOLEAN NOT NULL,
    is_quarter_end   BOOLEAN NOT NULL,
    is_year_end      BOOLEAN NOT NULL,       -- 31 December
    fiscal_year      INT  NOT NULL,          -- FY label, Apr-Mar
    fiscal_quarter   INT  NOT NULL,          -- 1 = Apr-Jun ... 4 = Jan-Mar
    fiscal_month     INT  NOT NULL,          -- 1 = April ... 12 = March
    fiscal_period    TEXT NOT NULL           -- e.g. 'FY26-Q1'
);

CREATE TABLE dim_company (
    company_id    INT PRIMARY KEY,
    ticker        TEXT NOT NULL UNIQUE,
    company_name  TEXT NOT NULL,
    sector        TEXT NOT NULL,
    industry      TEXT NOT NULL,
    country       TEXT NOT NULL,
    currency      CHAR(3) NOT NULL,
    exchange      TEXT NOT NULL,
    listing_date  DATE,
    shares_out_m  NUMERIC(14,2),             -- shares outstanding, millions
    is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

-- Chart of accounts for OUR company (the one whose ledger we analyse).
CREATE TABLE dim_account (
    account_id      INT PRIMARY KEY,
    account_code    TEXT NOT NULL UNIQUE,
    account_name    TEXT NOT NULL,
    statement       TEXT NOT NULL,           -- 'IS' income statement, 'BS' balance sheet
    category        TEXT NOT NULL,           -- Revenue / COGS / Opex / Asset / Liability / Equity
    subcategory     TEXT,
    normal_balance  CHAR(2) NOT NULL,        -- 'DR' or 'CR'
    is_cash_account BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order      INT NOT NULL
);

CREATE TABLE dim_department (
    dept_id     INT PRIMARY KEY,
    dept_name   TEXT NOT NULL,
    dept_group  TEXT NOT NULL,               -- 'Revenue-generating' or 'Support'
    cost_center TEXT NOT NULL,
    region      TEXT NOT NULL
);

CREATE TABLE dim_customer (
    customer_id   INT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    segment       TEXT NOT NULL,             -- SMB / Mid-Market / Enterprise
    country       TEXT NOT NULL,
    industry      TEXT NOT NULL,
    signup_date   DATE NOT NULL,
    channel       TEXT NOT NULL,             -- how we acquired them
    is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------
-- MARKET DATA
-- ---------------------------------------------------------------------

CREATE TABLE fact_price (
    company_id  INT     NOT NULL REFERENCES dim_company(company_id),
    price_date  DATE    NOT NULL REFERENCES dim_date(date_key),
    open_px     NUMERIC(14,4) NOT NULL,
    high_px     NUMERIC(14,4) NOT NULL,
    low_px      NUMERIC(14,4) NOT NULL,
    close_px    NUMERIC(14,4) NOT NULL,
    volume      BIGINT  NOT NULL,
    PRIMARY KEY (company_id, price_date)
);

CREATE TABLE fact_fx_rate (
    rate_date DATE     NOT NULL,
    from_ccy  CHAR(3)  NOT NULL,
    to_ccy    CHAR(3)  NOT NULL,
    rate      NUMERIC(14,6) NOT NULL,
    PRIMARY KEY (rate_date, from_ccy, to_ccy)
);

-- ---------------------------------------------------------------------
-- FINANCIAL STATEMENTS of the listed companies (quarterly)
-- These three tables tie together: the balance sheet balances, and the
-- cash flow statement explains the movement in cash. That is deliberate --
-- you will be asked to prove it.
-- ---------------------------------------------------------------------

CREATE TABLE fs_income_statement (
    company_id       INT  NOT NULL REFERENCES dim_company(company_id),
    period_end       DATE NOT NULL,
    period_type      TEXT NOT NULL,          -- 'Q' quarterly
    revenue          NUMERIC(18,2) NOT NULL,
    cogs             NUMERIC(18,2) NOT NULL,
    gross_profit     NUMERIC(18,2) NOT NULL,
    sga              NUMERIC(18,2) NOT NULL,
    rnd              NUMERIC(18,2) NOT NULL,
    other_opex       NUMERIC(18,2) NOT NULL,
    ebitda           NUMERIC(18,2) NOT NULL,
    depreciation     NUMERIC(18,2) NOT NULL,
    amortisation     NUMERIC(18,2) NOT NULL,
    ebit             NUMERIC(18,2) NOT NULL,
    interest_expense NUMERIC(18,2) NOT NULL,
    interest_income  NUMERIC(18,2) NOT NULL,
    other_income     NUMERIC(18,2) NOT NULL,
    pretax_income    NUMERIC(18,2) NOT NULL,
    tax_expense      NUMERIC(18,2) NOT NULL,
    net_income       NUMERIC(18,2) NOT NULL,
    shares_diluted_m NUMERIC(14,2) NOT NULL,
    eps_diluted      NUMERIC(10,4) NOT NULL,
    PRIMARY KEY (company_id, period_end)
);

CREATE TABLE fs_balance_sheet (
    company_id            INT  NOT NULL REFERENCES dim_company(company_id),
    period_end            DATE NOT NULL,
    cash                  NUMERIC(18,2) NOT NULL,
    accounts_receivable   NUMERIC(18,2) NOT NULL,
    inventory             NUMERIC(18,2) NOT NULL,
    other_current_assets  NUMERIC(18,2) NOT NULL,
    ppe_net               NUMERIC(18,2) NOT NULL,
    goodwill_intangibles  NUMERIC(18,2) NOT NULL,
    other_assets          NUMERIC(18,2) NOT NULL,
    total_assets          NUMERIC(18,2) NOT NULL,
    accounts_payable      NUMERIC(18,2) NOT NULL,
    accrued_liabilities   NUMERIC(18,2) NOT NULL,
    deferred_revenue      NUMERIC(18,2) NOT NULL,
    short_term_debt       NUMERIC(18,2) NOT NULL,
    long_term_debt        NUMERIC(18,2) NOT NULL,
    other_liabilities     NUMERIC(18,2) NOT NULL,
    total_liabilities     NUMERIC(18,2) NOT NULL,
    share_capital         NUMERIC(18,2) NOT NULL,
    retained_earnings     NUMERIC(18,2) NOT NULL,
    total_equity          NUMERIC(18,2) NOT NULL,
    PRIMARY KEY (company_id, period_end)
);

CREATE TABLE fs_cash_flow (
    company_id       INT  NOT NULL REFERENCES dim_company(company_id),
    period_end       DATE NOT NULL,
    net_income       NUMERIC(18,2) NOT NULL,
    dep_and_amort    NUMERIC(18,2) NOT NULL,
    change_in_wc     NUMERIC(18,2) NOT NULL,
    other_operating  NUMERIC(18,2) NOT NULL,
    cfo              NUMERIC(18,2) NOT NULL,  -- cash from operations
    capex            NUMERIC(18,2) NOT NULL,  -- negative = cash out
    other_investing  NUMERIC(18,2) NOT NULL,
    cfi              NUMERIC(18,2) NOT NULL,  -- cash from investing
    debt_raised      NUMERIC(18,2) NOT NULL,
    debt_repaid      NUMERIC(18,2) NOT NULL,
    dividends_paid   NUMERIC(18,2) NOT NULL,
    equity_issued    NUMERIC(18,2) NOT NULL,
    cff              NUMERIC(18,2) NOT NULL,  -- cash from financing
    net_change_cash  NUMERIC(18,2) NOT NULL,
    PRIMARY KEY (company_id, period_end)
);

-- ---------------------------------------------------------------------
-- OUR OWN COMPANY: general ledger, budget, headcount
-- (This is the FP&A playground: actual vs budget, variance analysis.)
-- ---------------------------------------------------------------------

CREATE TABLE gl_journal_line (
    line_id      BIGINT PRIMARY KEY,
    journal_id   BIGINT NOT NULL,            -- one journal = many lines, DR must equal CR
    entry_date   DATE   NOT NULL REFERENCES dim_date(date_key),
    fiscal_year  INT    NOT NULL,
    fiscal_month INT    NOT NULL,
    account_id   INT    NOT NULL REFERENCES dim_account(account_id),
    dept_id      INT    NOT NULL REFERENCES dim_department(dept_id),
    description  TEXT   NOT NULL,
    debit        NUMERIC(18,2) NOT NULL DEFAULT 0,
    credit       NUMERIC(18,2) NOT NULL DEFAULT 0,
    source       TEXT   NOT NULL             -- 'AP', 'AR', 'Payroll', 'Manual', 'Bank'
);

CREATE TABLE gl_budget (
    fiscal_year   INT NOT NULL,
    fiscal_month  INT NOT NULL,
    account_id    INT NOT NULL REFERENCES dim_account(account_id),
    dept_id       INT NOT NULL REFERENCES dim_department(dept_id),
    budget_amount NUMERIC(18,2) NOT NULL,
    version       TEXT NOT NULL DEFAULT 'Budget v1',
    PRIMARY KEY (fiscal_year, fiscal_month, account_id, dept_id, version)
);

CREATE TABLE gl_headcount (
    fiscal_year  INT NOT NULL,
    fiscal_month INT NOT NULL,
    dept_id      INT NOT NULL REFERENCES dim_department(dept_id),
    headcount    INT NOT NULL,
    avg_salary   NUMERIC(14,2) NOT NULL,
    PRIMARY KEY (fiscal_year, fiscal_month, dept_id)
);

-- ---------------------------------------------------------------------
-- SUBSCRIPTION BUSINESS (cohorts, churn, ARR, DSO, receivables ageing)
-- ---------------------------------------------------------------------

CREATE TABLE saas_subscription (
    subscription_id INT PRIMARY KEY,
    customer_id     INT  NOT NULL REFERENCES dim_customer(customer_id),
    plan            TEXT NOT NULL,           -- Starter / Growth / Scale / Enterprise
    mrr             NUMERIC(14,2) NOT NULL,  -- monthly recurring revenue
    seats           INT  NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE,                    -- NULL = still active
    cancel_reason   TEXT,
    billing_term    TEXT NOT NULL            -- 'Monthly' or 'Annual'
);

CREATE TABLE saas_invoice (
    invoice_id   INT  PRIMARY KEY,
    customer_id  INT  NOT NULL REFERENCES dim_customer(customer_id),
    invoice_date DATE NOT NULL,
    due_date     DATE NOT NULL,
    amount       NUMERIC(14,2) NOT NULL,
    currency     CHAR(3) NOT NULL,
    status       TEXT NOT NULL              -- 'Paid', 'Open', 'Written Off'
);

CREATE TABLE saas_payment (
    payment_id   INT  PRIMARY KEY,
    invoice_id   INT  NOT NULL REFERENCES saas_invoice(invoice_id),
    payment_date DATE NOT NULL,
    amount       NUMERIC(14,2) NOT NULL,
    method       TEXT NOT NULL
);

-- ---------------------------------------------------------------------
-- PORTFOLIO
-- ---------------------------------------------------------------------

CREATE TABLE pf_portfolio (
    portfolio_id   INT PRIMARY KEY,
    portfolio_name TEXT NOT NULL,
    mandate        TEXT NOT NULL,
    base_currency  CHAR(3) NOT NULL,
    inception_date DATE NOT NULL
);

CREATE TABLE pf_trade (
    trade_id     INT  PRIMARY KEY,
    portfolio_id INT  NOT NULL REFERENCES pf_portfolio(portfolio_id),
    company_id   INT  NOT NULL REFERENCES dim_company(company_id),
    trade_date   DATE NOT NULL,
    side         TEXT NOT NULL,              -- 'BUY' or 'SELL'
    quantity     NUMERIC(18,4) NOT NULL,
    price        NUMERIC(14,4) NOT NULL,
    fees         NUMERIC(14,2) NOT NULL
);

CREATE TABLE pf_holding (
    portfolio_id INT  NOT NULL REFERENCES pf_portfolio(portfolio_id),
    company_id   INT  NOT NULL REFERENCES dim_company(company_id),
    as_of_date   DATE NOT NULL,
    quantity     NUMERIC(18,4) NOT NULL,
    cost_basis   NUMERIC(18,2) NOT NULL,
    PRIMARY KEY (portfolio_id, company_id, as_of_date)
);

-- ---------------------------------------------------------------------
-- DELIBERATELY MESSY DATA
-- Used in the data-quality / reconciliation module. Everything that can be
-- wrong with a real vendor extract is wrong here on purpose: duplicates,
-- amounts stored as text, three different date formats, trailing spaces,
-- inconsistent vendor spellings, NULLs that should be zeros and zeros that
-- should be NULLs.
-- ---------------------------------------------------------------------

CREATE TABLE raw_vendor_invoices (
    row_id       INT PRIMARY KEY,
    vendor_name  TEXT,
    invoice_ref  TEXT,
    invoice_date TEXT,          -- yes, TEXT. That is the point.
    amount_text  TEXT,
    currency     TEXT,
    dept_code    TEXT,
    notes        TEXT
);

-- Indexes we will look at in the performance module.
CREATE INDEX idx_price_date ON fact_price(price_date);
CREATE INDEX idx_gl_period  ON gl_journal_line(fiscal_year, fiscal_month);
CREATE INDEX idx_gl_account ON gl_journal_line(account_id);
CREATE INDEX idx_inv_cust   ON saas_invoice(customer_id);
