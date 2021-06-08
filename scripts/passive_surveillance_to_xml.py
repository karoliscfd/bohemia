import ezsheets
import os
import shutil
os.chdir('../credentials')

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1zSTBdbVN1kR3sU40ydkIbG00QPgrnKdXm-ZMa0CcBr0/edit#gid=141178862')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform passivemalariasurveillancemoz.xlsx passivemalariasurveillancemoz.xml')

# Move
shutil.move('passivemalariasurveillancemoz.xlsx', '../forms/passivemalariasurveillance/passivemalariasurveillancemoz.xlsx')
shutil.move('passivemalariasurveillancemoz.xml',  '../forms/passivemalariasurveillance/passivemalariasurveillancemoz.xml')

print('Done. Docs in forms/passivemalariasurveillance.')
