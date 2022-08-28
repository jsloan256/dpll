import pandas as pd

df = pd.read_csv("scolog.csv")
number_of_runs = df.shape[0]

df.drop(df.loc[df['matched']==0].index, inplace=True)
max_lockable_fin = df['fin_frequency'].max()
min_lockable_fin = df['fin_frequency'].min()

pos_ppm = (max_lockable_fin - 390625)/390625 * 10000
neg_ppm = (390625 - min_lockable_fin)/390625 * 10000

print("Over {} runs, successfully locked on to frequencies from {} to {}".format(number_of_runs, min_lockable_fin, max_lockable_fin))
print("which is 390.625 kHz -{}pmm {}ppm".format(neg_ppm, pos_ppm))