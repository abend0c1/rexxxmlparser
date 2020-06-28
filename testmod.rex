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
** NAME     - TESTMOD                                                **
**                                                                   **
** FUNCTION - Tests modification of an existing XML file.            **
**                                                                   **
**                                                                   **
** SYNTAX   - testmod infile [outfile]                               **
**                                                                   **
**            Where,                                                 **
**            infile   = Name of XML file to be modified.            **
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
**               rexxpp testmod testmodp                             **
**                                                                   **
**               ...and then run the resulting rexx procedure over   **
**               an XML file of your choice:                         **
**                                                                   **
**               testmodp infile                                     **
**                ...or...                                           **
**               testmodp infile outfile                             **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top pls)       **
**            -------- --- ----------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20040707 AJA Intial version.                           **
**                                                                   **
**********************************************************************/


  parse arg sFileIn sFileOut' ('sOptions')'

  parse value sourceline(1) with . sVersion
  say 'Unit Test Suite 1 - ' sVersion
  
  if sFileIn = ''
  then do
    parse source sSystem sInvocation sSourceFile .
    say 'Syntax:' sSourceFile 'filein fileout (options...'
    exit
  end


  sOptions = 'NOBLANKS' sOptions
  call initParser sOptions /* <-- This is in PARSEXML rexx */

  parse source g.!ENV .
  if g.!ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.!LINES = 0
  end

  /* Open the specified file and parse it */
  nParseRC = parseFile(sFileIn)
  doc = getDocumentElement()

  /* Create a new tag */
  prologNode = createElement('prolog')
  faqNode = createElement('faq')
  call setAttribute faqNode,'question','What is your name?'
  textNode = createTextNode('Sir Gawain of Camelot')
  call appendChild textNode,faqNode
  call appendChild faqNode,prologNode
  /* We now have the following structure in memory:
     <prolog>
       <faq question="What is your name?">
         Sir Gawain of Camelot
       </faq>
     </prolog>
  */

  call Log 'Inserting a <prolog> tag at the start of the document'
  firstChild = getFirstChild(doc)
  if firstChild <> '' /* If document has a first child */
  then call insertBefore prologNode,firstChild
  else call appendChild prologNode,doc

  /* Verify that the first child is now indeed the <prolog> node */
  call assertEquals getFirstChild(doc),prologNode,,
              'Failed to insert <prolog> as the first child'

  call Log 'Appending an empty <epilog> at the end of the document'
  call appendChild createElement('epilog'),doc

  /* Save the document to a file (or display on console) */
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
