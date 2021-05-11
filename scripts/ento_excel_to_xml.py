import ezsheets
import os
import shutil
os.chdir('../credentials')

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1EiYNYG0FnLFFw35JUrPOhjzB9bLQOAxYKu3jY_zKXOk/edit#gid=0')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform entoa1.xlsx entoa1.xml ')

# Move
if not os.path.isdir('../forms/entoa1/'):
    os.mkdir('../forms/entoa1')
shutil.move('entoa1.xlsx', '../forms/entoa1/entoa1.xlsx')
shutil.move('entoa1.xml',  '../forms/entoa1/entoa1.xml')

print('Done. Docs in forms/entoa1.')
