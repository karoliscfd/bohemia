import ezsheets
import os
import shutil
os.chdir('../credentials')

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/17G4WE09FOLqA0u5xXC9Agwvu1fBWKpnOVCMJ-zBPA0E/edit?usp=sharing')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform varefusals.xlsx varefusals.xml ')

# Move
shutil.move('varefusals.xlsx', '../forms/varefusals/varefusals.xlsx')
shutil.move('varefusals.xml',  '../forms/varefusals/varefusals.xml')
# shutil.move('itemsets.csv', '../forms/varefusals/itemsets.csv')

print('Done. Docs in forms/varefusals.')
