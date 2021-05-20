import ezsheets
import os
import shutil
os.chdir('../credentials')

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/17t_MzLMJTbAc1xFBEEUaKb5MuYozZm_G7Qraosk3gEM/edit#gid=141178862')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform refusalsabsences.xlsx refusalsabsences.xml ')

# Move
shutil.move('refusalsabsences.xlsx', '../forms/refusalsabsences/refusalsabsences.xlsx')
shutil.move('refusalsabsences.xml',  '../forms/refusalsabsences/refusalsabsences.xml')
shutil.move('itemsets.csv', '../forms/refusalsabsences/itemsets.csv')

print('Done. Docs in forms/refusalsabsences.')
