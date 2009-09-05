/*REXX 2.0.0 $Rev$
$Id$
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
** NAME     - JCL2XML                                                **
**                                                                   **
** FUNCTION - Creates an XML and GraphML representation of JCL.      **
**                                                                   **
**            This is the first step in creating stunning visual     **
**            documentation of your JCL. GraphML (Graph Markup       **
**            Language) is an XML standard for decribing the nodes   **
**            and edges in a graph - in the mathematical sense.      **
**            In plain English it describes boxes connected by lines **
**            in a diagram.                                          **
**                                                                   **
**            The GraphML output can be viewed by a GraphML editor   **
**            such as yEd from yWorks (www.yworks.com) and exported  **
**            to SVG or PDF format for posting on your intranet.     **
**                                                                   **
**            The XML output can be used for any purpose. For        **
**            example, you may transform it using XSLT, say, into    **
**            documentation. You could also use it to recreate your  **
**            JCL will all COND= steps replaced by IF/THEN/ELSE.     **
**                                                                   **
** USAGE    - You can run this Rexx on an IBM mainframe or on a PC   **
**            with no code changes.                                  **
**                                                                   **
**            If you run JCL2XML on your PC, you should use Regina   **
**            Rexx from:                                             **
**                                                                   **
**               http://regina-rexx.sourceforge.net                  **
**                                                                   **
**            If you run JCL2XML on your mainframe, you should use   **
**            ftp to download the resulting files to your PC by:     **
**                                                                   **
**            ftp yourmainframe                                      **
**            youruserid                                             **
**            yourpassword                                           **
**            quote site sbdataconn=(IBM-1047,ISO8859-1)             **
**            get 'your.xml'  your.xml                               **
**            get 'your.gml'  your.graphml                           **
**                                                                   **
**            Alternatively, you can download your JCL to a PC and   **
**            run JCL2XML on your PC by:                             **
**                                                                   **
**            rexx jcl2xml.rexx your.jcl                             **
**                                                                   **
**            This will read your.jcl and create your.xml and        **
**            your.graphml.                                          **
**                                                                   **
**            With the GraphML output on your PC, you can use a      **
**            GraphML editor such as yEd from www.yworks.com to      **
**            view a flowchart-style representation of the JCL.      **
**            To do this with yEd:                                   **
**                                                                   **
**            1. Start yEd by running yed.exe                        **
**            2. Open the graphml file created by jcl2xml. You will  **
**               see crap piled on crap at this stage because the    **
**               graph has not been layed out yet...                 **
**            3. Choose Layout from the main menu                    **
**            4. Choose Orthogonal from the Layout dropdown          **
**            5. Choose UML Style from the Orthogonal dropdown       **
**            6. Click the Apply button. The result is a reasonable  **
**               attempt to layout the graph. You can tweak the      **
**               layout by clicking and dragging boxes and lines.    **
**               Displaying and snapping to grid lines is helpful    **
**               while doing the tweaking.                           **
**            7. If you intend to do this layout often, then click   **
**               the As Tool button to move this dialog box to the   **
**               left hand side of the window. You will now be able  **
**               to just click the 'play' button to layout the       **
**               graph instead of having to choose Layout from the   **
**               main menu all over again.                           **
**            8. Now you can export the resulting diagram in a       **
**               number of formats including Scalable Vector Graphics**
**               (SVG) which is an excellent format for posting on   **
**               your intranet. Other formats include png, pdf, jpg, **
**               gif, html, bmp and wmf.                             **
**            9. Try out a few other layout strategies if you want,  **
**               but I think UML Style is best for JCL.              **
**                                                                   **
** SYNTAX   - JCL2XML infile outfile [(options...]                   **
**                                                                   **
**            Where,                                                 **
**            infile   = File containing JCL.                        **
**            outfile  = Output xml and graphml path.                **
**            options  = XML    - Output infile.xml                  **
**                       GRAPHML- Output infile.graphml              **
**                       JCL    - Output infile.jcl (reconstructed   **
**                                from the XML).                     **
**                       DUMP   - List the parse tree for debugging. **
**                       SYSOUT - Include SYSOUT DDs in the graph.   **
**                       DUMMY  - Include DUMMY  DDs in the graph.   **
**                       INLINE - Include instream data in the graph.**
**                       TRACE  - Trace parsing of the JCL.          **
**                       ENCODING - Emit encoding=xxx in XML prolog. **
**                       WRAP n - Wrap XML output so that each line  **
**                                is no wider than 'n' characters.   **
**                                This is not always possible - for  **
**                                example, very long attribute values**
**                                cannot be wrapped over multiple    **
**                                lines. The default value for 'n'   **
**                                is 255.                            **
**                       LINE   - Output _line attributes containing **
**                                the source JCL line number.        **
**                       ID     - Output _id attributes (a unique    **
**                                id per element). This attribute is **
**                                nameed '_id' so that it does not   **
**                                clash with the predefined 'id'     **
**                                attribute in the XML specification.**
**                                                                   **
**                       You can negate any option by prefixing it   **
**                       with NO. For example, NOXML.                **
**                                                                   **
** NOTES    - 1. This uses the Rexx XML Parser in CBT FILE647 from   **
**               www.cbttape.org.                                    **
**                                                                   **
**                                                                   **
** LOGIC    - The general approach is to:                            **
**            1. Scan the JCL and build an in-memory XML document.   **
**            2. Walk through the in-memory XML document and create  **
**               another in-memory XML document containing graphml   **
**               markup.                                             **
**            3. Write out the XML and graphml documents to files.   **
**            4. If the JCL option is specified, write out a recon-  **
**               struction of the JCL from the in-memory XML data.   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** CONTRIBUTORS -                                                    **
**            Herbert.Frommwieser@partner.bmw.de                     **
**            Anne.Feldmeier@partner.bmw.de                          **
**                                                                   **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --- ----------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20070323 AJA Used createDocumentFragment() API.        **
**            20070220 AJA Added JCL option to output a file         **
**                         containing JCL reconstructed from the     **
**                         in-memory XML document. This effect-      **
**                         ively reformats your JCL file.            **
**            20070215 AJA Reworked string handling. Quotes are      **
**                         no longer stripped from quoted            **
**                         strings. This simplifies recreation       **
**                         of the JCL from the XML.                  **
**            20070208 AJA Allow numeric values to be specified      **
**                         after command line options. This is       **
**                         so that you can, for example, specify     **
**                         WRAP 72 to wrap XML output lines at       **
**                         column 72.                                **
**            20070130 AJA Parsed comments on ELSE statement.        **
**                         Added LINE and ID options.       .        **
**            20070128 AJA Implemented output line wrapping if       **
**                         line length exceeds the value in          **
**                         g.!MAX_OUTPUT_LINE_LENGTH and the         **
**                         WRAP option is specified. NOWRAP is       **
**                         the default for all environments          **
**                         other than TSO.                           **
**            20070124 AJA Only append inline data once!             **
**            20070119 AJA Rework inline data processing under       **
**                         TSO such that the CDATA section is        **
**                         split into lines at each linefeed         **
**                         instead of being output as a single       **
**                         possibly very long record.                **
**            20070118 AJA Write CDATA as multiple records in a      **
**                         TSO environment.                          **
**            20070117 HF  Added support for JES3 statements &       **
**                     AF  Tivoli Workload Scheduler (formerly       **
**                         OPC) directives.                          **
**            20070117 AF  Initialize g.!RC                          **
**            20061017 AJA Added support for UNIX environment.       **
**                         Tested on Ubuntu Linux 6.06 LTS.          **
**            20061012 AJA Preserved spaces in JCL comments.         **
**            20061006 AJA Added TRACE option (default NOTRACE).     **
**                         Added ENCODING option to allow the        **
**                         XML prolog "encoding" attribute to be     **
**                         suppressed using NOENCODING.              **
**                         Added src attribute to jcl element        **
**                         identifying the source of the JCL.        **
**                         Added _line attribute containing the      **
**                         line number of the first card of each     **
**                         statement parsed.                         **
**            20060922 AJA Fix bug in getParmMap().                  **
**            20060901 AJA Initial version.                          **
**                                                                   **
**********************************************************************/

  parse arg sFileIn sFileOut' ('sOptions')'

  numeric digits 16
  parse value sourceline(1) with . sVersion
  say 'JCL000I JCL to XML Converter' sVersion
  if sFileIn = ''
  then do
    say 'Syntax:'
    say '   JCL2XML infile outfile [(options]'
    say
    say 'Where:'
    say '   infile   = Input job control file'
    say '   outfile  = Output xml and graphml path'
    say '   options  = XML    - Output infile.xml'
    say '              GRAPHML- Output infile.graphml'
    say '              JCL    - Output infile.jcl (reconstructed'
    say '                       from the XML)'
    say '              DUMP   - List the parse tree for debugging'
    say '              SYSOUT - Include SYSOUT DDs in the graph'
    say '              DUMMY  - Include DUMMY  DDs in the graph'
    say '              INLINE - Include instream data in the graph'
    say '              TRACE  - Trace parsing of the JCL'
    say '              ENCODING - Emit encoding="xxx" in XML prolog'
    say '              WRAP n - Wrap output, where possible, to be no'
    say '                       wider than n characters'
    say '              LINE   - Output _line attributes containing'
    say '                       the source JCL line number'
    say '              ID     - Output _id attributes'
    say
    say '              You can negate any option by prefixing it'
    say '              with NO. For example, NOXML.'
    exit
  end
  say 'JCL001I Scanning job control in' sFileIn

  sOptions = 'NOBLANKS' toUpper(sOptions)
  call initParser sOptions /* <-- This is in PARSEXML rexx */

  g.!VERSION = sVersion
  parse source g.!ENV .
  if g.!ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.!LINES = 0
  end

  call setFileNames sFileIn,sFileOut
  call setOptions sOptions
  call Prolog

  gDoc = createDocument('graphml')

  call scanJobControlFile

  if g.!OPTION.GRAPHML
  then do
    call buildGraphML
    g.!YED_FRIENDLY = 1
    call prettyPrinter g.!FILEGML
  end

  if g.!OPTION.DUMP
  then call _displayTree

  if g.!OPTION.XML
  then do
    call setDocType /* we don't need a doctype declaration */
    call setPreserveWhitespace 1 /* retain spaces in JCL comments */
    if g.!OPTION.LINE = 0                                /* 20070130 */
    then call removeAttributes '_line',g.!JCL
    if g.!OPTION.ID = 0                                  /* 20070130 */
    then call removeAttributes '_id',g.!JCL
    call rearrangeComments
    g.!YED_FRIENDLY = 0
    call prettyPrinter g.!FILEXML,,g.!JCL
  end

  if g.!OPTION.JCL
  then do
    call prettyJCL g.!FILEJCL,g.!JCL
  end

  call Epilog
  say 'JCL002I Done'
exit


/* The JobControl input filename is supplied by the user.
The names of the XML and GRAPHML output files are automatically
generated from the input file filename. The generated file names also
depend on the operating system. Global variables are set as follows:
g.!FILETXT = name of input text file  (e.g. JobControl.txt)
g.!FILEGML = name of output GraphML file  (e.g. JobControl.graphml)
g.!FILEXML = name of output XML file  (e.g. JobControl.xml)
g.!FILEJCL = name of output JCL file  (e.g. JobControl.jcl)
*/
setFileNames: procedure expose g.
  parse arg sFileIn,sFileOut
  if sFileOut = '' then sFileOut = sFileIn
  if g.!ENV = 'TSO'
  then do
    g.!FILETXT = toUpper(sFileIn)
    parse var sFileOut sDataset'('sMember')'
    if pos('(',sFileOut) > 0 /* if member name notation used */
    then do /* output to members in the specified PDS */
      if sMember = '' then sMember = 'JCL'
      sPrefix = strip(left(sMember,7)) /* room for a suffix char */
      sPrefix = toUpper(sPrefix)
      /* squeeze the file extension into the member name...*/
      g.!FILEGML = sDataset'('strip(left(sPrefix'GML',8))')'
      g.!FILEXML = sDataset'('strip(left(sPrefix'XML',8))')'
      g.!FILEJCL = sDataset'('strip(left(sPrefix'JCL',8))')'
    end
    else do /* make output files separate datasets */
      g.!FILEGML = sDataset'.GRAPHML'
      g.!FILEXML = sDataset'.XML'
      g.!FILEJCL = sDataset'.JCL'
    end
  end
  else do
    sFileName  = getFilenameWithoutExtension(sFileOut)
    g.!FILETXT = sFileIn
    g.!FILEGML = sFileName'.graphml'
    g.!FILEXML = sFileName'.xml'
    g.!FILEJCL = sFileName'.jcl'
  end
return

getFilenameWithoutExtension: procedure expose g.
  parse arg sFile
  nLastDot = lastpos('.',sFile)
  if nLastDot > 1
  then sFileName = substr(sFile,1,nLastDot-1)
  else sFileName = sFile
return sFileName

initStack: procedure expose g.
  g.!T = 0              /* set top of stack index */
return

pushStack: procedure expose g.
  parse arg item
  tos = g.!T + 1        /* get new top of stack index */
  g.!E.tos = item       /* set new top of stack item */
  g.!T = tos            /* set new top of stack index */
return

popStack: procedure expose g.
  tos = g.!T            /* get top of stack index for */
  item = g.!E.tos       /* get item at top of stack */
  g.!T = max(tos-1,1)
return item

peekStack: procedure expose g.
  tos = g.!T            /* get top of stack index */
  item = g.!E.tos       /* get item at top of stack */
return item

/*
The syntax of a single statement is like:

//name  command   positionals,key=value,...     comment

Each statement can continue over several lines by appending a comma
and starting the continuation between columns 4 and 16:

//name   command key=value,           comment
//             key=value,             comment
//             key=value              comment

*/
scanJobControlFile: procedure expose g.
  call initStack /* stack of conditional jcl blocks */
  g.!JCL = createDocumentFragment('jcl')
  call setAttribute g.!JCL,'src',g.!FILETXT
  call appendAuthor g.!JCL
  g.!STMTID = 0 /* unique statement id */
  parent = g.!JCL
  call pushStack parent
  g.!FILEIN = openFile(g.!FILETXT)
  g.!JCLLINE = 0   /* current line number in the JCL */
  g.!DELIM = '/*'  /* current end-of-data delimiter */
  g.!JCLDATA.0 = 0    /* current number of lines of inline data */
  g.!PENDING_STMT = ''
  call getStatement /* returns data in g.!JCLxxxx variables */
  if g.!OPTION.TRACE                                     /* 20070130 */
  then say ' Stmt  Line Type Name     Op       Operands'
  do nStmt = 1 while g.!RC = 0 & g.!JCLTYPE <> g.!JCLTYPE_EOJ
    if g.!OPTION.TRACE then call sayTrace nStmt
    select
      when g.!JCLTYPE = g.!JCLTYPE_STATEMENT then do
        stmt = newStatementNode()
        select
          when g.!JCLOPER = 'IF' then do
            parent = popUntil('step if then else proc job')
            if getNodeName(parent) = 'step'
            then do
              parent = popStack() /* discard 'step' */
              parent = peekStack()
            end
            call appendChild stmt,parent
            call pushStack stmt
            thenNode = newPseudoStatementNode('then')
            call appendchild thenNode,stmt
            call pushStack thenNode
          end
          when g.!JCLOPER = 'ELSE' then do
            parent = popUntil('if')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.!JCLOPER = 'ENDIF' then do
            parent = popUntil('if')
            if g.!JCLNAME <> ''                          /* 20070130 */
            then call setAttribute parent,'_endname',g.!JCLNAME
            if g.!JCLCOMM <> ''                          /* 20070130 */
            then call setAttribute parent,'_endcomm',g.!JCLCOMM
            parent = popStack() /* discard 'if' */
          end
          when g.!JCLOPER = 'JOB' then do
            parent = popUntil('jcl')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.!JCLOPER = 'JCLLIB' then do
            parent = popUntil('job')
            call appendChild stmt,parent
            parse var g.!JCLPARM 'ORDER='sOrder .
            if left(sOrder,1) = '('
            then parse var sOrder '('sOrder')'
            sOrder = translate(sOrder,'',',')
            g.!ORDER.0 = 0
            do j = 1 to words(sOrder)
              g.!ORDER.j = word(sOrder,j)
              g.!ORDER.0 = j
            end
            /* TODO: Append system libraries somehow */
            /* The JES2 search order for INCLUDE groups is:
               1. // JCLLIB ORDER=(dsn,dsn...)
               2. /@JOBPARM PROCLIB=ddname
                  ...where ddname is in JES2 started task JCL.
               3. JES2 initialisation parameters:
                  JOBCLASS(v) PROCLIB=nn
                  ...where PROCnn DD is in JES2 started task JCL.
               4. PROC00 DD in JES2 started task JCL.
            */
          end
          when g.!JCLOPER = 'INCLUDE' then do
            /* TODO: Replace this with the actual included text */
            parent = popUntil('step proc job')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.!JCLOPER = 'PROC' then do
            parent = peekStack()
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.!JCLOPER = 'PEND' then do
            parent = popUntil('proc')
            parent = popStack() /* discard 'proc' */
          end
          when g.!JCLOPER = 'CNTL' then do
            parent = popUntil('step proc job')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.!JCLOPER = 'ENDCNTL' then do
            parent = popUntil('cntl')
            parent = popStack() /* discard 'cntl' */
          end
          when g.!JCLOPER = 'EXEC' then do
            parent = popUntil('proc job then else')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.!JCLOPER = 'DD' then do
            dd = stmt  /* used to append instream data later...*/
            if getAttribute(stmt,'_name') = '' /* concatenated dd? */
            then do
              parent = peekStack()
              call appendChild stmt,parent /* append to owning dd */
            end
            else do /* this is a named dd (i.e. not concatenated) */
              parent = popUntil('cntl step proc job')
              call appendChild stmt,parent
              call pushStack stmt
            end
          end
          when g.!JCLOPER = 'SET' then do
            /* coalesce multiple 'SET' statements into a single one */
            /* TODO: consider coalescing SET stmts after XML is built */
            if sLastOper <> 'SET'
            then do
              parent = peekStack()
              call appendChild stmt,parent
              set = stmt
            end
            else do /* move 'var' nodes in this 'set' to the first */
              vars = getChildNodes(stmt)
              do j = 1 to words(vars)
                var = word(vars,j)
                varCopy = cloneNode(var)                 /* 20070128 */
                call appendChild varCopy,set
                call removeChild var
              end
              call appendChild stmt,parent /* kludge... */
              call removeChild stmt /* ...to allow infanticide! */
            end
          end
          otherwise do /* all other statements cannot be parents */
            parent = peekStack()
            call appendChild stmt,parent
          end
        end
        sLastOper = g.!JCLOPER
      end
      when g.!JCLTYPE = g.!JCLTYPE_DATA then do
        call appendChild getInlineDataNode(),dd
        g.!JCLDATA.0 = 0                                 /* 20070124 */
      end
      when g.!JCLTYPE = g.!JCLTYPE_COMMENT then do
        if nLastStatementType <> g.!JCLTYPE_COMMENT
        then do /* group multiple comment lines together */
          comment = newElement('comment','_line',g.!JCLLINE)
          parent = popUntil('step proc job dd')
          call appendChild comment,parent
        end
        call appendChild createTextNode(g.!JCLCOMM),comment
      end
      when g.!JCLTYPE = g.!JCLTYPE_JES2CMD then do
        stmt = newStatementNode()
        parent = peekStack()
        call appendChild stmt,parent
      end
      when g.!JCLTYPE = g.!JCLTYPE_JES2STMT then do
        stmt = newStatementNode()
        parent = peekStack()
        call appendChild stmt,parent
      end
      when g.!JCLTYPE = g.!JCLTYPE_JES3STMT then do
        stmt = newStatementNode()
        parent = peekStack()
        call appendChild stmt,parent
      end
      when g.!JCLTYPE = g.!JCLTYPE_OPCDIR  then do      /* HF 061218 */
        stmt = newStatementNode()
        parent = peekStack()
        call appendChild stmt,parent
      end                                               /* HF 061218 */
      when g.!JCLTYPE = g.!JCLTYPE_EOJ then nop
      otherwise do /* should not occur (famous last words) */
        say 'JCL003E Unknown statement on line' g.!JCLLINE':',
            '"'g.!JCLOPER g.!JCLPARM'"'
      end
    end
    nLastStatementType = g.!JCLTYPE
    call getStatement
  end
  if g.!JCLDATA.0 > 0 /* dump any pending sysin before eof reached */
  then do
    call appendChild getInlineDataNode(),dd
  end
  rc = closeFile(g.!FILEIN)
  say 'JCL004I Processed' g.!K-1 'JCL statements'
return

sayTrace: procedure expose g.
  parse arg nStmt
  select
    when g.!JCLTYPE = g.!JCLTYPE_COMMENT then do
      call sayTraceLine nStmt,g.!JCLLINE,g.!JCLCOMM
    end
    when g.!JCLTYPE = g.!JCLTYPE_DATA then do
      nLine = g.!JCLLINE - g.!JCLDATA.0
      do i = 1 to g.!JCLDATA.0
        call sayTraceLine nStmt,nLine,g.!JCLDATA.i
        nLine = nLine + 1
      end
    end
    otherwise do
      call sayTraceLine nStmt,g.!JCLLINE,,
           left(g.!JCLNAME,8) left(g.!JCLOPER,8) g.!JCLPARM
    end
  end
return

sayTraceLine: procedure expose g.
  parse arg nStmt,nLine,sData
  nType = g.!JCLTYPE
  sType = g.!JCLTYPE.nType
  say left(right(nStmt,5) right(nLine,5) left(sType,4) sData,79)
return

appendAuthor: procedure expose g.
  parse arg node
  comment = createComment('Created by JCL to XML Converter' g.!VERSION)
  call appendChild comment,node
  comment = createComment('by Andrew J. Armstrong',
                          '(andrew_armstrong@unwired.com.au)')
  call appendChild comment,node
return

removeAttributes: procedure expose g.
  parse arg sAttrName,node
  if isElementNode(node)
  then call removeAttribute node,sAttrName
  children = getChildNodes(node)
  do i = 1 to words(children)
    child = word(children,i)
    call removeAttributes sAttrName,child
  end
return

/*
Usually, comments precede a step in JCL. However, the XML built by
this scanner will associate comments with the previous step. The
intention of the following routine is to move step comments to their
rightful position - under that step's node. It's not foolproof though.
*/
rearrangeComments: procedure expose g.
  steps = getElementsByTagName(g.!JCL,'step')
  do i = 1 to words(steps)
    step = word(steps,i)
    prev = getPreviousSibling(step)
    if prev <> ''
    then do
      if getNodeName(prev) = 'comment'
      then call moveNode prev,step
      else do
        node = getLastElementDescendant(prev)
        if node <> ''
        then do
          if getNodeName(node) = 'comment'
          then call moveNode node,step
        end
      end
    end
  end
return

getLastElementDescendant: procedure expose g.
  parse arg node
  child = getLastChild(node)
  if isElementNode(child)
  then decendant = getLastElementDescendant(child)
  else decendant = node
return decendant

moveNode: procedure expose g.
  parse arg original,newParent
  node = removeChild(original)
  firstChild = getFirstChild(newParent)
  if firstChild <> ''
  then call insertBefore node,firstChild
  else call appendChild node,newParent
return

popUntil: procedure expose g.
  parse arg sNodeNames
  node = peekStack()
  do while wordpos(getNodeName(node),sNodeNames 'jcl') = 0
    node = popStack()
    node = peekStack()
  end
return node

/*
The function of this routine is to return the next statement (by
accumulating continuations if necessary). The statement is returned in
a set of global variables as follows:
g.!JCLLINE   = the line number of the first card of the statement
g.!JCLTYPE   = the type of statement as follows:
               g.!JCLTYPE_UNKNOWN    - An unknown statement
               g.!JCLTYPE_STATEMENT  - A JCL statement
               g.!JCLTYPE_DATA       - Instream data (see below)
               g.!JCLTYPE_COMMENT    - A comment card
               g.!JCLTYPE_EOJ        - An end-of-job card
               g.!JCLTYPE_JES2CMD    - A JES2 command
               g.!JCLTYPE_JES2STMT   - A JES2 statement
               g.!JCLTYPE_JES3STMT   - A JES3 statement
               g.!JCLTYPE_OPCDIR     - An OPC directive
g.!JCLNAME   = the statement name field (e.g. a dd name)
g.!JCLOPER   = the statement operation field (e.g. DD)
g.!JCLPARM   = the statement parameters (e.g. DISP=SHR etc)
g.!JCLCOMM   = any comment following the statement, or the entire
               comment text if this is a comment card
One or more instream data cards are treated as a single pseudo-statement
with g.!JCLTYPE set to g.!JCLTYPE_DATA and the cards returned in an
array as follows:
g.!JCLDATA.0 = the number of instream data cards
g.!JCLDATA.n = instream data card 'n' (n = 1 to g.!JCLDATA.0)
*/
getStatement: procedure expose g.
  g.!JCLTYPE = g.!JCLTYPE_UNKNOWN
  g.!JCLNAME = ''  /* Statement label     */
  g.!JCLOPER = ''  /* Statement operation */
  g.!JCLCOMM = ''  /* Statement comment   */
  g.!RC      = 0                                        /* AF 061018 */
  /* The following kludge handles the case where a JCL author
     omits the end-of-data delimiter from inline data (instead the
     next statement terminates the inline data). When this happens we
     have already read the next statement, so we need to remember it
     and process it the next time 'getStatement' is called.
  */
  if g.!PENDING_STMT <> ''
  then do
    sLine = g.!PENDING_STMT
    g.!PENDING_STMT = ''
  end
  else sLine = getNextLine()
  parse var sLine 1 s2 +2 1 s3 +3
  select
    when s2 = '/*' & substr(sLine,3,1) <> ' ' then do
      if substr(sLine,3,1) = '$'
      then do
        parse var sLine '/*$'sJesCmd','sJesParms
        g.!JCLTYPE = g.!JCLTYPE_JES2CMD
        g.!JCLOPER = sJesCmd
        g.!JCLPARM = sJesParms
      end
      else do
        parse var sLine '/*'sJesStmt sJesParms
        g.!JCLTYPE = g.!JCLTYPE_JES2STMT
        g.!JCLOPER = sJesStmt
        g.!JCLPARM = sJesParms
      end
    end
    when s3 = '//*' then do                             /* HF 061218 */
      /* This statement may be a comment or a JES3 command or an OPC */
      /* directive or ......                                         */
      /* So let's make the distinction here...                       */
      sWord = substr(word(sLine,1),4)
      select
        when sWord = '%OPC' then do       /* OPC directive           */
          parse var sLine '//*%OPC' sOpcStmt sOpcParms
          g.!JCLTYPE = g.!JCLTYPE_OPCDIR
          g.!JCLOPER = sOpcStmt
          g.!JCLPARM = sOpcParms
        end
        when isJes3Statement(sWord) then do /* JES3 statement        */
          parse var sLine '//*'sJesStmt sJesParms
          g.!JCLTYPE = g.!JCLTYPE_JES3STMT
          g.!JCLOPER = sJesStmt
          g.!JCLPARM = sJesParms
        end
        otherwise do                      /* Comment                 */
          g.!JCLTYPE = g.!JCLTYPE_COMMENT
          g.!JCLCOMM = substr(sLine,4)
        end
      end
    end                                                 /* HF 061218 */
    when sLine = '//' then do
      g.!JCLTYPE = g.!JCLTYPE_EOJ
    end
    when s2 = '//' then do
      sName = ''
      if substr(sLine,3,1) = ' '
      then parse var sLine '//'      sOper sParms
      else parse var sLine '//'sName sOper sParms
      g.!JCLTYPE = g.!JCLTYPE_STATEMENT
      g.!JCLNAME = sName
      g.!JCLOPER = sOper
      select                                             /* 20070130 */
        when sOper = 'IF' then do
          /* IF has its own continuation rules */
          do while g.!RC = 0 & pos('THEN',sParms) = 0
             sLine = getNextLine()
             parse var sLine '//' sThenContinued
             sParms = sParms strip(sThenContinued)
          end
          parse var sParms sParms 'THEN' sComment
          g.!JCLPARM = strip(sParms)
          g.!JCLCOMM = sComment                          /* 20070128 */
        end
        when sOper = 'ELSE' | sOper = 'ENDIF' then do    /* 20070130 */
          g.!JCLPARM = ''
          g.!JCLCOMM = strip(sParms)
        end
        otherwise do /* Slurp up any continuation cards */
          /* This gets really ugly...
             Lines are considered to be continued when they end in a
             comma, or a comma followed by a comment, or if a quoted
             string has not been terminated by another quote.
             For exmample:
             //STEP1 EXEC PGM=IEFBR14,
             //           PARM='HI THERE'
             OR
             //STEP1 EXEC PGM=IEFBR14,    A COMMENT
             //           PARM='HI THERE'
             OR
             //STEP1 EXEC PGM=IEFBR14,PARM='HI
             //           THERE'          A COMMENT
             Comment statements in a continuation are ignored:
             //STEP1 EXEC PGM=IEFBR14,
             //.A comment (star is shown as a dot to keep Rexx happy)
             //           PARM='HI THERE'
          */
          g.!INSTRING = 0 /* for detecting continued quoted strings */
          sParms = getNormalized(sParms)
          parse var sParms sParms sComment
          g.!JCLPARM = sParms
          do while g.!RC = 0 & pos(right(sParms,1),'ff'x',') > 0
            sLine = getNextLine()
            do while g.!RC = 0 & left(sLine,3) = '//*'
              sLine = getNextLine()
            end
            if g.!RC = 0
            then do
              parse var sLine '//'       sParms
              sParms = getNormalized(sParms)
              parse var sParms sParms sComment
              g.!JCLPARM = g.!JCLPARM || sParms
            end
          end
          if sOper = 'DD' & pos('DLM=',g.!JCLPARM) > 0
          then parse var g.!JCLPARM 'DLM=' +4 g.!DELIM +2
          g.!JCLCOMM = sComment                          /* 20070128 */
        end
      end
    end
    otherwise do
      g.!JCLTYPE = g.!JCLTYPE_DATA
      g.!JCLPARM = ''
      n = 0
      do while g.!RC = 0 & \isEndOfData(s2)
        n = n + 1
        g.!JCLDATA.n = strip(sLine,'TRAILING')
        sLine = getNextLine()
        parse var sLine 1 s2 +2
      end
      if g.!DELIM = '/*' & s2 = '//' /* end-of-data marker omitted */
      then g.!PENDING_STMT = sLine
      g.!JCLDATA.0 = n
      g.!DELIM = '/*'  /* reset EOD delimiter to the default */
    end
  end
  g.!K = g.!K + 1
  g.!KDELTA = g.!KDELTA + 1
  if g.!KDELTA >= 100
  then do
    say 'JCL005I Processed' g.!K 'statements'
    g.!KDELTA = 0
  end
return

isJes3Statement: procedure expose g.
  arg sStmt
  sJes3Stmts = 'DATASET ENDDATASET ENDPROCESS FORMAT MAIN NET NETACCT',
               'OPERATOR *PAUSE PROCESS ROUTE'
return wordpos(sStmt,sJes3Stmts) > 0

/* Replace blanks in quoted strings with 'ff'x so it is easier
   to parse later. For example:
             <---parameters----><----comments------>
       this: ABC,('D E F','GH'),    'QUOTED COMMENT'
    becomes: ABC,('D~E~F','GH'),    'QUOTED COMMENT'
    Where '~' is a 'hard' blank ('ff'x)
*/
getNormalized: procedure expose g.
  parse arg sLine
  sLine = strip(sLine,'LEADING')
  sNormalized = ''
  do i = 1 to length(sLine) until c = ' ' & \g.!INSTRING
    c = substr(sLine,i,1)
    select
      when c = "'" & g.!INSTRING then g.!INSTRING = 0
      when c = "'" then g.!INSTRING = 1
      when c = ' ' & g.!INSTRING then c = 'ff'x
      otherwise nop
    end
    sNormalized = sNormalized || c
  end
  if i <= length(sLine)
  then do
    if g.!INSTRING /* make trailing blanks 'hard' blanks */
    then sNormalized = sNormalized ||,
                       translate(substr(sLine,i),'ff'x,' ')
    else sNormalized = sNormalized || substr(sLine,i)
  end
return strip(sNormalized)

isEndOfData: procedure expose g.
  parse arg s2
  bEOD =  g.!DELIM = s2,
       | (g.!DELIM = '/*' & s2 = '//')
return bEOD

getInlineDataNode: procedure expose g.
  sLines = ''
  do n = 1 to g.!JCLDATA.0
    sLines = sLines || g.!JCLDATA.n || g.!LF
  end
return createCDATASection(sLines)

newPseudoStatementNode: procedure expose g.
  parse arg sName
  g.!STMTID = g.!STMTID + 1
  stmt = newElement(sName,'_id',g.!STMTID)
return stmt

/*
  This is a helper routine that creates a named element and
  optionally sets one or more attributes on it. Note Rexx only allows
  up to 20 arguments to be passed.
*/
newElement: procedure expose g.
  parse arg sName /* attrname,attrvalue,attrname,attrvalue,... */
  id = createElement(sName)
  do i = 2 to arg() by 2
    call setAttribute id,arg(i),arg(i+1)
  end
return id

newStatementNode: procedure expose g.
  g.!STMTID = g.!STMTID + 1
  select
    when g.!JCLTYPE = g.!JCLTYPE_JES2CMD then do
      stmt = newElement('jes2cmd',,
                        '_id',g.!STMTID,,
                        '_line',g.!JCLLINE,,
                        'cmd',g.!JCLOPER,,
                        'parm',strip(g.!JCLPARM))
      return stmt
    end
    when g.!JCLTYPE = g.!JCLTYPE_JES2STMT then do
      stmt = newElement('jes2stmt',,
                       '_id',g.!STMTID,,
                        '_line',g.!JCLLINE,,
                       'stmt',g.!JCLOPER)
      call getParmMap g.!JCLPARM
      call setParms stmt
      return stmt
    end
    when g.!JCLTYPE = g.!JCLTYPE_JES3STMT then do
      stmt = newElement('jes3stmt',,
                       '_id',g.!STMTID,,
                        '_line',g.!JCLLINE,,
                       'stmt',g.!JCLOPER)
      call getParmMap g.!JCLPARM
      call setParms stmt
      return stmt
    end
    when g.!JCLTYPE = g.!JCLTYPE_OPCDIR  then do        /* HF 061218 */
      stmt = newElement('opcdir',,
                       '_id',g.!STMTID,,
                        '_line',g.!JCLLINE,,             /* 20070214 */
                        'cmd',g.!JCLOPER,,
                        'parm',strip(g.!JCLPARM))
      return stmt
    end                                                 /* HF 061218 */
    otherwise nop
  end
  if g.!JCLOPER = 'EXEC'
  then stmt = newElement('step')
  else stmt = newElement(toLower(g.!JCLOPER))
  call setAttributes stmt,'_id',g.!STMTID,,
                        '_line',g.!JCLLINE
  if g.!JCLNAME <> ''
  then call setAttribute stmt,'_name',g.!JCLNAME
  if g.!JCLCOMM <> ''                                    /* 20070128 */
  then call setAttribute stmt,'_comment',strip(g.!JCLCOMM)

  call getParmMap g.!JCLPARM
  sNodeName = getNodeName(stmt)
  select
    when sNodeName = 'if' then do
      call setAttributes stmt,'cond',space(g.!JCLPARM)
    end
    when sNodeName = 'set' then do
      /* //name  SET   var=value[,var=value]... comment */
      do i = 1 to g.!PARM.0
        sKey = translate(g.!PARM.i)
        var = newElement('var','name',sKey,,
                               'value',getParm(g.!PARM.i),,
                               '_line',g.!JCLLINE)
        call appendChild var,stmt
      end
      /* apply any comment to the last variable */
      if g.!JCLCOMM <> ''
      then call setAttribute var,'_comment',strip(g.!JCLCOMM)
    end
    when sNodeName = 'step' then do
      bPgm     = 0
      bProc    = 0
      do i = 1 to g.!PARM.0
        bPgm  = bPgm  | g.!PARM.i = 'pgm'
        bProc = bProc | g.!PARM.i = 'proc'
      end
      if \bPgm & \bProc
      then do
        sKey = '_' /* the name for positional parameters */
        sPositionals = g.!PARM.sKey
        sKey = 'proc'
        g.!PARM.1 = sKey
        g.!PARM.sKey = sPositionals
      end
      do i = 1 to g.!PARM.0
        sKey   = g.!PARM.i
        call setAttribute stmt,sKey,getParm(sKey)
      end
    end
    when sNodeName = 'job' then do
      do i = 1 to g.!PARM.0
        sKey   = g.!PARM.i
        if sKey = '_'
        then do /* [(acct,info)][,programmer] */
                /* [acct][,programmer] */
          sPositionals = g.!PARM.sKey
          if left(sPositionals,1) = '('
          then parse var sPositionals '('sAcctAndInfo'),'sProg
          else parse var sPositionals sAcctAndInfo','sProg
          parse var sAcctAndInfo sAcct','sInfo
          call setAttributes stmt,'acct',deQuote(sAcct),,
                                  'acctinfo',deQuote(sInfo),,
                                  'pgmr',deQuote(sProg)
        end
        else do
          call setAttribute stmt,sKey,getParm(sKey)
        end
      end
    end
    otherwise call setParms stmt
  end
return stmt

setParms: procedure expose g.
  parse arg stmt
  do i = 1 to g.!PARM.0
    sKey = g.!PARM.i
    call setAttribute stmt,sKey,getParm(sKey)
  end
return

getParm: procedure expose g.
  parse arg sKey
return deQuote(g.!PARM.sKey)

deQuote: procedure expose g.
  parse arg sValue
return translate(sValue,' ','ff'x)

  /*
  if left(sValue,1) = "'"  /- 'abc' --> abc -/
  then sValue = substr(sValue,2,length(sValue)-2)
  */
  n = pos("''",sValue)
  do while n > 0
    sValue = delstr(sValue,n,1)  /* '' --> ' */
    n = pos("''",sValue)
  end
return translate(sValue,' ','ff'x)

/*
  Parameters consist of positional keywords followed by key=value
  pairs. Values can be bracketed or quoted. For example:
    <---------------parms--------------->
    A,(B,C),'D E,F',G=H,I=(J,K),L='M,N O'
    <--positional--><------keywords----->
  This routine parses parameters into stem variables as follows:
  g.!PARM.0 = number of parameters
  g.!PARM.n = key for parameter n
  g.!PARM.key = value for parameter called 'key'
  ...where n = 1 to the number of parameters.
  A special parameter key called '_' is used for positionals.
  Using the above example:
  g.!PARM.0 = 4
  g.!PARM.1 = '_'; g.!PARM._ = "A,(B,C),'D E,F'"
  g.!PARM.2 = 'G'; g.!PARM.G = 'H'
  g.!PARM.3 = 'I'; g.!PARM.I = '(J,K)'
  g.!PARM.4 = 'L'; g.!PARM.L = "'M,N O'"
*/
getParmMap: procedure expose g.
  parse arg sParms
  sParms = strip(sParms)
  nParm = 0
  nComma  = pos(',',sParms)
  nEquals = pos('=',sParms)
  /* Process the positional operands */
  select
    when nComma = 0 & nEquals = 0 & sParms <> '' then do
      nParm = nParm + 1
      sKey = '_'
      g.!PARM.nParm = sKey
      g.!PARM.sKey = sParms
      sParms = ''
    end
    when nComma > 0 & nComma < nEquals then do
      nPos = lastpos(',',sParms,nEquals)
      sPositionals = left(sParms,nPos-1)
      nParm = nParm + 1
      sKey = '_'
      g.!PARM.nParm = sKey
      g.!PARM.sKey = sPositionals
      sParms = substr(sParms,nPos+1)
    end
    otherwise nop
  end
  /* Process the keyword=value operands */
  do while sParms <> ''
    parse var sParms sKey'='sValue
    sKey = toLower(sKey)
    select
      when left(sValue,1) = '(' then do /* K=(...) */
        nValue = getInBracketsLength(sValue)
        parse var sValue sValue +(nValue)','sParms
      end
      when left(sValue,1) = "'" then do /* K='...' */
        nValue = getInQuotesLength(sValue)
        if nValue = 2
        then do    /* K='',... */
          sParms = substr(sValue,4)
          sValue = ''
        end
        else do    /* K='V',... */
          parse var sValue sValue +(nValue)','sParms
        end
      end
      otherwise do /* K=V         */
                   /* K=S=(...)   */
                   /* K=S='...'   */
                   /* K=S=X       */
        sSymbol = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$'
        nSymbol = verify(sValue,sSymbol,'NOMATCH')
        if nSymbol > 0
        then do
          c = substr(sValue,nSymbol,1)
          if c = '='
          then do /* K=S=...*/
            parse var sValue sSubKey'='sParms
            select
              when left(sParms,1) = '(' then do /* S=(...) */
                nSubValue = getInBracketsLength(sParms)
                parse var sParms sSubValue +(nSubValue)','sParms
              end
              when left(sParms,1) = "'" then do /* S='...' */
                nSubValue = getInQuotesLength(sParms)
                if nSubValue = 2
                then do  /* K=S='',... */
                  sParms = substr(sParms,4)
                  sSubValue = ''
                end
                else do  /* K=S='V',... */
                  parse var sParms sSubValue +(nSubValue)','sParms
                end
              end
              otherwise do                      /* S=... */
                parse var sParms sSubValue','sParms
              end
            end
            sValue = sSubKey'='sSubValue
          end
          else do /* K=V,... */
            parse var sValue sValue','sParms
          end
        end
        else parse var sValue sValue','sParms
      end
    end
    nParm = nParm + 1
    g.!PARM.nParm = sKey
    g.!PARM.sKey = sValue
  end
  g.!PARM.0 = nParm
return

/* (abc) --> 5 */
getInBracketsLength: procedure expose g.
  parse arg sValue
  nLvl = 0
  do i = 1 to length(sValue) until nLvl = 0
    c = substr(sValue,i,1)
    select
      when c = '(' then nLvl = nLvl + 1
      when c = ')' then nLvl = nLvl - 1
      otherwise nop
    end
  end
return i

/* 'abc' --> 5 */
getInQuotesLength: procedure expose g.
  parse arg sValue
  bEndOfString = 0
  do i = 2 to length(sValue) until bEndOfString
    if substr(sValue,i,2) = "''"
    then i = i + 1 /* Skip over '' */
    else bEndOfString = substr(sValue,i,1) = "'"
  end
return i

toLower: procedure expose g.
  parse arg sText
return translate(sText,g.!LOWER,g.!UPPER)

toUpper: procedure expose g.
  parse upper arg sText
return sText

getNextLine: procedure expose g.
  sLine = left(getLine(g.!FILEIN),71)
  g.!JCLLINE = g.!JCLLINE + 1
return sLine


/*
We have two XML trees in memory, one for the XML representation of the
input JCL, and one for the GraphML representation.To distinguish them
easily, a Rexx variable naming convention is used. A 'g' prefix, for
example 'gStep', indicates that the node belongs to the GraphML tree.
Node names with no prefix, for example 'step', belong to the JCL tree.
*/
buildGraphML: procedure expose g.
  gDoc = getDocumentElement() /* created earlier by createDocument() */
  call setAttributes gDoc,,
       'xmlns','http://graphml.graphdrawing.org/xmlns/graphml',,
       'xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance',,
       'xmlns:schemalocation',,
          'http://graphml.graphdrawing.org/xmlns/1.0rc/graphml.xsd',
          'http://www.yworks.com/xml/schema/graphml/1.0/ygraphml.xsd',,
       'xmlns:y','http://www.yworks.com/xml/graphml'

  call appendAuthor gDoc

  gKey = newElement('key',,
                   'id','d0',,
                   'for','node',,
                   'yfiles.type','nodegraphics')
  call appendChild gKey,gDoc
  gKey = newElement('key',,
                   'id','d1',,
                   'for','edge',,
                   'yfiles.type','edgegraphics')
  call appendChild gKey,gDoc

  g.!GRAPH = newElement('graph',,
                     'id','G',,
                      'edgedefault','directed')

  call appendChild g.!GRAPH,gDoc

  call drawBlock g.!JCL

  call removeEndIfNodes
return

drawBlock: procedure expose g.
  parse arg node
  gFirstNode = ''
  gLastNode= ''
  children = getChildNodes(node)
  do i = 1 to words(children)
    child = word(children,i)
    sChild = getNodeName(child)
    select
      when sChild = 'job' then do
        gJob = newJobNode(child)
        sNodes = drawBlock(child)
        parse var sNodes gFirstChild','gLastChild
        gEoj = newEndOfJobNode()
        call newArrow gJob,gFirstChild,,newControlFlowLine()
        call newArrow gLastChild,gEoj,,newControlFlowLine()
      end
      when sChild = 'proc' then do
        gProc = newProcNode(child)
        sNodes = drawBlock(child)
        parse var sNodes gFirstChild','gLastChild
        gPend = newEndOfProcNode()
        call newArrow gProc,gFirstChild,,newControlFlowLine()
        call newArrow gLastChild,gPend,,newControlFlowLine()
      end
      when sChild = 'step' then do
        gStep = newStepNode(child)
        if gFirstNode = ''
        then gFirstNode = gStep
        else do
          sCond = getAttribute(child,'cond')
          if sCond <> ''
          then sLabel = 'COND='sCond
          else sLabel = ''
          call newArrow gLastNode,gStep,sLabel,newControlFlowLine()
        end
        gLastNode = gStep
      end
      when sChild = 'if' then do
        gIf = newDecisionNode(child)
        gEndIf = newEndIfNode() /* note: will be removed later */
        if gFirstNode = ''
        then gFirstNode = gIf
        else call newArrow gLastNode,gIf,,newControlFlowLine()
        thenNode = getChildrenByName(child,'then')
        sNodes = drawBlock(thenNode)
        parse var sNodes gFirstInThen','gLastInThen
        call newArrow gIf,gFirstInThen,'TRUE',newControlFlowLine()
        call newArrow gLastInThen,gEndIf,,newControlFlowLine()
        elseNode = getChildrenByName(child,'else')
        if elseNode <> ''
        then do
          sNodes = drawBlock(elseNode)
          parse var sNodes gFirstInElse','gLastInElse
          call newArrow gIf,gFirstInElse,'FALSE',newControlFlowLine()
          call newArrow gLastInElse,gEndIf,,newControlFlowLine()
        end
        else call newArrow gIf,gEndIf,'FALSE',newControlFlowLine()
        gLastNode = gEndIf
      end
      when sChild = 'set' then do
        gSet = newSetNode(child)
        if gFirstNode = ''
        then gFirstNode = gSet
        else call newArrow gLastNode,gSet,,newControlFlowLine()
        gLastNode = gSet
      end
      when sChild = 'include' then do
        gInclude = newIncludeNode(child)
        if gFirstNode = ''
        then gFirstNode = gInclude
        else call newArrow gLastNode,gInclude,,newControlFlowLine()
        gLastNode = gInclude
      end
      otherwise nop
    end
  end
return gFirstNode','gLastNode

/* Remove all the endif placeholder nodes. That is,
             this:                      becomes:

      .------[IF]------.          .------[IF]------.
      |                |          |                |
      | false          | true     | false          | true
      |             [STEP]        |             [STEP]
      |                |          |                |
      |             [STEP]        |             [STEP]
      |                |          |                |
      '------. .-------'          '------. .-------'
             | |                         | |
             V V                         | |
           [ENDIF]                       | |
              |                          | |
              V                          V V
            [STEP]                      [STEP]
*/
removeEndIfNodes: procedure expose g.
  gDeadNodes = ''
  gNodes = getElementsByTagName(g.!GRAPH,'node')
  gEdges = getElementsByTagName(g.!GRAPH,'edge')
  do i = 1 to words(gNodes)
    gEndIf = word(gNodes,i)
    if \hasChildren(gEndIf)
    then do /* This is an endif placeholder node */
      /* Find the node that the endif node points to */
      sEndIfId = getAttribute(gEndIf,'id')
      do j = 1 to words(gEdges) until sArrowSourceId = sEndIfId
        gArrowFromEndIf = word(gEdges,j)
        sArrowSourceId = getAttribute(gArrowFromEndIf,'source')
      end
      sEndifTargetId = getAttribute(gArrowFromEndIf,'target')
      /* Find all arrows pointing to the endif node and
         change them to point to the node that the endif points to */
      do j = 1 to words(gEdges)
        gArrow = word(gEdges,j)
        sArrowTargetId   = getAttribute(gArrow,'target')
        if sArrowTargetId = sEndIfId
        then call setAttribute gArrow,'target',sEndifTargetId
      end
      /* Schedule the endif node and its arrow for removal later */
      gDeadNodes = gDeadNodes gEndIf gArrowFromEndIf
    end
  end
  /* Finally, remove all the endif nodes and associated arrows */
  do i = 1 to words(gDeadNodes)
    gDeadNode = word(gDeadNodes,i)
    call removeChild gDeadNode
  end
return

newEndIfNode: procedure expose g.
  g.!STMTID = g.!STMTID + 1
  gEndIf = newElement('node','id','n'g.!STMTID)
  call appendChild gEndIf,g.!GRAPH
return gEndIf

newControlFlowLine: procedure expose g.
  gLineStyle = newElement('y:LineStyle',,
                          'type','line',,
                          'width',3,,
                          'color',g.!COLOR_CONTROL_FLOW)
return gLineStyle

newJobNode: procedure expose g.
  parse arg job
  sLabel = 'JOB' || g.!LF || getAttribute(job,'_name')
  gGeometry = newElement('y:Geometry','width',70,'height',70)
  gFill = newElement('y:Fill','color',g.!COLOR_JOB_NODE)
  gNodeLabel = newElement('y:NodeLabel')
  call appendChild createCDataSection(sLabel),gNodeLabel
  gJob = newShapeNode(job,,'octagon',gFill,gGeometry,gNodeLabel)
  dds = getChildrenByName(job,'dd')
  do i = 1 to words(dds)
    dd = word(dds,i)
    sDDName = getAttribute(dd,'_name')
    sDSN    = getAttribute(dd,'dsn')
    if sDDName <> ''
    then do
      gDD = newFileNode(dd)
      g.!DSN.sDSN = gDD
      sDDName = getAttribute(dd,'_name')
      call newArrow gDD,gJob,sDDName
    end
  end
  jcllib = getChildrenByName(job,'jcllib')
  if jcllib <> ''
  then do
    gJclLib = newJclLibNode(jcllib)
    call newArrow gJclLib,gJob,'JCLLIB'
  end
return gJob

newEndOfJobNode: procedure expose g.
  gGeometry = newElement('y:Geometry','width',70,'height',70)
  gFill = newElement('y:Fill','color',g.!COLOR_EOJ_NODE)
  gNodeLabel = newElement('y:NodeLabel',,
                          'fontSize',14,,
                          'textColor',g.!COLOR_WHITE)
  call appendChild createTextNode('EOJ'),gNodeLabel
  eoj = newPseudoStatementNode('eoj')
  gEndOfJob = newShapeNode(eoj,,'octagon',gFill,gGeometry,gNodeLabel)
return gEndOfJob

newProcNode: procedure expose g.
  parse arg proc
  sLabel = 'PROC' || g.!LF || getAttribute(proc,'_name')
  gGeometry = newElement('y:Geometry','width',100,'height',34)
  gFill = newElement('y:Fill','color',g.!COLOR_PROC_NODE)
  gNodeLabel = newElement('y:NodeLabel')
  call appendChild createCDataSection(sLabel),gNodeLabel
  gProc = newShapeNode(proc,,'roundrectangle',,
                             gFill,gGeometry,gNodeLabel)
  gParms = newParmsNode(proc)
  if gParms <> ''
  then call newDottedArrow gParms,gProc
return gProc

newParmsNode: procedure expose g.
  parse arg step,sIgnoredParms
  call getAttributeMap step
  sLabel = ''
  do i = 1 to g.!ATTRIBUTE.0
    sKey = g.!ATTRIBUTE.i
    if wordpos(sKey,'_id _name _line _comment' sIgnoredParms) = 0
    then do
      sVal = g.!ATTRIBUTE.sKey
      sLabel = sLabel || g.!LF || toUpper(sKey)'='sVal
    end
  end
  if sLabel = '' then return '' /* no parms worth mentioning */
  sLabel = strip(sLabel,'LEADING',g.!LF)
  parms = newPseudoStatementNode('parms')
  gBorderStyle = newElement('y:BorderStyle','type','dashed')
  gFill = newElement('y:Fill','color',g.!COLOR_PARMS_NODE)
  gNode = newShapeNode(parms,sLabel,'roundrectangle',,
                      gBorderStyle,gFill)
return gNode

newEndOfProcNode: procedure expose g.
  gGeometry = newElement('y:Geometry','width',100,'height',34)
  gFill = newElement('y:Fill','color',g.!COLOR_PEND_NODE)
  gNodeLabel = newElement('y:NodeLabel')
  call appendChild createTextNode('PEND'),gNodeLabel
  pend = newPseudoStatementNode('pend')
  gPend = newShapeNode(pend,,'roundrectangle',,
                             gFill,gGeometry,gNodeLabel)
return gPend

newDecisionNode: procedure expose g.
  parse arg id
  sLabel = getAttribute(id,'cond')
  gNodeLabel = newElement('y:NodeLabel')
  call appendChild createTextNode(sLabel),gNodeLabel
  gFill = newElement('y:Fill','color',g.!COLOR_IF_NODE)
  gGeometry = newElement('y:Geometry','width',130,'height',80)
  gDecision = newShapeNode(id,slabel,'diamond',,
                          gFill,gGeometry,gNodeLabel)
return gDecision

/* Create a new STEP node linked to all its DD nodes */
newStepNode: procedure expose g.
  parse arg step
  sStepName = getAttribute(step,'_name')
  sPgm = getAttribute(step,'pgm')
  if sPgm <> ''
  then sLabel = sStepName 'PGM='sPgm
  else sLabel = sStepName 'PROC='getAttribute(step,'proc')
  gFill = newElement('y:Fill','color',g.!COLOR_STEP_NODE)
  gGeometry = newTextGeometry(22,2)
  gNodeLabel = newElement('y:NodeLabel')
  call appendChild createTextNode(sLabel),gNodeLabel
  gStep = newShapeNode(step,,'roundrectangle',,
                       gFill,gGeometry,gNodeLabel)
  /* Draw any input parameters */
  gParms = newParmsNode(step,'pgm proc cond')
  if gParms <> '' then call newDottedArrow gParms,gStep
  /* Draw any INCLUDE statements */
  /* TODO: Replace this by actually including the member contents */
  includes = getChildrenByName(step,'include')
  do i = 1 to words(includes)
    include = word(includes,i)
    gInclude = newIncludeNode(include)
    call newDottedArrow gInclude,gStep
  end
  /* Draw any DD statements */
  dds = getChildrenByName(step,'dd')
  do i = 1 to words(dds)
    dd = word(dds,i)
    sDDName = getAttribute(dd,'_name')
    if sDDName <> ''
    then do
      select
        when isPrintFile(dd) then do
          if g.!OPTION.SYSOUT
          then do
            gDD = newPrinterNode(dd)
            call newArrow gStep,gDD,sDDName
          end
        end
        when isInternalReaderFile(dd) then do
          gDD = newInternalReaderNode(dd)
          call newArrow gStep,gDD,sDDName
        end
        when isInlineFile(dd) then do
          if g.!OPTION.INLINE
          then do
            gDD = newInlineNode(dd)
            call newArrow gDD,gStep,sDDName
          end
        end
        when isDummyFile(dd) then do
          if g.!OPTION.DUMMY
          then do
            gDD = newDummyNode(dd)
            call newLine gDD,gStep,sDDName
          end
        end
        when isConcatenatedFile(dd) then do
          gDD = newFileNode(dd)
          call newArrow gDD,gStep,sDDName
        end
        when getAttribute(dd,'dsn') = '' then nop
        when isInputFile(dd) then do
          gDD = getFileNode(dd)
          call newArrow gDD,gStep,sDDName
        end
        when isOutputFile(dd) then do
          gDD = getFileNode(dd)
          call newArrow gStep,gDD,sDDName
        end
        otherwise do /* assume it is both input and output */
          gDD = getFileNode(dd)
          call newDoubleArrow gDD,gStep,sDDName
        end
      end
    end
  end
return gStep

newShapeNode: procedure expose g.
  parse arg node,sLabel,sShape
  gShapeNode = newElement('y:ShapeNode')
  if sShape <> '' /* if not the default rectangle...*/
  then call appendChild newElement('y:Shape','type',sShape),gShapeNode
  sPropertiesAlreadySet = ''
  do i = 4 to arg()
    sPropertiesAlreadySet = sPropertiesAlreadySet getNodeName(arg(i))
    call appendChild arg(i),gShapeNode
  end
  sId = getAttribute(node,'_id')
  gNode = newElement('node','id','n'sId)
  gData = newElement('data','key','d0')
  call appendChild gData,gNode
  call appendChild gShapeNode,gData
  if wordpos('y:Geometry',sPropertiesAlreadySet) = 0
  then do
    parse value getLabelDimension(sLabel) with nChars','nLines
    call appendChild newTextGeometry(nChars,nLines),gShapeNode
  end
  if wordpos('y:NodeLabel',sPropertiesAlreadySet) = 0
  then do
    gNodeLabel = newElement('y:NodeLabel',,
                       'alignment','left',,
                       'modelPosition','l',,
                       'fontFamily','Monospaced')
    if pos(g.!LF,sLabel) > 0
    then gText = createCDataSection(sLabel)
    else gText = createTextNode(sLabel)
    call appendChild gText,gNodeLabel
    call appendChild gNodeLabel,gShapeNode
  end
  if wordpos('y:DropShadow',sPropertiesAlreadySet) = 0
  then do
    gDropShadow = newElement('y:DropShadow',,
                             'offsetX',4,'offsetY',4,,
                             'color',g.!COLOR_DROP_SHADOW)
    call appendChild gDropShadow,gShapeNode
  end
  if wordpos('y:Fill',sPropertiesAlreadySet) = 0
  then do
    gFill = newElement('y:Fill','color',g.!COLOR_SHAPE_NODE)
    call appendChild gFill,gShapeNode
  end
  call appendChild gNode,g.!GRAPH
return gNode

getFileNode: procedure expose g.
  parse arg dd
  sDSN = getAttribute(dd,'dsn')
  if g.!DSN.sDSN = '' /* if file is not already in graph */
  then do /* create a new file node and add it to the graph */
    gDD = newFileNode(dd)
    g.!DSN.sDSN = gDD
  end
  else do /* use existing file node in graph */
    gDD = g.!DSN.sDSN
  end
return gDD

isTempFile: procedure expose g.
  parse arg dd
  sDSN = getAttribute(dd,'dsn')
return left(sDSN,2) = '&&'

isPrintFile: procedure expose g.
  parse arg dd
  sSysout = getAttribute(dd,'sysout')
return sSysout <> '' & pos('INTRDR',sSysout) = 0

isInternalReaderFile: procedure expose g.
  parse arg dd
  sSysout = getAttribute(dd,'sysout')
return pos('INTRDR',sSysout) <> 0

isInlineFile: procedure expose g.
  parse arg dd
  sPositionals = getAttribute(dd,'_')
return sPositionals = '*' | sPositionals = 'DATA'

isDummyFile: procedure expose g.
  parse arg dd
  sPositionals = getAttribute(dd,'_')
return sPositionals = 'DUMMY'

isConcatenatedFile: procedure expose g.
  parse arg dd
  dds = getChildrenByName(dd,'dd')
return dds <> ''

isInputFile: procedure expose g.
  parse arg dd
  sStatus = getDispStatus(getAttribute(dd,'disp'))
  bSysout = hasAttribute(dd,'sysout')
return \bSysout & (wordpos(sStatus,'OLD SHR') > 0 | isInlineFile(dd))

isOutputFile: procedure expose g.
  parse arg dd
  sStatus = getDispStatus(getAttribute(dd,'disp'))
  bSysout = hasAttribute(dd,'sysout')
return bSysout | wordpos(sStatus,'NEW MOD') > 0

getDispStatus: procedure expose g.
  parse arg sDisp
  if left(sDisp,1) = '('
  then parse var sDisp '('sStatus','sNormal','sAbnormal')'
  else sStatus = sDisp
  if sStatus = '' then sStatus = 'NEW'
return sStatus

newFileNode: procedure expose g.
  parse arg dd
  sLabel = getAttribute(dd,'dsn')
  /* Get any concatenated dataset names too */
  dds = getChildrenByName(dd,'dd')
  if dds <> '' then sLabel = '+0' sLabel
  do i = 1 to words(dds)
    concatdd = word(dds,i)
    sDataset = getAttribute(concatdd,'dsn')
    if sDataset = '' then sDataset = '(in stream)'
    sLabel = sLabel || g.!LF || '+'i sDataset
  end
  gNode = newShapeNode(dd,sLabel)
return gNode

newPrinterNode: procedure expose g.
  parse arg dd
  sLabel = 'SYSOUT='getAttribute(dd,'sysout')
  gNode = newImageNode(dd,sLabel,'paper.png')
return gNode

newInternalReaderNode: procedure expose g.
  parse arg dd
  sLabel = 'SYSOUT='getAttribute(dd,'sysout')
  gGeometry = newPixelGeometry(70,34)
  gNode = newImageNode(dd,sLabel,'card.png',gGeometry)
return gNode

/*                                                             20070119
 The children of an inline dd node are zero or more CDATA nodes (one
 for each card of inline data) with an implied linefeed between each.
*/
newInlineNode: procedure expose g.
  parse arg dd
  sLabel = ''
  line = getFirstChild(dd)
  do while line <> ''
    sLabel = sLabel || g.!LF || getText(line) /* CDATA text */
    line = getNextSibling(line)
  end
  sLabel = strip(sLabel,'LEADING',g.!LF)
  parse value getLabelDimension(sLabel) with nChars','nLines
  gGeometry = newTextGeometry(nChars,nLines)
  gFill = newElement('y:Fill','color',g.!COLOR_INLINE_NODE)
  gNode = newShapeNode(dd,sLabel,,gGeometry,gFill)
return gNode

newDummyNode: procedure expose g.
  parse arg dd
  sLabel = 'DUMMY'
  gNode = newShapeNode(dd,sLabel)
return gNode

newJCLLibNode: procedure expose g.
  parse arg jcllib
  sOrder = getAttribute(jcllib,'order')
  if left(sOrder,1) = '('
  then parse var sOrder '('sOrder')'
  sLabel = translate(sOrder,g.!LF,',')
  gBorderStyle = newElement('y:BorderStyle','type','dashed')
  gFill = newElement('y:Fill','color',g.!COLOR_JCLLIB_NODE)
  gNode = newShapeNode(jcllib,sLabel,'roundrectangle',gBorderStyle,,
                       gFill)
return gNode

newSetNode: procedure expose g.
  parse arg set
  /* Get any var names too */
  sLabel = ''
  vars = getChildrenByName(set,'var')
  do i = 1 to words(vars)
    var = word(vars,i)
    sName = getAttribute(var,'name')
    sValue = getAttribute(var,'value')
    sLabel = sLabel || g.!LF || 'SET' sName'='sValue
  end
  gFill = newElement('y:Fill','color',g.!COLOR_SET_NODE)
  gNode = newShapeNode(set,substr(sLabel,2),,gFill)
return gNode

/*
This is a temporary solution until a way of including the actual
text is worked out.
*/
newIncludeNode: procedure expose g.
  parse arg include
  /* Get any var names too */
  sLabel = 'INCLUDE' getAttribute(include,'member')
  gFill = newElement('y:Fill','color',g.!COLOR_INCLUDE_NODE)
  gNode = newShapeNode(include,sLabel,,gFill)
return gNode

getLabelDimension: procedure expose g.
  parse arg sLabel
  if pos(g.!LF,sLabel) > 0
  then do /* compute dimensions of a multi-line label */
    nChars = 10 /* minimum width */
    do nLines = 1 by 1 until length(sLabel) = 0
      parse var sLabel sLine (g.!LF) sLabel
      nChars = max(nChars,length(sLine))
    end
  end
  else do
    nChars = max(length(sLabel),10)
    nLines = 1
  end
return nChars','nLines

newTextGeometry: procedure expose g.
  parse arg nChars,nLines
  gGeometry = newElement('y:Geometry',,
                        'width',format(nChars*9.7,,0),,
                        'height',nLines * 17)
return gGeometry

newPixelGeometry: procedure expose g.
  parse arg nWidth,nHeight
  gGeometry = newElement('y:Geometry','width',nWidth,'height',nHeight)
return gGeometry

newImageNode: procedure expose g.
  parse arg id,sLabel,sImage
  sId = getAttribute(id,'_id')
  gNode = newElement('node','id','n'sId)
  gData = newElement('data','key','d0')
  call appendChild gData,gNode
  gImageNode = newElement('y:ImageNode')
  call appendChild gImageNode,gData
  do i = 4 to arg()
    call appendChild arg(i),gImageNode
  end
  gNodeLabel = newElement('y:NodeLabel',,
                          'modelName','sandwich',,
                          'modelPosition','s')
  call appendChild gNodeLabel,gImageNode
  call appendChild createTextNode(sLabel),gNodeLabel
  gImage = newElement('y:Image','href',sImage)
  call appendChild gImage,gImageNode
  call appendChild gNode,g.!GRAPH
return gNode

newArrow: procedure expose g.
  parse arg gFrom,gTo,sLabel,gLineStyle
return newLine(gFrom,gTo,sLabel,gLineStyle,,'standard')

newDottedArrow: procedure expose g.
  parse arg gFrom,gTo,sLabel
  gLineStyle = newElement('y:LineStyle','type','dashed')
return newLine(gFrom,gTo,sLabel,gLineStyle,,'standard')

newDoubleArrow: procedure expose g.
  parse arg gFrom,gTo,sLabel
return newLine(gFrom,gTo,sLabel,,'standard','standard')

newLine: procedure expose g.
  parse arg gFrom,gTo,sLabel,gLineStyle,sBegArrow,sEndArrow
  gEdge = newElement('edge',,
                    'source',getAttribute(gFrom,'id'),,
                    'target',getAttribute(gTo,'id'))
  gData = newElement('data','key','d1')
  call appendChild gData,gEdge
  gPolyLineEdge = newElement('y:PolyLineEdge')
  call appendChild gPolyLineEdge,gData
  if sLabel <> ''
  then do
    gEdgeLabel = newElement('y:EdgeLabel')
    call appendChild gEdgeLabel,gPolyLineEdge
    call appendChild createTextNode(sLabel),gEdgeLabel
  end
  if gLineStyle <> ''
  then call appendChild gLineStyle,gPolyLineEdge
  if sBegArrow <> '' | sEndArrow <> ''
  then do
    if sBegArrow = '' then sBegArrow = 'none'
    if sEndArrow = '' then sEndArrow = 'none'
    gArrows = newElement('y:Arrows',,
                         'source',sBegArrow,,
                         'target',sEndArrow)
    call appendChild gArrows,gPolyLineEdge
  end
  gBendStyle = newElement('y:BendStyle','smoothed','true')
  call appendChild gBendStyle,gPolyLineEdge
  call appendChild gEdge,g.!GRAPH
return gEdge

prettyJCL: procedure expose g.
  parse arg sFileOut,node
  g.!FILEOUT = ''
  g.!INDENT = 0
  if sFileOut <> ''
  then do
    g.!FILEOUT = openFile(sFileOut,'OUTPUT')
    if g.!rc = 0
    then say 'JCL011I Creating' sFileOut
    else do
      say 'JCL012E Could not create' sFileOut'. Writing to console...'
      g.!FILEOUT = '' /* null handle means write to console */
    end
  end
  call emitJCL node
  if g.!FILEOUT <> ''
  then do
    say 'JCL013I Created' sFileOut
    rc = closeFile(g.!FILEOUT)
  end
return

emitJCL: procedure expose g.
  parse arg node
  if isCommentNode(node) then return /* ignore XML comments */
  if isCDATA(node)
  then do
    call Say strip(getText(node),'TRAILING',g.!LF)
    return
  end
  sElement = getNodeName(node)
  select
    when sElement = 'comment' then do
      children = getChildNodes(node)
      do i = 1 to words(children)
        child = word(children,i)
        call Say '//*'getText(child)
      end
    end
    when sElement = 'job' then do
      call emitJobStatement node
      call emitChildrenOf node
      call Say '//'
    end
    when sElement = 'proc' then do
      call emitStatement node
      call emitChildrenOf node
      call Say '//         PEND'
    end
    when sElement = 'step' then do
      call emitStatement node,'EXEC'
      call emitChildrenOf node
    end
    when sElement = 'dd' then do
      call emitStatement node  /* this DD...                  */
      call emitChildrenOf node /* ...and any concatenated DDs */
      if getAttribute(node,'_') = '*'
      then do
        sDelim = getAttribute(node,'dlm')
        if sDelim = '' then sDelim = '/*'
        call Say sDelim
      end
    end
    when sElement = 'if' then do
      call Say '//         IF' getAttribute(node,'cond') 'THEN',
                          getAttribute(node,'_comment')
      call emitChildrenOf node
      call Say '//         ENDIF' getAttribute(node,'_endcomment')
    end
    when sElement = 'then' then do
      call emitChildrenOf node
    end
    when sElement = 'else' then do
      call Say '//         ELSE' getAttribute(node,'_comment')
      call emitChildrenOf node
    end
    when sElement = 'set' then do
      call emitChildrenOf node
    end
    when sElement = 'var' then do
      call Say '//'getLabel(node) 'SET',
               toUpper(getAttribute(node,'name'))||,
               '='getAttribute(node,'value')
    end
    when sElement = 'cntl' then do
      call emitStatement node
      call emitChildrenOf node
      call Say '//         ENDCNTL'
    end
    when sElement = 'jes2cmd' then do
      call Say '/*$'getAttribute(node,'cmd')','getAttribute(node,'parm')
    end
    when sElement = 'jes2stmt' then do
      call Say '/*'getAttribute(node,'stmt') getKeywords(node,'stmt')
    end
    when sElement = 'jes3stmt' then do
      call Say '//*'getAttribute(node,'stmt') getKeywords(node,'stmt')
    end
    when sElement = 'opcdir' then do
      call Say '//*%OPC' getAttribute(node,'cmd'),
                         getAttribute(node,'parm')
    end
    when sElement = 'jcl' then do
      call emitChildrenOf node
    end
    otherwise do
      call emitStatement node
      call emitChildrenOf node
    end
  end
return

getLabel: procedure expose g.
  parse arg node
return left(getAttribute(node,'_name'),8)

emitJobStatement: procedure expose g.
  parse arg node
  sName = getAttribute(node,'_name')
  sAcct = getAttribute(node,'acct')
  sAcctInfo = getAttribute(node,'acctinfo')
  sProg = getAttribute(node,'pgmr')
  sPositionals = '('sAcct','sAcctInfo'),'sProg
  sOperands = sPositionals
  call getAttributeMap node
  do i = 1 to g.!ATTRIBUTE.0
    sKey = g.!ATTRIBUTE.i
    if left(sKey,1) <> '_' & wordpos(sKey,'acct acctinfo pgmr') = 0
    then do
      sValue = g.!ATTRIBUTE.sKey
      sOperands = sOperands','toUpper(sKey)'='sValue
    end
  end
  call Say '//'left(sName,8) 'JOB ' sOperands
return

emitStatement: procedure expose g.
  parse arg node,sOper
  sName = getAttribute(node,'_name')
  if sOper = '' then sOper = toUpper(getNodeName(node))
  if length(sOper) < 3 then sOper = left(sOper,3)
  nKeywords = 0
  k. = ''
  sPositionals = getAttribute(node,'_')
  if sPositionals <> ''
  then do /* treat positionals as keyword 1 */
   nKeywords = 1
   k.1 = sPositionals
  end
  call getAttributeMap node
  do i = 1 to g.!ATTRIBUTE.0
    sKey = g.!ATTRIBUTE.i
    if left(sKey,1) <> '_' & wordpos(sKey,sIgnored) = 0
    then do
      nKeywords = nKeywords + 1
      sValue = g.!ATTRIBUTE.sKey
      k.nKeywords = toUpper(sKey)'='sValue
    end
  end
  if nKeywords <= 1
  then call Say '//'left(sName,8) sOper k.1
  else do
    sLine = '//'left(sName,8) sOper k.1','
    do i = 2 to nKeywords-1
      if length(sLine || k.i',') < 72
      then sLine = sLine || k.i','
      else do
        call Say sLine
        sLine = '//             'k.i','
      end
    end
    if length(sLine || k.nKeywords) < 72
    then call Say sLine || k.nKeywords
    else do
      call Say sLine
      call Say '//             'k.nKeywords
    end
  end
return


getKeywords: procedure expose g.
  parse arg node,sIgnored
  sPositionals = getAttribute(node,'_')
  sKeywords = ''
  call getAttributeMap node
  do i = 1 to g.!ATTRIBUTE.0
    sKey = g.!ATTRIBUTE.i
    if left(sKey,1) <> '_' & wordpos(sKey,sIgnored) = 0
    then do
      sValue = g.!ATTRIBUTE.sKey
      sKeywords = sKeywords','toUpper(sKey)'='sValue
    end
  end
  if sPositionals <> ''
  then sParameters = sPositionals || sKeywords
  else sParameters = strip(sKeywords,'LEADING',',')
return sParameters

emitChildrenOf: procedure expose g.
  parse arg node
  children = getChildNodes(node)
  do i = 1 to words(children)
    child = word(children,i)
    call emitJCL child
  end
return

setOptions: procedure expose g.
  parse arg sOptions
  /* set default options... */
  g.!OPTION.WRAP.1 = 255 /* only when WRAP option is active    */
  g.!OPTION.GRAPHML  = 1 /* Output GraphML file?               */
  g.!OPTION.XML      = 1 /* Output XML file?                   */
  g.!OPTION.JCL      = 0 /* Output JCL file?                   */
  g.!OPTION.INLINE   = 1 /* Draw instream data?                */
  g.!OPTION.SYSOUT   = 1 /* Draw DD SYSOUT=x nodes?            */
  g.!OPTION.DUMMY    = 1 /* Draw DD DUMMY nodes?               */
  g.!OPTION.TRACE    = 0 /* Trace parsing of JCL?              */
  g.!OPTION.ENCODING = 1 /* Emit encoding="xxx" in XML prolog? */
  g.!OPTION.WRAP     = 0 /* Wrap output?                       */
  if g.!ENV = 'TSO' then g.!OPTION.WRAP = 1 /* TSO is special  */
  g.!OPTION.LINE     = 0 /* Output XML _line attributes?       */
  g.!OPTION.ID       = 0 /* Output XML _id attributes?         */
  do i = 1 to words(sOptions)
    sOption = word(sOptions,i)
    if left(sOption,2) = 'NO'
    then do
      sOption = substr(sOption,3)
      g.!OPTION.sOption = 0
    end
    else do
      g.!OPTION.sOption = 1
      sNextWord = word(sOptions,i+1)                     /* 20070208 */
      if datatype(sNextWord,'WHOLE')
      then do
        g.!OPTION.sOption.1 = sNextWord
        i = i + 1
      end                                                /* 20070208 */
    end
  end
return

Prolog:
  if g.!ENV = 'TSO'
  then g.!LF = '15'x
  else g.!LF = '0A'x

  g.!UPPER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  g.!LOWER = 'abcdefghijklmnopqrstuvwxyz'

  g.!LONGEST_LINE             = 0   /* longest output line found     */

  g.!K = 0
  g.!KDELTA = 0

  g.!JCLTYPE_UNKNOWN   = 0; g.!JCLTYPE.0 = '?'
  g.!JCLTYPE_STATEMENT = 1; g.!JCLTYPE.1 = 'STMT'
  g.!JCLTYPE_DATA      = 2; g.!JCLTYPE.2 = 'DATA'
  g.!JCLTYPE_COMMENT   = 3; g.!JCLTYPE.3 = '//*'
  g.!JCLTYPE_EOJ       = 4; g.!JCLTYPE.4 = '//'
  g.!JCLTYPE_JES2CMD   = 5; g.!JCLTYPE.5 = '/*$'
  g.!JCLTYPE_JES2STMT  = 6; g.!JCLTYPE.6 = 'JES2'
  g.!JCLTYPE_JES3STMT  = 7; g.!JCLTYPE.7 = 'JES3'
  g.!JCLTYPE_OPCDIR    = 8; g.!JCLTYPE.8 = 'OPC'        /* HF 061218 */

  call setStandardColors

  /* Set up your color scheme here...*/
  g.!COLOR_WHITE        = g.!COLOR.white
  g.!COLOR_PARMS_NODE   = g.!COLOR.white
  g.!COLOR_INLINE_NODE  = g.!COLOR.white
  g.!COLOR_SHAPE_NODE   = g.!COLOR.lavender /* default shape color */
  g.!COLOR_SET_NODE     = g.!COLOR.aliceblue
  g.!COLOR_INCLUDE_NODE = g.!COLOR.whitesmoke
  g.!COLOR_IF_NODE      = g.!COLOR.gold
  g.!COLOR_JCLLIB_NODE  = g.!COLOR.lavender
  g.!COLOR_JOB_NODE     = '#ccffcc' /* light green */
  g.!COLOR_PROC_NODE    = '#e3ffe3' /* lighter green */
  g.!COLOR_EOJ_NODE     = '#ff5c5c' /* light red */
  g.!COLOR_PEND_NODE    = g.!COLOR.mistyrose
  g.!COLOR_STEP_NODE    = g.!COLOR.beige
  g.!COLOR_CONTROL_FLOW = g.!COLOR.red
  g.!COLOR_DATA_FLOW    = g.!COLOR.black
  g.!COLOR_DROP_SHADOW  = '#e0e0e0' /* very light gray */
  drop g.!COLOR.   /* we dont need these anymore */
return


setStandardColors: procedure expose g.
  /* These are the standard SVG color names in order of increasing
     brightness. The brightness value is show as a comment...*/
  g.!COLOR.black = '#000000'                    /*   0 */
  g.!COLOR.maroon = '#800000'                   /*  14 */
  g.!COLOR.darkred = '#8B0000'                  /*  15 */
  g.!COLOR.red = '#FF0000'                      /*  28 */
  g.!COLOR.navy = '#000080'                     /*  38 */
  g.!COLOR.darkblue = '#00008B'                 /*  42 */
  g.!COLOR.indigo = '#4B0082'                   /*  47 */
  g.!COLOR.firebrick = '#B22222'                /*  50 */
  g.!COLOR.midnightblue = '#191970'             /*  51 */
  g.!COLOR.purple = '#800080'                   /*  52 */
  g.!COLOR.crimson = '#DC143C'                  /*  54 */
  g.!COLOR.brown = '#A52A2A'                    /*  56 */
  g.!COLOR.darkmagenta = '#8B008B'              /*  57 */
  g.!COLOR.darkgreen = '#006400'                /*  59 */
  g.!COLOR.mediumblue = '#0000CD'               /*  62 */
  g.!COLOR.saddlebrown = '#8B4513'              /*  62 */
  g.!COLOR.orangered = '#FF4500'                /*  69 */
  g.!COLOR.mediumvioletred = '#C71585'          /*  74 */
  g.!COLOR.darkslategray = '#2F4F4F'            /*  75 */
  g.!COLOR.darkslategrey = '#2F4F4F'            /*  75 */
  g.!COLOR.green = '#008000'                    /*  76 */
  g.!COLOR.blue = '#0000FF'                     /*  77 */
  g.!COLOR.sienna = '#A0522D'                   /*  79 */
  g.!COLOR.darkviolet = '#9400D3'               /*  80 */
  g.!COLOR.deeppink = '#FF1493'                 /*  84 */
  g.!COLOR.darkslateblue = '#483D8B'            /*  86 */
  g.!COLOR.darkolivegreen = '#556B2F'           /*  87 */
  g.!COLOR.olive = '#808000'                    /*  90 */
  g.!COLOR.chocolate = '#D2691E'                /*  94 */
  g.!COLOR.forestgreen = '#228B22'              /*  96 */
  g.!COLOR.darkgoldenrod = '#B8860B'            /* 103 */
  g.!COLOR.indianred = '#CD5C5C'                /* 104 */
  g.!COLOR.fuchsia = '#FF00FF'                  /* 105 */
  g.!COLOR.magenta = '#FF00FF'                  /* 105 */
  g.!COLOR.dimgray = '#696969'                  /* 105 */
  g.!COLOR.dimgrey = '#696969'                  /* 105 */
  g.!COLOR.olivedrab = '#6B8E23'                /* 106 */
  g.!COLOR.darkorchid = '#9932CC'               /* 108 */
  g.!COLOR.tomato = '#FF6347'                   /* 108 */
  g.!COLOR.blueviolet = '#8A2BE2'               /* 108 */
  g.!COLOR.darkorange = '#FF8C00'               /* 111 */
  g.!COLOR.seagreen = '#2E8B57'                 /* 113 */
  g.!COLOR.teal = '#008080'                     /* 114 */
  g.!COLOR.peru = '#CD853F'                     /* 120 */
  g.!COLOR.darkcyan = '#008B8B'                 /* 124 */
  g.!COLOR.orange = '#FFA500'                   /* 125 */
  g.!COLOR.slateblue = '#6A5ACD'                /* 126 */
  g.!COLOR.coral = '#FF7F50'                    /* 127 */
  g.!COLOR.gray = '#808080'                     /* 128 */
  g.!COLOR.grey = '#808080'                     /* 128 */
  g.!COLOR.goldenrod = '#DAA520'                /* 131 */
  g.!COLOR.slategray = '#708090'                /* 131 */
  g.!COLOR.slategrey = '#708090'                /* 131 */
  g.!COLOR.mediumorchid = '#BA55D3'             /* 134 */
  g.!COLOR.palevioletred = '#DB7093'            /* 134 */
  g.!COLOR.royalblue = '#4169E1'                /* 137 */
  g.!COLOR.salmon = '#FA8072'                   /* 137 */
  g.!COLOR.steelblue = '#4682B4'                /* 138 */
  g.!COLOR.lightslategray = '#778899'           /* 139 */
  g.!COLOR.lightslategrey = '#778899'           /* 139 */
  g.!COLOR.lightcoral = '#F08080'               /* 140 */
  g.!COLOR.limegreen = '#32CD32'                /* 141 */
  g.!COLOR.hotpink = '#FF69B4'                  /* 144 */
  g.!COLOR.mediumseagreen = '#3CB371'           /* 146 */
  g.!COLOR.mediumslateblue = '#7B68EE'          /* 146 */
  g.!COLOR.rosybrown = '#BC8F8F'                /* 148 */
  g.!COLOR.mediumpurple = '#9370DB'             /* 148 */
  g.!COLOR.lime = '#00FF00'                     /* 150 */
  g.!COLOR.darksalmon = '#E9967A'               /* 151 */
  g.!COLOR.cadetblue = '#5F9EA0'                /* 152 */
  g.!COLOR.sandybrown = '#F4A460'               /* 152 */
  g.!COLOR.yellowgreen = '#9ACD32'              /* 153 */
  g.!COLOR.orchid = '#DA70D6'                   /* 154 */
  g.!COLOR.gold = '#FFD700'                     /* 155 */
  g.!COLOR.lightsalmon = '#FFA07A'              /* 159 */
  g.!COLOR.lightseagreen = '#20B2AA'            /* 160 */
  g.!COLOR.darkkhaki = '#BDB76B'                /* 161 */
  g.!COLOR.lawngreen = '#7CFC00'                /* 162 */
  g.!COLOR.chartreuse = '#7FFF00'               /* 164 */
  g.!COLOR.dodgerblue = '#1E90FF'               /* 165 */
  g.!COLOR.darkgray = '#A9A9A9'                 /* 169 */
  g.!COLOR.darkgrey = '#A9A9A9'                 /* 169 */
  g.!COLOR.darkseagreen = '#8FBC8F'             /* 170 */
  g.!COLOR.cornflowerblue = '#6495ED'           /* 170 */
  g.!COLOR.tan = '#D2B48C'                      /* 171 */
  g.!COLOR.burlywood = '#DEB887'                /* 173 */
  g.!COLOR.violet = '#EE82EE'                   /* 174 */
  g.!COLOR.yellow = '#FFFF00'                   /* 179 */
  g.!COLOR.mediumaquamarine = '#66CDAA'         /* 183 */
  g.!COLOR.greenyellow = '#ADFF2F'              /* 184 */
  g.!COLOR.darkturquoise = '#00CED1'            /* 184 */
  g.!COLOR.plum = '#DDA0DD'                     /* 185 */
  g.!COLOR.springgreen = '#00FF7F'              /* 189 */
  g.!COLOR.deepskyblue = '#00BFFF'              /* 189 */
  g.!COLOR.silver = '#C0C0C0'                   /* 192 */
  g.!COLOR.mediumturquoise = '#48D1CC'          /* 192 */
  g.!COLOR.lightpink = '#FFB6C1'                /* 193 */
  g.!COLOR.mediumspringgreen = '#00FA9A'        /* 194 */
  g.!COLOR.lightgreen = '#90EE90'               /* 199 */
  g.!COLOR.thistle = '#D8BFD8'                  /* 201 */
  g.!COLOR.turquoise = '#40E0D0'                /* 202 */
  g.!COLOR.lightsteelblue = '#B0C4DE'           /* 202 */
  g.!COLOR.pink = '#FFC0CB'                     /* 202 */
  g.!COLOR.khaki = '#F0E68C'                    /* 204 */
  g.!COLOR.skyblue = '#87CEEB'                  /* 207 */
  g.!COLOR.palegreen = '#98FB98'                /* 210 */
  g.!COLOR.navajowhite = '#FFDEAD'              /* 211 */
  g.!COLOR.lightgray = '#D3D3D3'                /* 211 */
  g.!COLOR.lightgrey = '#D3D3D3'                /* 211 */
  g.!COLOR.lightskyblue = '#87CEFA'             /* 211 */
  g.!COLOR.wheat = '#F5DEB3'                    /* 212 */
  g.!COLOR.peachpuff = '#FFDAB9'                /* 212 */
  g.!COLOR.palegoldenrod = '#EEE8AA'            /* 214 */
  g.!COLOR.lightblue = '#ADD8E6'                /* 215 */
  g.!COLOR.moccasin = '#FFE4B5'                 /* 217 */
  g.!COLOR.gainsboro = '#DCDCDC'                /* 220 */
  g.!COLOR.powderblue = '#B0E0E6'               /* 221 */
  g.!COLOR.bisque = '#FFE4C4'                   /* 221 */
  g.!COLOR.aqua = '#00FFFF'                     /* 227 */
  g.!COLOR.cyan = '#00FFFF'                     /* 227 */
  g.!COLOR.aquamarine = '#7FFFD4'               /* 228 */
  g.!COLOR.blanchedalmond = '#FFEBCD'           /* 228 */
  g.!COLOR.mistyrose = '#FFE4E1'                /* 230 */
  g.!COLOR.antiquewhite = '#FAEBD7'             /* 231 */
  g.!COLOR.paleturquoise = '#AFEEEE'            /* 231 */
  g.!COLOR.papayawhip = '#FFEFD5'               /* 233 */
  g.!COLOR.lavender = '#E6E6FA'                 /* 236 */
  g.!COLOR.lemonchiffon = '#FFFACD'             /* 237 */
  g.!COLOR.beige = '#F5F5DC'                    /* 238 */
  g.!COLOR.lightgoldenrodyellow = '#FAFAD2'     /* 238 */
  g.!COLOR.linen = '#FAF0E6'                    /* 238 */
  g.!COLOR.cornsilk = '#FFF8DC'                 /* 240 */
  g.!COLOR.oldlace = '#FDF5E6'                  /* 241 */
  g.!COLOR.lavenderblush = '#FFF0F5'            /* 243 */
  g.!COLOR.seashell = '#FFF5EE'                 /* 244 */
  g.!COLOR.whitesmoke = '#F5F5F5'               /* 245 */
  g.!COLOR.lightyellow = '#FFFFE0'              /* 246 */
  g.!COLOR.floralwhite = '#FFFAF0'              /* 248 */
  g.!COLOR.honeydew = '#F0FFF0'                 /* 249 */
  g.!COLOR.aliceblue = '#F0F8FF'                /* 249 */
  g.!COLOR.ghostwhite = '#F8F8FF'               /* 250 */
  g.!COLOR.ivory = '#FFFFF0'                    /* 251 */
  g.!COLOR.snow = '#FFFAFA'                     /* 251 */
  g.!COLOR.lightcyan = '#E0FFFF'                /* 252 */
  g.!COLOR.mintcream = '#F5FFFA'                /* 252 */
  g.!COLOR.azure = '#F0FFFF'                    /* 253 */
  g.!COLOR.white = '#FFFFFF'                    /* 255 */
return

Epilog: procedure expose g.
  if g.!LONGEST_LINE > g.!OPTION.WRAP.1
  then say 'JCL010W To avoid output line truncation, specify: (WRAP',
           g.!LONGEST_LINE
return

prettyPrinter: procedure expose g.
  parse arg sFileOut,g.!TAB,node
  if g.!TAB = '' then g.!TAB = 2 /* indentation amount */
  if node = '' then node = getRoot()
  g.!INDENT = 0
  g.!FILEOUT = ''
  if sFileOut <> ''
  then do
    g.!FILEOUT = openFile(sFileOut,'OUTPUT')
    if g.!rc = 0
    then say 'JCL006I Creating' sFileOut
    else do
      say 'JCL007E Could not create' sFileOut'. Writing to console...'
      g.!FILEOUT = '' /* null handle means write to console */
    end
  end
  call _setDefaultEntities
  call emitProlog
  g.!INDENT = -g.!TAB
  call showNode node
  if g.!FILEOUT <> ''
  then do
    say 'JCL008I Created' sFileOut
    rc = closeFile(g.!FILEOUT)
  end
return

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
  g.!INDENT = 0
  if g.!OPTION.ENCODING
  then call Say '<?xml version="'sVersion'"',
                     'encoding="'sEncoding'"',
                   'standalone="'sStandalone'"?>'
  else call Say '<?xml version="'sVersion'"',
                   'standalone="'sStandalone'"?>'
  sDocType = getDocType()
  if sDocType <> ''
  then call Say '<!DOCTYPE' getName(getDocumentElement()) sDocType'>'
return

showNode: procedure expose g.
  parse arg node
  g.!INDENT = g.!INDENT + g.!TAB
  select
    when isTextNode(node)    then call emitTextNode    node
    when isCommentNode(node) then call emitCommentNode node
    when isCDATA(node)       then call emitCDATA       node
    otherwise                     call emitElementNode node
  end
  g.!INDENT = g.!INDENT - g.!TAB
return

setPreserveWhitespace: procedure expose g.
  parse arg bPreserve
  g.!PRESERVEWS = bPreserve = 1
return

emitTextNode: procedure expose g.
  parse arg node
  if g.!PRESERVEWS = 1
  then call Say escapeText(getText(node))
  else call Say escapeText(removeWhitespace(getText(node)))
return

emitCommentNode: procedure expose g.
  parse arg node
  call Say '<!--'getText(node)' -->'
return

emitCDATA: procedure expose g.
  parse arg node
  sText = getText(node)
  if g.!ENV = 'TSO'                                      /* 20070118 */
  then do
    do until length(sText) = 0
      parse var sText sLine (g.!LF) sText
      call Say '<![CDATA['sLine']]>'
    end
  end
  else do                                                /* 20070118 */
    call Say '<![CDATA['sText']]>'
  end
return

/* Here we override emitElementNode in prettyPrinter.
It is done here to ensure that elements containing text nodes are
output as:

<element>text</element>

instead of:

<element>
  text
</element>

The yEd viewer considers whitespace in text nodes to be significant,
so we need to avoid introducing whitespace before and after the text
content of an element. Coding CDATA instead of text does not help.
*/
emitElementNode: procedure expose g.
  parse arg node
  sElement = getName(node)
  children = getChildNodes(node)
  nChildren = words(children)
  select
    when nChildren = 0 then do
      call emitElementAndAttributes node,'/>'
    end
    when nChildren = 1 then do
      child = children
      bIsCDATA = isCDATA(child)
      if g.!YED_FRIENDLY = 1 & (isTextNode(child) | bIsCDATA)
      then do /* for yEd: <element attrs>text</element> */
        sText = toString(child)
        if g.!OPTION.WRAP & pos(g.!LF,sText) > 0
        then do /* split lines into records */
          parse var sText sLine (g.!LF) sText
          call emitElementAndAttributes node,'>'sLine
          do until length(sText) = 0
            parse var sText sLine (g.!LF) sText
            if bIsCDATA
            then call Say sLine,0 /* suppress indentation */
            else call Say sLine
          end
          call Say '</'sElement'>',0 /* suppress indentation */
        end
        else call emitElementAndAttributes node,,
                  '>'sText'</'sElement'>'
      end
      else do
        call emitElementAndAttributes node,'>'
        call showNode child
        call Say '</'sElement'>'
      end
    end
    otherwise do
      call emitElementAndAttributes node,'>'
      child = getFirstChild(node)
      do while child <> ''
        call showNode child
        child = getNextSibling(child)
      end
      call Say '</'sElement'>'
    end
  end
return

/*
Wrap attributes to the next line if the line is getting too long.
*/
emitElementAndAttributes: procedure expose g.
  parse arg node,sTermination
  sElement = getName(node)
  nAttrs = getAttributeCount(node)
  sPad = ''
  sLine = '<'sElement
  do i = 1 to nAttrs
    sAttr = getAttributeName(node,i)'="' ||,
            escapeText(getAttribute(node,i))'"'
    nLineLength = g.!INDENT + length(sPad || sLine sAttr),
                            + length(sTermination)
    if g.!OPTION.WRAP & nLineLength > g.!OPTION.WRAP.1   /* 20070208 */
    then do
      call Say sPad || sLine
      sPad = copies(' ',length(sElement)+2)
      sLine = sAttr
    end
    else sLine = sLine sAttr
  end
  call Say sPad || sLine || sTermination
return

Say: procedure expose g.
  parse arg sText,nIndent
  if nIndent <> ''
  then sLine = copies(' ',nIndent)sText /* temporary override */
  else sLine = copies(' ',g.!INDENT)sText
  if g.!ENV = 'TSO' & length(sLine) > g.!OPTION.WRAP.1   /* 20070208 */
  then do
    say 'JCL009W Line truncated:' strip(left(sText,50),'TRAILING')'...'
    g.!LONGEST_LINE = max(g.!LONGEST_LINE,length(sLine))
  end
  if g.!FILEOUT = ''
  then say sLine
  else call putLine g.!FILEOUT,sLine
return

/*INCLUDE io.rex */
/*INCLUDE parsexml.rex */
