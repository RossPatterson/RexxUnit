/* Package REXXUNIT for distribution */
Parse upper source System .
If System = 'WIN64' then 'DEL rexxunit.vmarc rexxunit.zip 2>NUL:'
Else 'rm rexxunit.vmarc rexxunit.zip 2>/dev/null'

Signal on Error
Say 'Building rexxunit.vmarc for CMS:'
'vma -at rexxunit.vmarc rexxunit.rexx,rexxunit.exec readme.md,rexxunit.memo rexxunit.help$cm'

Say 'Building rexxunit.zip for the ASCII world:'
'zip rexxunit.zip rexxunit.rexx readme.md'