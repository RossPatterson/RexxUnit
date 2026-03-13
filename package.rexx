/* Package REXXUNIT for distribution */
/* Requires pandoc from https://pandoc.org/ */
Parse upper source System .
If System = 'WIN64' then 'DEL rexxunit.vmarc rexxunit.zip 2>NUL:'
Else 'rm rexxunit.vmarc rexxunit.zip 2>/dev/null'

Signal on Error
Say 'Building rexxunit.vmarc for CMS:'
'pandoc --from gfm-smart --to plain --columns 80 < README.md > rexxunit.memo'
'vma -at rexxunit.vmarc rexxunit.rexx,rexxunit.exec rexxunit.memo rexxunit.help$cm'

Say 'Building rexxunit.zip for the ASCII world:'
'zip rexxunit.zip rexxunit.rexx readme.md'

If System = 'WIN64' then 'DEL rexxunit.memo 2>NUL:'
Else 'rm rexxunit.memo 2>/dev/null'
