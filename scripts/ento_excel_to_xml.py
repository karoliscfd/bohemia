import ezsheets
import os
import shutil
os.chdir('../credentials')

## ENTO A1

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

## ENTO A2

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1Sg438_a49yE1ps1IfN0aW2ZC0p0i-jrw1YRQ20Ppb2Q/edit#gid=0')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform entoa2.xlsx entoa2.xml ')

# Move
if not os.path.isdir('../forms/entoa2/'):
    os.mkdir('../forms/entoa2')
shutil.move('entoa2.xlsx', '../forms/entoa2/entoa2.xlsx')
shutil.move('entoa2.xml',  '../forms/entoa2/entoa2.xml')

print('Done. Docs in forms/entoa2.')

## ENTO A3

s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1hKpS9WNWjUKNdMSNg6EFAZVY9O4ytysFizMiNENdTCw/edit#gid=0')
s.downloadAsExcel()

## Convert to xml
os.system('xls2xform entoa3.xlsx entoa3.xml ')

# Move
if not os.path.isdir('../forms/entoa3/'):
    os.mkdir('../forms/entoa3')
shutil.move('entoa3.xlsx', '../forms/entoa3/entoa3.xlsx')
shutil.move('entoa3.xml',  '../forms/entoa3/entoa3.xml')

print('Done. Docs in forms/entoa3.')



