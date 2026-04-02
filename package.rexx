/* Package REXXUNIT for distribution */
/* Requires pandoc from https://pandoc.org/ */

'DEL rexxunit.vmarc rexxunit.zip 2>NUL:'
'RMDIR /q /s fixdoc\.venv 2>NUL:'

Signal on Error

Say 'Building documentation for CMS:'
Call CD 'fixdoc'
'py -m venv .venv'
'.venv\Scripts\activate.bat & pip install -r requirements.txt'
'.venv\Scripts\activate.bat & pandoc --from gfm-smart --to plain --filter .\fixdoc.py --columns 79 < ..\README.md > ..\rexxunit.memo'
Call CD '..'
'RMDIR /q /s fixdoc\.venv 2>NUL:'

Say 'Building rexxunit.vmarc for CMS:'
'vma -at rexxunit.vmarc rexxunit.rexx,rexxunit.exec rexxunit.memo rexxunit.help$cm'

Say 'Building rexxunit.zip for the ASCII world:'
'zip rexxunit.zip rexxunit.rexx readme.md'

'DEL rexxunit.memo 2>NUL:'
