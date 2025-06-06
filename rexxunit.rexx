/* RexxUnit 1.0.0 */
 
/*---------------------------------------------------------------------------*/
/* This is free and unencumbered software released into the public domain.   */
/*                                                                           */
/* Anyone is free to copy, modify, publish, use, compile, sell, or           */
/* distribute this software, either in source code form or as a compiled     */
/* binary, for any purpose, commercial or non-commercial, and by any         */
/* means.                                                                    */
/*                                                                           */
/* In jurisdictions that recognize copyright laws, the author or authors     */
/* of this software dedicate any and all copyright interest in the           */
/* software to the public domain. We make this dedication for the benefit    */
/* of the public at large and to the detriment of our heirs and              */
/* successors. We intend this dedication to be an overt act of               */
/* relinquishment in perpetuity of all present and future rights to this     */
/* software under copyright law.                                             */
/*                                                                           */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,           */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF        */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    */
/* IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR         */
/* OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,     */
/* ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR     */
/* OTHER DEALINGS IN THE SOFTWARE.                                           */
/*                                                                           */
/* For more information, please refer to <https://unlicense.org>             */
/*---------------------------------------------------------------------------*/
 
Parse arg Argstring
 
Signal on NoValue
Signal on Syntax
 
Call Setup
Call ParseArgs Argstring
TestNames = CollectTests(G._TestNamePatterns)
Call Time 'R'    /* Start the elapsed time clock. */
Say G._Separator
Do while Not(TestNames = '')
    Parse var TestNames TestName TestNames
    Call RunTest TestName
End
If Not(G._Verbose) then Call LineOut , ''
Call DeleteFile G._TempFile
Call Report
Exit
 
/* Signal traps are at the bottom, since they have to be shared with the */
/* $RXU code. */
 
/*---------------------------------------------------------------------------*/
/* CacheRoutinesFromFile(Filename)                                           */
/*                                                                           */
/* Collect the Test* subroutine names from the specified file.               */
/*---------------------------------------------------------------------------*/
CacheRoutinesFromFile: Procedure expose G. TestCache.
Parse arg Filename
 
FilenameUpper = Translate(Filename)
If WordPos(Translate(FilenameUpper), TestCache._Files) > 0 then Return
G._HasSetup.FilenameUpper = G._False
G._HasTeardown.FilenameUpper = G._False
Call SystemInterface 'READFILE', Filename
TestRoutines = ''
Do I = 1 to SI_Results.0
    Do while Pos(':', SI_Results.I) > 0
        Parse var SI_Results.I Instruction ';' SI_Results.I
        Do while Pos(':', Instruction) > 0
            Parse var Instruction Label ':' Instruction
            LabelUpper = Translate(Label)
            Select
                When Not(Words(Label) = 1) then Nop
                When Not(Left(LabelUpper, 4) = 'TEST') then Nop
                When LabelUpper = 'TESTSETUP' then ,
                    G._HasSetup.FilenameUpper = G._True
                When LabelUpper = 'TESTTEARDOWN' then ,
                    G._HasTeardown.FilenameUpper = G._True
                Otherwise
                    TestRoutines = TestRoutines Label
            End
        End
    End
End
TestCache._Files = TestCache._Files FilenameUpper
TestCache.FilenameUpper = TestRoutines
If G._Verbose then Say Filename':' Words(TestCache.FilenameUpper) 'tests'
Return
 
 
/*---------------------------------------------------------------------------*/
/* CollectTests(TestNamePatterns)                                            */
/*                                                                           */
/* Collect and return names of tests from the supplied name patterns.  Each  */
/* name is 'file:rtn', where either part may contain a '*' for pattern       */
/* matching.                                                                 */
/*---------------------------------------------------------------------------*/
CollectTests: Procedure expose G.
Parse arg TestNamePatterns
 
TestCache. = ''
TestNames = ''
Do while Not(TestNamePatterns = '')
    Parse var TestNamePatterns TestNamePattern TestNamePatterns
    Parse var TestNamePattern TestFilePattern ':' TestRoutinePattern
    If TestRoutinePattern = '' then TestRoutinePattern = '*'
    Select
        When Pos('*', TestFilePattern) > 0 then Do
            TestFiles = ListFiles(TestFilePattern)
            Do while Not(TestFiles = '')
                Parse var TestFiles TestFile TestFiles
                Call CacheRoutinesFromFile TestFile
                TestName = TestFile || ':' || TestRoutinePattern
                TestNamePatterns = TestNamePatterns TestName
            End
        End
        When Pos('*', TestRoutinePattern) > 0 then Do
            TestRoutines = ListRoutines(TestFilePattern, TestRoutinePattern)
            Do while Not(TestRoutines = '')
                Parse var TestRoutines TestRoutine TestRoutines
                TestName = TestFilePattern || ':' || TestRoutine
                TestNamePatterns = TestNamePatterns TestName
            End
        End
        Otherwise
            Call CacheRoutinesFromFile TestFilePattern
            TestFilePatternUpper = Translate(TestFilePattern)
            I = WordPos(Translate(TestRoutinePattern), ,
                Translate(TestCache.TestFilePatternUpper))
            If I = 0 then ,
                Say 'Test' TestNamePattern 'not found, ignored'
            Else Do
                TestName = TestFilePattern || ':' || ,
                    Word(TestCache.TestFilePatternUpper, I)
                If WordPos(Translate(TestName), Translate(TestNames)) = 0 ,
                    then TestNames = TestNames TestName
            End
    End
End
Return TestNames
 
 
/*---------------------------------------------------------------------------*/
/* DeleteFile(Filename)                                                      */
/*                                                                           */
/* Delete the specified file.                                                */
/*---------------------------------------------------------------------------*/
DeleteFile: Procedure expose G.
Parse arg Filename
 
Call SystemInterface 'DELETEFILE', Filename
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* ExitError(ExitRC, Message)                                                */
/*                                                                           */
/* Display a message and exit.                                               */
/*---------------------------------------------------------------------------*/
ExitError:
Parse arg ExitRC, Message
 
Say ExitRC ':' Message
 
Exit ExitRC
 
 
/*---------------------------------------------------------------------------*/
/* GetSigL()                                                                 */
/*                                                                           */
/* This just sets SigL to the caller's line #, to work around a bug in BREXX */
/* 1.0.2 and earlier (BREXX Issue #80).                                      */
/*---------------------------------------------------------------------------*/
GetSigL: Return SigL
 
 
/*---------------------------------------------------------------------------*/
/* ListFiles(FilePattern)                                                    */
/*                                                                           */
/* Return a list of files matching the pattern.                              */
/*---------------------------------------------------------------------------*/
ListFiles: Procedure expose G.
Parse arg FilePattern
 
FileList = ''
Call SystemInterface 'LISTFILES', FilePattern
Do I = 1 to SI_Results.0
    FileList = FileList SI_Results.I
End
 
Return FileList
 
 
/*---------------------------------------------------------------------------*/
/* ListRoutines(Filename, RoutinePattern)                                    */
/*                                                                           */
/* Return a list of test routine names in the file matching the pattern .    */
/*---------------------------------------------------------------------------*/
ListRoutines: Procedure expose G. TestCache.
Parse arg Filename, RoutinePattern
 
Call CacheRoutinesFromFile Filename
FilenameUpper = Translate(Filename)
Routines = TestCache.FilenameUpper
RoutineList = ''
Do while Not(Routines = '')
    Parse var Routines Routine Routines
    If Match(Routine, RoutinePattern) then RoutineList = RoutineList Routine
End
 
Return RoutineList
 
 
/*---------------------------------------------------------------------------*/
/* Match(String, Pattern)                                                    */
/*                                                                           */
/* Return true if string matches pattern, otherwise false.                   */
/*---------------------------------------------------------------------------*/
Match: Procedure expose G.
Parse arg String, Pattern
 
Select
    When String == Pattern then Return G._True
    When Pos('*',Pattern) > 0 then Do
        Parse var Pattern Before '*' After
        Return (Left(String, Length(Before)) == Before & ,
            Right(String, Length(After)) == After )
    End
    /* There are probably other patterns to check, but we'll code them later */
    Otherwise Return G._False
End /* notreached */
 
 
/*---------------------------------------------------------------------------*/
/* Not(Boolean)                                                              */
/*                                                                           */
/* Because some Rexx implementations have problems with not-sign operators.  */
/*---------------------------------------------------------------------------*/
Not: Procedure
 
If Arg(1) then Return 0
Return 1
 
 
/*---------------------------------------------------------------------------*/
/* ParseArgs(Argstring)                                                      */
/*                                                                           */
/* Parse the argument string in the style of the current system.             */
/* NOTE: We allow the command to specify it's syntax style, both for ease of */
/*       testing, and so scripts can call this command in a                  */
/*       system-independent manner.                                          */
/*---------------------------------------------------------------------------*/
ParseArgs: Procedure expose G.
Parse arg Argstring
 
SavedSystemInterface = G._SystemInterface
If Left(Word(Argstring, 1), 2) == '__' then Do
    Parse value Substr(Argstring, 3) with G._SystemInterface Argstring
    G._SystemInterface = Translate(G._SystemInterface)
End
Call SystemInterface 'PARSEARGS', Argstring
G._SystemInterface = SavedSystemInterface
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* Report()                                                                  */
/*                                                                           */
/* Report on final results.                                                  */
/*---------------------------------------------------------------------------*/
Report: Procedure expose G.
Say G._Separator
Do I = 1 to G._BadTests.0
    Parse var G._BadTests.I TestName '15'x TestStatus TestMessage '15'x ,
        TestDetails
    Say TestName TestStatus TestMessage
    Do while Not(TestDetails = '')
        Parse var TestDetails Line '15'x TestDetails
        Say '   ' || Line
    End
End
Say G._Separator
Say G._Count.PASS 'passed'
Say G._Count.FAIL 'failed'
Say G._Count.ERROR 'errors'
Say G._Count.SIGNAL 'SIGNALed'
Say G._Count.SKIP 'skipped'
Say G._Count.XFAIL 'passed when expected to fail'
Say 'Elapsed time:' Time('E') 'seconds'
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* RunTest(TestName)                                                         */
/*                                                                           */
/* Run a test.                                                               */
/*---------------------------------------------------------------------------*/
RunTest:  Procedure expose G.
Parse arg TestName
Parse var TestName Filename ':' Routine
 
FilenameUpper = Translate(Filename)
If Not(G._CurrentTestFile = FilenameUpper) then Do
    Call SystemInterface 'WRITETESTFILE', Filename, G._TempFile
    G._CurrentTestFile = FilenameUpper
End
If G._Verbose then Say TestName '...'
Interpret "TestResult = " G._TempFileName || "('" || Routine ,
    G._HasSetup.FilenameUpper G._HasTeardown.FilenameUpper G._OS G._RexxLevel ,
    G._SoftAsserts G._AssertionDetails || "')"
 
Parse var TestResult TestStatus TestMessage '15'x TestDetails
TestStatus = Translate(TestStatus)
If WordPos(TestStatus, 'ERROR FAIL PASS SKIP SIGNAL XFAIL') = 0 then Do
    TestMessage = 'Invalid test status:' TestResult
    TestStatus = 'ERROR'
End
If G._Verbose then Do
    Say TestName TestStatus TestMessage
    Do while Not(TestDetails = '')
        Parse var TestDetails Line '15'x TestDetails
        Say '   ' || Line
    End
End
Else Call CharOut , G._Char.TestStatus
G._Count.TestStatus = G._Count.TestStatus + 1
If Not(TestStatus = 'PASS') then Do
    I = G._BadTests.0 + 1
    G._BadTests.I = TestName || '15'x || TestResult
    G._BadTests.0 = I
End
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* Setup()                                                                   */
/*                                                                           */
/* Set up to run tests, including system dependencies.                       */
/*---------------------------------------------------------------------------*/
Setup: Procedure expose G.
 
/* Global variables that the RexxUnit program itself will use. */
G. = ''
G._True = (1=1)
G._False = Not(G._True)
G._Separator = Copies('=', 80)
G._AssertionDetails = G._False
G._SoftAsserts = G._False
G._Verbose = G._False
G._BadTests.0 = 0
G._Char.ERROR  = 'E'
G._Char.FAIL   = 'F'
G._Char.PASS   = '.'
G._Char.SIGNAL = '!'
G._Char.SKIP   = 'S'
G._Char.XFAIL  = 'X'
G._Count.ERROR  = 0
G._Count.FAIL   = 0
G._Count.PASS   = 0
G._Count.SIGNAL = 0
G._Count.SKIP   = 0
G._Count.XFAIL  = 0
 
/* System dependent behaviors. */
Parse source SourceSystem SourceAddress SourceFile
Parse version VersionSystem VersionRexxLevel VersionDate
G._OS = SourceSystem
G._RexxLevel = VersionRexxLevel
Select
    When VersionSystem = 'REXX370' & SourceSystem = 'CMS' then ,
        G._SystemInterface = 'CMS' /* VM/SP et seq. */
    When Left(VersionSystem, 10) = 'REXX-bREXX' & ,
        Substr(VersionSystem, 18, 6) = 'CMS370' then ,
        G._SystemInterface = 'CMS' /* VM/CE BREXX > 1.0.1 */
    When Left(VersionSystem, 11) = 'REXX-Regina' & ,
            Left(SourceSystem, 3) = 'WIN' then ,
        G._SystemInterface = 'WINDOWS'  /* Regina on Windows */
    When Left(VersionSystem, 11) = 'REXX-Regina' & ,
            SourceSystem = 'UNIX' then ,
        G._SystemInterface = 'UNIX'  /* Regina on Linux/Unix/etc. */
    When SourceSystem = 'CMS' then ,
        G._SystemInterface = 'CMS' /* Unknown VM Rexx */
    Otherwise Call ExitError 1, 'Unknown system type:' ,
        SourceSystem VersionSystem
End
Call SystemInterface 'SETUP'
/* Get the RexxUnit test boilerplate for later use. */
BoilerPlateStart = FindBoilerPlate()
Do I = 1 by 1 for SourceLine() - BoilerPlateStart
    G._Framework.I = SourceLine(BoilerPlateStart + I)
End
G._Framework.0 = I - 1
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* ShowHelp(SystemType)                                                      */
/*                                                                           */
/* Display the command help and exit.                                        */
/*---------------------------------------------------------------------------*/
ShowHelp: Procedure
SystemType = Arg(1)
 
Select
    When SystemType = 'CMS' then ,
        Say 'REXXUNIT fn_pat[:test_pat] ... (' ,
           '[[NO]DETAILS] [HELP] [QUIET] [[NO]SOFT] [[NO]TYPE] [)]'
    When SystemType = 'WIN' then ,
        Say 'rexxunit [/d|/D] [/?|/H] [/q|/Q] [/s|/S] [/v|/V]' ,
            'file_pat[:test_pat]'
    When SystemType = 'UNIX' then ,
        Say 'rexxunit [-d|--details] [-h|--help] [-q|--quiet] [-s|--soft]' ,
            '[-v|--verbose] file_pat[:test_pat] ...'
    Otherwise Call ExitError 2, 'Bad system type:' SystemType
End
 
Exit
 
 
/*---------------------------------------------------------------------------*/
/* SystemInterface(Action, Arg1, Arg2, ...)                                  */
/*                                                                           */
/* Perform the specified system-interface action with the specified          */
/* arguments.                                                                */
/*---------------------------------------------------------------------------*/
SystemInterface: Procedure expose G. SI_Input. SI_Results.
Parse arg Action, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9
 
Select
    When WordPos(Translate(Action), ,
        'DELETEFILE LISTFILES PARSEARGS READFILE SETUP WRITETESTFILE') = 0 ,
            then Call ExitError 3, 'Invalid system interface action:' Action
    When G._SystemInterface = 'CMS' then ,
        Call SyI_CMS Action, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, ,
            Arg7, Arg8, Arg9
    When G._SystemInterface = 'WINDOWS' then ,
        Call SyI_Windows Action, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, ,
            Arg7, Arg8, Arg9
    When G._SystemInterface = 'UNIX' then ,
        Call SyI_Unix Action, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, ,
            Arg7, Arg8, Arg9
    Otherwise Call ExitError 4, 'Unknown system interface:' G._SystemInterface
End
 
Return
 
SI_ReadStream: Procedure expose G. SI_Results.
Parse arg InFile
 
$RXU_TrapNotReadyDest = 'SIRS_EOF'
Signal on NotReady
Do I = 1 by 1
    SI_Results.I = LineIn(InFile)
End
SIRS_EOF:
SI_Results.0 = I - 1
Call Stream InFile, 'C', 'CLOSE'
If Not(Result = 'UNKNOWN') then ,
    Call ExitError 5, 'Error' Result 'closing' InFile
 
Return
 
SI_WriteTestStream: Procedure expose G.
Parse arg InFile, OutFile
 
Call Stream OutFile, 'C', 'OPEN WRITE REPLACE'
Call LineOut OutFile, '/* RexxUnit Test Case file */ Signal $RXU_Start'
Call Stream InFile, 'C', 'OPEN READ'
$RXU_TrapNotReadyDest = 'SIWTS_EOF'
Signal on NotReady
Do Forever
    Call LineOut OutFile, LineIn(InFile)
End
SIWTS_EOF:
Call Stream InFile, 'C', 'CLOSE'
Do I = 1 to G._Framework.0
    Call LineOut OutFile, G._Framework.I
End
Call Stream OutFile, 'C', 'CLOSE'
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* SyI_CMS(Action, Arg1, Arg2, ...)                                          */
/*                                                                           */
/* Perform the specified system-interface action with the specified          */
/* arguments for the CMS system.                                             */
/*---------------------------------------------------------------------------*/
SyI_CMS: Procedure expose G. SI_Input. SI_Results.
Parse arg Action, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9
 
Select
    When Action = 'DELETEFILE' then Do
        Parse upper var Arg1 Fn '.' Ft '.' Fm
        If Fm = '' then Fm = 'A'
        'SET CMSTYPE HT'
        'ERASE' Fn Ft Fm
        'SET CMSTYPE RT'
    End
    When Action = 'LISTFILES' then Do
        Parse upper var Arg1 Fn '.' Ft
        'MAKEBUF'
        BufferNum = RC
        'SENTRIES'
        StackedBefore = RC
        'LISTFILE' Fn Ft '* ( FIFO'
        'SENTRIES'
        FileCount = RC - StackedBefore
        Do I = 1 to FileCount
            Pull Fn Ft .
            SI_Results.I = Fn || '.' || Ft
        End
        SI_Results.0 = FileCount
        'DROPBUF' BufferNum
    End
    When Action = 'PARSEARGS' then Do
        Parse var Arg1 Operands '(' Options
        Options = Translate(Options)
        Do while Not(Operands = '')
            Parse var Operands Testname Operands
            Parse var Testname Fn ':' Routine
            G._TestNamePatterns = G._TestNamePatterns Fn || ,
                '.rexxunit:' || Routine
        End
        If G._TestNamePatterns = '' then G._TestNamePatterns = '*.rexxunit'
        Do while Not(Options = '')
            Parse var Options Option Options
            Select
                When Left(Option, 1) = ')' then Options = ''
                When Option = 'HELP' then Call ShowHelp 'CMS'
                When Option = 'DETAILS' then G._AssertionDetails = G._True
                When Option = 'NODETAILS' then G._AssertionDetails = G._False
                When Option = 'SOFT' then G._SoftAsserts = G._True
                When Option = 'NOSOFT' then G._SoftAsserts = G._False
                When Option = 'TYPE' then G._Verbose = G._True
                When Option = 'NOTYPE' | Option = 'QUIET' then ,
                    G._Verbose = G._False
                Otherwise Call ExitError 6, 'Unknown option:' Option
            End
        End
    End
    When Action = 'READFILE' then Do
        Parse upper var Arg1 Fn '.' Ft
        'EXECIO * DISKR' Fn Ft '* ( STEM SI_RESULTS. FINIS'
    End
    When Action = 'SETUP' then Do
        G._TempFile = 'RXUTEMP.EXEC.A'
        Parse var G._TempFile G._TempFileName '.' .
        If G._RexxLevel < 3 then G._RexxLevel = '3.40'
    End
    When Action = 'WRITETESTFILE' then Do
        Parse upper var Arg1 InFn '.' InFt '.' InFm
        If InFm = '' then InFm = '*'
        Parse upper var Arg2 OutFn '.' OutFt '.' OutFm
        If OutFm = '' then OutFm = 'A'
        Call DeleteFile Arg2
        'EXECIO 1 DISKW' OutFn OutFt OutFm '( FINIS STRING',
            '/* RexxUnit Test Case file */ Signal $RXU_Start'
        'COPYFILE' InFn InFt InFm OutFn OutFt OutFm '( APPEND'
        X.0 = G._Framework.0
        Do I = 1 to X.0
            X.I = G._Framework.I
            If X.I == '' then X.I = ' ' /* Ensure Length() > 0 */
        End
        'EXECIO' X.0 'DISKW' OutFn OutFt OutFm '( STEM X. FINIS'
    End
End
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* SyI_Unix(Action, Arg1, Arg2, ...)                                         */
/*                                                                           */
/* Perform the specified system-interface action with the specified          */
/* arguments.                                                                */
/*---------------------------------------------------------------------------*/
SyI_Unix: Procedure expose G. SI_Input. SI_Results.
Parse arg Action, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9
 
Select
    When Action = 'DELETEFILE' then Do
        If Words(Arg1) > 1 | Arg1 = '*' then Call ExitError 9, 'No.'
        'rm' Arg1 '2>/dev/null'
    End
    When Action = 'LISTFILES' then ,
        Address SYSTEM 'ls' Arg1 with output stem SI_Results.
    When Action = 'PARSEARGS' then Do
        G._TestNamePatterns = ''
        Do while Not(Arg1 = '')
            Parse var Arg1 Arg Arg1
            Select
                When Arg = '--' then Leave
                When Left(Arg,1) = '-' & Not(Left(Arg,2) = '--') & ,
                    Length(Arg) > 2 then Do
                    Parse var Arg Arg +2 Rest
                    Arg1 = '-' || Rest Arg1
                End
                When Arg = '--details' | Arg = '-d' then ,
                   G._AssertionDetails = G._True
                When Arg = '--help' | Arg = '-h' then Call ShowHelp 'UNIX'
                When Arg = '--quiet' | Arg = '-q' then G._Verbose = G._False
                When Arg = '--soft' | Arg = '-s' then G._SoftAsserts = G._True
                When Arg = '--verbose' | Arg = '-v' then G._Verbose = G._True
                When Left(Arg, 1) = '-' then ,
                    Call ExitError 10, 'Unknown option:' Arg
                Otherwise G._TestNamePatterns = G._TestNamePatterns Arg
            End
        End
        G._TestNamePatterns = G._TestNamePatterns Arg1
        If G._TestNamePatterns = '' then G._TestNamePatterns = '*.rexxunit'
    End
    When Action = 'READFILE' then Call SI_ReadStream Arg1
    When Action = 'SETUP' then Do
        G._TempFile = 'rxutemp.rexx'
        G._TempFileName = G._TempFile
    End
    When Action = 'WRITETESTFILE' then Do
        Call DeleteFile Arg2
        Call SI_WriteTestStream Arg1, Arg2
    End
End
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* SyI_Windows(Action, Arg1, Arg2, ...)                                      */
/*                                                                           */
/* Perform the specified system-interface action with the specified          */
/* arguments.                                                                */
/*---------------------------------------------------------------------------*/
SyI_Windows: Procedure expose G. SI_Input. SI_Results.
Parse arg Action, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9
 
Select
    When Action = 'DELETEFILE' then Do
        If Words(Arg1) > 1 | Arg1 = '*.*' then Call ExitError 7, 'No.'
        'DEL' Arg1 '2>NUL:'
    End
    When Action = 'LISTFILES' then ,
        Address SYSTEM 'DIR /B' Arg1 with output stem SI_Results.
    When Action = 'PARSEARGS' then Do
        G._TestNamePatterns = ''
        Do while Not(Arg1 = '')
            Parse var Arg1 Arg Arg1
            Select
                When Arg = '/?' | Translate(Arg) = '/H' then ,
                    Call ShowHelp 'WIN'
                When Translate(Arg) = '/D' then G._AssertionDetails = G._True
                When Translate(Arg) = '/Q' then G._Verbose = G._False
                When Translate(Arg) = '/S' then G._SoftAsserts = G._True
                When Translate(Arg) = '/V' then G._Verbose = G._True
                When Left(Arg, 1) = '/' then ,
                    Call ExitError 8, 'Unknown option:' Arg
                Otherwise G._TestNamePatterns = G._TestNamePatterns Arg
            End
        End
        If G._TestNamePatterns = '' then G._TestNamePatterns = '*.rexxunit'
    End
    When Action = 'READFILE' then Call SI_ReadStream Arg1
    When Action = 'SETUP' then Do
        G._OS = 'WINDOWS'
        G._TempFile = 'rxutemp.rexx'
        G._TempFileName = G._TempFile
    End
    When Action = 'WRITETESTFILE' then Do
        Call DeleteFile Arg2
        Call SI_WriteTestStream Arg1, Arg2
    End
End
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* WordPos(needle, haystack, startword)                                      */
/*                                                                           */
/* Because some Rexx implementations don't have the built-in.                */
/*---------------------------------------------------------------------------*/
WordPos: Procedure
Parse arg Needle, Haystack, StartWord
 
If StartWord = '' then StartWord = 1
If Words(Needle) = 0 then Return 0
Do I = StartWord by 1 while Not(Haystack = '')
    Parse var Haystack HaystackWord1 Haystack
    If Not(Word(Needle, 1) = HaystackWord1) then Iterate
    Do J = 2 to Words(Needle)
        If Not(Word(Needle, J) = Word(Haystack, J-1)) then Iterate
    End
    Return I
End
 
Return 0
 
 
/*
===============================================================================
Everything below here is the "boilerplate" code that will be appended to
the actual test file.  None of the variables or labels above here are used in
it, and none of its variables or labels are used above.
===============================================================================
*/
FindBoilerPlate: Return GetSigL()
Call Fail 'Test script ran off end of file instead of RETURNing.'
 
 
/*---------------------------------------------------------------------------*/
/* AssertEndsWith(expected, actual, [message])                               */
/*                                                                           */
/* Return if the actual value ends with the expected value, otherwise fail   */
/* the test with the optional assertion message.                             */
/*---------------------------------------------------------------------------*/
AssertEndsWith: Procedure expose $RXU. SigL
Parse arg Expected, Actual, Message
 
Line = SigL /* Patch for Regina bug #610 */
OK = Expected == Right(Actual, Length(Expected))
If $RXU._AssertionDetails | $RXU_Not(OK) then ,
   Details = RXU$_AssertionDetails('Expected ending', Expected, 'Actual', ,
      Actual, Line)
If $RXU._AssertionDetails then Say Details
If OK then Return
Call $RXU_AssertFailed Message, Details
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* AssertEqual(expected, actual, [message])                                  */
/*                                                                           */
/* Return if the actual value matches the expected value, otherwise fail     */
/* the test with the optional assertion message.                             */
/*---------------------------------------------------------------------------*/
AssertEqual: Procedure expose $RXU. SigL
Parse arg  Expected, Actual, Message
 
Line = SigL /* Patch for Regina bug #610 */
OK = Expected = Actual
If $RXU._AssertionDetails | $RXU_Not(OK) then ,
   Details = RXU$_AssertionDetails('Expected', Expected, 'Actual', ,
      Actual, Line)
If $RXU._AssertionDetails then Say Details
If OK then Return
Call $RXU_AssertFailed Message, Details
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* AssertFalse(actual, [message])                                            */
/*                                                                           */
/* Return if the actual value is false (i.e., 0), otherwise fail the test    */
/* with the optional assertion message.                                      */
/*---------------------------------------------------------------------------*/
AssertFalse: Procedure expose $RXU. SigL
Parse arg Actual, Message
 
Line = SigL /* Patch for Regina bug #610 */
OK = $RXU_Not(Actual)
If $RXU._AssertionDetails | $RXU_Not(OK) then ,
   Details = RXU$_AssertionDetails('Expected', 0, 'Actual', Actual, Line)
If $RXU._AssertionDetails then Say Details
If OK then Return
Call $RXU_AssertFailed Message, Details
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* AssertIdentical(expected, actual, [message])                              */
/*                                                                           */
/* Return if the actual value is identical to the expected value, otherwise  */
/* fail the test with the optional assertion message.                        */
/*---------------------------------------------------------------------------*/
AssertIdentical: Procedure expose $RXU. SigL
Parse arg Expected, Actual, Message
 
Line = SigL /* Patch for Regina bug #610 */
OK = Expected == Actual
If $RXU._AssertionDetails | $RXU_Not(OK) then ,
   Details = RXU$_AssertionDetails('Expected', Expected, 'Actual', Actual, ,
      Line)
If $RXU._AssertionDetails then Say Details
If OK then Return
Call $RXU_AssertFailed Message, Details
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* AssertNotEqual(expected, actual, [message])                               */
/*                                                                           */
/* Return if the actual value does not match the expected value, otherwise   */
/* fail the test with the optional assertion message.                        */
/*---------------------------------------------------------------------------*/
AssertNotEqual: Procedure expose $RXU. SigL
Parse arg Expected, Actual, Message
 
Line = SigL /* Patch for Regina bug #610 */
OK = $RXU_Not(Expected = Actual)
If $RXU._AssertionDetails | $RXU_Not(OK) then ,
   Details = RXU$_AssertionDetails('Expected', Expected, 'Actual', Actual, ,
      Line)
If $RXU._AssertionDetails then Say Details
If OK then Return
Call $RXU_AssertFailed Message, Details
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* AssertNotIdentical(expected, actual, [message])                           */
/*                                                                           */
/* Return if the actual value is not identical to the expected value,        */
/* otherwise fail the test with the optional assertion message.              */
/*---------------------------------------------------------------------------*/
AssertNotIdentical: Procedure expose $RXU. SigL
Parse arg Expected, Actual, Message
 
Line = SigL /* Patch for Regina bug #610 */
OK = $RXU_Not(Expected == Actual)
If $RXU._AssertionDetails | $RXU_Not(OK) then ,
   Details = RXU$_AssertionDetails('Expected', Expected, 'Actual', Actual, ,
      Line)
If $RXU._AssertionDetails then Say Details
If OK then Return
Call $RXU_AssertFailed Message, Details
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* AssertStartsWith(expected, actual, [message])                             */
/*                                                                           */
/* Return if the actual value starts with the expected value, otherwise fail */
/* the test with the optional assertion message.                             */
/*---------------------------------------------------------------------------*/
AssertStartsWith: Procedure expose $RXU. SigL
Parse arg Expected, Actual, Message
 
Line = SigL /* Patch for Regina bug #610 */
OK = Expected == Left(Actual, Length(Expected))
If $RXU._AssertionDetails | $RXU_Not(OK) then ,
   Details = RXU$_AssertionDetails('Expected begining', Expected, 'Actual', ,
      Actual, Line)
If $RXU._AssertionDetails then Say Details
If OK then Return
Call $RXU_AssertFailed Message, Details
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* AssertStemEqual(expected_stem, actual_stem, [message])                    */
/*                                                                           */
/* Return if the actual stem matches the expected stem via the rules that    */
/* Rexx uses for "=", otherwise fail the test with the optional assertion    */
/* message.  Stems must be numeric-indexed with a count in stem.0, and are   */
/* compared in order, starting at 0.                                         */
/*---------------------------------------------------------------------------*/
AssertStemEqual:
 
$RXU_StemNames = Arg(1) Arg(2)
Line = SigL /* Patch for Regina bug #610 */
Call $RXU_ASEI_Inner Arg(1), Arg(2), 'EQUAL', Arg(3)
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* AssertStemIdentical(expected_stem, actual_stem, [message])                */
/*                                                                           */
/* Return if the actual stem is identical to  the expected stem, otherwise   */
/* fail the test with the optional assertion message.  Stems must be numeric-*/
/* indexed with a count in stem.0, and are compared in order, starting at 0. */
/*---------------------------------------------------------------------------*/
AssertStemIdentical:
 
$RXU_StemNames = Arg(1) Arg(2)
Line = SigL /* Patch for Regina bug #610 */
Call $RXU_ASEI_Inner Arg(1), Arg(2), 'IDENTICAL', Arg(3)
 
Return
 
$RXU_ASEI_Inner: Procedure expose $RXU. Line ($RXU_StemNames)
Parse arg  ExpectedStem, ActualStem, How, Message
 
Expected0 = Value(ExpectedStem || '0')
Actual0 = Value(ActualStem || '0')
Select
   When DataType(Expected0, 'W') & DataType(Actual0, 'W') then ,
      MaxCount = Max(Expected0, Actual0)
   When DataType(Expected0, 'W') then MaxCount = Expected0
   Otherwise MaxCount = Actual0
End
AllOK = 1
Details = ''
Do I = 0 to MaxCount
   Expected = Value(ExpectedStem || I)
   Actual = Value(ActualStem || I)
   If How = 'EQUAL' then OK = Expected = Actual
   Else OK = Expected == Actual
   AllOK = AllOK & OK
   If $RXU_Not(OK) | $RXU._AssertionDetails then ,
      Details = Details || '15'x || ,
         RXU$_AssertionDetails('Expected', Expected, 'Actual', ,
            Actual, Line)
End
If $RXU._AssertionDetails then Say Details
If AllOK then Return
Call $RXU_AssertFailed Message, Details
 
Return /* NotReached */
 
 
/*---------------------------------------------------------------------------*/
/* AssertTrue(actual, [message])                                             */
/*                                                                           */
/* Return if the actual value is true (i.e., 1), otherwise fail the test     */
/* with the optional assertion message.                                      */
/*---------------------------------------------------------------------------*/
AssertTrue: Procedure expose $RXU. SigL
Parse arg Actual, Message
 
Line = SigL /* Patch for Regina bug #610 */
OK = Actual
If $RXU._AssertionDetails | $RXU_Not(OK) then ,
   Details = RXU$_AssertionDetails('Expected', 1, 'Actual', Actual, Line)
If $RXU._AssertionDetails then Say Details
If OK then Return
Call $RXU_AssertFailed Message, Details
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* Expect(condition, [subcondition], [message])                              */
/*                                                                           */
/* Expect the named condition to occur before the test returns.  Condition   */
/* must be one of 'ERROR', 'FAILURE', 'HALT', 'NOTREADY', 'NOVALUE', or      */
/* 'SYNTAX', case independent. In the case of 'ERROR', 'FAILURE', and        */
/* 'SYNTAX', there may be an expected subcondition RC value.                 */
/*---------------------------------------------------------------------------*/
Expect: Procedure expose $RXU.
Parse arg $RXU._ExpectWhat, $RXU._ExpectHow, $RXU._ExpectMsg
 
$RXU._ExpectWhat = Translate($RXU._ExpectWhat)
If WordPos($RXU._ExpectWhat, ,
        'ERROR FAILURE HALT NOTREADY NOVALUE SYNTAX') = 0 then Do
    $RXU._TestStatus = 'ERROR Invalid parameter:' $RXU._ExpectWhat
    Signal $RXU_TestComplete
End
If WordPos($RXU._ExpectWhat, 'ERROR FAILURE SYNTAX') = 0 & ,
    $RXU_Not($RXU._ExpectHow = '') then Do
    $RXU._TestStatus = 'ERROR Unexpected details for' ,
        $RXU._ExpectWhat':' $RXU._ExpectHow
    Signal $RXU_TestComplete
End
 
Return
 
/*---------------------------------------------------------------------------*/
/* Fail([message])                                                           */
/*                                                                           */
/* Fail the test with the optional message.                                  */
/*---------------------------------------------------------------------------*/
Fail: Procedure expose $RXU. SigL
Parse arg Message
 
Line = SigL /* Patch for Regina bug #610 */
Call $RXU_AssertFailed RXU$_AssertionDetails(, , , , Message, Line)
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* NoError(command)                                                          */
/*                                                                           */
/* Execute a command with SIGNAL OFF ERROR and return its return code.       */
/* This is not a procedure, so the command can access the caller's variables.*/
/*---------------------------------------------------------------------------*/
NoError:
 
Signal off Error
''Arg(1)
Signal on Error
 
Return RC
 
 
/*---------------------------------------------------------------------------*/
/* RexxLevel()                                                               */
/*                                                                           */
/* Return the version of the Rexx language supported by this implementation. */
/*---------------------------------------------------------------------------*/
RexxLevel: Procedure expose $RXU.
 
Return $RXU._RexxLevel
 
 
/*---------------------------------------------------------------------------*/
/* RexxOS()                                                                  */
/*                                                                           */
/* Return the OS name of the Rexx language supported by this implementation. */
/*---------------------------------------------------------------------------*/
RexxOS: Procedure expose $RXU.
 
Return $RXU._OS
 
 
/*---------------------------------------------------------------------------*/
/* Skip([message])                                                           */
/*                                                                           */
/* Skip the test with the optional message.                                  */
/*---------------------------------------------------------------------------*/
Skip: Procedure expose $RXU.
Parse arg Message
 
$RXU._TestStatus = 'SKIP' Message
Signal $RXU_TestComplete
 
 
/*---------------------------------------------------------------------------*/
/* SkipIf(condition, [message])                                              */
/*                                                                           */
/* Skip the test with the optional message, if the condition is true.        */
/*---------------------------------------------------------------------------*/
SkipIf: Procedure expose $RXU.
Parse arg Condition, Message
 
If $RXU_Not(Condition) then Return
$RXU._TestStatus = 'SKIP' Message
Signal $RXU_TestComplete
 
 
/*---------------------------------------------------------------------------*/
/* XFail([Message])                                                          */
/*                                                                           */
/* Expect the test to fail, and report the optional message if it passes.    */
/*---------------------------------------------------------------------------*/
XFail: Procedure expose $RXU.
Parse arg Message
 
If Message = '' then Message = 'Expected to fail, but passed'
$RXU._ExpectFailure = 1
$RXU._ExpectFailureMessage = Message
 
Return
 
 
/*---------------------------------------------------------------------------*/
/* Test authors: Do not call or signal anything below this point.            */
/*---------------------------------------------------------------------------*/
 
 
/*---------------------------------------------------------------------------*/
/* $RXU_AssertFailed(Message, Details)                                       */
/*                                                                           */
/* Back-end processing for a failed assertion.  Adds to the response to      */
/* the test runner and exits to $RXU_TestComplete.  Does not return to       */
/* caller unless SoftAsserts is set.                                         */
/*---------------------------------------------------------------------------*/
$RXU_AssertFailed: Procedure expose $RXU.
Parse arg Message, Details
 
Signal off Error
If $RXU._RexxLevel > 3.40 then Interpret "Signal off Failure"
Signal off NotReady
Signal off NoValue
Signal off Syntax
If Message = '' then Message = 'Assertion failed'
Parse var $RXU._TestStatus . PreviousDetails
If $RXU_Not(PreviousDetails = '') then ,
    PreviousDetails = PreviousDetails || '15'x
$RXU._TestStatus = 'FAIL' PreviousDetails || Message || '15'x || Details
 
If $RXU._SoftAsserts then Return
Signal $RXU_TestComplete
 
 
/*---------------------------------------------------------------------------*/
/* RXU$_AssertionDetails([ExpectedText], [ExpectedValue], [ActualText],      */
/*                [ActualValue], [Line])                                     */
/*                                                                           */
/* Format and return a assertion-details string.                             */
/*---------------------------------------------------------------------------*/
RXU$_AssertionDetails: Procedure expose $RXU.
 
Parse arg ExpectedText, ExpectedValue, ActualText, ActualValue, Line
If $RXU_Not(Line = '') then FailingCode = Line-1':' $RXU_SourceCode(Line)
Else FailingCode = ''
Details = FailingCode
TextWidth = Max(Length(ExpectedText), Length(ActualText))
If $RXU_Not(ExpectedText = '') then ,
    Details = Details || '15'x || Left(ExpectedText, TextWidth) || ,
        ': ["' || ExpectedValue || '"]'
If $RXU_Not(ActualText = '') then ,
    Details = Details || '15'x || Left(ActualText, TextWidth) || ,
        ': ["' || ActualValue || '"]'
 
Return Details
 
 
/*---------------------------------------------------------------------------*/
/* $RXU_Not(Boolean)                                                         */
/*                                                                           */
/* Because some Rexx implementations have problems with not-sign operators.  */
/*---------------------------------------------------------------------------*/
$RXU_Not: Procedure
 
If Arg(1) then Return 0
Return 1
 
 
$RXU_TrapError:
Call $RXU_TrapSprung 'ERROR', RC, RXU_TrapLine
 
 
$RXU_TrapFailure:
Call $RXU_TrapSprung 'FAILURE', RC, RXU_TrapLine
 
 
$RXU_TrapNotReady:
Call $RXU_TrapSprung 'NOTREADY', , RXU_TrapLine
 
 
$RXU_TrapNoValue:
Call $RXU_TrapSprung 'NOVALUE', , RXU_TrapLine
 
 
$RXU_TrapSyntax:
Call $RXU_TrapSprung 'SYNTAX', RC, RXU_TrapLine
 
/*---------------------------------------------------------------------------*/
/* $RXU_SourceCode(line_num)                                                 */
/*                                                                           */
/* Return the source code on the specified line, including any continuatioms.*/
/*---------------------------------------------------------------------------*/
$RXU_SourceCode: Procedure
Arg Line
 
Code = ''
Do Line = Line by 1
   Code = Code Strip(SourceLine(Line))
   If $RXU_Not(Right(Code, 1) = ',') then Leave
   Code = Left(Code, Length(Code)-1)
End
 
Return Strip(Code)
 
 
/*---------------------------------------------------------------------------*/
/* $RXU_Start                                                                */
/*                                                                           */
/* Run the test.                                                             */
/*---------------------------------------------------------------------------*/
$RXU_Start:
 
Drop $RXU.
$RXU. = ''
$RXU._ExpectOccurred = 0
$RXU._ExpectFailure = 0
$RXU._TestStatus = 'PASS'
 
Parse arg $RXU._Testname $RXU._HasSetup $RXU._HasTeardown $RXU._OS ,
    $RXU._RexxLevel $RXU._SoftAsserts $RXU._AssertionDetails .
Signal on Error ; $RXU_TrapErrorDest = '$RXU_TrapError'
If $RXU._RexxLevel > 3.40 then ,
    Interpret "Signal on Failure ; $RXU_TrapFailureDest = '$RXU_TrapFailure'"
Signal on NotReady ; $RXU_TrapNotReadyDest = '$RXU_TrapNotReady'
Signal on NoValue ; $RXU_TrapNoValueDest = '$RXU_TrapNoValue'
Signal on Syntax; $RXU_TrapSyntaxDest = '$RXU_TrapSyntax'
If $RXU._HasSetup then Call TestSetup
Interpret 'Call' $RXU._Testname
 
$RXU_TestComplete:
If $RXU._HasTeardown then Call TestTeardown
 
If $RXU._ExpectFailure & $RXU._TestStatus = 'PASS' then ,
    Exit 'XFAIL' $RXU._ExpectFailureMessage
If $RXU._ExpectWhat = '' then Exit $RXU._TestStatus
If $RXU._ExpectOccurred then Exit $RXU._TestStatus
If $RXU_Not($RXU._ExpectMsg = '') then Exit 'FAIL' $RXU._ExpectMsg
Exit 'FAIL Expected' $RXU._ExpectWhat $RXU._ExpectHow 'not SIGNALed'
 
 
/*---------------------------------------------------------------------------*/
/* $RXU_TrapSprung(ConditionName, [Details], Line)                           */
/*                                                                           */
/* Back-end processing for a trapped SIGNAL.  Constructs the response to     */
/* the test runner and exits to $RXU_TestComplete.  Does not return to       */
/* caller.                                                                   */
/*---------------------------------------------------------------------------*/
$RXU_TrapSprung:
 
Signal off Error
If $RXU._RexxLevel > 3.40 then Interpret "Signal off Failure"
Signal off NotReady
Signal off NoValue
Signal off Syntax
Parse arg ConditionName, Details, Line
$RXU._ExpectOccurred = ($RXU._ExpectWhat == ConditionName)
if $RXU_Not($RXU._ExpectHow = '') then ,
    $RXU._ExpectOccurred = $RXU._ExpectOccurred & ($RXU._ExpectHow == Details)
If $RXU._ExpectOccurred then $RXU._TestStatus = 'PASS'
Else $RXU._TestStatus = 'SIGNAL' ConditionName Details
 
Signal $RXU_TestComplete
 
 
/*---------------------------------------------------------------------------*/
/* $RXU_WordPos(needle, haystack, startword)                                 */
/*                                                                           */
/* Because some Rexx implementations don't have the built-in.                */
/*---------------------------------------------------------------------------*/
$RXU_WordPos: Procedure
Parse arg Needle, Haystack, StartWord
 
If StartWord = '' then StartWord = 1
If Words(Needle) = 0 then Return 0
Do I = StartWord by 1 while $RXU_Not(Haystack = '')
    Parse var Haystack HaystackWord1 Haystack
    If $RXU_Not(Word(Needle, 1) = HaystackWord1) then Iterate
    Do J = 2 to Words(Needle)
        If $RXU_Not(Word(Needle, J) = Word(Haystack, J-1)) then Iterate
    End
    Return I
End
 
Return 0
 
/* Note: This program does not use SIGNAL ON condition NAME label,
         because it isn't supported in (at least) VM/SP5 Rexx.  Instead,
         it uses SignalDest='label'; SIGNAL ON condition; ... Syntax:
         SIGNAL VALUE SignalDest.  Yes, it's hokey.  But it works.
*/
 
Error:
$RXU_TrapLine = SigL
If Symbol('$RXU_TrapErrorDest') = 'VAR' then ,
    Signal value Translate($RXU_TrapErrorDest)
Say 'Error in line' RXU_TrapLine || ':' $RXU_SourceCode(RXU_TrapLine)
Exit 1
 
Failure:
$RXU_TrapLine = SigL
If Symbol('$RXU_TrapFailureDest') = 'VAR' then ,
    Signal value Translate($RXU_TrapFailureDest)
Say 'Failure in line' RXU_TrapLine || ':' $RXU_SourceCode(RXU_TrapLine)
Exit 2
 
NotReady:
$RXU_TrapLine = SigL
If Symbol('$RXU_TrapNotReadyDest') = 'VAR' then ,
    Signal value Translate($RXU_TrapNotReadyDest)
Say 'NotReady in line' RXU_TrapLine || ':' $RXU_SourceCode(RXU_TrapLine)
Exit 3
 
NoValue:
$RXU_TrapLine = SigL
If Symbol('$RXU_TrapNoValueDest') = 'VAR' then ,
    Signal value Translate($RXU_TrapNoValueDest)
Say 'NoValue error in line' RXU_TrapLine || ':' $RXU_SourceCode(RXU_TrapLine)
Exit 4
 
 
Syntax:
$RXU_TrapLine = SigL
If Symbol('$RXU_TrapSyntaxDest') = 'VAR' then ,
    Signal value Translate($RXU_TrapSyntaxDest)
Say 'Syntax error' RC ErrorText(RC) 'in line' RXU_TrapLine || ':' $RXU_SourceCode(RXU_TrapLine)
Exit 5
 
