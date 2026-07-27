# Data source and publication note

## Source

This project uses the simulated
[Starbucks Customer Data](https://www.kaggle.com/datasets/ihormuliar/starbucks-customer-data/data)
published on Kaggle by Ihor Muliar. The dataset contains three files describing
offers, customer profiles, and app events.

Kaggle lists the dataset under the
[Community Data License Agreement — Permissive 1.0](https://cdla.dev/permissive-1-0/).

## Repository policy

The GitHub repository does not redistribute the raw CSVs or row-level cleaned
exports. Contributors download the source files from Kaggle and place them in
`data/raw/`. This keeps the repository small, preserves the source attribution,
and prevents generated databases from being committed accidentally.

The tracked CSVs in `output/` are aggregate analytical results. They are
reproducible by running the pipeline and contain no direct customer profile
records.

## Non-affiliation

This is an independent educational portfolio project using simulated data. It
is not sponsored by or affiliated with Starbucks.
