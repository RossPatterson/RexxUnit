# RexxUnit - A unit-testing framework for Classic Rexx programs

## Contents

* [Overview](#overview)
* [Test structure](#test-structure)
* [Command syntax](#command-syntax)
* [Examples](#examples)
* [Assertion functions](#assertion-functions)
* [Additonal functions](#additonal-functions)
* [Compatibilty](#compatibilty)

## Overview

Inspired by Rony Flatscher's [ooRexxUnit](https://wi.wu.ac.at/rgf/rexx/orx17/),
an unit-testing framework for Open Object Rexx programs, and the basis for
[ooTest](https://wi.wu.ac.at/rgf/rexx/misc/ooTest/ootest.pdf), a test suite for
ooRexx itself, I've built a simple test framework for "Classic Rexx" (_i.e.,
the language described in Mike Cowlishaw's "_The Rexx Language_", and
standardized by the ANSI Rexx Committee).  My initial use for it is to test the
[bREXX](https://github.com/rosspatterson/CMS-370-BREXX) Rexx implementation for
the [VM/370 Community Edition](http://vm370.org/vm) retro-computing system.
After building this, I found a similar project called
[t.rexx](https://github.com/neopragma/t-rexx) by
[Dave Nicolette](https://neopragma.com).  Dave and I went in similar but
different directions, and I'd encourage you to take a look at t.rexx.  RexxUnit
is modeled after the [xUnit](https://en.wikipedia.org/wiki/XUnit) family of
testing frameworks, with addition influence from the
[pytest](https://docs.pytest.org/en/stable/) framework for testing Python
programs.

## Test structure

Unit tests for RexxUnit are simple Rexx subroutines, named `TestWhatever`,
which call assertion subroutines to verify test results, and which just return
if they succeed.  The assertion subroutines are all named `AssertWhatever`, and
if the assertion fails, they fail the test instead of returning to it.  All
symbols starting with `$RXU` are reserved by RexxUnit for its own use.  It does
not use any other symbols, at least not in any way that would interfere with
your test code.  It is not necessary to start your tests with a `PROCEDURE`
instruction, but if you do code one anywhere in your test, be sure to expose
the `$RXU.` stem (_i.e._, `PROCEDURE EXPOSE $RXU.`).  Tests start with the
`ERROR`, `FAILURE`, `NOTREADY`, `NOVALUE`, and `SYNTAX` conditions trapped, and
the `HALT` condition not trapped.  If your test expects to provoke a condition,
use the `Expect()` subroutine to declare that.  If your tests need some code to
run before or after them, put them in a `TestSetup` or `TestTeardown`
subroutine respectively.  Those routines will be called before and after each
test.

For example:

File example1.rexxunit:
```Rexx
TestDefaultNumericDigits:
    Call AssertEqual 9, Digits(), 'Default for NUMERIC DIGITS'
    Return

TestSkipper:
    Call Skip 'for no good reason'
    Return

TestDefaultNumericFuzz: Call AssertEqual 0, Fuzz(); Return
TestFail:
    Call Fail 'Because that''s how I roll'
TestExpect:
    Call Expect 'ERROR', 1
    'asdfqwer'
    Return
```

## Command syntax

The RexxUnit command syntax is styled to the system where you are running it:
* On CMS:
  * `REXXUNIT` _fnpat_[:_testpat]_ ... `(` [[`NO`]`DETAILS`] [`HELP`] [`QUIET`]
    [[`NO`]`SOFT`] [[`NO`]`TYPE`] [`)`]
  * All test files have the filetype `REXXUNIT`, and are located via the normal
    CMS disk-search order.
* On Windows:
  * `rexxunit` [`/d`|`/D`] [`/?`|`/H`] [`/q`|`/Q`] [`/s`|`/S`] [`/v`|`/V`]
    _filepat_[:_testpat_] ...
  * All test filenames are relative to the current directory.
* Elsewhere:
  * `rexxunit` [`-d`|`--details`] [`-h`|`--help`] [`-q`|`--quiet`]
    [`-s`|`--soft`] [`-v`|`--verbose`] _filepat_[:_testpat_] ...
  * All test filenames are relative to the current directory.
## Examples

As an example, to run tests on Windows with
[Regina](https://regina-rexx.sourceforge.io/) installed:

```bat
C:\Ross\Source\VM\RexxUnit>rexx rexxunit.rexx example1.rexxunit
===============================================================================
.S.F'asdfqwer' is not recognized as an internal or external command,
operable program or batch file.
.
===============================================================================
example1.rexxunit:TestSkipper SKIP for no good reason
example1.rexxunit:TestFail FAIL Because that's how I roll
   9:     Call Fail 'Because that''s how I roll'
===============================================================================
3 passed
1 failed
0 errors
1 skipped
0 passed when expected to fail
Elapsed time: .119000 seconds
```

```bat
C:\Ross\Source\VM\RexxUnit>rexx rexxunit.rexx /v example2.rexxunit
example2.rexxunit: 13 tests
================================================================================
example2.rexxunit:Test_1 ...
example2.rexxunit:Test_1 PASS
example2.rexxunit:Test_2 ...
example2.rexxunit:Test_2 PASS
example2.rexxunit:Test_3 ...
example2.rexxunit:Test_3 FAIL Assertion failed
   4: Test_3: Call AssertEqual 'abcabzabc', changestr('','abcabcabc','xy'); Return
   Expected: ["abcabzabc"]
   Actual  : ["abcabcabc"]
example2.rexxunit:Test_4 ...
example2.rexxunit:Test_4 PASS
example2.rexxunit:Test_5 ...
example2.rexxunit:Test_5 PASS
example2.rexxunit:Test_6 ...
example2.rexxunit:Test_6 PASS
example2.rexxunit:Test_7 ...
example2.rexxunit:Test_7 PASS
example2.rexxunit:Test_8 ...
example2.rexxunit:Test_8 PASS
example2.rexxunit:Test_9 ...
example2.rexxunit:Test_9 PASS
example2.rexxunit:Test_10 ...
example2.rexxunit:Test_10 PASS
example2.rexxunit:Test_11 ...
example2.rexxunit:Test_11 PASS
example2.rexxunit:Test_12 ...
example2.rexxunit:Test_12 PASS
example2.rexxunit:Test_13 ...
example2.rexxunit:Test_13 PASS
===============================================================================
example2.rexxunit:Test_3 FAIL Assertion failed
   4: Test_3: Call AssertEqual 'abcabzabc', changestr('','abcabcabc','xy'); Return
   Expected: ["abcabzabc"]
   Actual  : ["abcabcabc"]
===============================================================================
12 passed
1 failed
0 errors
0 skipped
0 passed when expected to fail
Elapsed time: .111000 seconds
```

## Assertion functions

Assertion functions can fail the test in one of two ways.  The normal way,
"hard" assertions, causes the test to fail at the first assertion failure.
When the `soft` option is specified, the test continues to run through all
of its assertions, and reports failure at the end, with the full set of
assertion messages.  Such "soft" assertions can be a handy tool when developing
or modifying a test, but should not be used for normal operation.

The assertions you can use are:

* `AssertEndsWith(expected, actual, [message])` - Return if the actual value
  ends with the expected value, otherwise fail the test and optionally display
  the message.
* `AssertEqual(expected, actual, [message])` - Return if the actual value
  matches the expected value via the rules that Rexx uses for "=", otherwise
  fail the test and optionally display the message.
* `AssertFalse(actual, [message])` - Return if the actual value is false (i.e.,
  0), otherwise fail the test and optionally display the message.
* `AssertIdentical(expected, actual, [message])` - Return if the actual value
  is identical to the expected value, otherwise fail the test and optionally
  display the message.
* `AssertNotEqual(expected, actual, [message])` - Return if the actual value
  does not match the expected value via the rules that Rexx uses for "=",
  otherwise fail the test and optionally display the message.
* `AssertNotIdentical(expected, actual, [message])` - Return if the actual
  value is not identical to the expected value, otherwise fail the test with
  and optionally display the message.
* `AssertStartsWith(expected, actual, [message])` - Return if the actual value
  starts with the expected value, otherwise fail the test and optionally
  display the message.
* `AssertTrue(actual, [message])` - Return if the actual value is true (i.e.,
  1), otherwise fail the test and optionally display the message.

## Additonal functions

Additonal functions supplied by RexxUnit:

* `Expect(condition, [subcondition], [message])` - Expect the named condition
  to occur before the test returns.  Condition must be one of 'ERROR',
  'FAILURE', 'HALT', 'NOTREADY', 'NOVALUE', or 'SYNTAX', case independent. In
  the case of 'ERROR', 'FAILURE', and 'SYNTAX', there may be an expected
  subcondition RC value.  If the condition does not occur, fail the test and
  optionally display the message
* `Fail([message])` - Fail the test and optionally display the message.
* `NoError(command)` - Execute a command with SIGNAL OFF ERROR and return its
  return code.  This is intended for test-support commands that that use the
  return code for some data (_e.g._, the CMS `MAKEBUF` and `SENTRIES`
  commands).
* `RexxOS()` - Return the type of system the test is running on.  Values are
  `CMS`, `Linux`, and `Windows` (and perhaps more in the future).
* `RexxLevel()` - Return the version of the Rexx language supported by this
  implementation.
* `Skip([message])` - Skip the test and optionally display the message.
* `SkipIf(condition, [message])` - Skip the test if the condition is true
  (_i.e._, 1) and optionally display the message.
* `XFail([message])` - Expect the test to fail.  If it unexpectedly passes,
  report that and optionally display the message.

## Compatibilty

RexxUnit attempts to support any Rexx implementation that is at least Rexx
level 3.40 - the version described in Cowlishaw's _The Rexx Language, 2nd
edition_ - on any platform.  In practice, it has needed to "patch around"
implementation variations to be able to do so.

RexxUnit has been tested on:

* CMS Rexx on VM/SP Release 5
* CMS bREXX 1.0.1 on VM/370 CE 1.1.2
* CMS bREXX 1.1.0 on VM/370 CE 1.1.2
* CMS bREXX 1.1.1 on VM/370 CE 1.1.2
* Regina 3.6.5 on Ubuntu x86_64 Linux 20.04
* Regina 3.9.3 on Windows 11 Home 24H2

Other implementations are welcome!  If you find something that doesn't work as
expected, open an
[issue on GitHub](https://github.com/RossPatterson/RexxUnit/issues).  Please
include as clear a description of the error as possible, and if you can, a
`TRACE I` that points to it.

The Rexx code in RexxUnit is somewhat contorted, to ensure as much compatibilty
as possible.  For example, before VM/SP Release 6, the CMS Rexx implementation
didn't support the `FAILURE` condition.  So RexxUnit checks if the interpeter
is new enough, and doesn't do `SIGNAL ON FAILURE` if it isn't:

```Rexx
If $RXU._RexxLevel > 3.40 then Signal on Failure
```

Similarly, the bREXX release 1.0.1 implementation, shipped as part of several
VM/370 Community Edition releases, didn't support `FAILURE` either.  But since
bREXX is a compile-then-interpret implementation, it won't even allow the
`SIGNAL ON FAILURE` line to exist - it can't compile it.  So RexxUnit uses the
`INTERPRET` instruction to do `SIGNAL ON FAILURE`, hiding it from the compiler:

```Rexx
If $RXU._RexxLevel > 3.40 then Interpret "Signal on Failure"
```

Ah, but it's worse than that!  RexxUnit really needs multiple trap handlers for
each condition.  Rexx, of couse, has `SIGNAL ON condition NAME handler`.
But that wasn't introduced until Rexx level 3.46, so some implementations don't
have it.  Thus, what RexxUnit _really_ does for `SIGNAL ON FAILURE` is this:

```Rexx
If $RXU._RexxLevel > 3.40 then ,
    Interpret "Signal on Failure ; $RXU_TrapFailureDest = '$RXU_TrapFailure'"
...
Failure:
If Symbol('$RXU_TrapFailureDest') = 'VAR' then Signal value $RXU_TrapFailureDest
...
```

Whew!
