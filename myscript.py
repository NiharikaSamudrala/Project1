import pandas as pd
from pathlib import Path

# ---- file paths (change if needed) ----

p_txn = Path(r"C:\Users\nihar\OneDrive\Desktop\mydemo-bucket-0906\data\transaction (1).csv")
p_acct = Path(r"C:\Users\nihar\OneDrive\Desktop\mydemo-bucket-0906\data\account (2).csv")
p_cust = Path(r"C:\Users\nihar\OneDrive\Desktop\mydemo-bucket-0906\data\customer (2).csv")
p_out = Path("transactions_simple.csv")


# ---- read ----
txn  = pd.read_csv(p_txn)
acct = pd.read_csv(p_acct)
cust = pd.read_csv(p_cust)

# ---- simple transformations ----
# 1) parse transaction time
txn["txn_time"] = pd.to_datetime(txn.get("txn_time"), errors="coerce", utc=True)

# 2) cents -> dollars
if "amount_cents" in txn.columns:
    txn["amount"] = pd.to_numeric(txn["amount_cents"], errors="coerce") / 100

# 3) normalize a few strings
if "currency" in txn.columns:
    txn["currency"] = txn["currency"].astype(str).str.upper().str.strip()

for col in ("merchant_name", "category", "status"):
    if col in txn.columns:
        txn[col] = txn[col].astype(str).str.strip()

# ---- joins ----
# transactions ← accounts on account_id (left join keeps all transactions)
df = txn.merge(acct, on="account_id", how="left", suffixes=("", "_acct"))

# ← customers on customer_id
if "customer_id" in df.columns and "customer_id" in cust.columns:
    df = df.merge(cust, on="customer_id", how="left", suffixes=("", "_cust"))

# ---- select a simple, useful column set (only if present) ----
cols = [
    "txn_id", "txn_time", "merchant_name", "category",
    "amount", "currency",
    "account_id", "account_type",
    "customer_id", "full_name", "email"
]
cols = [c for c in cols if c in df.columns]
df = df[cols + [c for c in df.columns if c not in cols]]  # keep the rest at the end

# ---- write output ----
p_out.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(p_out, index=False)

print(f"Saved: {p_out}")
print(df.head(5).to_string(index=False))
