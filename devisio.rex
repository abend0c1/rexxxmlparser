/*REXX 2.0.0.1

Copyright (c) 2009, Andrew J. Armstrong
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
** NAME     - DEVISIO                                                **
**                                                                   **
** FUNCTION - Removes non-SVG markup from SVG documents created by   **
**            Microsoft Visio. The Microsoft-specific extensions are **
**            identified by the 'v:' name space.                     **
**                                                                   **
** USAGE    - You can run this Rexx on an IBM mainframe, or on a PC  **
**            by using Regina Rexx from:                             **
**                                                                   **
**               http://regina-rexx.sourceforge.net                  **
**                                                                   **
**                                                                   **
** SYNTAX   - DEVISIO infile outfile [(options...]                   **
**                                                                   **
**            Where,                                                 **
**            infile   = Microsoft Visio SVG file.                   **
**            outfile  = SVG file.                                   **
**            options  = Options                                     **
**                                                                   **
** NOTES    - 1. You will have to either append the PARSEXML and     **
**               PRETTY source files manually to this file, or run   **
**               this file through the REXX rexx pre-processor.      **
**                                                                   **
**               To use the pre-processor, run:                      **
**                                                                   **
**               tso rexxpp your.rexx.lib(devisio)                   **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --- ----------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20051026 AJA Initial version.                          **
**                                                                   **
**********************************************************************/

  parse arg sFileIn sFileOut' ('sOptions')'

  numeric digits 16
  parse value sourceline(1) with . sVersion .
  say 'VIS000I Microsoft Visio SVG extensions remover' sVersion
  if sFileIn = ''
  then do
    say 'Syntax:'
    say '   devisio infile outfile (options'
    say
    say 'Where:'
    say '   infile  = Microsoft Visio SVG file'
    say '   outfile = SVG file (without Microsoft extensions)'
    exit
  end

  sOptions = 'NOBLANKS' translate(sOptions)
  call initParser sOptions /* DO THIS FIRST! Sets g. vars to '' */

  parse source g.!ENV .
  if g.!ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.!LINES = 0
  end

  call Prolog

  /* Open the specified file and parse it */
  nParseRC = parseFile(sFileIn)
  doc = getDocumentElement()

  g.!PREFIXES = getVisioNamespacePrefixes(doc)
  say 'VIS002I Removing elements and attributes with prefixes:',
      g.!PREFIXES

  call removeVisioTags doc

  call findAllReferences doc

  call removeUnusedReferences doc

  /* fix ups to make the svg render properly...*/
  call setAttributes doc,,
               'xml:space','default',,
               'xmlns:xlink','http://www.w3.org/1999/xlink'

  call prettyPrinter sFileOut

  call Epilog
exit

getVisioNamespacePrefixes: procedure expose g.
  parse arg doc
  sAttrNames = getAttributeNames(doc)
  sPrefixes = ''
  do i = 1 to words(sAttrNames)
    sAttrName = word(sAttrNames,i)
    if left(sAttrName,6) = 'xmlns:'
    then do
      sNameSpace = getAttribute(doc,sAttrName)
      if pos('schemas.microsoft.com',sNameSpace) > 0
      then do
        sPrefix = substr(sAttrName,7)
        sPrefixes = sPrefixes sPrefix
        say 'VIS001I Removing' sAttrName'='getAttribute(doc,sAttrName)
        call removeAttribute doc,sAttrName
      end
    end
  end
return strip(sPrefixes)

removeVisioTags: procedure expose g.
  parse arg node
  sTagName = getNodeName(node)
  if isVisioExtension(sTagName)
  then call removeChild node
  else do
    if sTagName = 'marker' /* HACK: fixes Visio 2003 bug */
    then call setAttribute node,'overflow','visible'
    sAttrNames = getAttributeNames(node)
    do i = 1 to words(sAttrNames)
      sAttrName = word(sAttrNames,i)
      if isVisioExtension(sAttrName)
      then call removeAttribute node,sAttrName
    end
    children = getChildNodes(node)
    do i = 1 to words(children)
      child = word(children,i)
      call removeVisioTags child
    end
  end
return

isVisioExtension: procedure expose g.
  parse arg sTagName .
  if wordpos(sTagName,'title desc') > 0 then return 1
  if pos(':',sTagName) = 0              then return 0
  parse arg sPrefix':'
  if wordpos(sPrefix,g.!PREFIXES) > 0   then return 1
return 0

findAllReferences: procedure expose g.
  parse arg node
  sText = getNodeValue(node)
  do while pos('url(#',sText) > 0
    parse var sText 'url(#'sId')'sText
    sRef = '#'sId
    g.!ID.sRef = 1
  end
  if hasAttribute(node,'xlink:href')
  then do
    sId = getAttribute(node,'xlink:href')
    if left(sId,1) = '#' /* is it a local reference? */
    then g.!ID.sId = 1 /* For example: g.!ID.#mrkr13-14 = 1 */
  end
  children = getChildNodes(node)
  do i = 1 to words(children)
    child = word(children,i)
    call findAllReferences child
  end
return

removeUnusedReferences: procedure expose g.
  parse arg node
  if hasAttribute(node,'id')
  then do
    sId = getAttribute(node,'id')
    sRef = '#'sId
    if g.!ID.sRef <> 1
    then call removeAttribute node,'id'
  end
  children = getChildNodes(node)
  do i = 1 to words(children)
    child = word(children,i)
    call removeUnusedReferences child
  end
return


Prolog: procedure expose g.
return

Epilog: procedure expose g.
return

/*INCLUDE pretty.rex */
