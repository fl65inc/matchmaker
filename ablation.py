import pandas as pd
from sklearn.model_selection import train_test_split

# the size of the train_validation set.
train_val_size = [0.3, 0.4, 0.6, 0.8]

# Read the DrugCombination data
df = pd.read_csv('data/DrugCombinationData.tsv', sep='\t')
df['cell_line_num'] = df.groupby('cell_line_name')['drug_col'].transform('count')
df['cell_line_mean_synergy'] = df.groupby('cell_line_name')['synergy_loewe'].transform('mean')

# I'm choosing EKVX because it satisfies the 
# number of datapoints > 2000
# and
# mean(loewe's synergy)
large_cell_df = df[df['cell_line_num'] >=2000].sort_values(by='cell_line_num')

for cell_line in large_cell_df['cell_line_name'].drop_duplicates():
    for size in train_val_size:
        cell_line_df = large_cell_df[large_cell_df['cell_line_name']==cell_line]
        train_val, test = train_test_split(cell_line_df, train_size=size)
        train, val = train_test_split(train_val, train_size=0.8)
        frac_string = str(size).replace('0.','')
        cell_line_name = cell_line.replace(' ','-')
        with open(f'ablation_data/{cell_line_name}_train_inds_frac{frac_string}0.txt','w') as tr:
            for ix in train.index.tolist():
                tr.write(f'{ix}\n')
        with open(f'ablation_data/{cell_line_name}_val_inds_frac{frac_string}0.txt','w') as va:
            for ix in val.index.tolist():
                va.write(f'{ix}\n')
        with open(f'ablation_data/{cell_line_name}_test_inds_frac{frac_string}0.txt','w') as te:
            for ix in test.index.tolist():
                te.write(f'{ix}\n')
        with open(f'ablation_data/{cell_line_name}_inds.txt','w') as cl:
            for ix in cell_line_df.index.tolist():
                cl.write(f'{ix}\n')
