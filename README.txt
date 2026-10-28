ANALTIXLABS — FINAL MYSQL PROJECT SUBMISSION
Mobile Tech Retailers Q1–Q10 | QuickBite Analytics Q1–Q21
Target: MySQL 8.0.46

PACKAGE CONTENTS
This submission includes both complete assignment briefs, all supplied CSV datasets, table-creation scripts, full SQL answer scripts, the question-by-question analysis guide, project-specific run guides, and the QuickBite anomaly reference.

START HERE
1. Read README.txt and QUESTION_BY_QUESTION_ANALYSIS_GUIDE.txt for the full review, then the project README for dataset load order.
2. Run the matching Project_1_01_Create_Tables.sql or Project_2_01_Create_Tables.sql.
3. Import the included CSVs into the matching tables in the order shown in that project's README.
4. Run the matching numbered solution script. Each script selects its project database and labels every question.

Q7 — MOBILE TECH RETAILERS
The Q7 query is corrected in the included full Q1–Q10 script. It reports annual top-five model results for 2008, 2009, and 2010, retains sales ties, and includes a coverage count and an all-three-years flag. The supplied dataset has no model that reaches the top five in all three years. The query therefore shows the yearly ranked results and makes the “none across all three years” conclusion visible instead of returning a blank result.

QUICKBITE COVERAGE
All 21 questions are included. Q16–Q21 are the six requested anomaly-detection questions. The CSV datasets are included so the SQL can be loaded and run from this package.

For the Q17 and Q20 counts found in the supplied QuickBite CSVs versus the assignment reference, see QUESTION_BY_QUESTION_ANALYSIS_GUIDE.txt.

Mobile Tech Q9 returns no rows on the included CSVs because no manufacturer meets both year conditions; this is the correct empty result, not a NULL record. Details are in QUESTION_BY_QUESTION_ANALYSIS_GUIDE.txt.
