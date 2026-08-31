-- =====================================================================
-- 04_verify.sql  --  "did my install actually work?"
-- ---------------------------------------------------------------------
--   psql -d sqlcamp -f 04_verify.sql
--
-- Every line below should say PASS. If any line says FAIL, tell your tutor
-- which one -- do not start the course on a broken dataset, because you
-- will spend a week thinking you cannot write SQL when actually the data
-- is missing.
-- =====================================================================
\pset border 2
\echo ''
\echo '================ SQL CAMP DATASET HEALTH CHECK ================'

SELECT check_name, expected, actual,
       CASE WHEN actual = expected THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT 'dim_date rows'          AS check_name, 2556  AS expected, (SELECT count(*) FROM dim_date)::int            AS actual, 1 AS ord
    UNION ALL SELECT 'dim_company rows',            20,   (SELECT count(*) FROM dim_company)::int, 2
    UNION ALL SELECT 'dim_account rows',            30,   (SELECT count(*) FROM dim_account)::int, 3
    UNION ALL SELECT 'dim_department rows',          8,   (SELECT count(*) FROM dim_department)::int, 4
    UNION ALL SELECT 'dim_customer rows',          900,   (SELECT count(*) FROM dim_customer)::int, 5
    UNION ALL SELECT 'fact_price rows',          16940,   (SELECT count(*) FROM fact_price)::int, 6
    UNION ALL SELECT 'fs_income_statement rows',   240,   (SELECT count(*) FROM fs_income_statement)::int, 7
    UNION ALL SELECT 'fs_balance_sheet rows',      240,   (SELECT count(*) FROM fs_balance_sheet)::int, 8
    UNION ALL SELECT 'fs_cash_flow rows',          240,   (SELECT count(*) FROM fs_cash_flow)::int, 9
    UNION ALL SELECT 'gl_journal_line rows',     12168,   (SELECT count(*) FROM gl_journal_line)::int, 10
    UNION ALL SELECT 'gl_budget rows',            1053,   (SELECT count(*) FROM gl_budget)::int, 11
    UNION ALL SELECT 'saas_subscription rows',     900,   (SELECT count(*) FROM saas_subscription)::int, 12
    UNION ALL SELECT 'saas_invoice rows',         8639,   (SELECT count(*) FROM saas_invoice)::int, 13
    UNION ALL SELECT 'saas_payment rows',         8248,   (SELECT count(*) FROM saas_payment)::int, 14
    UNION ALL SELECT 'pf_trade rows',              160,   (SELECT count(*) FROM pf_trade)::int, 15
    UNION ALL SELECT 'raw_vendor_invoices rows',    40,   (SELECT count(*) FROM raw_vendor_invoices)::int, 16
    -- accounting integrity: these are the checks a real finance system runs nightly
    UNION ALL SELECT 'balance sheets that balance', 0,
              (SELECT count(*) FROM fs_balance_sheet WHERE total_assets <> total_liabilities + total_equity)::int, 17
    UNION ALL SELECT 'cash flow statements that tie', 0,
              (SELECT count(*) FROM fs_cash_flow WHERE net_change_cash <> cfo + cfi + cff)::int, 18
    UNION ALL SELECT 'journals where DR = CR', 0,
              (SELECT count(*) FROM (SELECT journal_id FROM gl_journal_line
                                     GROUP BY journal_id HAVING sum(debit) <> sum(credit)) z)::int, 19
) t
ORDER BY ord;

\echo ''
\echo 'If every row says PASS you are ready. Start with Module 0.'
\echo ''
