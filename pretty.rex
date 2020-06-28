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
** NAME     - PRETTY                                                 **
**                                                                   **
** FUNCTION - Pretty printer. This demonstrates the XML parser by    **
**            reformatting an xml input file.                        **
**                                                                   **
**                                                                   **
** SYNTAX   - pretty infile [outfile] (options...)                   **
**                                                                   **
**            Where,                                                 **
**            infile   = Name of file to be parsed                   **
**            outfile  = Name of file to store the pretty output in. **
**                       The default is the console.                 **
**            options  = NOBLANKS - Suppress whitespace-only nodes   **
**                       DEBUG    - Display some debugging info      **
**                       DUMP     - Display the parse tree           **
**                                                                   **
**                                                                   **
** NOTES    - 1. You will have to either append the PARSEXML source  **
**               manually to this demo source, or run this demo      **
**               source through the REXXPP rexx pre-processor.       **
**                                                                   **
**               To use the pre-processor, run:                      **
**                                                                   **
**               rexxpp pretty prettypp                              **
**                                                                   **
**               ...and then run the resulting rexx procedure over   **
**               an XML file of your choice:                         **
**                                                                   **
**               prettypp testxml [outxml]                           **
**                ...or...                                           **
**               prettypp testxml [outxml] (noblanks                 **
**                ...or...                                           **
**               prettypp testxml [outxml] (noblanks dump            **
**                                                                   **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com     **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --------------------------------------------- **
**            20200628 AJA Added showNodeNonRecursive function.      **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20050920 AJA Allow root node to be specified.          **
**            20050907 AJA Escape text of attribute values.          **
**            20040706 AJA Assume default indentation amount.        **
**                         Allow output to a file.                   **
**            20031031 AJA Fix escaping text.                        **
**            20030911 AJA Removed default filename value. You       **
**                         must specify your own filename.           **
**            20030905 AJA Intial version.                           **
**                                                                   **
**********************************************************************/

  parse arg sFileIn sFileOut' ('sOptions')'
  parse value sourceline(1) with . sVersion
  say 'PRP000I Pretty Printer' sVersion

  /* Initialise the parser */
  call initParser sOptions /* <-- This is in PARSEXML rexx */

  /* Open the specified file and parse it */
  nParseRC = parseFile(sFileIn)

  parse source g.0ENV .
  if g.0ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.0LINES = 0
    g.0NONRECURSIVE = 1
  end

  call prettyPrinter sFileOut,2 /* 2 is the indentation amount */

exit nParseRC

/*-------------------------------------------------------------------*
 * An example of how to navigate the tree
 *-------------------------------------------------------------------*/

prettyPrinter: procedure expose g.
  parse arg sFileOut,g.0TAB,nRoot
  if g.0TAB = '' then g.0TAB = 2 /* indentation amount */
  if nRoot = '' then nRoot = getRoot()
  g.0INDENT = 0
  g.0FILEOUT = ''
  if sFileOut <> ''
  then do
    g.0FILEOUT = openFile(sFileOut,'OUTPUT')
    if g.0rc = 0
    then say 'PRP001I Creating' sFileOut
    else do
      say 'PRP002E Could not create' sFileOut'. Writing to console...'
      g.0FILEOUT = '' /* null handle means write to console */
    end
  end

  call _setDefaultEntities

  call emitProlog
  if g.0NONRECURSIVE = 1
  then do
    call showNodeNonRecursive nRoot
   end
  else do
    g.0INDENT = -g.0TAB
    call showNode nRoot
  end

  if g.0FILEOUT <> ''
  then do
    say 'PRP002I Created' sFileOut
    rc = closeFile(g.0FILEOUT)
  end
return

showNodeNonRecursive: procedure expose g.
  parse arg topNodeAgain
  g.0INDENT = 0
  node = topNodeAgain
  do until node = topNodeAgain | node = 0
    if g.0SEEN.node = ''
    then call emitBegin node
    else call emitEnd node
    g.0SEEN.node = 1
    if g.0SOUTH.node = '' then do
      g.0SOUTH.node = 1
      if hasChildren(node)
      then do
        node = getFirstChild(node)
      end
      else do
        call emitEnd node
        nextSibling = getNextSibling(node)
        if nextSibling = ''
        then node = getParent(node)
        else node = nextSibling
      end
    end
    else do
      nextSibling = getNextSibling(node)
      if nextSibling = ''
      then node = getParent(node)
      else node = nextSibling
    end
  end
  call emitEnd node
  drop g.0SOUTH. g.0SEEN.
return

emitBegin: procedure expose g.
  parse arg node
  select
    when isElementNode(node) then call emitElementNodeNonRecursive(node)
    when isTextNode(node)    then call emitTextNode(node)
    when isCommentNode(node) then call emitCommentNode(node)
    when isCDATA(node)       then call emitCDATA(node)
    otherwise nop
  end
  g.0INDENT = g.0INDENT + 2
return

emitEnd: procedure expose g.
  parse arg node
  g.0INDENT = g.0INDENT - 2
  if isElementNode(node) & hasChildren(node)
  then call Say '</'getName(node)'>'
return

emitElementNodeNonRecursive: procedure expose g.
  parse arg node
  if hasChildren(node)
  then call Say '<'getName(node)getAttrs(node)'>'
  else call Say '<'getName(node)getAttrs(node)'/>'
return

getAttrs: procedure expose g.
  parse arg node
  sAttrs = ''
  do i = 1 to getAttributeCount(node)
    sAttrs = sAttrs getAttributeName(node,i)'="' ||,
                    escapeText(getAttribute(node,i))'"'
  end
return sAttrs

emitProlog: procedure expose g.
  if g.?xml.version = ''
  then sVersion = '1.0'
  else sVersion = g.?xml.version
  if g.?xml.encoding = ''
  then sEncoding = 'UTF-8'
  else sEncoding = g.?xml.encoding
  if g.?xml.standalone = ''
  then sStandalone = 'yes'
  else sStandalone = g.?xml.standalone

  g.0INDENT = 0
  call Say '<?xml version="'sVersion'"',
                'encoding="'sEncoding'"',
              'standalone="'sStandalone'"?>'

  sDocType = getDocType()
  if sDocType <> ''
  then call Say '<!DOCTYPE' getName(getDocumentElement()) sDocType'>'
return

showNode: procedure expose g.
  parse arg node
  g.0INDENT = g.0INDENT + g.0TAB
  select
    when isTextNode(node)    then call emitTextNode    node
    when isCommentNode(node) then call emitCommentNode node
    when isCDATA(node)       then call emitCDATA       node
    otherwise                     call emitElementNode node
  end
  g.0INDENT = g.0INDENT - g.0TAB
return

setPreserveWhitespace: procedure expose g.
  parse arg bPreserve
  g.0PRESERVEWS = bPreserve = 1
return

emitTextNode: procedure expose g.
  parse arg node
  sText = getText(node)
  if sText = '' then return
  if g.0PRESERVEWS = 1
  then call Say escapeText(sText)
  else call Say escapeText(removeWhitespace(sText))
return

emitCommentNode: procedure expose g.
  parse arg node
  call Say '<!--'getText(node)' -->'
return

emitCDATA: procedure expose g.
  parse arg node
  call Say '<![CDATA['getText(node)']]>'
return

emitElementNode: procedure expose g.
  parse arg node
  sName = getName(node)
  sAttrs = ''
  do i = 1 to getAttributeCount(node)
    sAttrs = sAttrs getAttributeName(node,i)'="' ||,
                    escapeText(getAttribute(node,i))'"'
  end
  sChildren = getChildren(node)
  if sChildren = ''
  then do
    if sAttrs = ''
    then call Say '<'sName'/>'
    else call Say '<'sName strip(sAttrs)'/>'
  end
  else do
    if sAttrs = ''
    then call Say '<'sName'>'
    else call Say '<'sName strip(sAttrs)'>'
    child = getFirstChild(node)
    do while child <> ''
      call showNode child
      child = getNextSibling(child)
    end
    call Say '</'sName'>'
  end
return

Say: procedure expose g.
  parse arg sMessage
  sLine = copies(' ',g.0INDENT)sMessage
  if g.0FILEOUT = ''
  then say sLine
  else call putLine g.0FILEOUT,sLine
return

/*INCLUDE io.rex */
/*INCLUDE parsexml.rex */
