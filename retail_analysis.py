import pandas as pd
from sqlalchemy import create_engine, URL

# PostgreSQL connection
url = URL.create(
    drivername="postgresql+psycopg2",
    username="postgres",
    password="nive@2020",
    host="localhost",
    port=5432,
    database="IKEA"
)

engine = create_engine(url)

# Fetch data from PostgreSQL
query = "SELECT * FROM public.retailcombined"

df = pd.read_sql(query, engine)

# filter and calculate recency , frequency , monetary
rfm_data  = df[(df["customerid"].notna()) & (df["quantity"] > 0 )].copy()
snapshot_date = pd.to_datetime("2011-12-10")

rfm = rfm_data.groupby('customerid').agg(
    recency=('invoicedate', lambda x: (snapshot_date - x.max()).days),
    frequency=('invoice','nunique'),
    monetory=('quantity', lambda x:(x * rfm_data.loc[x.index, 'price']).sum())
).reset_index()

#  score customers and assign businesss segments
rfm['R_Score']=pd.qcut(rfm['recency'],5, labels=[5,4,3,2,1]).astype(int)
rfm['F_Score']=pd.qcut(rfm['frequency'].rank(method='first'),5, labels=[5,4,3,2,1]).astype(int)
rfm['M_Score']=pd.qcut(rfm['monetory'],5, labels=[5,4,3,2,1]).astype(int)

def segment_customer(row):
    if row['R_Score'] >= 4 and row["F_Score"] >= 4 and row["M_Score"] >= 4:
        return "Champion"
    elif row['R_Score'] >= 3 and row["F_Score"] >= 3:
        return "Loyal"
    elif row['R_Score'] >= 2 and row["F_Score"] >= 3 :
            return "At Risk"
    elif row['R_Score'] >= 4 and row["F_Score"] >= 2:
            return "New"
    elif row['R_Score'] >= 3 and row["F_Score"] >= 2:
            return "Need Attention"
    else:
          return 'Lost'


rfm['Segment'] = rfm.apply(segment_customer,axis=1)
rfm['IsChurned'] = rfm['recency'] > 90

df = df[(df["customerid"].notna()) & (df["quantity"] > 0 )].copy()
df['invoiceMonth'] = df['invoicedate'].dt.to_period('M').dt.to_timestamp()
df['revenue']= df['quantity'] * df['price']

df_final = df.merge(
      rfm[['customerid', 'recency','frequency','R_Score','M_Score','Segment','IsChurned']],
      on='customerid',how='left'
)
df_final.to_csv(r"C:\Users\Asus\OneDrive\Desktop\IKEA_SET\Ecommerce_dashboardData.csv", index=False)
print(type(df_final), df_final.shape)
