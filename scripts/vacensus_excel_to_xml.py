import ezsheets
import os
import shutil
os.chdir('../credentials')

# Read in main sheet
s = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1tCgPwXVtugUuXa-IQ0Qous2DgmRGv7VS4aCLAEy9oAk/edit#gid=1264701015')
s.downloadAsExcel()

# Read in locations
import pandas as pd

d = ezsheets.Spreadsheet('https://docs.google.com/spreadsheets/d/1hQWeHHmDMfojs5gjnCnPqhBhiOeqKWG32xzLQgj5iBY/edit#gid=640399777')
d.downloadAsCSV('locations.csv')


## Convert to xml
os.system('xls2xform va153census.xlsx va153census.xml')

# Move
shutil.move('va153census.xlsx', '../forms/va153census/va153census.xlsx')
shutil.move('va153census.xml',  '../forms/va153census/va153census.xml')
shutil.move('itemsets.csv', '../forms/va153census/itemsets.csv')
shutil.move('locations.csv', '../forms/va153census/locations.csv')

# Zip
os.chdir('../forms/va153census/')
if os.path.exists('metadata'):
    shutil.rmtree('metadata')
os.mkdir('metadata')
shutil.move('itemsets.csv', 'metadata/itemsets.csv')
shutil.move('locations.csv', 'metadata/locations.csv')
shutil.make_archive('metadata', 'zip', 'metadata')
if os.path.exists('metadata'):
    shutil.rmtree('metadata')

print('Done. Careful, the locations.csv came from github, not the xls')
