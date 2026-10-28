PROJECT 2 — QUICKBITE ANALYTICS | MySQL 8.0.46

FILES
Project_2_01_Create_Tables.sql — creates the database and four tables.
Project_2_02_QuickBite_Solutions_Q1-Q21.sql — complete answers for Q1–Q21.
Project_2_Assignment_Brief.pdf — original assignment and schema.
Project_2_ANOMALY_REFERENCE_Q16-Q21.txt — supplied anomaly guide.
Project_2_*.csv — all four supplied source datasets.

RUN ORDER
1. Run Project_2_01_Create_Tables.sql in MySQL Workbench.
2. Import CSV files, preserving headers, in this order:
   DIM_CUSTOMER, DIM_DELIVERY_AGENT, DIM_RESTAURANT, FACT_ORDERS.
3. Keep every DIM_CUSTOMER row, including the duplicate-identity accounts.
4. Run the numbered blocks in Project_2_02_QuickBite_Solutions_Q1-Q21.sql.

SCHEMA NOTES
- FACT_ORDERS has no City field. Q1 and Q7 use the restaurant's City as the order city; Q15 uses the delivery agent's assigned City.
- DIM_CUSTOMER has no primary/unique constraint on CustomerID so the source anomaly rows remain loadable.
- Q21 uses the lowest CustomerID as a display convention for the presumed original account; the data does not establish account chronology.
- Q16–Q21 detect duplicates, unusually high daily agent volume, order-amount outliers, severe delivery delays, pre-membership orders, and orders linked to duplicate IDs. They calculate from the data rather than hard-code anomaly rows.

The SQL targets MySQL 8.0.46 and uses CTEs and window functions.

See QUESTION_BY_QUESTION_ANALYSIS_GUIDE.txt for per-question methods and an important mismatch between the Q17/Q20 anomaly reference counts and the supplied CSV results.
