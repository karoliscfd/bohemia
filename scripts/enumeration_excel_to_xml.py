import ezsheets
import os
import shutil
os.chdir('../credentials')

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1rPBLjrto66gAmbJSYc_H-I-ymkbnYPCprAzrpmGwKF4/edit#gid=0')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform enumerationscensus.xlsx enumerationscensus.xml ')

# Move
shutil.move('enumerationscensus.xlsx', '../forms/enumerationscensus/enumerationscensus.xlsx')
shutil.move('enumerationscensus.xml',  '../forms/enumerationscensus/enumerationscensus.xml')

print('Done. Docs in forms/enumerationscensus.')
