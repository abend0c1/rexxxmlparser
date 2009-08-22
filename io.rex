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
** NAME     - IO                                                     **
**                                                                   **
** FUNCTION - Simple I/O routines.                                   **
**                                                                   **
** API      - The routines in this module are:                       **
**                                                                   **
**            openFile(filename,options,attrs)                       **
**                Opens the specified file with the specified options**
**                and returns a file handle to be used in other I/O  **
**                operations. By default the file will be opened for **
**                input. Specify 'OUTPUT' to open it for output.     **
**                For TSO, you can specify any operand of the TSO    **
**                ALLOCATE command in the third operand. For example:**
**                rc = openFile('MY.FILE','OUTPUT','RECFM(F,B)'      **
**                              'LRECL(80) BLKSIZE(27920)')          **
**                                                                   **
**            closeFile(handle)                                      **
**                Closes the file specified by 'handle' (which was   **
**                returned by the openFile() routine.                **
**                                                                   **
**            getLine(handle)                                        **
**                Reads the next line from the file specified by     **
**                'handle'.                                          **
**                                                                   **
**            putLine(handle,data)                                   **
**                Appends the specified data to the file specified   **
**                by 'handle'.                                       **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --------------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20061017 AJA Added support for UNIX environment.       **
**                         Tested on Ubuntu Linux 6.06 LTS.          **
**            20050930 AJA Initial version.                          **
**                                                                   **
**********************************************************************/

  parse source . . sSourceFile .
  parse value sourceline(1) with . sVersion .
  say 'Simple Rexx I/O routines' sVersion
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

/*-------------------------------------------------------------------*
 * Open a file
 *-------------------------------------------------------------------*/

openFile: procedure expose g.
  parse arg sFile,sOptions,sAttrs
  hFile = ''
  select
    when g.!ENV = 'TSO' then do
      bOutput = wordpos('OUTPUT',sOptions) > 0
      bQuoted = left(sFile,1) = "'"
      if bQuoted then sFile = strip(sFile,,"'")
      parse var sFile sDataset'('sMember')'
      if sMember <> '' then sFile = sDataset
      if bQuoted then sFile = "'"sFile"'"
      if bOutput
      then 'LMINIT  DATAID(hFile) DATASET(&sFile) ENQ(EXCLU)'
      else 'LMINIT  DATAID(hFile) DATASET(&sFile)'
      if sMember <> ''
      then do /* Open a member of a PDS */
        'LMOPEN  DATAID(&hFile) OPTION(INPUT)' /* Input initially */
        /* ... can't update ISPF stats when opened for output */
        g.!MEMBER.hFile = sMember
        'LMMFIND DATAID(&hFile) MEMBER('sMember') STATS(YES)'
        if bOutput
        then do
          if rc = 0
          then g.!STATS.hFile = zlvers','zlmod','zlc4date
          else g.!STATS.hFile = '1,0,0000/00/00'
          'LMCLOSE DATAID(&hFile)'
          'LMOPEN  DATAID(&hFile) OPTION(&sOptions)'
        end
      end
      else do /* Open a sequential dataset */
        'LMOPEN  DATAID(&hFile) OPTION(&sOptions)'
        if rc <> 0 /* If dataset does not already exist... */
        then do /* Create sequential dataset then open it */
          'LMCLOSE DATAID(&hFile)'
          'LMFREE  DATAID(&hFile)'
          address TSO 'ALLOCATE DATASET('sFile') NEW CATALOG',
                      'SPACE(5,15) TRACKS RECFM(V,B)',
                      'LRECL('g.!OPTION.WRAP.1 + 4')',
                      'BLKSIZE(27990)' sAttrs
          if bOutput
          then do
            'LMINIT  DATAID(hFile) DATASET(&sFile) ENQ(EXCLU)'
            'LMOPEN  DATAID(&hFile) OPTION(&sOptions)'
          end
          else do
            'LMINIT  DATAID(hFile) DATASET(&sFile)'
            'LMOPEN  DATAID(&hFile) OPTION(INPUT)'
          end
        end
      end
      g.!OPTIONS.hFile = sOptions
      g.!rc = rc /* Return code from LMOPEN */
    end
    otherwise do
      if wordpos('OUTPUT',sOptions) > 0
      then junk = stream(sFile,'COMMAND','OPEN WRITE REPLACE')
      else junk = stream(sFile,'COMMAND','OPEN READ')
      hFile = sFile
      if stream(sFile,'STATUS') = 'READY'
      then g.!rc = 0
      else g.!rc = 4
    end
  end
return hFile

/*-------------------------------------------------------------------*
 * Read a line from the specified file
 *-------------------------------------------------------------------*/

getLine: procedure expose g.
  parse arg hFile
  sLine = ''
  select
    when g.!ENV = 'TSO' then do
      'LMGET DATAID(&hFile) MODE(INVAR)',
            'DATALOC(sLine) DATALEN(nLine) MAXLEN(32768)'
      g.!rc = rc
      sLine = strip(sLine,'TRAILING')
      if sLine = '' then sLine = ' '
    end
    otherwise do
      g.!rc = 0
      if chars(hFile) > 0
      then sLine = linein(hFile)
      else g.!rc = 4
    end
  end
return sLine

/*-------------------------------------------------------------------*
 * Append a line to the specified file
 *-------------------------------------------------------------------*/

putLine: procedure expose g.
  parse arg hFile,sLine
  select
    when g.!ENV = 'TSO' then do
      g.!LINES = g.!LINES + 1
      'LMPUT DATAID(&hFile) MODE(INVAR)',
            'DATALOC(sLine) DATALEN('length(sLine)')'
    end
    otherwise do
      junk = lineout(hFile,sLine)
      rc = 0
    end
  end
return rc

/*-------------------------------------------------------------------*
 * Close the specified file
 *-------------------------------------------------------------------*/

closeFile: procedure expose g.
  parse arg hFile
  rc = 0
  select
    when g.!ENV = 'TSO' then do
      if g.!MEMBER.hFile <> '', /* if its a PDS */
      & wordpos('OUTPUT',g.!OPTIONS.hFile) > 0 /* opened for output */
      then do
        parse value date('STANDARD') with yyyy +4 mm +2 dd +2
        parse var g.!STATS.hFile zlvers','zlmod','zlc4date
        zlcnorc  = min(g.!LINES,65535)   /* Number of lines   */
        nVer = right(zlvers,2,'0')right(zlmod,2,'0')  /* vvmm */
        nVer = right(nVer+1,4,'0')       /* vvmm + 1          */
        parse var nVer zlvers +2 zlmod +2
        if zlc4date = '0000/00/00'
        then zlc4date = yyyy'/'mm'/'dd   /* Creation date     */
        zlm4date = yyyy'/'mm'/'dd        /* Modification date */
        zlmtime  = time()                /* Modification time */
        zluser   = userid()              /* Modification user */
        'LMMREP DATAID(&hFile) MEMBER('g.!MEMBER.hFile') STATS(YES)'
      end
      'LMCLOSE DATAID(&hFile)'
      'LMFREE  DATAID(&hFile)'
    end
    otherwise do
      if stream(hFile,'COMMAND','CLOSE') = 'UNKNOWN'
      then rc = 0
      else rc = 4
    end
  end
return rc