import ezsheets
import os
import shutil
os.chdir('../credentials')

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1GRgZ96GRCjM39qAjp-q2F6FMHaxoIT-xBEnSYTsfZyI/edit#gid=141178862')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform transcription.xlsx transcription.xml ')

# Move
shutil.move('transcription.xlsx', '../forms/transcription/transcription.xlsx')
shutil.move('transcription.xml',  '../forms/transcription/transcription.xml')
# shutil.move('itemsets.csv', '../forms/varefusals/itemsets.csv')

print('Done. Docs in forms/transcription.')
