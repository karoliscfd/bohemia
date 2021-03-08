import ezsheets
import os
import shutil
os.chdir('../credentials')

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1GRgZ96GRCjM39qAjp-q2F6FMHaxoIT-xBEnSYTsfZyI/edit#gid=141178862')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform audio.xlsx audio.xml ')

# Move
shutil.move('audio.xlsx', '../forms/audio/audio.xlsx')
shutil.move('audio.xml',  '../forms/audio/audio.xml')
# shutil.move('itemsets.csv', '../forms/varefusals/itemsets.csv')

print('Done. Docs in forms/audio.')
