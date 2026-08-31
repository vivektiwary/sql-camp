-- =====================================================================
-- 02_seed_dimensions.sql  --  the "lists of things"
-- ---------------------------------------------------------------------
-- Every company, customer and vendor in this dataset is FICTIONAL and the
-- numbers are synthetic. Nothing here is real market data. That is on
-- purpose: you can publish your work, share your screen, and post your
-- queries anywhere without leaking anyone's information.
-- =====================================================================

-- ---------------------------------------------------------------------
-- dim_date : 2021-01-01 .. 2027-12-31, April-March fiscal year
-- ---------------------------------------------------------------------
INSERT INTO dim_date
SELECT
    d::date                                                   AS date_key,
    EXTRACT(YEAR  FROM d)::int                                AS year,
    EXTRACT(QUARTER FROM d)::int                              AS quarter,
    EXTRACT(MONTH FROM d)::int                                AS month,
    TO_CHAR(d, 'Mon')                                         AS month_name,
    EXTRACT(DAY   FROM d)::int                                AS day_of_month,
    EXTRACT(ISODOW FROM d)::int                               AS day_of_week,
    TO_CHAR(d, 'Dy')                                          AS day_name,
    EXTRACT(ISODOW FROM d)::int <= 5                          AS is_weekday,
    DATE_TRUNC('month', d)::date                              AS month_start_date,
    (DATE_TRUNC('month', d) + INTERVAL '1 month - 1 day')::date AS month_end_date,
    d::date = (DATE_TRUNC('month', d) + INTERVAL '1 month - 1 day')::date AS is_month_end,
    d::date = (DATE_TRUNC('quarter', d) + INTERVAL '3 month - 1 day')::date AS is_quarter_end,
    (EXTRACT(MONTH FROM d) = 12 AND EXTRACT(DAY FROM d) = 31) AS is_year_end,
    CASE WHEN EXTRACT(MONTH FROM d) >= 4
         THEN EXTRACT(YEAR FROM d)::int + 1
         ELSE EXTRACT(YEAR FROM d)::int END                   AS fiscal_year,
    ((EXTRACT(MONTH FROM d)::int + 8) % 12) / 3 + 1           AS fiscal_quarter,
    ((EXTRACT(MONTH FROM d)::int + 8) % 12) + 1               AS fiscal_month,
    'FY' || RIGHT((CASE WHEN EXTRACT(MONTH FROM d) >= 4
                        THEN EXTRACT(YEAR FROM d)::int + 1
                        ELSE EXTRACT(YEAR FROM d)::int END)::text, 2)
          || '-Q' || (((EXTRACT(MONTH FROM d)::int + 8) % 12) / 3 + 1)::text AS fiscal_period
FROM generate_series(DATE '2021-01-01', DATE '2027-12-31', INTERVAL '1 day') d;

-- ---------------------------------------------------------------------
-- dim_company : 20 fictional listed companies across sectors and countries
-- ---------------------------------------------------------------------
INSERT INTO dim_company (company_id, ticker, company_name, sector, industry, country, currency, exchange, listing_date, shares_out_m) VALUES
 (1,'KVRA','Kaveri Retail Ltd',            'Consumer Discretionary','Specialty Retail',     'India','INR','NSE','2014-06-12', 620.00),
 (2,'NLSP','Nilgiri Spice Foods Ltd',      'Consumer Staples',      'Packaged Foods',       'India','INR','NSE','2011-03-04', 480.00),
 (3,'ARVT','Aravalli Steel & Tubes Ltd',   'Materials',             'Steel',                'India','INR','BSE','2007-09-18', 310.00),
 (4,'BHMT','Bhima Motors Ltd',             'Consumer Discretionary','Auto Manufacturers',   'India','INR','NSE','2004-11-22', 275.00),
 (5,'CHNB','Chenab Power Ltd',             'Utilities',             'Electric Utilities',   'India','INR','NSE','2009-02-10', 890.00),
 (6,'SRYU','Suryodaya Solar Ltd',          'Utilities',             'Renewable Energy',     'India','INR','NSE','2019-08-27', 410.00),
 (7,'MRDN','Meridian Softworks Ltd',       'Information Technology','Software',             'India','INR','NSE','2016-05-19', 340.00),
 (8,'VNDH','Vindhya Pharma Ltd',           'Health Care',           'Generic Drugs',        'India','INR','NSE','2012-07-30', 265.00),
 (9,'KSHB','Kosambi Housing Finance Ltd',  'Financials',            'Mortgage Finance',     'India','INR','NSE','2015-01-15', 520.00),
(10,'TPTI','Taptee Logistics Ltd',         'Industrials',           'Trucking & Logistics', 'India','INR','BSE','2018-10-08', 190.00),
(11,'GDVR','Godavari Cement Ltd',          'Materials',             'Cement',               'India','INR','NSE','2003-04-25', 355.00),
(12,'ZNTH','Zenith Telecom Ltd',           'Communication Services','Wireless Telecom',     'India','INR','NSE','2010-12-01', 1450.00),
(13,'NRTH','Northgate Analytics Inc',      'Information Technology','Data & Analytics',     'USA',  'USD','NASDAQ','2020-02-14', 118.00),
(14,'CLDW','Cloudwell Systems Inc',        'Information Technology','Cloud Infrastructure', 'USA',  'USD','NASDAQ','2017-06-09',  96.00),
(15,'HRBR','Harbourline Freight Corp',     'Industrials',           'Marine Shipping',      'USA',  'USD','NYSE','2006-03-17',  74.00),
(16,'PLMT','Palmetto Grocers Inc',         'Consumer Staples',      'Food Retail',          'USA',  'USD','NYSE','1998-11-05', 142.00),
(17,'ATLB','Atlas Biosciences Inc',        'Health Care',           'Biotechnology',        'USA',  'USD','NASDAQ','2021-09-23',  63.00),
(18,'FRNC','Frontier Energy Corp',         'Energy',                'Oil & Gas E&P',        'USA',  'USD','NYSE','2002-01-29', 205.00),
(19,'STNM','Stonemark Bancorp',            'Financials',            'Regional Banks',       'USA',  'USD','NYSE','1995-05-11', 158.00),
(20,'VRDN','Verdant Materials Plc',        'Materials',             'Specialty Chemicals',  'UK',   'GBP','LSE', '2013-04-03',  88.00);

-- ---------------------------------------------------------------------
-- dim_account : chart of accounts for OUR company (Meridian Softworks Ltd)
-- ---------------------------------------------------------------------
INSERT INTO dim_account (account_id, account_code, account_name, statement, category, subcategory, normal_balance, is_cash_account, sort_order) VALUES
 (1,'4000','Subscription Revenue',       'IS','Revenue','Recurring',      'CR',FALSE,10),
 (2,'4010','Services Revenue',           'IS','Revenue','Non-recurring',  'CR',FALSE,20),
 (3,'4020','Hardware Resale Revenue',    'IS','Revenue','Non-recurring',  'CR',FALSE,30),
 (4,'5000','Hosting & Infrastructure',   'IS','COGS','Direct',            'DR',FALSE,40),
 (5,'5010','Customer Support Salaries',  'IS','COGS','Direct',            'DR',FALSE,50),
 (6,'5020','Third Party Licences',       'IS','COGS','Direct',            'DR',FALSE,60),
 (7,'6000','Salaries & Wages',           'IS','Opex','Personnel',         'DR',FALSE,70),
 (8,'6010','Employee Benefits',          'IS','Opex','Personnel',         'DR',FALSE,80),
 (9,'6020','Recruitment',                'IS','Opex','Personnel',         'DR',FALSE,90),
(10,'6100','Marketing Programmes',       'IS','Opex','Sales & Marketing', 'DR',FALSE,100),
(11,'6110','Sales Commission',           'IS','Opex','Sales & Marketing', 'DR',FALSE,110),
(12,'6120','Travel & Entertainment',     'IS','Opex','Sales & Marketing', 'DR',FALSE,120),
(13,'6200','Rent & Facilities',          'IS','Opex','G&A',               'DR',FALSE,130),
(14,'6210','Professional Fees',          'IS','Opex','G&A',               'DR',FALSE,140),
(15,'6220','Software Subscriptions',     'IS','Opex','G&A',               'DR',FALSE,150),
(16,'6230','Insurance',                  'IS','Opex','G&A',               'DR',FALSE,160),
(17,'6240','Telephone & Internet',       'IS','Opex','G&A',               'DR',FALSE,170),
(18,'6900','Depreciation & Amortisation','IS','Opex','Non-cash',          'DR',FALSE,180),
(19,'7000','Interest Expense',           'IS','Below the line','Finance', 'DR',FALSE,190),
(20,'7100','Income Tax Expense',         'IS','Below the line','Tax',     'DR',FALSE,200),
(21,'1000','Cash at Bank',               'BS','Asset','Current',          'DR',TRUE, 210),
(22,'1100','Accounts Receivable',        'BS','Asset','Current',          'DR',FALSE,220),
(23,'1200','Prepaid Expenses',           'BS','Asset','Current',          'DR',FALSE,230),
(24,'1500','Property Plant & Equipment', 'BS','Asset','Non-current',      'DR',FALSE,240),
(25,'2000','Accounts Payable',           'BS','Liability','Current',      'CR',FALSE,250),
(26,'2100','Accrued Expenses',           'BS','Liability','Current',      'CR',FALSE,260),
(27,'2200','Deferred Revenue',           'BS','Liability','Current',      'CR',FALSE,270),
(28,'2500','Long Term Debt',             'BS','Liability','Non-current',  'CR',FALSE,280),
(29,'3000','Share Capital',              'BS','Equity','Contributed',     'CR',FALSE,290),
(30,'3100','Retained Earnings',          'BS','Equity','Accumulated',     'CR',FALSE,300);

-- ---------------------------------------------------------------------
-- dim_department
-- ---------------------------------------------------------------------
INSERT INTO dim_department (dept_id, dept_name, dept_group, cost_center, region) VALUES
 (1,'Engineering',      'Support',            'CC-100','India'),
 (2,'Product',          'Support',            'CC-110','India'),
 (3,'Sales',            'Revenue-generating', 'CC-200','India'),
 (4,'Sales - Overseas', 'Revenue-generating', 'CC-210','USA'),
 (5,'Marketing',        'Revenue-generating', 'CC-300','India'),
 (6,'Customer Success', 'Revenue-generating', 'CC-400','India'),
 (7,'Finance',          'Support',            'CC-500','India'),
 (8,'People & Admin',   'Support',            'CC-600','India');

-- ---------------------------------------------------------------------
-- pf_portfolio
-- ---------------------------------------------------------------------
INSERT INTO pf_portfolio (portfolio_id, portfolio_name, mandate, base_currency, inception_date) VALUES
 (1,'Bluewater Core Equity',  'Large-cap long-only',        'INR','2023-04-03'),
 (2,'Bluewater Opportunities','Mid-cap high conviction',    'INR','2023-04-03'),
 (3,'Bluewater Global Feeder','Global developed markets',   'USD','2023-07-03');

-- ---------------------------------------------------------------------
-- dim_customer : 900 fictional B2B customers, generated
-- ---------------------------------------------------------------------
INSERT INTO dim_customer (customer_id, customer_name, segment, country, industry, signup_date, channel, is_active)
SELECT
    n,
    (ARRAY['Alder','Banyan','Cedar','Deodar','Elm','Fig','Gulmohar','Hazel','Ironwood','Jacaranda',
           'Kadam','Larch','Mahogany','Neem','Oak','Peepal','Quince','Rosewood','Sal','Teak',
           'Umbrella','Vachellia','Willow','Xylia','Yew','Zelkova'])[1 + (n * 7) % 26]
      || ' ' ||
    (ARRAY['Analytics','Brands','Capital','Dynamics','Enterprises','Foods','Global','Holdings',
           'Industries','Labs','Logistics','Media','Networks','Partners','Retail','Systems',
           'Technologies','Ventures'])[1 + (n * 11) % 18]
      || ' ' ||
    (ARRAY['Ltd','Pvt Ltd','Inc','LLC','Plc'])[1 + (n * 3) % 5]                       AS customer_name,
    CASE WHEN n % 20 = 0 THEN 'Enterprise'
         WHEN n % 4  = 0 THEN 'Mid-Market'
         ELSE 'SMB' END                                                                AS segment,
    (ARRAY['India','India','India','India','USA','USA','UK','Singapore','UAE','Australia'])[1 + n % 10] AS country,
    (ARRAY['Retail','Manufacturing','Healthcare','Financial Services','Logistics','Education',
           'Hospitality','Real Estate','Media','Professional Services'])[1 + (n * 13) % 10]  AS industry,
    DATE '2023-04-01' + ((n * 37) % 1095)                                              AS signup_date,
    (ARRAY['Inbound','Outbound','Partner','Referral','Paid Search','Events'])[1 + (n * 5) % 6] AS channel,
    TRUE
FROM generate_series(1, 900) n;
