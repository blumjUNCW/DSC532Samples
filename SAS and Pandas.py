# %%

import pandas as pd

grads = pd.read_sas(
    "/workspaces/myfolder/IPEDS/graduation.sas7bdat",
    format="sas7bdat",
    encoding="utf-8"
)

grads.head(20)
# %%
grads.columns
# %%
grads.shape
# %%
grads.info()