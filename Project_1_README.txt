PROJECT 1 — MOBILE TECH RETAILERS | MySQL 8.0.46

FILES
Project_1_01_Create_Tables.sql — creates the database and six tables.
Project_1_02_MobileTech_Solutions_Q1-Q10.sql — complete answers for Q1–Q10.
Project_1_Assignment_Brief.pdf — original assignment and schema.
Project_1_*.csv — all six supplied source datasets.

RUN ORDER
1. Run Project_1_01_Create_Tables.sql in MySQL Workbench.
2. Import the CSV files, preserving their headers, in this order:
   DIM_MANUFACTURER, DIM_MODEL, DIM_CUSTOMER, DIM_LOCATION, DIM_DATE, FACT_TRANSACTIONS.
3. Run the numbered blocks in Project_1_02_MobileTech_Solutions_Q1-Q10.sql.

INTERPRETATION NOTES
- DIM_CUSTOMER has no active/status field. Q1 treats a customer with a recorded purchase since 2005 as active and reports country/state because the question does not restrict the geography.
- Q5 computes realized average selling price as SUM(TotalPrice)/SUM(Quantity).
- Q7 ranks models separately for each of 2008, 2009, and 2010, retains ties, and shows annual top-five rows with a YearsInTopFive coverage count. In the supplied data, no model is top-five in all three years. The query still returns the annual results and marks that answer explicitly, rather than returning an empty result set.
- Q10 includes calendar years from DIM_DATE; years with no spend are treated as zero for the annual averages. Percentage change is NULL when the prior-year spend is zero or unavailable.

The SQL targets MySQL 8.0.46 and uses CTEs and window functions.
