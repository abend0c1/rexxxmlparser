/*REXX 2.0.0
Copyright (c) 2009-2020, Andrew J. Armstrong
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are 
met:

    * Redistributions of source code must retain the above copyright 
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in 
      the documentation and/or other materials provided with the
      distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

/*REXX*****************************************************************
**                                                                   **
** NAME     - ASSERT                                                 **
**                                                                   **
** FUNCTION - Unit test assertion plumbing.                          **
**                                                                   **
**                                                                   **
** SYNTAX   - n/a                                                    **
**                                                                   **
** NOTES    - 1. You will have to either append the ASSERT rexx code **
**               manually to your Rexx source, or run your Rexx      **
**               source through the REXXPP rexx pre-processor.       **
**                                                                   **
**               To use the pre-processor, run:                      **
**                                                                   **
**               rexxpp yourrexx xyz                                 **
**                                                                   **
**               ...and then run the resulting 'xyz' rexx procedure: **
**                                                                   **
**               xyz                                                 **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --- ----------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20060803 AJA Added message number to messages.         **
**            20050517 AJA Initial version.                          **
**                                                                   **
**********************************************************************/

  parse source . . sSourceFile .
  parse value sourceline(1) with . sVersion
  say 'Unit test routines' sVersion
  say 'You cannot invoke this rexx by itself!'
  say
  say 'This rexx is a collection of subroutines to be called'
  say 'from your own rexx procedures. You should either:'
  say '  - Append this procedure to your own rexx procedure,'
  say '    or,'
  say '  - Append the following line to your rexx:'
  say '    /* INCLUDE' sSourceFile '*/'
  say '    ...and run the rexx preprocessor:'
  say '    rexxpp myrexx myrexxpp'
  say '    This will create myrexxpp by appending this file to myrexx'
exit

assertEquals: procedure
  parse arg expected,actual,message
  if actual <> expected
  then call failNotEquals expected,actual,message
return

assertTrue: procedure
  parse arg condition,message
  if condition = 0
  then call failNotEquals 1,condition,message
return

assertFalse: procedure
  parse arg condition,message
  if condition = 1
  then call failNotEquals 0,condition,message
return

failNotEquals: procedure:
  parse arg expected,actual,message
  reason = 'expected:<'expected'> but was:<'actual'>'
  if message = ''
  then say 'ASS001E Assertion failed:' reason
  else say 'ASS002E Assertion failed:' message reason
return
