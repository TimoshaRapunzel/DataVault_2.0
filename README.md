# retail_vault — Data Vault 2.0 on Snowflake

A production-grade **Data Vault 2.0** warehouse built on Snowflake, orchestrated with Apache Airflow + Cosmos, and transformed with dbt Core.

## Stack

| Layer | Technology |
|---|---|
| Source | `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` |
| Warehouse | Snowflake |
| Transformation | dbt Core `1.7.10` + dbt-snowflake `1.7.0` |
| DV macros | `datavault4dbt 1.5.0` |
| Orchestration | Apache Airflow `2.10.3` + astronomer-cosmos `1.11.2` |
| Container | Docker + Docker Compose |
| Python deps | `uv` (spec in `pyproject.toml`) |
| SQL lint | `sqlfluff ≥3.0` (Snowflake dialect, dbt templater) |
| Python lint | `ruff ≥0.4` (target py311, strict) |
| CI/CD | GitHub Actions — ruff → sqlfluff → gitleaks |

## Repository Structure

```
DataVault/
├── .github/workflows/ci.yml   # CI: lint + credential scan
├── airflow/
│   ├── dags/
│   │   └── retail_vault_dag.py
│   └── plugins/
├── dbt_core/
│   ├── models/
│   │   ├── staging/            # Source-aligned views (stg_tpch_*)
│   │   ├── raw_vault/
│   │   │   ├── hubs/           # hub_customer, hub_order
│   │   │   ├── links/          # lnk_customer_order
│   │   │   └── satellites/     # sat_customer_details
│   │   └── business_vault/     # pit_customer
│   ├── dbt_project.yml
│   ├── packages.yml
│   └── profiles.yml            # git-ignored; reads env vars
├── .env.example                # Copy → .env, fill in secrets
├── .pre-commit-config.yaml
├── .sqlfluff
├── docker-compose.yml
├── Dockerfile
├── Makefile
└── pyproject.toml
```

## Quick Start

### 1. Clone & configure secrets
```bash
git clone <repo-url> && cd DataVault
cp .env.example .env
# Edit .env — fill in SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, etc.
```

### 2. Build & start
```bash
make build
make up
# Airflow UI → http://localhost:8080  (admin / admin)
```

### 3. Install pre-commit hooks
```bash
make pre-commit-install
```

### 4. Verify dbt connection
```bash
make dbt-debug
# Expected: All checks passed!
```

### 5. Install dbt packages
```bash
make dbt-deps
```

### 6. Run models
```bash
make run-local        # full refresh
make run-incremental  # incremental load
```

### 7. Lint
```bash
make lint             # ruff + sqlfluff
```

## Makefile Targets

| Target | Description |
|---|---|
| `make build` | Build Docker images |
| `make up` | Start all services |
| `make down` | Stop all services |
| `make lint` | Run ruff + sqlfluff |
| `make dbt-debug` | Verify Snowflake connection |
| `make dbt-deps` | Install dbt packages |
| `make dbt-run` | Full-refresh dbt run |
| `make dbt-test` | dbt data tests |
| `make run-local` | Trigger full-load DAG |
| `make run-incremental` | Trigger incremental DAG |
| `make clean-db` | Drop & recreate Snowflake schemas |

## Data Vault Layers

| Layer | Schema | Models |
|---|---|---|
| Staging | `STAGING` | `stg_tpch_customer`, `stg_tpch_orders`, `stg_tpch_lineitem` |
| Raw Vault — Hubs | `RAW_VAULT` | `hub_customer`, `hub_order` |
| Raw Vault — Links | `RAW_VAULT` | `lnk_customer_order` |
| Raw Vault — Satellites | `RAW_VAULT` | `sat_customer_details` |
| Business Vault | `BUSINESS_VAULT` | `pit_customer` |

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`) runs on every push/PR to `master`:

1. **ruff** — Python linting (strict py311)
2. **sqlfluff** — SQL linting (Snowflake dialect, dbt templater)
3. **gitleaks** — Credential leak detection

Add Snowflake credentials as **GitHub Repository Secrets**: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`.

## Stage Roadmap

- [x] **Stage 1** — Infrastructure & Environment Setup *(current)*
- [ ] **Stage 2** — Raw Vault full model implementation
- [ ] **Stage 3** — Business Vault (PITs, bridges, business rules)
- [ ] **Stage 4** — Information Mart / reporting layer
- [ ] **Stage 5** — Data quality & observability
