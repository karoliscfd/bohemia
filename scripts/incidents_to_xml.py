import ezsheets
import os
import shutil
os.chdir('../credentials')

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1KaJVsiBvf3gpmp3-4t-M9Ro58rzQX5SSAyZ-DLNQ5Vs/edit#gid=141178862')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform incidents.xlsx incidents.xml ')

# Move
shutil.move('incidents.xlsx', '../forms/incidents/incidents.xlsx')
shutil.move('incidents.xml',  '../forms/incidents/incidents.xml')
# shutil.move('itemsets.csv', '../forms/varefusals/itemsets.csv')

print('Done. Docs in forms/incidents.')
