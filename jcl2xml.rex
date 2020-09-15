/*REXX 2.0.0
Copyright (c) 2011-2020, Andrew J. Armstrong
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
**            Language) is an XML standard for describing the nodes  **
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
**            or ooRexx from:                                        **
**                                                                   **
**               http://oorexx.sourceforge.net                       **
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
**               the Dock button to move this dialog box to the      **
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
**                                named '_id' so that it does not    **
**                                clash with the predefined 'id'     **
**                                attribute in the XML specification.**
**                                                                   **
**                       You can negate any option by prefixing it   **
**                       with NO. For example, NOXML.                **
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
**            ZA  - Ze'ev Atlas <zatlas1@yahoo.com>                  **
**            AF  - Anne.Feldmeier@partner.bmw.de                    **
**            HF  - Herbert.Frommwieser@partner.bmw.de               **
**                                                                   **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --- ----------------------------------------- **
**            20120316 AJA Return always (instead of exit)           **
**            20120315 AJA Return if called as a subroutine else     **
**                         exit.                                     **
**            20111205 AJA Corrected parsing of key=(value) operands **
**                         where value contains quoted strings.      **
**                         Added getSafeAttrName function to avoid   **
**                         generating attribute names containing     **
**                         '@', '#' or '$' characters. None is valid **
**                         in an XML attribute name so they are      **
**                         translated to uppercase 'A', 'N' and 'S'  **
**                         respectively. For example, DB# becomes dbN**
**                         Renamed deQuote to deNormalize and removed**
**                         dead code.                                **
**            20111109 AJA Added JES3 option so that NOJES3 can be   **
**                         specified to prevent comments that happen **
**                         to look like JES3 statements being parsed.**
**            20110929 AJA Prevent INCLUDE from becoming a parent of **
**                         subsequent nodes. Ideally, JCL2XML should **
**                         expand the included JCL but that is not   **
**                         currently implemented.                    **
**            20110911 AJA Clear dd for every JOB, EXEC and CNTL card**
**            20110910 AJA Fixed handling of instream data without a **
**                         preceding DD card.                        **
**            20110907 AJA Fixed handling of comments after IF, THEN **
**                         and ELSE statements.                      **
**            20110903 AJA Improved drawing of concatenated DDs.     **
**            20110903 ZA  Fixed getFileWithoutExtension to work when**
**                         dots are present in the path name.        **
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
**                         g.0MAX_OUTPUT_LINE_LENGTH and the         **
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
**            20070117 AF  Initialize g.0RC                          **
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

jcl2xml:
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
    return
  end
  say 'JCL001I Scanning job control in' sFileIn

  sOptions = 'NOBLANKS' toUpper(sOptions)
  call initParser sOptions /* <-- This is in PARSEXML rexx */

  g.0VERSION = sVersion
  parse source g.0ENV .
  if g.0ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.0LINES = 0
  end

  call setFileNames sFileIn,sFileOut
  call setOptions sOptions
  call Prolog

  gDoc = createDocument('graphml')

  call scanJobControlFile

  if g.0OPTION.GRAPHML
  then do
    call buildGraphML
    g.0YED_FRIENDLY = 1
    call prettyPrinter g.0FILEGML
  end

  if g.0OPTION.DUMP
  then call _displayTree

  if g.0OPTION.XML
  then do
    call setDocType /* we don't need a doctype declaration */
    call setPreserveWhitespace 1 /* retain spaces in JCL comments */
    if g.0OPTION.LINE = 0                                /* 20070130 */
    then call removeAttributes '_line',g.0JCL
    if g.0OPTION.ID = 0                                  /* 20070130 */
    then call removeAttributes '_id',g.0JCL
    call rearrangeComments
    g.0YED_FRIENDLY = 0
    call prettyPrinter g.0FILEXML,,g.0JCL
  end

  if g.0OPTION.JCL
  then do
    call prettyJCL g.0FILEJCL,g.0JCL
  end

  call Epilog
  say 'JCL002I Done'
return


/* The JobControl input filename is supplied by the user.
The names of the XML and GRAPHML output files are automatically
generated from the input file filename. The generated file names also
depend on the operating system. Global variables are set as follows:
g.0FILETXT = name of input text file  (e.g. JobControl.txt)
g.0FILEGML = name of output GraphML file  (e.g. JobControl.graphml)
g.0FILEXML = name of output XML file  (e.g. JobControl.xml)
g.0FILEJCL = name of output JCL file  (e.g. JobControl.jcl)
*/
setFileNames: procedure expose g.
  parse arg sFileIn,sFileOut
  if sFileOut = '' then sFileOut = sFileIn
  if g.0ENV = 'TSO'
  then do
    g.0FILETXT = toUpper(sFileIn)
    parse var sFileOut sDataset'('sMember')'
    if pos('(',sFileOut) > 0 /* if member name notation used */
    then do /* output to members in the specified PDS */
      if sMember = '' then sMember = 'JCL'
      sPrefix = strip(left(sMember,7)) /* room for a suffix char */
      sPrefix = toUpper(sPrefix)
      /* squeeze the file extension into the member name...*/
      g.0FILEGML = sDataset'('strip(left(sPrefix'GML',8))')'
      g.0FILEXML = sDataset'('strip(left(sPrefix'XML',8))')'
      g.0FILEJCL = sDataset'('strip(left(sPrefix'JCL',8))')'
    end
    else do /* make output files separate datasets */
      g.0FILEGML = sDataset'.GRAPHML'
      g.0FILEXML = sDataset'.XML'
      g.0FILEJCL = sDataset'.JCL'
    end
  end
  else do
    sFileName  = getFilenameWithoutExtension(sFileOut)
    g.0FILETXT = sFileIn
    g.0FILEGML = sFileName'.graphml'
    g.0FILEXML = sFileName'.xml'
    g.0FILEJCL = sFileName'.jcl'
  end
return

getFilenameWithoutExtension: procedure expose g.
  parse arg sFile
  nLastDot = lastpos('.',sFile)
  /*ZA deal with dir with dot, file w/o dot */
  nLastSlash = lastpos('\',sFile)
  if nLastSlash = 0
  then nLastSlash = lastpos('/',sFile) 
   
  if nLastSlash > nLastDot
  then sFileName = sFile 
  else do
  /*ZA end */
    if nLastDot > 1
    then sFileName = substr(sFile,1,nLastDot-1)
    else sFileName = sFile
  end
return sFileName

initStack: procedure expose g.
  g.0T = 0              /* set top of stack index */
return

pushStack: procedure expose g.
  parse arg item
  tos = g.0T + 1        /* get new top of stack index */
  g.0E.tos = item       /* set new top of stack item */
  g.0T = tos            /* set new top of stack index */
return

popStack: procedure expose g.
  tos = g.0T            /* get top of stack index for */
  item = g.0E.tos       /* get item at top of stack */
  g.0T = max(tos-1,1)
return item

peekStack: procedure expose g.
  tos = g.0T            /* get top of stack index */
  item = g.0E.tos       /* get item at top of stack */
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
  g.0JCL = createDocumentFragment('jcl')
  call setAttribute g.0JCL,'src',g.0FILETXT
  call appendAuthor g.0JCL
  g.0STMTID = 0 /* unique statement id */
  parent = g.0JCL
  call pushStack parent
  g.0FILEIN = openFile(g.0FILETXT)
  g.0JCLLINE = 0   /* current line number in the JCL */
  g.0DELIM = '/*'  /* current end-of-data delimiter */
  g.0JCLDATA.0 = 0    /* current number of lines of inline data */
  g.0PENDING_STMT = ''
  dd = '' /* DD associated with any inline data */
  call getStatement /* returns data in g.0JCLxxxx variables */
  if g.0OPTION.TRACE                                     /* 20070130 */
  then say ' Stmt  Line Type Name     Op       Operands'
  do nStmt = 1 while g.0RC = 0 & g.0JCLTYPE <> g.0JCLTYPE_EOJ
    if g.0OPTION.TRACE then call sayTrace nStmt
    select
      when g.0JCLTYPE = g.0JCLTYPE_STATEMENT then do
        stmt = newStatementNode()
        select
          when g.0JCLOPER = 'IF' then do
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
          when g.0JCLOPER = 'ELSE' then do
            parent = popUntil('if')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.0JCLOPER = 'ENDIF' then do
            parent = popUntil('if')
            if g.0JCLNAME <> ''                          /* 20070130 */
            then call setAttribute parent,'_endname',g.0JCLNAME
            if g.0JCLCOMM <> ''                          /* 20070130 */
            then call setAttribute parent,'_endcomm',g.0JCLCOMM
            parent = popStack() /* discard 'if' */
          end
          when g.0JCLOPER = 'JOB' then do
            dd = ''
            parent = popUntil('jcl')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.0JCLOPER = 'JCLLIB' then do
            parent = popUntil('job')
            call appendChild stmt,parent
            parse var g.0JCLPARM 'ORDER='sOrder .
            if left(sOrder,1) = '('
            then parse var sOrder '('sOrder')'
            sOrder = translate(sOrder,'',',')
            g.0ORDER.0 = 0
            do j = 1 to words(sOrder)
              g.0ORDER.j = word(sOrder,j)
              g.0ORDER.0 = j
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
          when g.0JCLOPER = 'INCLUDE' then do
            /* TODO: Replace this with the actual included text */
            parent = popUntil('step proc job')
            call appendChild stmt,parent
          end
          when g.0JCLOPER = 'PROC' then do
            parent = peekStack()
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.0JCLOPER = 'PEND' then do
            parent = popUntil('proc')
            parent = popStack() /* discard 'proc' */
          end
          when g.0JCLOPER = 'CNTL' then do
            dd = ''
            parent = popUntil('step proc job')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.0JCLOPER = 'ENDCNTL' then do
            parent = popUntil('cntl')
            parent = popStack() /* discard 'cntl' */
          end
          when g.0JCLOPER = 'EXEC' then do
            dd = ''
            parent = popUntil('proc job then else')
            call appendChild stmt,parent
            call pushStack stmt
          end
          when g.0JCLOPER = 'DD' then do
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
          when g.0JCLOPER = 'SET' then do
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
        sLastOper = g.0JCLOPER
      end
      when g.0JCLTYPE = g.0JCLTYPE_DATA then do
        if dd = '' /* inline data without a preceding dd */
        then do /* auto-generate a SYSIN DD statement */
          g.0STMTID = g.0STMTID + 1
          dd = newElement('dd','_id',g.0STMTID,,
                               '_line',g.0JCLLINE,,
                               '_name','SYSIN',,
                               '_','*',,
                               '_comment','GENERATED STATEMENT')
          parent = popUntil('cntl step proc job')
          call appendChild dd,parent
          call pushStack dd
        end
        call appendChild getInlineDataNode(),dd
        g.0JCLDATA.0 = 0                                 /* 20070124 */
      end
      when g.0JCLTYPE = g.0JCLTYPE_COMMENT then do
        if nLastStatementType <> g.0JCLTYPE_COMMENT
        then do /* group multiple comment lines together */
          comment = newElement('comment','_line',g.0JCLLINE)
          parent = popUntil('step proc job dd if then else') /* 20110907 */
          call appendChild comment,parent
        end
        call appendChild createTextNode(g.0JCLCOMM),comment
      end
      when g.0JCLTYPE = g.0JCLTYPE_JES2CMD then do
        stmt = newStatementNode()
        parent = peekStack()
        call appendChild stmt,parent
      end
      when g.0JCLTYPE = g.0JCLTYPE_JES2STMT then do
        stmt = newStatementNode()
        parent = peekStack()
        call appendChild stmt,parent
      end
      when g.0JCLTYPE = g.0JCLTYPE_JES3STMT then do
        stmt = newStatementNode()
        parent = peekStack()
        call appendChild stmt,parent
      end
      when g.0JCLTYPE = g.0JCLTYPE_OPCDIR  then do      /* HF 061218 */
        stmt = newStatementNode()
        parent = peekStack()
        call appendChild stmt,parent
      end                                               /* HF 061218 */
      when g.0JCLTYPE = g.0JCLTYPE_EOJ then nop
      otherwise do /* should not occur (famous last words) */
        say 'JCL003E Unknown statement on line' g.0JCLLINE':',
            '"'g.0JCLOPER g.0JCLPARM'"'
      end
    end
    nLastStatementType = g.0JCLTYPE
    call getStatement
  end
  if g.0JCLDATA.0 > 0 /* dump any pending sysin before eof reached */
  then do
    call appendChild getInlineDataNode(),dd
  end
  rc = closeFile(g.0FILEIN)
  say 'JCL004I Processed' g.0K-1 'JCL statements'
return

sayTrace: procedure expose g.
  parse arg nStmt
  select
    when g.0JCLTYPE = g.0JCLTYPE_COMMENT then do
      call sayTraceLine nStmt,g.0JCLLINE,g.0JCLCOMM
    end
    when g.0JCLTYPE = g.0JCLTYPE_DATA then do
      nLine = g.0JCLLINE - g.0JCLDATA.0
      do i = 1 to g.0JCLDATA.0
        call sayTraceLine nStmt,nLine,g.0JCLDATA.i
        nLine = nLine + 1
      end
    end
    otherwise do
      call sayTraceLine nStmt,g.0JCLLINE,,
           left(g.0JCLNAME,8) left(g.0JCLOPER,8) g.0JCLPARM
    end
  end
return

sayTraceLine: procedure expose g.
  parse arg nStmt,nLine,sData
  nType = g.0JCLTYPE
  sType = g.0JCLTYPE.nType
  say left(right(nStmt,5) right(nLine,5) left(sType,4) sData,79)
return

appendAuthor: procedure expose g.
  parse arg node
  comment = createComment('Created by JCL to XML Converter' g.0VERSION)
  call appendChild comment,node
  comment = createComment('by Andrew J. Armstrong',
                          '(androidarmstrong@gmail.com)')
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
  steps = getElementsByTagName(g.0JCL,'step')
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
g.0JCLLINE   = the line number of the first card of the statement
g.0JCLTYPE   = the type of statement as follows:
               g.0JCLTYPE_UNKNOWN    - An unknown statement
               g.0JCLTYPE_STATEMENT  - A JCL statement
               g.0JCLTYPE_DATA       - Instream data (see below)
               g.0JCLTYPE_COMMENT    - A comment card
               g.0JCLTYPE_EOJ        - An end-of-job card
               g.0JCLTYPE_JES2CMD    - A JES2 command
               g.0JCLTYPE_JES2STMT   - A JES2 statement
               g.0JCLTYPE_JES3STMT   - A JES3 statement
               g.0JCLTYPE_OPCDIR     - An OPC directive
g.0JCLNAME   = the statement name field (e.g. a dd name)
g.0JCLOPER   = the statement operation field (e.g. DD)
g.0JCLPARM   = the statement parameters (e.g. DISP=SHR etc)
g.0JCLCOMM   = any comment following the statement, or the entire
               comment text if this is a comment card
One or more instream data cards are treated as a single pseudo-statement
with g.0JCLTYPE set to g.0JCLTYPE_DATA and the cards returned in an
array as follows:
g.0JCLDATA.0 = the number of instream data cards
g.0JCLDATA.n = instream data card 'n' (n = 1 to g.0JCLDATA.0)
*/
getStatement: procedure expose g.
  g.0JCLTYPE = g.0JCLTYPE_UNKNOWN
  g.0JCLNAME = ''  /* Statement label     */
  g.0JCLOPER = ''  /* Statement operation */
  g.0JCLCOMM = ''  /* Statement comment   */
  g.0RC      = 0                                        /* AF 061018 */
  /* The following kludge handles the case where a JCL author
     omits the end-of-data delimiter from inline data (instead the
     next statement terminates the inline data). When this happens we
     have already read the next statement, so we need to remember it
     and process it the next time 'getStatement' is called.
  */
  if g.0PENDING_STMT <> ''
  then do
    sLine = g.0PENDING_STMT
    g.0PENDING_STMT = ''
  end
  else sLine = getNextLine()
  parse var sLine 1 s2 +2 1 s3 +3
  select
    when s2 = '/*' & substr(sLine,3,1) <> ' ' then do
      if substr(sLine,3,1) = '$'
      then do
        parse var sLine '/*$'sJesCmd','sJesParms
        g.0JCLTYPE = g.0JCLTYPE_JES2CMD
        g.0JCLOPER = sJesCmd
        g.0JCLPARM = sJesParms
      end
      else do
        parse var sLine '/*'sJesStmt sJesParms
        g.0JCLTYPE = g.0JCLTYPE_JES2STMT
        g.0JCLOPER = sJesStmt
        g.0JCLPARM = sJesParms
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
          g.0JCLTYPE = g.0JCLTYPE_OPCDIR
          g.0JCLOPER = sOpcStmt
          g.0JCLPARM = sOpcParms
        end
        when isJes3Statement(sWord) then do /* JES3 statement        */
          parse var sLine '//*'sJesStmt sJesParms
          g.0JCLTYPE = g.0JCLTYPE_JES3STMT
          g.0JCLOPER = sJesStmt
          g.0JCLPARM = sJesParms
        end
        otherwise do                      /* Comment                 */
          g.0JCLTYPE = g.0JCLTYPE_COMMENT
          g.0JCLCOMM = substr(sLine,4)
        end
      end
    end                                                 /* HF 061218 */
    when sLine = '//' then do
      g.0JCLTYPE = g.0JCLTYPE_EOJ
    end
    when s2 = '//' then do
      sName = ''
      if substr(sLine,3,1) = ' '
      then parse var sLine '//'      sOper sParms
      else parse var sLine '//'sName sOper sParms
      g.0JCLTYPE = g.0JCLTYPE_STATEMENT
      g.0JCLNAME = sName
      g.0JCLOPER = sOper
      select                                             /* 20070130 */
        when sOper = 'IF' then do
          /* IF has its own continuation rules */
          do while g.0RC = 0 & pos('THEN',sParms) = 0
             sLine = getNextLine()
             parse var sLine '//' sThenContinued
             sParms = sParms strip(sThenContinued)
          end
          parse var sParms sParms 'THEN' sComment
          g.0JCLPARM = strip(sParms)
          g.0JCLCOMM = sComment                          /* 20070128 */
        end
        when sOper = 'ELSE' | sOper = 'ENDIF' then do    /* 20070130 */
          g.0JCLPARM = ''
          g.0JCLCOMM = strip(sParms)
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
          g.0INSTRING = 0 /* for detecting continued quoted strings */
          sParms = getNormalized(sParms)
          parse var sParms sParms sComment
          g.0JCLPARM = sParms
          do while g.0RC = 0 & pos(right(sParms,1),'ff'x',') > 0
            sLine = getNextLine()
            do while g.0RC = 0 & left(sLine,3) = '//*'
              sLine = getNextLine()
            end
            if g.0RC = 0
            then do
              parse var sLine '//'       sParms
              sParms = getNormalized(sParms)
              parse var sParms sParms sComment
              g.0JCLPARM = g.0JCLPARM || sParms
            end
          end
          if sOper = 'DD' & pos('DLM=',g.0JCLPARM) > 0
          then parse var g.0JCLPARM 'DLM=' +4 g.0DELIM +2
          g.0JCLCOMM = sComment                          /* 20070128 */
        end
      end
    end
    otherwise do
      g.0JCLTYPE = g.0JCLTYPE_DATA
      g.0JCLPARM = ''
      n = 0
      do while g.0RC = 0 & \isEndOfData(s2)
        n = n + 1
        g.0JCLDATA.n = strip(sLine,'TRAILING')
        sLine = getNextLine()
        parse var sLine 1 s2 +2
      end
      if g.0DELIM = '/*' & s2 = '//' /* end-of-data marker omitted */
      then g.0PENDING_STMT = sLine
      g.0JCLDATA.0 = n
      g.0DELIM = '/*'  /* reset EOD delimiter to the default */
    end
  end
  g.0K = g.0K + 1
  g.0KDELTA = g.0KDELTA + 1
  if g.0KDELTA >= 100
  then do
    say 'JCL005I Processed' g.0K 'statements'
    g.0KDELTA = 0
  end
return

isJes3Statement: procedure expose g.
  arg sStmt
  if \g.0OPTION.JES3 then return 0 
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
  do i = 1 to length(sLine) until c = ' ' & \g.0INSTRING
    c = substr(sLine,i,1)
    select
      when c = "'" & g.0INSTRING then g.0INSTRING = 0
      when c = "'" then g.0INSTRING = 1
      when c = ' ' & g.0INSTRING then c = 'ff'x
      otherwise nop
    end
    sNormalized = sNormalized || c
  end
  if i <= length(sLine)
  then do
    if g.0INSTRING /* make trailing blanks 'hard' blanks */
    then sNormalized = sNormalized ||,
                       translate(substr(sLine,i),'ff'x,' ')
    else sNormalized = sNormalized || substr(sLine,i)
  end
return strip(sNormalized)

isEndOfData: procedure expose g.
  parse arg s2
  bEOD =  g.0DELIM = s2,
       | (g.0DELIM = '/*' & s2 = '//')
return bEOD

getInlineDataNode: procedure expose g.
  sLines = ''
  do n = 1 to g.0JCLDATA.0
    sLines = sLines || g.0JCLDATA.n || g.0LF
  end
return createCDATASection(sLines)

newPseudoStatementNode: procedure expose g.
  parse arg sName
  g.0STMTID = g.0STMTID + 1
  stmt = newElement(sName,'_id',g.0STMTID)
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
  g.0STMTID = g.0STMTID + 1
  select
    when g.0JCLTYPE = g.0JCLTYPE_JES2CMD then do
      stmt = newElement('jes2cmd',,
                        '_id',g.0STMTID,,
                        '_line',g.0JCLLINE,,
                        'cmd',g.0JCLOPER,,
                        'parm',strip(g.0JCLPARM))
      return stmt
    end
    when g.0JCLTYPE = g.0JCLTYPE_JES2STMT then do
      stmt = newElement('jes2stmt',,
                       '_id',g.0STMTID,,
                        '_line',g.0JCLLINE,,
                       'stmt',g.0JCLOPER)
      call getParmMap g.0JCLPARM
      call setParms stmt
      return stmt
    end
    when g.0JCLTYPE = g.0JCLTYPE_JES3STMT then do
      stmt = newElement('jes3stmt',,
                       '_id',g.0STMTID,,
                        '_line',g.0JCLLINE,,
                       'stmt',g.0JCLOPER)
      call getParmMap g.0JCLPARM
      call setParms stmt
      return stmt
    end
    when g.0JCLTYPE = g.0JCLTYPE_OPCDIR  then do        /* HF 061218 */
      stmt = newElement('opcdir',,
                       '_id',g.0STMTID,,
                        '_line',g.0JCLLINE,,             /* 20070214 */
                        'cmd',g.0JCLOPER,,
                        'parm',strip(g.0JCLPARM))
      return stmt
    end                                                 /* HF 061218 */
    otherwise nop
  end
  if g.0JCLOPER = 'EXEC'
  then stmt = newElement('step')
  else stmt = newElement(toLower(g.0JCLOPER))
  call setAttributes stmt,'_id',g.0STMTID,,
                        '_line',g.0JCLLINE
  if g.0JCLNAME <> ''
  then call setAttribute stmt,'_name',g.0JCLNAME
  if g.0JCLCOMM <> ''                                    /* 20070128 */
  then call setAttribute stmt,'_comment',strip(g.0JCLCOMM)

  call getParmMap g.0JCLPARM
  sNodeName = getNodeName(stmt)
  select
    when sNodeName = 'if' then do
      call setAttributes stmt,'cond',space(g.0JCLPARM)
    end
    when sNodeName = 'set' then do
      /* //name  SET   var=value[,var=value]... comment */
      do i = 1 to g.0PARM.0
        sKey = translate(g.0PARM.i)
        var = newElement('var','name',sKey,,
                               'value',getParm(g.0PARM.i),,
                               '_line',g.0JCLLINE)
        call appendChild var,stmt
      end
      /* apply any comment to the last variable */
      if g.0JCLCOMM <> ''
      then call setAttribute var,'_comment',strip(g.0JCLCOMM)
    end
    when sNodeName = 'step' then do
      bPgm     = 0
      bProc    = 0
      do i = 1 to g.0PARM.0
        bPgm  = bPgm  | g.0PARM.i = 'pgm'
        bProc = bProc | g.0PARM.i = 'proc'
      end
      if \bPgm & \bProc
      then do
        sKey = '_' /* the name for positional parameters */
        sPositionals = g.0PARM.sKey
        sKey = 'proc'
        g.0PARM.1 = sKey
        g.0PARM.sKey = sPositionals
      end
      do i = 1 to g.0PARM.0
        sKey   = g.0PARM.i
        call setAttribute stmt,getSafeAttrName(sKey),getParm(sKey)
      end
    end
    when sNodeName = 'job' then do
      do i = 1 to g.0PARM.0
        sKey   = g.0PARM.i
        if sKey = '_'
        then do /* [(acct,info)][,programmer] */
                /* [acct][,programmer] */
          sPositionals = g.0PARM.sKey
          if left(sPositionals,1) = '('
          then parse var sPositionals '('sAcctAndInfo'),'sProg
          else parse var sPositionals sAcctAndInfo','sProg
          parse var sAcctAndInfo sAcct','sInfo
          call setAttributes stmt,'acct',deNormalize(sAcct),,
                                  'acctinfo',deNormalize(sInfo),,
                                  'pgmr',deNormalize(sProg)
        end
        else do
          call setAttribute stmt,getSafeAttrName(sKey),getParm(sKey)
        end
      end
    end
    otherwise call setParms stmt
  end
return stmt

getSafeAttrName: procedure expose g.
  parse arg sAttrName
return translate(sAttrName,'ANS','@#$')

setParms: procedure expose g.
  parse arg stmt
  do i = 1 to g.0PARM.0
    sKey = g.0PARM.i
    call setAttribute stmt,sKey,getParm(sKey)
  end
return

getParm: procedure expose g.
  parse arg sKey
return deNormalize(g.0PARM.sKey)

deNormalize: procedure expose g.
  parse arg sValue
return translate(sValue,' ','ff'x)

/*
  Parameters consist of positional keywords followed by key=value
  pairs. Values can be bracketed or quoted. For example:
    <---------------parms--------------->
    A,(B,C),'D E,F',G=H,I=(J,K),L='M,N O'
    <--positional--><------keywords----->
  This routine parses parameters into stem variables as follows:
  g.0PARM.0 = number of parameters
  g.0PARM.n = key for parameter n
  g.0PARM.key = value for parameter called 'key'
  ...where n = 1 to the number of parameters.
  A special parameter key called '_' is used for positionals.
  Using the above example:
  g.0PARM.0 = 4
  g.0PARM.1 = '_'; g.0PARM._ = "A,(B,C),'D E,F'"
  g.0PARM.2 = 'G'; g.0PARM.G = 'H'
  g.0PARM.3 = 'I'; g.0PARM.I = '(J,K)'
  g.0PARM.4 = 'L'; g.0PARM.L = "'M,N O'"
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
      g.0PARM.nParm = sKey
      g.0PARM.sKey = sParms
      sParms = ''
    end
    when nComma > 0 & nComma < nEquals then do
      nPos = lastpos(',',sParms,nEquals)
      sPositionals = left(sParms,nPos-1)
      nParm = nParm + 1
      sKey = '_'
      g.0PARM.nParm = sKey
      g.0PARM.sKey = sPositionals
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
    g.0PARM.nParm = sKey
    g.0PARM.sKey = sValue
  end
  g.0PARM.0 = nParm
return

/* (abc) --> 5 */
/* ('abc') --> 7 */ 
getInBracketsLength: procedure expose g.
  parse arg sValue
  bInString = 0
  nLvl = 0
  do i = 1 to length(sValue) until nLvl = 0
    c = substr(sValue,i,1)
    select
      when c = '(' & \bInString then nLvl = nLvl + 1
      when c = ')' & \bInString then nLvl = nLvl - 1
      when c = "'" then bInString = \bInString
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
return translate(sText,g.0LOWER,g.0UPPER)

toUpper: procedure expose g.
  parse upper arg sText
return sText

getNextLine: procedure expose g.
  sLine = left(getLine(g.0FILEIN),71)
  g.0JCLLINE = g.0JCLLINE + 1
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

  g.0GRAPH = newElement('graph',,
                     'id','G',,
                      'edgedefault','directed')

  call appendChild g.0GRAPH,gDoc

  call drawBlock g.0JCL

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
  gNodes = getElementsByTagName(g.0GRAPH,'node')
  gEdges = getElementsByTagName(g.0GRAPH,'edge')
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
  g.0STMTID = g.0STMTID + 1
  gEndIf = newElement('node','id','n'g.0STMTID)
  call appendChild gEndIf,g.0GRAPH
return gEndIf

newControlFlowLine: procedure expose g.
  gLineStyle = newElement('y:LineStyle',,
                          'type','line',,
                          'width',3,,
                          'color',g.0COLOR_CONTROL_FLOW)
return gLineStyle

newJobNode: procedure expose g.
  parse arg job
  sLabel = 'JOB' || g.0LF || getAttribute(job,'_name')
  gGeometry = newElement('y:Geometry','width',70,'height',70)
  gFill = newElement('y:Fill','color',g.0COLOR_JOB_NODE)
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
      g.0DSN.sDSN = gDD
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
  gFill = newElement('y:Fill','color',g.0COLOR_EOJ_NODE)
  gNodeLabel = newElement('y:NodeLabel',,
                          'fontSize',14,,
                          'textColor',g.0COLOR_WHITE)
  call appendChild createTextNode('EOJ'),gNodeLabel
  eoj = newPseudoStatementNode('eoj')
  gEndOfJob = newShapeNode(eoj,,'octagon',gFill,gGeometry,gNodeLabel)
return gEndOfJob

newProcNode: procedure expose g.
  parse arg proc
  sLabel = 'PROC' || g.0LF || getAttribute(proc,'_name')
  gGeometry = newElement('y:Geometry','width',100,'height',34)
  gFill = newElement('y:Fill','color',g.0COLOR_PROC_NODE)
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
  do i = 1 to g.0ATTRIBUTE.0
    sKey = g.0ATTRIBUTE.i
    if wordpos(sKey,'_id _name _line _comment' sIgnoredParms) = 0
    then do
      sVal = g.0ATTRIBUTE.sKey
      sLabel = sLabel || g.0LF || toUpper(sKey)'='sVal
    end
  end
  if sLabel = '' then return '' /* no parms worth mentioning */
  sLabel = strip(sLabel,'LEADING',g.0LF)
  parms = newPseudoStatementNode('parms')
  gBorderStyle = newElement('y:BorderStyle','type','dashed')
  gFill = newElement('y:Fill','color',g.0COLOR_PARMS_NODE)
  gNode = newShapeNode(parms,sLabel,'roundrectangle',,
                      gBorderStyle,gFill)
return gNode

newEndOfProcNode: procedure expose g.
  gGeometry = newElement('y:Geometry','width',100,'height',34)
  gFill = newElement('y:Fill','color',g.0COLOR_PEND_NODE)
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
  gFill = newElement('y:Fill','color',g.0COLOR_IF_NODE)
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
  gFill = newElement('y:Fill','color',g.0COLOR_STEP_NODE)
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
          if g.0OPTION.SYSOUT
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
          if g.0OPTION.INLINE
          then do
            gDD = newInlineNode(dd)
            call newArrow gDD,gStep,sDDName
          end
        end
        when isDummyFile(dd) then do
          if g.0OPTION.DUMMY
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
    if pos(g.0LF,sLabel) > 0
    then gText = createCDataSection(sLabel)
    else gText = createTextNode(sLabel)
    call appendChild gText,gNodeLabel
    call appendChild gNodeLabel,gShapeNode
  end
  if wordpos('y:DropShadow',sPropertiesAlreadySet) = 0
  then do
    gDropShadow = newElement('y:DropShadow',,
                             'offsetX',4,'offsetY',4,,
                             'color',g.0COLOR_DROP_SHADOW)
    call appendChild gDropShadow,gShapeNode
  end
  if wordpos('y:Fill',sPropertiesAlreadySet) = 0
  then do
    gFill = newElement('y:Fill','color',g.0COLOR_SHAPE_NODE)
    call appendChild gFill,gShapeNode
  end
  call appendChild gNode,g.0GRAPH
return gNode

getFileNode: procedure expose g.
  parse arg dd
  sDSN = getAttribute(dd,'dsn')
  if g.0DSN.sDSN = '' /* if file is not already in graph */
  then do /* create a new file node and add it to the graph */
    gDD = newFileNode(dd)
    g.0DSN.sDSN = gDD
  end
  else do /* use existing file node in graph */
    gDD = g.0DSN.sDSN
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
  /* Get any concatenated dataset names too */
  dds = getChildrenByName(dd,'dd')
  if dds <> '' 
  then do
    sDataset = getAttribute(dd,'dsn')
    if sDataset = '' 
    then sLabel = getCDataLines(dd, '+0')
    else sLabel = '+0' sDataset
    do i = 1 to words(dds)
      concatdd = word(dds,i)
      sDataset = getAttribute(concatdd,'dsn')
      if sDataset = '' 
      then sLabel = sLabel || g.0LF || getCDataLines(concatdd, '+'i)
      else sLabel = sLabel || g.0LF || '+'i sDataset
    end
  end
  else sLabel = getAttribute(dd,'dsn')
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
 If this dd contains only inline data, then show it as a block.
 If this dd contains a mix of inline data and concatenated dds, then
 show it as a new file node (see newFileNode).
 */
newInlineNode: procedure expose g.
  parse arg dd
  if isConcatenatedFile(dd)
  then return newFileNode(dd)
  sLabel = getCDataLines(dd, '')
  parse value getLabelDimension(sLabel) with nChars','nLines
  gGeometry = newTextGeometry(nChars,nLines)
  gFill = newElement('y:Fill','color',g.0COLOR_INLINE_NODE)
  gNode = newShapeNode(dd,sLabel,,gGeometry,gFill)
return gNode

getCDataLines: procedure expose g.
  parse arg dd,sPrefix
  bPrefix = sPrefix <> ''
  sLines = ''
  sPad = copies(' ',length(sPrefix))
  if bPrefix then sPrefix = sPrefix '| '
  line = getFirstChild(dd)
  do while line <> '' & isCDATA(line) 
    sData = getText(line)
    if pos(g.0LF,sData) > 0
    then do until sData = ''
      parse var sData sLine (g.0LF) sData
      sLines = sLines || sPrefix || sLine || g.0LF
      if bPrefix 
      then sPrefix = sPad '| '
      else sPrefix = ''
    end
    else sLines = sLines || sPrefix || sData || g.0LF 
    sPrefix = sPad
    line = getNextSibling(line)
  end
  sLines = strip(sLines,'BOTH',g.0LF)
return sLines

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
  sLabel = translate(sOrder,g.0LF,',')
  gBorderStyle = newElement('y:BorderStyle','type','dashed')
  gFill = newElement('y:Fill','color',g.0COLOR_JCLLIB_NODE)
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
    sLabel = sLabel || g.0LF || 'SET' sName'='sValue
  end
  gFill = newElement('y:Fill','color',g.0COLOR_SET_NODE)
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
  gFill = newElement('y:Fill','color',g.0COLOR_INCLUDE_NODE)
  gNode = newShapeNode(include,sLabel,,gFill)
return gNode

getLabelDimension: procedure expose g.
  parse arg sLabel
  if pos(g.0LF,sLabel) > 0
  then do /* compute dimensions of a multi-line label */
    nChars = 10 /* minimum width */
    do nLines = 1 by 1 until length(sLabel) = 0
      parse var sLabel sLine (g.0LF) sLabel
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
  call appendChild gNode,g.0GRAPH
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
  call appendChild gEdge,g.0GRAPH
return gEdge

prettyJCL: procedure expose g.
  parse arg sFileOut,node
  g.0FILEOUT = ''
  g.0INDENT = 0
  if sFileOut <> ''
  then do
    g.0FILEOUT = openFile(sFileOut,'OUTPUT')
    if g.0rc = 0
    then say 'JCL011I Creating' sFileOut
    else do
      say 'JCL012E Could not create' sFileOut'. Writing to console...'
      g.0FILEOUT = '' /* null handle means write to console */
    end
  end
  call emitJCL node
  if g.0FILEOUT <> ''
  then do
    say 'JCL013I Created' sFileOut
    rc = closeFile(g.0FILEOUT)
  end
return

emitJCL: procedure expose g.
  parse arg node
  if isCommentNode(node) then return /* ignore XML comments */
  if isCDATA(node)
  then do
    call Say strip(getText(node),'TRAILING',g.0LF)
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
  do i = 1 to g.0ATTRIBUTE.0
    sKey = g.0ATTRIBUTE.i
    if left(sKey,1) <> '_' & wordpos(sKey,'acct acctinfo pgmr') = 0
    then do
      sValue = g.0ATTRIBUTE.sKey
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
  do i = 1 to g.0ATTRIBUTE.0
    sKey = g.0ATTRIBUTE.i
    if left(sKey,1) <> '_' & wordpos(sKey,sIgnored) = 0
    then do
      nKeywords = nKeywords + 1
      sValue = g.0ATTRIBUTE.sKey
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
  do i = 1 to g.0ATTRIBUTE.0
    sKey = g.0ATTRIBUTE.i
    if left(sKey,1) <> '_' & wordpos(sKey,sIgnored) = 0
    then do
      sValue = g.0ATTRIBUTE.sKey
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
  g.0OPTION.WRAP.1 = 255 /* only when WRAP option is active    */
  g.0OPTION.GRAPHML  = 1 /* Output GraphML file?               */
  g.0OPTION.XML      = 1 /* Output XML file?                   */
  g.0OPTION.JCL      = 0 /* Output JCL file?                   */
  g.0OPTION.INLINE   = 1 /* Draw instream data?                */
  g.0OPTION.SYSOUT   = 1 /* Draw DD SYSOUT=x nodes?            */
  g.0OPTION.DUMMY    = 1 /* Draw DD DUMMY nodes?               */
  g.0OPTION.TRACE    = 0 /* Trace parsing of JCL?              */
  g.0OPTION.ENCODING = 1 /* Emit encoding="xxx" in XML prolog? */
  g.0OPTION.WRAP     = 0 /* Wrap output?                       */
  if g.0ENV = 'TSO' then g.0OPTION.WRAP = 1 /* TSO is special  */
  g.0OPTION.LINE     = 0 /* Output XML _line attributes?       */
  g.0OPTION.ID       = 0 /* Output XML _id attributes?         */
  g.0OPTION.JES3     = 1 /* Process JES3 statements?           */
  do i = 1 to words(sOptions)
    sOption = word(sOptions,i)
    if left(sOption,2) = 'NO'
    then do
      sOption = substr(sOption,3)
      g.0OPTION.sOption = 0
    end
    else do
      g.0OPTION.sOption = 1
      sNextWord = word(sOptions,i+1)                     /* 20070208 */
      if datatype(sNextWord,'WHOLE')
      then do
        g.0OPTION.sOption.1 = sNextWord
        i = i + 1
      end                                                /* 20070208 */
    end
  end
return

Prolog:
  if g.0ENV = 'TSO'
  then g.0LF = '15'x
  else g.0LF = '0A'x

  g.0UPPER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  g.0LOWER = 'abcdefghijklmnopqrstuvwxyz'

  g.0LONGEST_LINE             = 0   /* longest output line found     */

  g.0K = 0
  g.0KDELTA = 0

  g.0JCLTYPE_UNKNOWN   = 0; g.0JCLTYPE.0 = '?'
  g.0JCLTYPE_STATEMENT = 1; g.0JCLTYPE.1 = 'STMT'
  g.0JCLTYPE_DATA      = 2; g.0JCLTYPE.2 = 'DATA'
  g.0JCLTYPE_COMMENT   = 3; g.0JCLTYPE.3 = '//*'
  g.0JCLTYPE_EOJ       = 4; g.0JCLTYPE.4 = '//'
  g.0JCLTYPE_JES2CMD   = 5; g.0JCLTYPE.5 = '/*$'
  g.0JCLTYPE_JES2STMT  = 6; g.0JCLTYPE.6 = 'JES2'
  g.0JCLTYPE_JES3STMT  = 7; g.0JCLTYPE.7 = 'JES3'
  g.0JCLTYPE_OPCDIR    = 8; g.0JCLTYPE.8 = 'OPC'        /* HF 061218 */

  call setStandardColors

  /* Set up your color scheme here...*/
  g.0COLOR_WHITE        = g.0COLOR.white
  g.0COLOR_PARMS_NODE   = g.0COLOR.white
  g.0COLOR_INLINE_NODE  = g.0COLOR.white
  g.0COLOR_SHAPE_NODE   = g.0COLOR.lavender /* default shape color */
  g.0COLOR_SET_NODE     = g.0COLOR.aliceblue
  g.0COLOR_INCLUDE_NODE = g.0COLOR.whitesmoke
  g.0COLOR_IF_NODE      = g.0COLOR.gold
  g.0COLOR_JCLLIB_NODE  = g.0COLOR.lavender
  g.0COLOR_JOB_NODE     = '#ccffcc' /* light green */
  g.0COLOR_PROC_NODE    = '#e3ffe3' /* lighter green */
  g.0COLOR_EOJ_NODE     = '#ff5c5c' /* light red */
  g.0COLOR_PEND_NODE    = g.0COLOR.mistyrose
  g.0COLOR_STEP_NODE    = g.0COLOR.beige
  g.0COLOR_CONTROL_FLOW = g.0COLOR.red
  g.0COLOR_DATA_FLOW    = g.0COLOR.black
  g.0COLOR_DROP_SHADOW  = '#e0e0e0' /* very light gray */
  drop g.0COLOR.   /* we dont need these anymore */
return


setStandardColors: procedure expose g.
  /* These are the standard SVG color names in order of increasing
     brightness. The brightness value is show as a comment...*/
  g.0COLOR.black = '#000000'                    /*   0 */
  g.0COLOR.maroon = '#800000'                   /*  14 */
  g.0COLOR.darkred = '#8B0000'                  /*  15 */
  g.0COLOR.red = '#FF0000'                      /*  28 */
  g.0COLOR.navy = '#000080'                     /*  38 */
  g.0COLOR.darkblue = '#00008B'                 /*  42 */
  g.0COLOR.indigo = '#4B0082'                   /*  47 */
  g.0COLOR.firebrick = '#B22222'                /*  50 */
  g.0COLOR.midnightblue = '#191970'             /*  51 */
  g.0COLOR.purple = '#800080'                   /*  52 */
  g.0COLOR.crimson = '#DC143C'                  /*  54 */
  g.0COLOR.brown = '#A52A2A'                    /*  56 */
  g.0COLOR.darkmagenta = '#8B008B'              /*  57 */
  g.0COLOR.darkgreen = '#006400'                /*  59 */
  g.0COLOR.mediumblue = '#0000CD'               /*  62 */
  g.0COLOR.saddlebrown = '#8B4513'              /*  62 */
  g.0COLOR.orangered = '#FF4500'                /*  69 */
  g.0COLOR.mediumvioletred = '#C71585'          /*  74 */
  g.0COLOR.darkslategray = '#2F4F4F'            /*  75 */
  g.0COLOR.darkslategrey = '#2F4F4F'            /*  75 */
  g.0COLOR.green = '#008000'                    /*  76 */
  g.0COLOR.blue = '#0000FF'                     /*  77 */
  g.0COLOR.sienna = '#A0522D'                   /*  79 */
  g.0COLOR.darkviolet = '#9400D3'               /*  80 */
  g.0COLOR.deeppink = '#FF1493'                 /*  84 */
  g.0COLOR.darkslateblue = '#483D8B'            /*  86 */
  g.0COLOR.darkolivegreen = '#556B2F'           /*  87 */
  g.0COLOR.olive = '#808000'                    /*  90 */
  g.0COLOR.chocolate = '#D2691E'                /*  94 */
  g.0COLOR.forestgreen = '#228B22'              /*  96 */
  g.0COLOR.darkgoldenrod = '#B8860B'            /* 103 */
  g.0COLOR.indianred = '#CD5C5C'                /* 104 */
  g.0COLOR.fuchsia = '#FF00FF'                  /* 105 */
  g.0COLOR.magenta = '#FF00FF'                  /* 105 */
  g.0COLOR.dimgray = '#696969'                  /* 105 */
  g.0COLOR.dimgrey = '#696969'                  /* 105 */
  g.0COLOR.olivedrab = '#6B8E23'                /* 106 */
  g.0COLOR.darkorchid = '#9932CC'               /* 108 */
  g.0COLOR.tomato = '#FF6347'                   /* 108 */
  g.0COLOR.blueviolet = '#8A2BE2'               /* 108 */
  g.0COLOR.darkorange = '#FF8C00'               /* 111 */
  g.0COLOR.seagreen = '#2E8B57'                 /* 113 */
  g.0COLOR.teal = '#008080'                     /* 114 */
  g.0COLOR.peru = '#CD853F'                     /* 120 */
  g.0COLOR.darkcyan = '#008B8B'                 /* 124 */
  g.0COLOR.orange = '#FFA500'                   /* 125 */
  g.0COLOR.slateblue = '#6A5ACD'                /* 126 */
  g.0COLOR.coral = '#FF7F50'                    /* 127 */
  g.0COLOR.gray = '#808080'                     /* 128 */
  g.0COLOR.grey = '#808080'                     /* 128 */
  g.0COLOR.goldenrod = '#DAA520'                /* 131 */
  g.0COLOR.slategray = '#708090'                /* 131 */
  g.0COLOR.slategrey = '#708090'                /* 131 */
  g.0COLOR.mediumorchid = '#BA55D3'             /* 134 */
  g.0COLOR.palevioletred = '#DB7093'            /* 134 */
  g.0COLOR.royalblue = '#4169E1'                /* 137 */
  g.0COLOR.salmon = '#FA8072'                   /* 137 */
  g.0COLOR.steelblue = '#4682B4'                /* 138 */
  g.0COLOR.lightslategray = '#778899'           /* 139 */
  g.0COLOR.lightslategrey = '#778899'           /* 139 */
  g.0COLOR.lightcoral = '#F08080'               /* 140 */
  g.0COLOR.limegreen = '#32CD32'                /* 141 */
  g.0COLOR.hotpink = '#FF69B4'                  /* 144 */
  g.0COLOR.mediumseagreen = '#3CB371'           /* 146 */
  g.0COLOR.mediumslateblue = '#7B68EE'          /* 146 */
  g.0COLOR.rosybrown = '#BC8F8F'                /* 148 */
  g.0COLOR.mediumpurple = '#9370DB'             /* 148 */
  g.0COLOR.lime = '#00FF00'                     /* 150 */
  g.0COLOR.darksalmon = '#E9967A'               /* 151 */
  g.0COLOR.cadetblue = '#5F9EA0'                /* 152 */
  g.0COLOR.sandybrown = '#F4A460'               /* 152 */
  g.0COLOR.yellowgreen = '#9ACD32'              /* 153 */
  g.0COLOR.orchid = '#DA70D6'                   /* 154 */
  g.0COLOR.gold = '#FFD700'                     /* 155 */
  g.0COLOR.lightsalmon = '#FFA07A'              /* 159 */
  g.0COLOR.lightseagreen = '#20B2AA'            /* 160 */
  g.0COLOR.darkkhaki = '#BDB76B'                /* 161 */
  g.0COLOR.lawngreen = '#7CFC00'                /* 162 */
  g.0COLOR.chartreuse = '#7FFF00'               /* 164 */
  g.0COLOR.dodgerblue = '#1E90FF'               /* 165 */
  g.0COLOR.darkgray = '#A9A9A9'                 /* 169 */
  g.0COLOR.darkgrey = '#A9A9A9'                 /* 169 */
  g.0COLOR.darkseagreen = '#8FBC8F'             /* 170 */
  g.0COLOR.cornflowerblue = '#6495ED'           /* 170 */
  g.0COLOR.tan = '#D2B48C'                      /* 171 */
  g.0COLOR.burlywood = '#DEB887'                /* 173 */
  g.0COLOR.violet = '#EE82EE'                   /* 174 */
  g.0COLOR.yellow = '#FFFF00'                   /* 179 */
  g.0COLOR.mediumaquamarine = '#66CDAA'         /* 183 */
  g.0COLOR.greenyellow = '#ADFF2F'              /* 184 */
  g.0COLOR.darkturquoise = '#00CED1'            /* 184 */
  g.0COLOR.plum = '#DDA0DD'                     /* 185 */
  g.0COLOR.springgreen = '#00FF7F'              /* 189 */
  g.0COLOR.deepskyblue = '#00BFFF'              /* 189 */
  g.0COLOR.silver = '#C0C0C0'                   /* 192 */
  g.0COLOR.mediumturquoise = '#48D1CC'          /* 192 */
  g.0COLOR.lightpink = '#FFB6C1'                /* 193 */
  g.0COLOR.mediumspringgreen = '#00FA9A'        /* 194 */
  g.0COLOR.lightgreen = '#90EE90'               /* 199 */
  g.0COLOR.thistle = '#D8BFD8'                  /* 201 */
  g.0COLOR.turquoise = '#40E0D0'                /* 202 */
  g.0COLOR.lightsteelblue = '#B0C4DE'           /* 202 */
  g.0COLOR.pink = '#FFC0CB'                     /* 202 */
  g.0COLOR.khaki = '#F0E68C'                    /* 204 */
  g.0COLOR.skyblue = '#87CEEB'                  /* 207 */
  g.0COLOR.palegreen = '#98FB98'                /* 210 */
  g.0COLOR.navajowhite = '#FFDEAD'              /* 211 */
  g.0COLOR.lightgray = '#D3D3D3'                /* 211 */
  g.0COLOR.lightgrey = '#D3D3D3'                /* 211 */
  g.0COLOR.lightskyblue = '#87CEFA'             /* 211 */
  g.0COLOR.wheat = '#F5DEB3'                    /* 212 */
  g.0COLOR.peachpuff = '#FFDAB9'                /* 212 */
  g.0COLOR.palegoldenrod = '#EEE8AA'            /* 214 */
  g.0COLOR.lightblue = '#ADD8E6'                /* 215 */
  g.0COLOR.moccasin = '#FFE4B5'                 /* 217 */
  g.0COLOR.gainsboro = '#DCDCDC'                /* 220 */
  g.0COLOR.powderblue = '#B0E0E6'               /* 221 */
  g.0COLOR.bisque = '#FFE4C4'                   /* 221 */
  g.0COLOR.aqua = '#00FFFF'                     /* 227 */
  g.0COLOR.cyan = '#00FFFF'                     /* 227 */
  g.0COLOR.aquamarine = '#7FFFD4'               /* 228 */
  g.0COLOR.blanchedalmond = '#FFEBCD'           /* 228 */
  g.0COLOR.mistyrose = '#FFE4E1'                /* 230 */
  g.0COLOR.antiquewhite = '#FAEBD7'             /* 231 */
  g.0COLOR.paleturquoise = '#AFEEEE'            /* 231 */
  g.0COLOR.papayawhip = '#FFEFD5'               /* 233 */
  g.0COLOR.lavender = '#E6E6FA'                 /* 236 */
  g.0COLOR.lemonchiffon = '#FFFACD'             /* 237 */
  g.0COLOR.beige = '#F5F5DC'                    /* 238 */
  g.0COLOR.lightgoldenrodyellow = '#FAFAD2'     /* 238 */
  g.0COLOR.linen = '#FAF0E6'                    /* 238 */
  g.0COLOR.cornsilk = '#FFF8DC'                 /* 240 */
  g.0COLOR.oldlace = '#FDF5E6'                  /* 241 */
  g.0COLOR.lavenderblush = '#FFF0F5'            /* 243 */
  g.0COLOR.seashell = '#FFF5EE'                 /* 244 */
  g.0COLOR.whitesmoke = '#F5F5F5'               /* 245 */
  g.0COLOR.lightyellow = '#FFFFE0'              /* 246 */
  g.0COLOR.floralwhite = '#FFFAF0'              /* 248 */
  g.0COLOR.honeydew = '#F0FFF0'                 /* 249 */
  g.0COLOR.aliceblue = '#F0F8FF'                /* 249 */
  g.0COLOR.ghostwhite = '#F8F8FF'               /* 250 */
  g.0COLOR.ivory = '#FFFFF0'                    /* 251 */
  g.0COLOR.snow = '#FFFAFA'                     /* 251 */
  g.0COLOR.lightcyan = '#E0FFFF'                /* 252 */
  g.0COLOR.mintcream = '#F5FFFA'                /* 252 */
  g.0COLOR.azure = '#F0FFFF'                    /* 253 */
  g.0COLOR.white = '#FFFFFF'                    /* 255 */
return

Epilog: procedure expose g.
  if g.0LONGEST_LINE > g.0OPTION.WRAP.1
  then say 'JCL010W To avoid output line truncation, specify: (WRAP',
           g.0LONGEST_LINE
return

prettyPrinter: procedure expose g.
  parse arg sFileOut,g.0TAB,node
  if g.0TAB = '' then g.0TAB = 2 /* indentation amount */
  if node = '' then node = getRoot()
  g.0INDENT = 0
  g.0FILEOUT = ''
  if sFileOut <> ''
  then do
    g.0FILEOUT = openFile(sFileOut,'OUTPUT')
    if g.0rc = 0
    then say 'JCL006I Creating' sFileOut
    else do
      say 'JCL007E Could not create' sFileOut'. Writing to console...'
      g.0FILEOUT = '' /* null handle means write to console */
    end
  end
  call _setDefaultEntities
  call emitProlog
  g.0INDENT = -g.0TAB
  call showNode node
  if g.0FILEOUT <> ''
  then do
    say 'JCL008I Created' sFileOut
    rc = closeFile(g.0FILEOUT)
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
  g.0INDENT = 0
  if g.0OPTION.ENCODING
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
  if g.0PRESERVEWS = 1
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
  if g.0ENV = 'TSO'                                      /* 20070118 */
  then do
    do until length(sText) = 0
      parse var sText sLine (g.0LF) sText
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
      if g.0YED_FRIENDLY = 1 & (isTextNode(child) | bIsCDATA)
      then do /* for yEd: <element attrs>text</element> */
        sText = toString(child)
        if g.0OPTION.WRAP & pos(g.0LF,sText) > 0
        then do /* split lines into records */
          parse var sText sLine (g.0LF) sText
          call emitElementAndAttributes node,'>'sLine
          do until length(sText) = 0
            parse var sText sLine (g.0LF) sText
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
    nLineLength = g.0INDENT + length(sPad || sLine sAttr),
                            + length(sTermination)
    if g.0OPTION.WRAP & nLineLength > g.0OPTION.WRAP.1   /* 20070208 */
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
  else sLine = copies(' ',g.0INDENT)sText
  if g.0ENV = 'TSO' & length(sLine) > g.0OPTION.WRAP.1   /* 20070208 */
  then do
    say 'JCL009W Line truncated:' strip(left(sText,50),'TRAILING')'...'
    g.0LONGEST_LINE = max(g.0LONGEST_LINE,length(sLine))
  end
  if g.0FILEOUT = ''
  then say sLine
  else call putLine g.0FILEOUT,sLine
return

/*INCLUDE io.rex */
/*INCLUDE parsexml.rex */
