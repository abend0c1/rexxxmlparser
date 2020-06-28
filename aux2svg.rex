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
** NAME     - AUX2SVG                                                **
**                                                                   **
** FUNCTION - Creates a graphical representation of a CICS auxiliary **
**            trace printout by using Scalable Vector Graphics (SVG).**
**            The SVG markup represents the trace data in the form   **
**            of a Unified Modelling Language (UML) Sequence Diagram **
**            (or at least something quite like it).                 **
**                                                                   **
**            The 'actors' (for example, programs) are listed side-  **
**            by-side at the top of the diagram. A life line is      **
**            drawn vertically below each actor. Interactions        **
**            between actors (for example, calls and returns) are    **
**            represented as arrows drawn between the life lines.    **
**            The vertical axis is time. Each interaction is labeled **
**            on the left of the diagram with the relative time in   **
**            seconds since the start of the trace and the task id.  **
**            All the interactions for a task are assigned the same  **
**            unique color. Each interaction is annotated with the   **
**            trace sequence number, to enable you to refer back to  **
**            the original trace record for more detail, and a summ- **
**            ary of the call and return values. Exception responses **
**            are shown in red.                                      **
**                                                                   **
**            You choose which actors you are interested in by       **
**            specifying one or more domain names. For example, if   **
**            you want to visualize TCP/IP socket activity, you      **
**            might specify the PG (program) and SO (socket) domains:**
**                                                                   **
**              aux2svg mytrace.txt (PG SO                           **
**                                                                   **
**            If you want to examine a storage allocation problem    **
**            you might specify the SM (storage manager) domain:     **
**                                                                   **
**              aux2svg mytrace.txt (SM                              **
**                                                                   **
**            By default, ALL domains are selected but this can take **
**            a long time to process. It is best to restrict the     **
**            actors to a few domains that you are interested in.    **
**                                                                   **
**            More documentation is at:                              **
**                                                                   **
**            http://sites.google.com/site/auxiliarytracevisualizer  **
**                                                                   **
**                                                                   **
** USAGE    - You can run this Rexx on an IBM mainframe, or on a PC  **
**            by using either Regina Rexx or ooRexx from:            **
**                                                                   **
**               http://regina-rexx.sourceforge.net                  **
**               http://oorexx.sourceforge.net                       **
**                                                                   **
**            If you run aux2svg on your mainframe, you should use   **
**            ftp to download the resulting svg and html files by:   **
**                                                                   **
**            ftp yourmainframe                                      **
**            youruserid                                             **
**            yourpassword                                           **
**            quote site sbdataconn=(IBM-1047,ISO8859-1)             **
**            get 'your.output.html' your.output.html                **
**            get 'your.output.svg'  your.output.svg                 **
**                                                                   **
**            It is easier to download the CICS trace print file and **
**            run aux2svg.rexx on your PC using Regina Rexx by:      **
**                                                                   **
**            rexx aux2svg.rexx your.trace.txt (options...           **
**                                                                   **
**            You can view the resulting SVG file using either:      **
**                                                                   **
**            1. Mozilla Firefox 1.5, or later, has native SVG rend- **
**               ering capability.                                   **
**                                                                   **
**            2. Microsoft Internet Explorer 6 with the Adobe SVG    **
**               Viewer plugin installed. The plugin is free from    **
**               www.adobe.com. Open the html file created by this   **
**               Rexx if you want to scroll the output in the        **
**               browser. Alternatively, you could publish the html  **
**               file on a web server and point your browser at that **
**               web server. Adobe SVG Viewer supports the following **
**               mouse/key actions:                                  **
**               LeftButton+Ctrl           Zoom in                   **
**               LeftButton+Ctrl+Shift     Zoom out                  **
**               LeftButton+Alt            Move                      **
**               LeftButton+Alt+Shift      Move constrained          **
**               Tool tips are not supported by this viewer yet.     **
**                                                                   **
**            3. Apache Batik Squiggle program with Sun Java 1.3 or  **
**               later installed. Batik is free from www.apache.org  **
**               To run Squiggle: java -jar batik-squiggle.jar       **
**               Squiggle supports the following mouse/key actions:  **
**               LeftButton+Ctrl (+drag)   Zoom in to rectangle      **
**               LeftButton+Shift (+drag)  Move                      **
**               RightButton+Ctrl (+drag)  Rotate                    **
**               RightButton+Shift (+drag) Zoom (in or out)          **
**               Squiggle shows tool tips when you hover the mouse   **
**               over items that have a tool tip defined.            **
**                                                                   **
**            4. Microsoft Visio 2003 or later.                      **
**                                                                   **
** SYNTAX   - AUX2SVG infile [(options...]                           **
**                                                                   **
**            Where,                                                 **
**            infile   = Name of file to read auxtrace printout from.**
**            options  = DETAIL - Include hex data for each record.  **
**                       XML    - Create xml file from input file.   **
**                       HTML   - Create HTML file wrapper for SVG.  **
**                                This allows you to scroll the SVG  **
**                                in Internet Explorer.              **
**                       EVENT  - Process input EVENT trace records. **
**                       DATA   - Process input DATA trace records.  **
**                       To negate any of the above options, prefix  **
**                       the option with NO. For example, NOHTML.    **
**                       xx     - One or more 2-letter domain names  **
**                                that you want to process. The      **
**                                default is all trace domains and   **
**                                can be much slower. For example,   **
**                                to show socket activity you would  **
**                                specify PG and SO.                 **
**                                                                   **
** LOGIC    - 1. Create an in-memory <svg> document.                 **
**                                                                   **
**            2. Create an in-memory <auxtrace> element, but do not  **
**               connect it to the <svg> document.                   **
**                                                                   **
**            3. Scan the auxiliary trace output and convert each    **
**               pair of ENTRY/EXIT trace entries into a single XML  **
**               <trace> element. Add each <trace> element to the    **
**               <auxtrace> element and nest the <trace> elements.   **
**               The <auxtrace> element is a temporary representation**
**               of the auxiliary trace data and will be discarded   **
**               and/or written to an output file later.             **
**                                                                   **
**            4. Walk through the tree of <trace> elements and when  **
**               an interesting <trace> element is found, add        **
**               appropriate SVG markup to the <svg> element in order**
**               to visualize the <trace> element.                   **
**                                                                   **
**            5. Output an SVG document by using the PrettyPrinter   **
**               routine to 'print' the <svg> element to a file.     **
**                                                                   **
**            6. Output an XML document by using the PrettyPrinter   **
**               routine to 'print' the <auxtrace> element (only if  **
**               the XML option was specified).                      **
**                                                                   **
** EXAMPLE  - 1. To investigate a socket programming problem:        **
**                                                                   **
**               AUX2SVG auxtrace.txt (PG SO DETAIL XML              **
**                                                                   **
**               This will create the following files:               **
**                 auxtrace.svg  - SVG representation of trace.      **
**                 auxtrace.html - HTML to scroll the SVG.           **
**                 auxtrace.xml  - XML representation of trace.      **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --- ----------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20060120 AJA Conform to CSS2 requirements of           **
**                         Mozilla Firefox 1.5 (font-size must       **
**                         have a unit, stroke-dasharray must        **
**                         use a comma as a delimiter).              **
**            20051027 AJA Draw colored arrow heads.                 **
**            20051026 AJA Set xml name space to 'svg' (oops!).      **
**            20051025 AJA Minor changes. Fixed bug in parsexml.     **
**            20051018 AJA Documentation corrections. Enhanced       **
**                         getDescriptionOfCall() for CC, GC,        **
**                         DS and AP domains.                        **
**            20051014 AJA Intial version.                           **
**                                                                   **
**********************************************************************/

  parse arg sFileIn' ('sOptions')'

  numeric digits 16
  parse value sourceline(1) with . sVersion
  say 'AUX000I CICS Auxiliary Trace Visualizer' sVersion
  if sFileIn = ''
  then do
    say 'Syntax:'
    say '   aux2svg infile [(options]'
    say
    say 'Where:'
    say '   infile  = CICS auxiliary trace print file'
    say '   options = DETAIL - Include hex data for each record.'
    say '             XML    - Create xml file from input file.'
    say '             HTML   - Create HTML file wrapper for SVG.'
    say '                      This allows you to scroll the SVG'
    say '                      in Internet Explorer.'
    say '             EVENT  - Include EVENT trace records.'
    say '             DATA   - Include DATA trace records.'
    say '             To negate of the above options, prefix the'
    say '             option with NO. For example, NOHTML.'
    say '             xx     - One or more 2-letter domain names'
    say '                      that you want to process. The'
    say '                      default is all trace domains and'
    say '                      can be much slower. For example,'
    say '                      to show socket activity you would'
    say '                      specify PG and SO.'
    exit
  end
  say 'AUX001I Scanning CICS auxiliary trace in' sFileIn

  sOptions = 'NOBLANKS' translate(sOptions)
  call initParser sOptions /* DO THIS FIRST! Sets g. vars to '' */

  parse source g.!ENV .
  if g.!ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.!LINES = 0
  end

  call setFileNames sFileIn
  call setOptions sOptions
  call Prolog

  doc = createDocument('svg')

  call scanAuxTraceFile

  if g.!OPTION.DUMP
  then call _displayTree

  if g.!OPTION.XML
  then do
    call setDocType /* we don't need a doctype declaration */
    call prettyPrinter g.!FILEXML,,g.!AUXTRACE
  end

  call buildSVG

  call setPreserveWhitespace 1 /* to keep newlines in <desc> tags */
  call prettyPrinter g.!FILESVG

  if g.!OPTION.HTML
  then call createHTML

  call Epilog
exit

/* The auxtrace input filename is supplied by the user.
The names of the SVG, XML and HTML output files are automatically
generated from the input file filename. The generated file names also
depend on the operating system. Global variables are set as follows:
g.!FILETXT = name of input text file  (e.g. auxtrace.txt)
g.!FILESVG = name of output SVG file  (e.g. auxtrace.svg)
g.!FILEXML = name of output XML file  (e.g. auxtrace.xml)
g.!FILEHTM = name of output HTML file (e.g. auxtrace.html)
*/
setFileNames: procedure expose g.
  parse arg sFileIn
  if g.!ENV = 'TSO'
  then do
    parse var sFileIn sDataset'('sMember')'
    if sMember <> ''
    then do /* make output files members in the same PDS */
      sPrefix = strip(left(sMember,7)) /* room for a suffix char */
      sPrefix = translate(sPrefix) /* translate to upper case */
      g.!FILETXT = translate(sFileIn)
      /* squeeze the file extension into the member name...*/
      g.!FILESVG = sDataset'('strip(left(sPrefix'SVG',8))')'
      g.!FILEXML = sDataset'('strip(left(sPrefix'XML',8))')'
      g.!FILEHTM = sDataset'('strip(left(sPrefix'HTM',8))')'
    end
    else do /* make output files separate datasets */
      g.!FILETXT = translate(sFileIn)
      g.!FILESVG = sDataset'.SVG'
      g.!FILEXML = sDataset'.XML'
      g.!FILEHTM = sDataset'.HTML'
    end
  end
  else do
    sFileName  = getFilenameWithoutExtension(sFileIn)
    g.!FILETXT = sFileIn
    g.!FILESVG = sFileName'.svg'
    g.!FILEXML = sFileName'.xml'
    g.!FILEHTM = sFileName'.html'
  end
return

getFilenameWithoutExtension: procedure expose g.
  parse arg sFile
  parse value reverse(sFile) with '.'sRest
return reverse(sRest)

scanAuxTraceFile: procedure expose g.
  g.!AUXTRACE = createElement('auxtrace')
  g.!FILEIN = openFile(g.!FILETXT)
  g.!K = 0   /* Trace entry count */
  g.!KD = 0  /* Trace entry delta since last progress message */

  sLine = getLineContaining('CICS - AUXILIARY TRACE FROM')
  parse var sLine 'CICS - AUXILIARY TRACE FROM ',
                   sDate ' - APPLID' sAppl .
  call setAttributes g.!AUXTRACE,,
       'date',sDate,,
       'appl',sAppl

  g.!ROWS = 0
  bAllDomains = words(g.!DOMAIN_FILTER) = 0
  sEntry = getFirstTraceEntry()
  parse var g.!ENTRYDATA.1 '='g.!FIRSTSEQ'=' .
  do while g.!RC = 0
    parse var sEntry sDomain xType sModule sAction sParms
    if g.!FREQ.sDomain = ''
    then do
      g.!FREQ.sDomain = 0
      if g.!DOMAIN.sDomain = ''
      then say 'AUX002W Unknown domain "'sDomain'" found in' sEntry
    end
    g.!FREQ.sDomain = g.!FREQ.sDomain + 1
    if bAllDomains | wordpos(sDomain,g.!DOMAIN_FILTER) > 0
    then do
      parse var g.!ENTRYDATA.1 'TASK-'nTaskId . 'TIME-'sTime .,
                               'INTERVAL-'nInterval . '='nSeq'=' .
      if g.!TASK.nTaskId = '' /* if task is new */
      then do
        call initStack nTaskId
        e = createElement('task')
        call pushStack nTaskId,e
        g.!TASK.nTaskId = e
        call appendChild e,g.!AUXTRACE
        call setAttribute e,'taskid',nTaskId
      end
      task = g.!TASK.nTaskId

      nElapsed = getElapsed(sTime)
      select
        when sAction = 'ENTRY' then do
          g.!ROWS = g.!ROWS + 1 /* row to draw arrow on */
          sParms = strip(sParms)
          select
            when left(sParms,1) = '-' then do /* if new style parms */
              /* ENTRY - FUNCTION(xxx) yyy(xxx) ... */
              sParms = space(strip(sParms,'LEADING','-'))
              if pos('FUNCTION(',sParms) > 0
              then do
                parse var sParms 'FUNCTION('sFunction')'
                n = wordpos('FUNCTION('sFunction')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
              end
              else do
                if left(sParms,1) = '*'
                /* e.g. '** Decode of parameter list failed **' */
                then sFunction = sParms
                else parse var sParms sFunction sParms
              end
            end
            when pos('REQ(',sParms) > 0 then do /* old style parms */
              /* ENTRY function                 REQ(xxx) ... */
              parse var sParms sFixed'REQ('sParms
              sParms = 'REQ('sParms
              parse var sFixed sFunction sRest
              sParms = 'PARMS('sRest')'
            end
            otherwise do /* old style parms */
              /* ENTRY function parms                        */
              /* ENTRY FUNCTION(function) parms              */
              if pos('FUNCTION(',sParms) > 0
              then do
                parse var sParms 'FUNCTION('sFunction')'
                n = wordpos('FUNCTION('sFunction')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
              end
              else do
                parse var sParms sFunction sParms
              end
            end
          end
          parent = peekStack(nTaskId)
          e = createElement('trace')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.!ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'taskid',nTaskId
          call setParmAttributes e,sParms
          if g.!OPTION.DETAIL & g.!ENTRYDATA.0 > 1
          then call appendDetail e,'on-entry'
          call pushStack nTaskId,e
        end
        when sAction = 'EXIT' then do
          g.!ROWS = g.!ROWS + 1 /* row to draw arrow on */
          sParms = strip(sParms)
          sReason = ''
          sAbend = ''
          select
            when left(sParms,1) = '-' then do
              /* EXIT - FUNCTION(xxx) yyy(xxx) ... */
              sParms = space(strip(sParms,'LEADING','-'))
              if pos('FUNCTION(',sParms) > 0
              then do
                parse var sParms 'FUNCTION('sFunction')',
                               1 'RESPONSE('sResponse')',
                               1 'REASON('sReason')',
                               1 'ABEND_CODE('sAbend')'
                n = wordpos('FUNCTION('sFunction')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
                n = wordpos('RESPONSE('sResponse')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
              end
              else do
                if left(sParms,1) = '*'
                /* e.g. '** Decode of parameter list failed **' */
                then do
                  sFunction = ''
                  sResponse = ''
                end
                else parse var sParms sFunction sResponse sParms
                sReason   = ''
                sAbend    = ''
              end
            end
            when pos('REQ(',sParms) > 0 then do
              /* EXIT function response         REQ(xxx) ... */
              /* EXIT response                  REQ(xxx) ... */
              parse var sParms sFixed'REQ('sParms
              sParms = 'REQ('sParms
              if words(sFixed) = 1
              then do
                sFunction = ''
                sResponse = strip(sFixed)
              end
              else do
                parse var sFixed sFunction sResponse .
              end
            end
            when pos('FUNCTION(',sParms) > 0 then do
              /* EXIT FUNCTION(xxx) RESPONSE(xxx) parms ...  */
                parse var sParms 'FUNCTION('sFunction')',
                               1 'RESPONSE('sResponse')'
                n = wordpos('FUNCTION('sFunction')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
                n = wordpos('RESPONSE('sResponse')',sParms)
                if n > 0 then sParms = delword(sParms,n,1)
            end
            otherwise do
              parse var sParms sFunction sParms
            end
          end /* select */
          parent = popStack(nTaskId)
          if parent <> g.!AUXTRACE
          then do
            call setAttributes parent,,
                 'exitrow',g.!ROWS,,
                 'response',sResponse,,
                 'exitseq',nSeq
            sCompoundReason = strip(sReason sAbend)
            if sCompoundReason <> ''
            then call setAttribute parent,'reason',sCompoundReason
            call setParmAttributes parent,sParms
          end
          if g.!OPTION.DETAIL & g.!ENTRYDATA.0 > 1
          then call appendDetail parent,'on-exit'
        end
        when sAction = 'EVENT' then do
          if g.!OPTION.EVENT
          then do
            g.!ROWS = g.!ROWS + 1 /* row to draw arrow on */
            sParms = space(strip(strip(sParms),'LEADING','-'))
            parse var sParms sFunction sParms
            parent = peekStack(nTaskId)
            e = createElement('event')
            call appendChild e,parent
            call setAttributes e,,
                 'seq',nSeq,,
                 'row',g.!ROWS,,
                 'elapsed',nElapsed,,
                 'interval',getInterval(sTime),,
                 'domain',sDomain,,
                 'module','DFH'sModule,,
                 'function',sFunction,,
                 'parms',sParms,,
                 'taskid',nTaskId
            if g.!OPTION.DETAIL & g.!ENTRYDATA.0 > 1
            then call appendDetail e,'detail'
          end
        end
        when sAction = 'CALL' then do
          sParms = space(strip(strip(sParms),'LEADING','-'))
          parse var sParms sFunction sParms
          parent = peekStack(nTaskId)
          e = createElement('call')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.!ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'taskid',nTaskId
          call setParmAttributes e,sParms
        end
        when sAction = '*EXC*' then do
          g.!ROWS = g.!ROWS + 1 /* row to draw arrow on */
          sParms = space(strip(sParms,'LEADING','-'))
          parse var sParms sFunction sParms
          parent = peekStack(nTaskId)
          e = createElement('exception')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.!ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'parms',sParms,,
               'taskid',nTaskId
        end
        when sAction = 'DATA' then do
          if g.!OPTION.DATA
          then do
            g.!ROWS = g.!ROWS + 1 /* row to draw arrow on */
            sParms = space(strip(strip(sParms),'LEADING','-'))
            parse var sParms sFunction sParms
            parent = peekStack(nTaskId)
            e = createElement('data')
            call appendChild e,parent
            call setAttributes e,,
                 'seq',nSeq,,
                 'row',g.!ROWS,,
                 'elapsed',nElapsed,,
                 'interval',getInterval(sTime),,
                 'domain',sDomain,,
                 'module','DFH'sModule,,
                 'function',sFunction,,
                 'taskid',nTaskId
            if g.!OPTION.DETAIL & g.!ENTRYDATA.0 > 1
            then call appendDetail e,'detail'
          end
        end
        when sAction = 'RESUMED' then do
          g.!ROWS = g.!ROWS + 1 /* row to draw arrow on */
          sParms = space(strip(strip(sParms),'LEADING','-'))
          parse var sParms sFunction sParms
          parent = peekStack(nTaskId)
          e = createElement('resumed')
          call appendChild e,parent
          call setAttributes e,,
               'seq',nSeq,,
               'row',g.!ROWS,,
               'elapsed',nElapsed,,
               'interval',getInterval(sTime),,
               'domain',sDomain,,
               'module','DFH'sModule,,
               'function',sFunction,,
               'taskid',nTaskId
          call setParmAttributes e,sParms
        end
        when sAction = 'PC' then do
          /* this trace type does not seem to add any value */
        end
        otherwise do
          parent = peekStack(nTaskId)
          call appendChild createTextNode(sEntry),parent
          say 'AUX003E Unknown trace entry <'sAction'>:' sEntry
        end
      end
    end
    sEntry = getTraceEntry()
  end
  rc = closeFile(g.!FILEIN)
  say 'AUX004I Processed' g.!K-1 'trace entries'
  say 'AUX005I Domain processing summary:'
  do i = 1 to g.!DOMAIN.0
    sDomain = g.!DOMAIN.i
    sDesc   = g.!DOMAIN.sDomain
    if bAllDomains | wordpos(sDomain,g.!DOMAIN_FILTER) > 0
    then sFilter = 'Requested'
    else sFilter = '         '
    if g.!FREQ.sDomain > 0
    then sFound  = 'Found' right(g.!FREQ.sDomain,5)
    else sFound  = '           '
    say 'AUX006I   'sFilter sFound sDomain sDesc
  end
return

initStack: procedure expose g.
  parse arg task
  g.!T.task = 0         /* set top of stack index for task */
return

pushStack: procedure expose g.
  parse arg task,item
  tos = g.!T.task + 1   /* get new top of stack index for task */
  g.!E.task.tos = item  /* set new top of stack item */
  g.!T.task = tos       /* set new top of stack index */
return

popStack: procedure expose g.
  parse arg task
  tos = g.!T.task       /* get top of stack index for task */
  item = g.!E.task.tos  /* get item at top of stack */
  g.!T.task = max(tos-1,1)
return item

peekStack: procedure expose g.
  parse arg task
  tos = g.!T.task       /* get top of stack index for task */
  item = g.!E.task.tos  /* get item at top of stack */
return item

getLineContaining: procedure expose g.
  parse arg sSearchArg
  sLine = getLine(g.!FILEIN)
  do while g.!RC = 0 & pos(sSearchArg, sLine) = 0
    sLine = getLine(g.!FILEIN)
  end
return sLine

getNextLine: procedure expose g.
  sLine = getLine(g.!FILEIN)
  if g.!RC = 0
  then do
    cc = left(sLine,1)
    select
      when cc = '0' then sLine = '' /* ASA double space */
      when cc = '1' then do         /* ASA page eject */
        sLine = getLine(g.!FILEIN)  /* skip blank line after title */
        if sLine <> ''
        then say 'AUX007W Line after heading is not blank:' sLine
        sLine = getLine(g.!FILEIN)  /* read next data line */
      end
      when sLine = '<<<<  STARTING DATA FROM NEXT EXTENT  >>>>' then,
        sLine = ''
      otherwise nop
    end
  end
return sLine

getFirstTraceEntry: procedure expose g.
  sLine = getNextLine()
  parse var sLine sDomain xType sModule .
  do while g.!RC = 0 & length(sDomain) <> 2
    sLine = getNextLine()
    parse var sLine sDomain xType sModule .
  end
return getTraceEntry(sLine)

getTraceEntry: procedure expose g.
  parse arg sEntry
  /* The general format of a trace entry is something like:

Old style:
 dd tttt mmmm action ...fixed_width_stuff... parms...
                     moreparms...

               TASK-nnnnn ....timing info etc...........  =seqno=
                 1-0000  ...hex dump.... *...character dump...*
                 2-0000  ...hex dump.... *...character dump...*
                   0020  ...hex dump.... *...character dump...*
                         .
                         .
                 n-0000  ...hex dump.... *...character dump...*
                         .
                         .

New style:
 dd tttt mmmm action - parms...
                     moreparms...

               TASK-nnnnn ....timing info etc...........  =seqno=
                 1-0000  ...hex dump.... *...character dump...*
                 2-0000  ...hex dump.... *...character dump...*
                   0020  ...hex dump.... *...character dump...*
                         .
                         .
                 n-0000  ...hex dump.... *...character dump...*
                         .
                         .

  */
  sLine = getNextLine()
  do while g.!RC = 0 & left(strip(sLine),5) <> 'TASK-'
    sEntry = sEntry strip(sLine)
    sLine = getNextLine()
  end
  g.!ENTRYDATA.0 = 0
  do i = 1 while g.!RC = 0 & sLine <> ''
    g.!ENTRYDATA.i = sLine
    g.!ENTRYDATA.0 = i
    sLine = getNextLine()
  end
  g.!K = g.!K + 1
  g.!KD = g.!KD + 1
  if g.!KD >= 1000
  then do
    say 'AUX008I Processed' g.!K 'trace entries'
    g.!KD = 0
  end
return sEntry

getElapsed: procedure expose g.
  parse arg nHH':'nMM':'nSS
  nThisOffset = ((nHH*60)+nMM)*60+nSS
  if g.!FIRSTOFFSET = ''
  then g.!FIRSTOFFSET = nThisOffset
return nThisOffset - g.!FIRSTOFFSET

getInterval: procedure expose g.
  parse arg sTime
  nThisOffset = getElapsed(sTime) /* seconds from start of trace */
  if g.!PREVOFFSET = ''
  then nInterval = 0
  else nInterval = nThisOffset - g.!PREVOFFSET
  g.!PREVOFFSET = nThisOffset
return nInterval

setParmAttributes: procedure expose g.
  parse arg e,sParms
  if pos('(',sParms) > 0
  then do while sParms <> ''
    parse var sParms sName'('sValue')'sParms
    sName = getValidAttributeName(sName)
    if wordpos(sName,'FIELD-A FIELD-B') > 0
    then parse var sValue sValue .
    call setAttribute e,space(sName,0),strip(sValue)
  end
  else do
    if sParms <> ''
    then call setAttribute e,'parms',sParms
  end
return

buildSVG: procedure expose g.
  say 'AUX009I Building SVG'

  g.!LINEDEPTH = 12

  doc = getDocumentElement()
  call setDocType 'PUBLIC "-//W3C//DTD SVG 1.1//EN"',
                  '"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"'

  call setAttributes doc,,
       'xmlns','http://www.w3.org/2000/svg',,
       'xmlns:xlink','http://www.w3.org/1999/xlink'

  title = createElement('title')
  call appendChild title,doc
  sAppl = getAttribute(g.!AUXTRACE,'appl')
  sDate = getAttribute(g.!AUXTRACE,'date')
  sTitle = 'CICS auxiliary trace of' sAppl 'captured on' sDate
  call appendChild createTextNode(sTitle),title

  call addTooltip doc,,
       'Created by CICS Auxiliary Trace Visualizer' sVersion 'see',
       'http://sourceforge.net/projects/rexxxmlparser/'

  g.!STYLE = createElement('style')
  call appendChild g.!STYLE,doc

  call setAttribute g.!STYLE,'type','text/css'

  queue
  queue '.background  {fill:white;}'
  queue '.actors      {text-anchor:middle;' ||,
                      'fill:lemonchiffon;stroke:slateblue;}'
  queue '.lifeline    {stroke:yellowgreen;stroke-dasharray:5,2;' ||,
                      'fill:none;}'
  queue '.seq         {fill:gray;}'
  queue '.arrows      {stroke-width:2;fill:none;}'
  queue '.return      {stroke-dasharray:2,3;}'
  queue '.annotation  {stroke:none;font-size:6px;}'
  queue '.ltr         {text-anchor:start;}'
  queue '.rtl         {text-anchor:end;}'
  queue '.error       {fill:red;}'
  queue 'text.dump    {font-family:monospace;font-size:10px;}'
  queue 'text         {font-family:Arial;font-size:10px;fill:black;' ||,
                      'stroke:none;}'
  queue
  styles = createCDATASection(pullLines())
  call appendChild styles,g.!STYLE

  defs = createElement('defs')
  call appendChild defs,doc
  path = createElement('path')
  call appendChild path,defs
  call setAttributes path,,
       'id','arrow',,
       'd','M 0 0 L 10 5 L 0 10 z'
  circle = createElement('circle')
  call appendChild circle,defs
  call setAttributes circle,,
       'id','circle',,
       'cx',5,'cy',5,'r',5

  background = createElement('rect')
  call appendChild background,doc

  g.!ACTOR_NODES = ''
  call getActors g.!AUXTRACE
  lifelinebg = createElement('g')
  call setAttribute lifelinebg,'class','background'
  lifelines = createElement('g')
  call setAttribute lifelines,'class','lifeline'
  g = createElement('g')
  call setAttribute g,'class','actors'
  call appendChild createComment(' Life lines'),doc
  call appendChild lifelinebg,doc
  call appendChild lifelines,doc
  call appendChild createComment(' Actor rectangles'),doc
  call appendChild g,doc
  w = 60 /* width of an actor rectangle */
  h = 22 /* height of an actor rectangle */
  x = w  /* horizontal position of actor rectangle */
  do i = 1 to words(g.!ACTOR_NODES) /* for each actor... */
    node = word(g.!ACTOR_NODES,i)
    sActor = getActorName(node)
    sDomain = getAttribute(node,'domain')
    xMid = x + w/2
    /* Draw the life line background (for tooltips)... */
    rect = createElement('rect')
    call appendChild rect,lifelinebg
    call setAttributes rect,,
         'x',xMid-5,,
         'y',h,,
         'width',10,,
         'height',0 /* placeholder...see below */
    /* Add a tooltip for this life line background rect... */
    call addTooltip rect,sActor
    /* Draw the life line... */
    line = createElement('line')
    call appendChild line,lifelines
    call setAttributes line,,
         'x1',xMid,,
         'y1',h,,
         'x2',xMid,,
         'y2',0 /* placeholder...see below */
    /* Add an identical tooltip for this life line... */
    call addTooltip line,sActor
    g.!X.sActor = xMid /* remember where this actor is by name */
    /* Draw the rectangle to contain the actor name... */
    rect = createElement('rect')
    call appendChild rect,g
    call setAttributes rect,,
         'x',x,,
         'y',0,,
         'width',w,,
         'height',h,,
         'rx',1,,
         'ry',1
    /* Draw the domain name and actor name within the rectangle... */
    text = createElement('text')
    call appendChild text,g
    call setAttributes text,'y',9
    domain = createElement('tspan')
    actor = createElement('tspan')
    call appendChild domain,text
    call appendChild actor,text
    call setAttributes domain,'x',xMid
    call setAttributes actor,'x',xMid,'dy',10
    select
      when isProgram(node),
        then call appendChild createTextNode('program'),domain
      when isSocket(node),
        then call appendChild createTextNode('socket'),domain
      otherwise,
        call appendChild createTextNode(sDomain),domain
    end
    call appendChild createTextNode(sActor),actor
    x = x + w + 5
  end

  nImageWidth = x + w /* room on the right for a longish message */

  call appendChild createComment(' Actor relationships'),doc
  g = createElement('g')
  call appendChild g,doc
  call setAttribute g,'class','arrows'

  g.!FIRSTARROW = 2 * g.!LINEDEPTH /* vertical offset of first arrow */
  tasks = getChildren(g.!AUXTRACE)
  do i = 1 to words(tasks)
    task = word(tasks,i)
    nTaskId = getAttribute(task,'taskid')
    h = getHue(i)
    s = getSaturation(i)
    v = getValue(i)
    sColor = hsv2rgb(h,s,v)
    style = createTextNode('.task'nTaskId '{stroke:'sColor';}')
    call appendChild style,g.!STYLE
    style = createTextNode('.fill'nTaskId '{fill:'sColor';}')
    call appendChild style,g.!STYLE
    call createMarkers defs,nTaskId
    call drawArrows g,task
  end

  nImageHeight = (2 + g.!ROWS + 1 ) * g.!LINEDEPTH
  call setAttributes doc,,
       'height',nImageHeight,,
       'width',nImageWidth,,
       'viewBox','-10 -10' nImageWidth+10 nImageHeight+10
  call setAttributes background,,
       'class','background',,
       'x',0,,
       'y',0,,
       'height',nImageHeight,,
       'width',nImageWidth
   g.!WIDTH = nImageWidth
   g.!HEIGHT = nImageHeight

  /* Now we know the image height we can update the lifeline depth */
  nodes = getChildren(lifelinebg)
  do i = 1 to words(nodes)
    node = word(nodes,i)
    call setAttribute node,'height',nImageHeight
  end
  nodes = getChildren(lifelines)
  do i = 1 to words(nodes)
    node = word(nodes,i)
    call setAttribute node,'y2',nImageHeight
  end

  /* Finally, remove unreferenced marker definitions...*/
  nodes = getChildren(defs)
  do i = 1 to words(nodes)
    node = word(nodes,i)
    if getNodeName(node) = 'marker'
    then do
      sId = getAttribute(node,'id')
      if g.!MARKER.sId = ''
      then call removeChild node
    end
  end

return

createMarkers: procedure expose g.
  parse arg defs,nTaskId
/*
    <marker id="ArrowXXXXX" viewBox="0 0 10 10" refX="7" refY="5"
            orient="auto">
      <use xlink:href="#arrow"/>
    </marker>
*/
  marker = createElement('marker')
  call appendChild marker,defs
  call setAttributes marker,,
       'id','Arrow'nTaskId,,
       'class','fill'nTaskId,,
       'viewBox','0 0 10 10',,
       'refX',7,,
       'refY',5,,
       'orient','auto'
  use = createElement('use')
  call appendChild use,marker
  call setAttribute use,'xlink:href','#arrow'
/*
    <marker id="CircleXXXXX" viewBox="0 0 10 10" refX="8" refY="5">
      <use xlink:href="#circle"/>
    </marker>
*/
  marker = createElement('marker')
  call appendChild marker,defs
  call setAttributes marker,,
       'id','Circle'nTaskId,,
       'class','fill'nTaskId,,
       'viewBox','0 0 10 10',,
       'refX',8,,
       'refY',5
  use = createElement('use')
  call appendChild use,marker
  call setAttribute use,'xlink:href','#circle'
return

addTooltip: procedure expose g.
  parse arg node,sTip
  tooltip = createElement('desc')
  call appendChild tooltip,node
  call appendChild createTextNode(sTip),tooltip
return

getHue: procedure expose g.
  arg n
return (g.!HUE_INIT + (n-1) * g.!HUE_STEP) // 360

getSaturation: procedure expose g.
  arg n
  n = g.!SAT_LEVELS - 1 - (n-1) // g.!SAT_LEVELS
return g.!SAT_MIN + n * g.!SAT_STEP

getValue: procedure expose g.
  arg n
  n = g.!VAL_LEVELS - 1 - (n-1) // g.!VAL_LEVELS
return g.!VAL_MIN + n * g.!VAL_STEP

hsv2rgb: procedure
  parse arg h,s,v
  /*
  Hue (h) is from 0 to 360, where 0 = red and 360 also = red
  Saturation (s) is from 0.0 to 1.0 (0 = least color, 1 = most color)
  Value (v) is from 0.0 to 1.0 (0 = darkest, 1 = brightest)
  */
  v = 100 * v /* convert to a percentage */
  if s = 0 /* if grayscale */
  then do
    v = format(v,,2)'%'
    rgb = 'rgb('v','v','v')'
  end
  else do
    sextant = trunc(h/60) /* 0 to 5 */
    fraction = h/60 - sextant
    p = v * (1 - s)
    q = v * (1 - s * fraction)
    r = v * (1 - s * (1 - fraction))
    v = format(v,,2)'%'
    p = format(p,,2)'%'
    q = format(q,,2)'%'
    r = format(r,,2)'%'
    select
      when sextant = 0 then rgb = 'rgb('v','r','p')'
      when sextant = 1 then rgb = 'rgb('q','v','p')'
      when sextant = 2 then rgb = 'rgb('p','v','r')'
      when sextant = 3 then rgb = 'rgb('p','q','v')'
      when sextant = 4 then rgb = 'rgb('r','q','v')'
      when sextant = 5 then rgb = 'rgb('v','p','q')'
      otherwise rgb = 'rgb(0,0,0)' /* should not happen :) */
    end
  end
return rgb


pullLines: procedure expose g.
  sLines = ''
  do queued()
    parse pull sLine
    sLines = sLines || sLine || g.!LF
  end
return sLines

getActors: procedure expose g.
  parse arg node
  sActor = getActorName(node)
  if sActor <> '' & g.!ACTOR.sActor = ''
  then do /* if this node is a new actor */
      g.!ACTOR_NODES = g.!ACTOR_NODES node
      g.!ACTOR.sActor = 1 /* we've seen it now */
  end
  children = getChildren(node)
  do i = 1 to words(children)
    child = word(children,i)
    call getActors child
  end
return

getActorName: procedure expose g.
  parse arg node
  select
    when node = g.!AUXTRACE then do
      sActor = '<<cics>>'
    end
    when getNodeName(node) = 'task' then do
      sActor = '<<cics>>'
    end
    when isProgram(node) then do
      sActor = getAttribute(node,'PROGRAM_NAME')
      if sActor = '' then sActor = getAttribute(node,'PROGRAM')
      if sActor = '' then sActor = '<<program>>'
    end
    when isSocket(node) then do
      sActor = getAttribute(node,'SOCKET_TOKEN')
      if sActor = '' then sActor = '<<socket>>'
    end
    otherwise sActor = getAttribute(node,'module')
  end
return sActor

isProgram: procedure expose g.
  parse arg node
  sDomain = getAttribute(node,'domain')
  sFunction = getAttribute(node,'function')
  bIsProgram = sDomain = 'PG' &,
     wordpos(sFunction,'LINK LINK_EXEC INITIAL_LINK',
                       'LOAD LOAD_EXEC LINK_URM') > 0
  bIsProgram = bIsProgram | (sDomain = 'AP' &,
     wordpos(sFunction,'START_PROGRAM') > 0)
return bIsProgram

isSocket: procedure expose g.
  parse arg node
  sModule = getAttribute(node,'module')
  sFunction = getAttribute(node,'function')
  bIsSocket = sModule = 'DFHSOCK' &,
     wordpos(sFunction,'SEND RECEIVE CONNECT CLOSE') > 0
return bIsSocket

drawArrows: procedure expose g.
  parse arg g,source
  if isActor(source)
  then do
    children = getChildren(source)
    do i = 1 to words(children)
      target = word(children,i)
      if isActor(target)
      then do /* we can draw an arrow between actors */
        sClass = 'task'getAttribute(target,'taskid')
        group = createElement('g')
        call appendChild group,g
        call setAttribute group,'class',sClass
        call drawArrow group,source,target,'call'
        call drawArrows group,target
        call drawArrow group,target,source,'return'
      end
      else do
        call drawArrows g,target
      end
    end
  end
  else do
    children = getChildren(caller)
    do i = 1 to words(children)
      child = word(children,i)
      call drawArrows g,child
    end
  end
return

isActor: procedure expose g.
  parse arg node
  bIsActor = getActorName(node) <> '' | getNodeName(node) = 'task'
return bIsActor

drawArrow: procedure expose g.
  parse arg g,source,target,sClass
  /* the source actor invokes a function on the target actor */
  bIsCall = sClass = 'call' /* ...else it is a return arrow */
  if bIsCall
  then nRow = getAttribute(target,'row')
  else nRow = getAttribute(source,'exitrow')
  if nRow = '' then return /* <event> has no 'return' arrow */
  y = g.!FIRSTARROW + g.!LINEDEPTH * nRow
  sSourceActor = getActorName(source)
  sTargetActor = getActorName(target)
  sFunction = getAttribute(target,'function')

  /* Group the arrow, text and optional tooltip together */
  arrow = createElement('g')
  call appendChild arrow,g

  /* Draw the elapsed time and task id of this <trace> entry...*/
  sTaskId = getAttribute(target,'taskid')
  if bIsCall
  then do
    call appendChild createComment(' 'sTargetActor),arrow
    elapsed = createElement('text')
    call appendChild elapsed,arrow
    call setAttributes elapsed,'x',0,'y',y
    nElapsed = getAttribute(target,'elapsed')
    sElapsed = '+'left(format(nElapsed,,6),8,'0')' 'sTaskId
    call appendChild createTextNode(sElapsed),elapsed
  end

  /* Draw the arrow for this call or return...*/
  line = createElement('line')
  call appendChild line,arrow
  tooltip = createElement('desc') /* tool tip for this arrow */
  call appendChild tooltip,line
  if \bIsCall
  then call setAttribute line,'class',sClass
  x1 = g.!X.sSourceActor
  x2 = g.!X.sTargetActor
  if x1 < x2 /* if left-to-right arrow */
  then do
    x1b = x1 + 2
    x2 = x2 - 2
    sDir = 'ltr'
  end
  else do
    x1b = x1 - 2
    x2 = x2 + 2
    sDir = 'rtl'
  end
  call setAttributes line,,
       'x1',x1,,
       'y1',y,,
       'x2',x2,,
       'y2',y
  if sSourceActor = sTargetActor
  then do
    sId = 'Circle'sTaskId
    g.!MARKER.sId = 1 /* remember that we have used this marker */
    call setAttribute line,'marker-end','url(#'sId')'
  end
  else do
    sId = 'Arrow'sTaskId
    g.!MARKER.sId = 1 /* remember that we have used this marker */
    call setAttribute line,'marker-end','url(#'sId')'
  end

  /* Annotate the arrow...*/
  annotation = createElement('text')
  call appendChild annotation,arrow
  call setAttributes annotation,,
       'class','annotation' sDir,,
       'x',x1b,,
       'y',y-2
  if bIsCall
  then do /* annotate the invoking arrow */
    sExtra = getDescriptionOfCall(target)
    sModule = getAttribute(target,'module')
    if getNodeName(target) = 'exception'
    then call setAttribute annotation,'class','annotation error' sDir
  end
  else do /* annotate the returning arrow */
    sExtra = ''
    sModule = getAttribute(source,'module')
    sFunction = getAttribute(source,'function')
    sResponse = getAttribute(source,'response')
    if sResponse = '' |,
       sResponse = 'NORMAL' |,
       sResponse = 'RESPONSE(OK)'
    then sResponse = 'OK'
    select
      when sSourceActor = sTargetActor then,
        sExtra = sFunction sResponse
      when sResponse = 'OK' then,
        sExtra = sResponse
      otherwise,
        sExtra = sResponse getAttribute(source,'reason')
    end
    if sResponse <> 'OK'
    then call setAttribute annotation,'class','annotation error' sDir
  end

  /* Every arrow is annotated with the trace sequence number... */
  tspanSeq = createElement('tspan')
  call setAttribute tspanSeq,'class','seq'
  if bIsCall
  then nSeq = getAttribute(target,'seq')
  else nSeq = getAttribute(source,'exitseq')
  call appendChild createTextNode(nSeq),tspanSeq

  /* Some arrows have extra info near the sequence number... */
  if sDir = 'ltr' /* if left-to-right arrow */
  then do /* e.g. 001234 LOAD_EXEC ------------------>  */
    call appendChild tspanSeq,annotation
    if sExtra <> ''
    then do
      tspanExtra = createElement('tspan')
      call appendChild createTextNode(sExtra),tspanExtra
      call appendChild tspanExtra,annotation
    end
  end
  else do /* e.g. <----------- PROGRAM_NOT_FOUND 001235 */
    if sExtra <> ''
    then do
      tspanExtra = createElement('tspan')
      call appendChild createTextNode(sExtra),tspanExtra
      call appendChild tspanExtra,annotation
    end
    call appendChild tspanSeq,annotation
  end

  /* Now create a tool tip for this line */
  sTip = nSeq sExtra
  select
    when sModule = 'DFHSOCK' then do
      if sFunction = 'SEND'
      then sTip = sTip getSocketDetail(target,'on-entry')
      if sFunction = 'RECEIVE'
      then sTip = sTip getSocketDetail(source,'on-exit')
    end
    when getNodeName(target) = 'data' then do
      sTip = sTip getDataDetail(target)
    end
    otherwise nop
  end
  call appendChild createTextNode(sTip),tooltip
return

getSocketDetail: procedure expose g.
  parse arg node,sContainer
  detail = getChildrenByName(node,sContainer)
  args = getChildrenByName(detail,'arg')
  if words(args) < 2 then return ''
  data = word(args,2) /* arg2 contains the packet payload */
  sData = getText(getFirstChild(data)) /* ...a CDATA node */
return sData

getDataDetail: procedure expose g.
  parse arg node
  sData = ''
  detail = getChildrenByName(node,'detail')
  if detail <> ''
  then do
    args = getChildrenByName(detail,'arg')
    do i = 1 to words(args)
      data = word(args,i)
      sData = sData getText(getFirstChild(data))
    end
  end
return sData

getDescriptionOfCall: procedure expose g.
  parse arg node
  sDesc = ''
  sDomain = getAttribute(node,'domain')
  sFunction = getAttribute(node,'function')
  select
    when sDomain = 'PG' then do
      sProgram = getAttribute(node,'PROGRAM_NAME')
      select
        when sProgram <> '' then,
          sDesc = '('sProgram')'
        otherwise nop
      end
    end
    when sDomain = 'AP' then do
      select
        when sFunction = 'START_PROGRAM' then,
          sDesc = '('getAttribute(node,'PROGRAM')')'
        when sFunction = 'WRITE_TRANSIENT_DATA' then,
          sDesc = '('getAttribute(node,'QUEUE')')'
        when sFunction = 'READ_UPDATE_INTO' then,
          sDesc = '('getAttribute(node,'FILE_NAME')')'
        when sFunction = 'LOCATE' then,
          sDesc = getAttribute(node,'TABLE')'(' ||,
                  getAttribute(node,'KEY')')'
        when wordpos(sFunction,'GET_QUEUE',
                               'PUT_QUEUE',
                               'DELETE_QUEUE') > 0 then,
          sDesc = '('getAttribute(node,'RECORD_TYPE')')'
        otherwise nop
      end
    end
    when sDomain = 'BA' then do
      select
        when wordpos(sFunction,'PUT_CONTAINER',
                               'GET_CONTAINER_SET',
                               'GET_CONTAINER_INTO',
                               'DELETE_CONTAINER') > 0 then,
          sDesc = '('getAttribute(node,'CONTAINER_NAME')')'
        when wordpos(sFunction,'ADD_ACTIVITY',
                               'LINK_ACTIVITY',
                               'CHECK_ACTIVITY') > 0 then,
          sDesc = '('getAttribute(node,'ACTIVITY_NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'WB' then do
      select
        when wordpos(sFunction,'PUT_QUEUE',
                               'DELETE_QUEUE',
                               'GET_QUEUE') > 0 then,
          sDesc = '('getAttribute(node,'RECORD_TYPE')')'
        when wordpos(sFunction,'START_BROWSE',
                               'READ_NEXT',
                               'END_BROWSE') > 0 then,
          sDesc = '('getAttribute(node,'DATA_TYPE')')'
        otherwise nop
      end
    end
    when sDomain = 'SM' then do
      select
        when sFunction = 'GETMAIN' then do
            if hasAttribute(node,'STORAGE_CLASS')
            then do
              xLen = getAttribute(node,'GET_LENGTH')
              sDesc = getAttribute(node,'ADDRESS'),
                      getAttribute(node,'STORAGE_CLASS'),
                      "LENGTH=X'"xLen"' ("x2d(xLen)')',
                      getAttribute(node,'REMARK')
            end
            else,
              sDesc = getAttribute(node,'ADDRESS'),
                      'SUBPOOL',
                      getAttribute(node,'REMARK')
        end
        when sFunction = 'FREEMAIN' then do
          select
            when hasAttribute(node,'STORAGE_CLASS') then,
              sDesc = getAttribute(node,'ADDRESS'),
                      getAttribute(node,'STORAGE_CLASS'),
                      getAttribute(node,'REMARK')
            when hasAttribute(node,'SUBPOOL_TOKEN') then,
              sDesc = getAttribute(node,'ADDRESS'),
                      'SUBPOOL',
                      getAttribute(node,'REMARK')
            otherwise,
              sDesc = getAttribute(node,'ADDRESS'),
                      getAttribute(node,'REMARK')
          end
        end
        otherwise nop
      end
    end
    when sDomain = 'DD' then do
      select
        when sFunction = 'LOCATE' then,
          sDesc = getAttribute(node,'DIRECTORY_NAME')'(' ||,
                  getAttribute(node,'NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'TS' then do
      select
        when wordpos(sFunction,'MATCH',
                               'DELETE',
                               'READ_INTO',
                               'READ_SET',
                               'READ_AUX_DATA',
                               'WRITE') > 0 then,
          sDesc = 'QUEUE('getAttribute(node,'QUEUE_NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'XS' then do
      select
        when sFunction = 'CHECK_CICS_RESOURCE' then,
          sDesc = getAttribute(node,'RESOURCE_TYPE')'(' ||,
                  getAttribute(node,'RESOURCE')') ACCESS(' ||,
                  getAttribute(node,'ACCESS')')'
        otherwise nop
      end
    end
    when sDomain = 'XM' then do
      select
        when sFunction = 'ATTACH' then,
          sDesc = 'TRANS('getAttribute(node,'TRANSACTION_ID')')'
        when sFunction = 'INQUIRE_MXT' then,
          sDesc = 'LIMIT('getAttribute(node,'MXT_LIMIT')')',
                  'ACTIVE('getAttribute(node,'CURRENT_ACTIVE')')'
        otherwise nop
      end
    end
    when sDomain = 'EM' then do
      select
        when wordpos(sFunction,'FIRE_EVENT',
                               'DEFINE_ATOMIC_EVENT',
                               'DELETE_EVENT',
                               'RETRIEVE_REATTACH_EVENT') > 0 then,
          sDesc = '('getAttribute(node,'EVENT')')'
        otherwise nop
      end
    end
    when sDomain = 'DU' then do
      select
        when wordpos(sFunction,'TRANSACTION_DUMP',
                               'COMMIT_TRAN_DUMPCODE',
                               'LOCATE_TRAN_DUMPCODE') > 0 then,
          sDesc = '('getAttribute(node,'TRANSACTION_DUMPCODE')')',
                     getAttribute(node,'DUMPID')
        when wordpos(sFunction,'INQUIRE_SYSTEM_DUMPCODE') > 0 then,
          sDesc = '('getAttribute(node,'SYSTEM_DUMPCODE')')'
        otherwise nop
      end
    end
    when sDomain = 'CC' then do
      select
        when wordpos(sFunction,'GET') > 0 then,
          sDesc = getAttribute(node,'TYPE')'(' ||,
                  getAttribute(node,'NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'GC' then do
      select
        when wordpos(sFunction,'WRITE') > 0 then,
          sDesc = getAttribute(node,'TYPE')'(' ||,
                  getAttribute(node,'NAME')')'
        otherwise nop
      end
    end
    when sDomain = 'DS' then do
      select
        when wordpos(sFunction,'SUSPEND',
                               'WAIT_MVS',
                               'WAIT_OLDW') > 0 then,
          sDesc = getAttribute(node,'RESOURCE_TYPE')'(' ||,
                  getAttribute(node,'RESOURCE_NAME')')'
        otherwise nop
      end
    end
    otherwise nop
  end
  if getNodeName(node) = 'trace'
  then sPrefix = sFunction
  else sPrefix = getNodeName(node)':' sFunction
return strip(sPrefix sDesc)

setOptions: procedure expose g.
  parse arg sOptions
  /* set default options... */
  g.!OPTION.EVENT   = 1 /* Process input EVENT trace records? */
  g.!OPTION.DATA    = 1 /* Process input DATA trace records? */
  g.!OPTION.DETAIL  = 0 /* Output trace detail? */
  g.!OPTION.XML     = 0 /* Output XML file? */
  g.!OPTION.HTML    = 1 /* Output HTML file? */
  g.!DOMAIN_FILTER = ''
  do i = 1 to words(sOptions)
    sOption = word(sOptions,i)
      if length(sOption) = 2 then,
        g.!DOMAIN_FILTER = g.!DOMAIN_FILTER sOption
      else do
        if left(sOption,2) = 'NO'
        then do
          sOption = substr(sOption,3)
          g.!OPTION.sOption = 0
        end
        else g.!OPTION.sOption = 1
      end
  end
return

Prolog:
  if g.!ENV = 'TSO'
  then g.!LF = '15'x
  else g.!LF = '0A'x

  /* Constants for generating line colors */
  g.!HUE_INIT   = 151 /* random(0,360) */
  g.!HUE_STEP   = 43  /* random(0,360) */
  g.!SAT_MIN    = 1.0
  g.!SAT_MAX    = 1.0
  g.!SAT_LEVELS = 2
  g.!SAT_STEP   = (g.!SAT_MAX - g.!SAT_MIN) / (g.!SAT_LEVELS - 1)
  g.!VAL_MIN    = 0.5
  g.!VAL_MAX    = 0.8
  g.!VAL_LEVELS = 2
  g.!VAL_STEP   = (g.!VAL_MAX - g.!VAL_MIN) / (g.!VAL_LEVELS - 1)

  g.!DOMAIN.0 = 0 /* Number of domains */
  call addDomain 'AP','Application Domain'
  call addDomain 'BA','Business Application Manager Domain'
  call addDomain 'CC','CICS Catalog Domain'
  call addDomain 'GC','Global Catalog Domain'
  call addDomain 'LC','Local Catalog Domain'
  call addDomain 'DD','Directory Domain'
  call addDomain 'DH','Document Handler Domain'
  call addDomain 'DM','Domain Manager Domain'
  call addDomain 'DP','Debugging Profiles Domain'
  call addDomain 'DS','Dispatcher Domain'
  call addDomain 'DU','Dump Domain'
  call addDomain 'EJ','Enterprise Java Domain'
  call addDomain 'EM','Event Manager Domain'
  call addDomain 'EX','External CICS Interface Domain'
  call addDomain 'EI','External CICS Interface over TCP/IP Domain'
  call addDomain 'FT','Feature Domain'
  call addDomain 'II','IIOP Domain'
  call addDomain 'KE','Kernel Domain'
  call addDomain 'LD','Loader Domain'
  call addDomain 'LG','Log Manager Domain'
  call addDomain 'LM','Lock Manager Domain'
  call addDomain 'ME','Message Domain'
  call addDomain 'MN','Monitoring Domain'
  call addDomain 'NQ','Enqueue Domain'
  call addDomain 'OT','Object Transaction Domain'
  call addDomain 'PA','Parameter Manager Domain'
  call addDomain 'PG','Program Manager Domain'
  call addDomain 'PI','Pipeline Manager Domain'
  call addDomain 'PT','Partner Domain'
  call addDomain 'RM','Recovery Manager Domain'
  call addDomain 'RX','RRMS Domain'
  call addDomain 'RZ','Request Streams Domain'
  call addDomain 'SH','Scheduler Domain'
  call addDomain 'SJ','Java Virtual Machine Domain'
  call addDomain 'SM','Storage Manager Domain'
  call addDomain 'SO','Socket Domain'
  call addDomain 'ST','Statistics Domain'
  call addDomain 'TI','Timer Domain'
  call addDomain 'TR','Trace Domain'
  call addDomain 'TS','Temporary Storage Domain'
  call addDomain 'US','User Domain'
  call addDomain 'WB','Web Domain'
  call addDomain 'XM','Transaction Manager Domain'
  call addDomain 'XS','Security Manager Domain'
return

addDomain: procedure expose g.
  parse arg sDomain,sDesc
  if g.!DOMAIN.sDomain = ''
  then do
    nDomain = g.!DOMAIN.0       /* Number of domains */
    nDomain = nDomain + 1
    g.!DOMAIN.sDomain = sDesc   /* e.g. g.!DOMAIN.AP = 'App Domain'  */
    g.!DOMAIN.nDomain = sDomain /* e.g. g.!DOMAIN.1 = 'AP'           */
    g.!DOMAIN.0 = nDomain
  end
return

/* Embed the svg in an html file to allow the browser to scroll it */
createHTML: procedure expose g.
  html = openFile(g.!FILEHTM,'OUTPUT')
  if g.!rc = 0
  then do
    say 'AUX010I Creating' g.!FILEHTM
    queue '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0',
          'Transitional//EN">'
    queue '<html>'
    queue '  <body>'
    queue '    <object data="'g.!FILESVG'"',
                      'width="'g.!WIDTH'"',
                      'height="'g.!HEIGHT'"',
                      'type="image/svg+xml"></object>'
    queue '  </body>'
    queue '</html>'
    do queued()
      parse pull sLine
      call putLine html,sLine
    end
    rc = closeFile(html)
    say 'AUX011I Created' g.!FILEHTM
  end
  else do
    say 'AUX012E Could not create' g.!FILEHTM'. Return code' g.!rc
  end
return

Epilog: procedure expose g.
return


getValidAttributeName: procedure expose g.
  parse arg sName
  sName = space(sName,0)
  sName = strip(sName,'LEADING','-')
  if datatype(left(sName,1),'WHOLE')
  then sName = 'X'sName /* must start with an alphabetic */
return sName


appendDetail: procedure expose g.
  parse arg e,sName
  x = createElement(sName)
  call appendChild x,e
  sData = ''
  do i = 2 to g.!ENTRYDATA.0
    sLine = strip(g.!ENTRYDATA.i,'LEADING')
    parse var sLine nArg'-0000 '
    if datatype(nArg,'WHOLE')
    then do
      if sData <> ''
      then call appendDetailArg x,sData
      parse var sLine nArg'-'sData
      sData = sData || g.!LF
    end
    else do
      sData = sData || sLine || g.!LF
    end
  end
  if sData <> ''
  then call appendDetailArg x,sData
return

appendDetailArg: procedure expose g.
  parse arg parent,sData
  a = createElement('arg')
  call appendChild a,parent
  call appendChild createCDATASection(g.!LF || sData),a
return

/*INCLUDE pretty.rex */
