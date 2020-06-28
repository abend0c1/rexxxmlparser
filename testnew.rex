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
** NAME     - TESTNEW                                                **
**                                                                   **
** FUNCTION - Tests creation and modification of XML.                **
**                                                                   **
**                                                                   **
** SYNTAX   - testnew outfile                                        **
**                                                                   **
**            Where,                                                 **
**            outfile  = Name of file to store the output in.        **
**                       The default is the console.                 **
**                                                                   **
**                                                                   **
** NOTES    - 1. You will have to either append the PRETTY rexx code **
**               manually to this demo source, or run this demo      **
**               source through the REXXPP rexx pre-processor.       **
**                                                                   **
**               To use the pre-processor, run:                      **
**                                                                   **
**               rexxpp testnew testnewp                             **
**                                                                   **
**               ...and then run the resulting rexx procedure:       **
**                                                                   **
**               testnewp                                            **
**                ...or...                                           **
**               testnewp outfile                                    **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --- ----------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20060803 AJA Added unit tests for getAttributeMap.     **
**            20040707 AJA Intial version.                           **
**                                                                   **
**********************************************************************/


  parse arg sFileOut' ('sOptions

  parse value sourceline(1) with . sVersion
  say 'Unit Test Suite 2 - ' sVersion

  sOptions = 'NOBLANKS' sOptions
  call initParser /* <-- This is in PARSEXML rexx */

  parse source g.!ENV .
  if g.!ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.!LINES = 0
  end

  g.!TEST = 0

  call Log 'Create a new document'
  doc = createDocument('bridgekeeper')
  call prettyPrinter

  call Log 'Create a faq tag and append it to the document'
  q1 = createElement('faq')
  call appendChild q1,doc
  count = words(getChildren(doc))
  call assertEquals 1,count,'001 <bridgekeeper> has wrong child count'
  call setAttribute q1,'question','What is your name?'
  count = getAttributeCount(q1)
  call assertEquals 1,count,'002 <faq> element has wrong attr count'
  textNode = createTextNode('Sir Gawain of Camelot')
  call appendChild textNode,q1
  count = words(getChildren(q1))
  call assertEquals 1,count,'003 <faq> element has wrong child count'
  call prettyPrinter

  call Log 'Create another faq tag and append it to the document'
  q2 = createElement('faq')
  call setAttribute q2,'question','What is your quest?'
  count = getAttributeCount(q2)
  call assertEquals 1,count,'004 <faq> element has wrong attr count'
  call setAttribute q2,'answer','To seek the Holy Grail'
  count = getAttributeCount(q2)
  call assertEquals 2,count,'005 <faq> element has wrong attr count'
  call appendChild q2,doc
  count = words(getChildren(doc))
  call assertEquals 2,count,'006 <bridgekeeper> has wrong child count'
  call prettyPrinter

  call Log 'Create yet another faq tag and append it to the document'
  q3 = createElement('faq')
  call setAttribute q3,'question','What is your favourite color?'
  call setAttribute q3,'answer','Blue'
  call appendChild q3,doc
  count = words(getChildren(doc))
  call assertEquals 3,count,'007 <bridgekeeper> has wrong child count'
  call prettyPrinter

  call Log 'Modify the answer attribute on the third faq tag'
  call setAttribute q3,'answer','No yelloooooww'
  call assertEquals 'No yelloooooww',getAttribute(q3,'answer'),,
          '008 "answer" attribute of <faq> is not correct'
  call prettyPrinter

  call Log 'Remove a text node and some attributes'
  count = words(getChildren(q1))
  call assertEquals 1,count,'009 <faq> has wrong child count'
  call removeChild textNode /* give Sir Gawain the flick */
  count = words(getChildren(q1))
  call assertEquals 0,count,'010 <faq> has wrong child count'

  count = getAttributeCount(q3)
  call assertEquals 2,count,'011 <faq> element has wrong attr count'
  call removeAttribute q3,'question'
  count = getAttributeCount(q3)
  call assertEquals 1,count,'012 <faq> element has wrong attr count'
  call removeAttribute q3,'answer'
  count = getAttributeCount(q3)
  call assertEquals 0,count,'013 <faq> element has wrong attr count'
  call prettyPrinter

  call Log 'Insert a new text node in the first faq tag'
  textNode = createTextNode('King of the Britons')
  call appendChild textNode,q1
  call insertBefore createTextNode('It is Arthur, '),textNode
  call setAttribute q3,'question','What is the air-speed velocity',
                                  'of an unladen swallow?'
  call setAttribute q3,'answer','What do you mean?  An African or',
                                  'European swallow?'
  call prettyPrinter

  call Log 'Exercise getAttributeMap'
  call prettyPrinter ,,q3
  call getAttributeMap q3
  count = g.!ATTRIBUTE.0
  call assertEquals 2,count,'014 <faq> element has wrong attr count'
  s = g.!ATTRIBUTE.1
  call assertEquals 'question',s,,
                            '015 Attribute 1 of <faq> has wrong name'
  s = g.!ATTRIBUTE.2
  call assertEquals 'answer',s,,
                            '016 Attribute 2 of <faq> has wrong name'

  call Log 'Write the document to a file (or console)'
  call prettyPrinter sFileOut
exit

Log: procedure expose g.
  parse arg sMessage
  g.!TEST = g.!TEST + 1 /* increment test number */
  say
  say 'Test' right(g.!TEST,3,'0') left(sMessage,68,'-')
return

/*INCLUDE pretty.rex */
/*INCLUDE assert.rex */
