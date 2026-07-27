# GitHub publication checklist

## Recommended repository metadata

- Repository name: `starbucks-sql-analytics-portfolio`
- Description: `Audited SQLite/MySQL pipeline for sequence-aware Starbucks offer analytics, data quality, window functions, and stored procedures.`
- Visibility: Public
- Suggested topics: `sql`, `sqlite`, `mysql`, `data-cleaning`,
  `data-quality`, `analytics-engineering`, `window-functions`,
  `stored-procedures`, `portfolio-project`

## Before the first push

- Confirm that only aggregate evidence is tracked from `output/`.
- Confirm that `data/raw/*.csv`, generated clean exports, `.sqlite` files, and
  `mysql/.env` are ignored.
- Review the author name/email for the first commit.
- Choose a software license deliberately if you want others to reuse the code.
  No software license has been selected automatically.

## Publish with Git

```bash
git init -b main
git add .
git status
git commit -m "Publish Starbucks SQL analytics portfolio"
git remote add origin https://github.com/BarryZhong1/starbucks-sql-analytics-portfolio.git
git push -u origin main
```

After the push, wait for both GitHub Actions jobs to pass:

- `sqlite-pipeline`
- `mysql-smoke-test`

## Recruiter-facing final check

- The README opens with quantified outcomes and the business problem.
- Raw data is attributed but not redistributed.
- The latest validation report shows 0 hard errors and unchanged source hashes.
- The sequence-aware funnel is used for business rates.
- Limitations distinguish descriptive analysis from causal claims.
- MySQL assignment coverage remains available without dominating the business
  story.
