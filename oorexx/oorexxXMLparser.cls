/*REXX 2.1.0

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

/**********************************************************************
**                                                                   **
** ALL CODE BELOW THIS POINT BELONGS TO THE XML PARSER. YOU MUST     **
** USE A OOREXX;                                                     **
**                                                                   **
**             ::REQUIRES "oorexxXMLparser.cls"                      **
**                                                                   **
** DIRECTIVE IN ANY REXX SOURCE FILE THAT REQUIRES AN XML            **
** PARSING CAPABILITY.                                               **
**********************************************************************/

/*REXX*****************************************************************
**                                                                   **
** NAME     - oorexxXMLparser.cls                                    **
**                                                                   **
**           (Based on original file "parsexml.rex")                 **
**                                                                   **
** FUNCTION - A Rexx XML parser. It is non-validating, so DTDs and   **
**            XML schemas are ignored. Ok, DTD entities are processed**
**            but that's all.                                        **
**                                                                   **
** USAGE    - 1. Initialize the parser by instantiating an instance  **
**               of the CLASS "ParseXML". E.g.                       **
**                                                                   **
**               parserObj = .ParseXML~new(<options>)                **
**                                                                   **
**               for <options> see description of function           **
**               "initParser [options]" under API documentation      **
**               below.                                              **
**                                                                   **
**            2. Parse the XML file to build an in-memory model      **
**                                                                   **
**               returncd = parserObj~parseFile('filename')          **
**                ...or...                                           **
**               returncd = parserObj~parseString('xml in a string') **
**                                                                   **
**            3. Navigate the in-memory model with the DOM API. For  **
**               example:                                            **
**                                                                   **
**               say 'The document element is called',               **
**                 parserObj~getName(parserObj~getDocumentElement()) **
**                                                                   **
**               say 'Children of the document element are:'         **
**               node = parserObj~getFirstChild( ,                   **
**                                parserObj~getDocumentElement())    **
**               do while node <> ''                                 **
**                 if parserObj~isElementNode(node)                  **
**                 then say 'Element node:' parserObj~getName(node)  **
**                 else say '   Text node:' parserObj~getText(node)  **
**                 node = parserObj~getNextSibling(node)             **
**               end                                                 **
**                                                                   **
**            4. Optionally, destroy the in-memory model:            **
**                                                                   **
**               parserObj~destroyParser                             **
**                                                                   **
** INPUT    - An XML file containing:                                **
**              1. An optional XML prolog:                           **
**                 - 0 or 1 XML declaration:                         **
**                     <?xml version="1.0" encoding="..." ...?>      **
**                 - 0 or more comments, PIs, and whitespace:        **
**                     <!-- a comment -->                            **
**                     <?target string?>                             **
**                 - 0 or 1 document type declaration. Formats:      **
**                     <!DOCTYPE root SYSTEM "sysid">                **
**                     <!DOCTYPE root PUBLIC "pubid" SYSTEM "sysid"> **
**                     <!DOCTYPE root [internal dtd]>                **
**              2. An XML body:                                      **
**                 - 1 Document element containing 0 or more child   **
**                     elements. For example:                        **
**                     <doc attr1="value1" attr2="value2"...>        **
**                       Text of doc element                         **
**                       <child1 attr1="value1">                     **
**                         Text of child1 element                    **
**                       </child1>                                   **
**                       More text of doc element                    **
**                       <!-- an empty child element follows -->     **
**                       <child2/>                                   **
**                       Even more text of doc element               **
**                     </doc>                                        **
**                 - Elements may contain:                           **
**                   Unparsed character data:                        **
**                     <![CDATA[...unparsed data...]]>               **
**                   Entity references:                              **
**                     &name;                                        **
**                   Character references:                           **
**                     &#nnnnn;                                      **
**                     &#xXXXX;                                      **
**              3. An XML epilog (which is ignored):                 **
**                 - 0 or more comments, PIs, and whitespace.        **
**                                                                   **
** API      - The basic setup/teardown API calls are:                **
**                                                                   **
**            initParser [options]                                   **
**                Initialises the parser's global variables and      **
**                remembers any runtime options you specify. The     **
**                options recognized are:                            **
**                NOBLANKS - Suppress whitespace-only nodes          **
**                DEBUG    - Display some debugging info             **
**                DUMP     - Display the parse tree                  **
**                                                                   **
**            parseFile(filename)                                    **
**                Parses the XML data in the specified filename and  **
**                builds an in-memory model that can be accessed via **
**                the DOM API (see below).                           **
**                                                                   **
**            parseString(text)                                      **
**                Parses the XML data in the specified string.       **
**                                                                   **
**            destroyParser                                          **
**                Destroys the in-memory model and miscellaneous     **
**                global variables.                                  **
**                                                                   **
**          - In addition, the following utility API calls can be    **
**            used:                                                  **
**                                                                   **
**            removeWhitespace(text)                                 **
**                Returns the supplied text string but with all      **
**                whitespace characters removed, multiple spaces     **
**                replaced with single spaces, and leading and       **
**                trailing spaces removed.                           **
**                                                                   **
**            removeQuotes(text)                                     **
**                Returns the supplied text string but with any      **
**                enclosing apostrophes or double-quotes removed.    **
**                                                                   **
**            escapeText(text)                                       **
**                Returns the supplied text string but with special  **
**                characters encoded (for example, '<' becomes &lt;) **
**                                                                   **
**            toString(node)                                         **
**                Walks the document tree (beginning at the specified**
**                node) and returns a string in XML format.          **
**                                                                   **
** DOM API  - The DOM (ok, DOM-like) calls that you can use are      **
**            listed below:                                          **
**                                                                   **
**            Document query/navigation API calls                    **
**            -----------------------------------                    **
**                                                                   **
**            getRoot()                                              **
**                Returns the node number of the root node. This     **
**                can be used in calls requiring a 'node' argument.  **
**                In this implementation, getDocumentElement() and   **
**                getRoot() are (incorrectly) synonymous - this may  **
**                change, so you should use getDocumentElement()     **
**                in preference to getRoot().                        **
**                                                                   **
**            getDocumentElement()                                   **
**                Returns the node number of the document element.   **
**                The document element is the topmost element node.  **
**                You should use this in preference to getRoot()     **
**                (see above).                                       **
**                                                                   **
**            getName(node)                                          **
**                Returns the name of the specified node.            **
**                                                                   **
**            getNodeValue(node)                                     **
**            getText(node)                                          **
**                Returns the text content of an unnamed node. A     **
**                node without a name can only contain text. It      **
**                cannot have attributes or children.                **
**                                                                   **
**            getAttributeCount(node)                                **
**                Returns the number of attributes present on the    **
**                specified node.                                    **
**                                                                   **
**            getAttributeMap(node)                                  **
**                Builds a map of the attributes of the specified    **
**                node. The map can be accessed via the following    **
**                variables:                                         **
**                  g.0ATTRIBUTE.0 = The number of attributes mapped.**
**                  g.0ATTRIBUTE.n = The name of attribute 'n' (in   **
**                                   order of appearance). n > 0.    **
**                  g.0ATTRIBUTE.name = The value of the attribute   **
**                                   called 'name'.                  **
**                                                                   **
**            getAttributeName(node,n)                               **
**                Returns the name of the nth attribute of the       **
**                specified node (1 is first, 2 is second, etc).     **
**                                                                   **
**            getAttributeNames(node)                                **
**                Returns a space-delimited list of the names of the **
**                attributes of the specified node.                  **
**                                                                   **
**            getAttribute(node,name)                                **
**                Returns the value of the attribute called 'name' of**
**                the specified node.                                **
**                                                                   **
**            getAttribute(node,n)                                   **
**                Returns the value of the nth attribute of the      **
**                specified node (1 is first, 2 is second, etc).     **
**                                                                   **
**            setAttribute(node,name,value)                          **
**                Updates the value of the attribute called 'name'   **
**                of the specified node. If no attribute exists with **
**                that name, then one is created.                    **
**                                                                   **
**            setAttributes(node,name1,value1,name2,value2,...)      **
**                Updates the attributes of the specified node. Zero **
**                or more name/value pairs are be specified as the   **
**                arguments.                                         **
**                                                                   **
**            hasAttribute(node,name)                                **
**                Returns 1 if the specified node has an attribute   **
**                with the specified name, else 0.                   **
**                                                                   **
**            getParentNode(node)                                    **
**            getParent(node)                                        **
**                Returns the node number of the specified node's    **
**                parent. If the node number returned is 0, then the **
**                specified node is the root node.                   **
**                All nodes have a parent (except the root node).    **
**                                                                   **
**            getFirstChild(node)                                    **
**                Returns the node number of the specified node's    **
**                first child node.                                  **
**                                                                   **
**            getLastChild(node)                                     **
**                Returns the node number of the specified node's    **
**                last child node.                                   **
**                                                                   **
**            getChildNodes(node)                                    **
**            getChildren(node)                                      **
**                Returns a space-delimited list of node numbers of  **
**                the children of the specified node. You can use    **
**                this list to step through the children as follows: **
**                  children = getChildren(node)                     **
**                  say 'Node' node 'has' words(children) 'children' **
**                  do i = 1 to words(children)                      **
**                     child = word(children,i)                      **
**                     say 'Node' child 'is' getName(child)          **
**                  end                                              **
**                                                                   **
**            getChildrenByName(node,name)                           **
**                Returns a space-delimited list of node numbers of  **
**                the immediate children of the specified node which **
**                are called 'name'. Names are case-sensitive.       **
**                                                                   **
**            getElementsByTagName(node,name)                        **
**                Returns a space-delimited list of node numbers of  **
**                the descendants of the specified node which are    **
**                called 'name'. Names are case-sensitive.           **
**                                                                   **
**            getNextSibling(node)                                   **
**                Returns the node number of the specified node's    **
**                next sibling node. That is, the next node sharing  **
**                the same parent.                                   **
**                                                                   **
**            getPreviousSibling(node)                               **
**                Returns the node number of the specified node's    **
**                previous sibline node. That is, the previous node  **
**                sharing the same parent.                           **
**                                                                   **
**            getProcessingInstruction(name)                         **
**                Returns the value of the PI with the specified     **
**                target name.                                       **
**                                                                   **
**            getProcessingInstructionList()                         **
**                Returns a space-delimited list of the names of all **
**                PI target names.                                   **
**                                                                   **
**            getNodeType(node)                                      **
**                Returns a number representing the specified node's **
**                type. The possible values can be compared to the   **
**                following global variables:                        **
**                g.0ELEMENT_NODE                = 1                 **
**                g.0ATTRIBUTE_NODE              = 2                 **
**                g.0TEXT_NODE                   = 3                 **
**                g.0CDATA_SECTION_NODE          = 4                 **
**                g.0ENTITY_REFERENCE_NODE       = 5                 **
**                g.0ENTITY_NODE                 = 6                 **
**                g.0PROCESSING_INSTRUCTION_NODE = 7                 **
**                g.0COMMENT_NODE                = 8                 **
**                g.0DOCUMENT_NODE               = 9                 **
**                g.0DOCUMENT_TYPE_NODE          = 10                **
**                g.0DOCUMENT_FRAGMENT_NODE      = 11                **
**                g.0NOTATION_NODE               = 12                **
**                Note: as this exposes internal implementation      **
**                details, it is best not to use this routine.       **
**                Consider using isTextNode() etc instead.           **
**                                                                   **
**            isCDATA(node)                                          **
**                Returns 1 if the specified node is an unparsed     **
**                character data (CDATA) node, else 0. CDATA nodes   **
**                are used to contain content that you do not want   **
**                to be treated as XML data. For example, HTML data. **
**                                                                   **
**            isElementNode(node)                                    **
**                Returns 1 if the specified node is an element node,**
**                else 0.                                            **
**                                                                   **
**            isTextNode(node)                                       **
**                Returns 1 if the specified node is a text node,    **
**                else 0.                                            **
**                                                                   **
**            isCommentNode(node)                                    **
**                Returns 1 if the specified node is a comment node, **
**                else 0. Note: when a document is parsed, comment   **
**                nodes are ignored. This routine returns 1 iff a    **
**                comment node has been inserted into the in-memory  **
**                document tree by using createComment().            **
**                                                                   **
**            hasChildren(node)                                      **
**                Returns 1 if the specified node has one or more    **
**                child nodes, else 0.                               **
**                                                                   **
**            getDocType(doctype)                                    **
**                Gets the text of the <!DOCTYPE> prolog node.       **
**                                                                   **
**            Document creation/mutation API calls                   **
**            ------------------------------------                   **
**                                                                   **
**            createDocument(name)                                   **
**                Returns the node number of a new document node     **
**                with the specified name.                           **
**                                                                   **
**            createDocumentFragment(name)                           **
**                Returns the node number of a new document fragment **
**                node with the specified name.                      **
**                                                                   **
**            createElement(name)                                    **
**                Returns the node number of a new empty element     **
**                node with the specified name. An element node can  **
**                have child nodes.                                  **
**                                                                   **
**            createTextNode(data)                                   **
**                Returns the node number of a new text node. A text **
**                node can *not* have child nodes.                   **
**                                                                   **
**            createCDATASection(data)                               **
**                Returns the node number of a new Character Data    **
**                (CDATA) node. A CDATA node can *not* have child    **
**                nodes. CDATA nodes are used to contain content     **
**                that you do not want to be treated as XML data.    **
**                For example, HTML data.                            **
**                                                                   **
**            createComment(data)                                    **
**                Returns the node number of a new commend node.     **
**                A command node can *not* have child nodes.         **
**                                                                   **
**            appendChild(node,parent)                               **
**                Appends the specified node to the end of the list  **
**                of children of the specified parent node.          **
**                                                                   **
**            insertBefore(node,refnode)                             **
**                Inserts node 'node' before the reference node      **
**                'refnode'.                                         **
**                                                                   **
**            removeChild(node)                                      **
**                Removes the specified node from its parent and     **
**                returns its node number. The removed child is now  **
**                an orphan.                                         **
**                                                                   **
**            replaceChild(newnode,oldnode)                          **
**                Replaces the old child 'oldnode' with the new      **
**                child 'newnode' and returns the old child's node   **
**                number. The old child is now an orphan.            **
**                                                                   **
**            setAttribute(node,attrname,attrvalue)                  **
**                Adds or replaces the attribute called 'attrname'   **
**                on the specified node.                             **
**                                                                   **
**            removeAttribute(node,attrname)                         **
**                Removes the attribute called 'attrname' from the   **
**                specified node.                                    **
**                                                                   **
**            setDocType(doctype)                                    **
**                Sets the text of the <!DOCTYPE> prolog node.       **
**                                                                   **
**            cloneNode(node,[deep])                                 **
**                Creates a copy (a clone) of the specified node     **
**                and returns its node number. If deep = 1 then      **
**                all descendants of the specified node are also     **
**                cloned, else only the specified node and its       **
**                attributes are cloned.                             **
**                                                                   **
** FORMAT   - Reformatting the xml input file to console output or   **
**            file.                                                  **
**                                                                   **
**            pretty(infile,[outfile])                               **
**                                                                   **
**            prettyPrinter([outfile],[indent])                      **
**                 Format which takes an indentation amounnt for     **
**                 rewriting to output. Default value is 2.          **
**                                                                   **
** I/O      - File I/O routines.                                     **
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
** NOTES    - 1. This parser creates global class variables and so   **
**               its operation may be severely jiggered if you       **
**               update any of them accidentally (or on purpose).    **
**               The variables you should avoid updating yourself    **
**               are:                                                **
**                                                                   **
**               g.0ATTRIBUTE.n                                      **
**               g.0ATTRIBUTE.name                                   **
**               g.0ATTRSOK                                          **
**               g.0DTD                                              **
**               g.0ENDOFDOC                                         **
**               g.0ENTITIES                                         **
**               g.0ENTITY.name                                      **
**               g.0FIRST.n                                          **
**               g.0LAST.n                                           **
**               g.0NAME.n                                           **
**               g.0NEXT.n                                           **
**               g.0NEXTID                                           **
**               g.0OPTION.name                                      **
**               g.0OPTIONS                                          **
**               g.0PARENT.n                                         **
**               g.0PI                                               **
**               g.0PI.name                                          **
**               g.0PREV.n                                           **
**               g.0PUBLIC                                           **
**               g.0ROOT                                             **
**               g.0STACK                                            **
**               g.0SYSTEM                                           **
**               g.0TEXT.n                                           **
**               g.0TYPE.n                                           **
**               g.0WHITESPACE                                       **
**               g.0XML                                              **
**               g.?XML                                              **
**               g.?XML.VERSION                                      **
**               g.?XML.ENCODING                                     **
**               g.?XML.STANDALONE                                   **
**                                                                   **
**            2. To reduce the incidence of name clashes, methods    **
**               names that are not meant to be part of the public   **
**               API have been prefixed with '_'.                    **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** CONTRIBUTORS -                                                    **
**            Alessandro Battilani                                   **
**              <alessandro.battilani@bancaintesa.it>                **
**            Paul W. Dunkley                                        **
**              <pdunkley@nycers.org>                                **
**                                                                   **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top pls)       **
**            -------- --------------------------------------------- **
**            20160818 PWD Incorporate functions from "pretty.rex"   **
**                         and "io.rex" files into the "ParseXML"    **
**                         CLASS structure.                          **
**            20160817 PWD Changed to ooRexx CLASS methods. updated  **
**                         parts of documentation above to reflect   **
**                         ooRexx terminology and syntax.            **
**            20090822 AJA Changed from GPL to BSD license.          **
**                         Ignore whitespace to fix parse error.     **
**            20070325 AJA Whitespace defaults to '090a0d'x.         **
**            20070323 AJA Added createDocumentFragment().           **
**                         Added isDocumentFragmentNode().           **
**                         Added isDocumentNode().                   **
**            20060915 AJA Added cloneNode().                        **
**                         Added deepClone().                        **
**                         Changed removeChild() to return the       **
**                         node number of the child instead of       **
**                         clearing it.                              **
**                         Changed replaceChild() to return the      **
**                         node number of the old child instead      **
**                         of clearing it.                           **
**            20060913 AJA Fixed bug in _resolveEntities().          **
**            20060808 AB  Added support for reading from a DD       **
**                         name when running IRXJCL on MVS.          **
**                         This change was contributed by            **
**                         Alessandro Battilani from Banca           **
**                         Intesa, Italy.                            **
**            20060803 AJA Fixed loop in getAttributeMap().          **
**            20051025 AJA Now checks parentage before adding a      **
**                         child node:                               **
**                         Fixed appendChild(id,parent)              **
**                         Fixed insertBefore(id,ref)                **
**            20051014 AJA Added alias routine names to more         **
**                         closely match the DOM specification.      **
**                         Specifically:                             **
**                         Added getNodeName()                       **
**                         Added getNodeValue()                      **
**                         Added getParentNode()                     **
**                         Added getChildNodes()                     **
**                         Added hasChildNodes()                     **
**                         Added getElementsByTagName()      .       **
**            20050919 AJA Added setAttributes helper routine.       **
**            20050914 AJA Added createComment and isComment.        **
**            20050913 AJA Added get/setDocType routines.            **
**            20050907 AJA Added _setDefaultEntities routine.        **
**            20050601 AJA Added '250d'x to whitespace for TSO.      **
**            20050514 AJA Removed getAttributes API call and        **
**                         reworked attribute processing.            **
**                         Added toString API call.                  **
**            20040706 AJA Added creation/modification support.      **
**            20031216 AJA Bugfix: _parseElement with no attrs       **
**                         causes crash.                             **
**            20031031 AJA Correctly parse '/' in attributes.        **
**                         Fixed entity resolution.                  **
**            20030912 AJA Bugfix: Initialize sXmlData first.        **
**                         Bugfix: Correctly parse a naked '>'       **
**                         present in an attribute value.            **
**                         Enhancement: DUMP option now displays     **
**                         first part of each text node.             **
**            20030901 AJA Intial version.                           **
**                                                                   **
**********************************************************************/

::OPTIONS Trace o
::CLASS ParseXML public
/*-------------------------------------------------------------------*
 * Set up global variables for the parser
 *-------------------------------------------------------------------*/
::METHOD init
  expose g.

  /* initParser: procedure expose g. */
  parse arg sOptions
  g. = '' /* Note: stuffs up caller who may have set g. variables */
  g.0OPTIONS = translate(sOptions)
  sOptions = 'DEBUG DUMP NOBLANKS'
  do i = 1 to words(sOptions)
    sOption = word(sOptions,i)
    g.0OPTION.sOption = wordpos(sOption,g.0OPTIONS) > 0
  end

  parse source sSystem sInvocation sSourceFile
  select
    when sSystem = 'WIN32'  then g.0WHITESPACE = '090a0d'x
    when sSystem = 'TSO'    then g.0WHITESPACE = '05250d'x
    otherwise                    g.0WHITESPACE = '090a0d'x /*20070325*/
  end

  g.0ENV     = sSystem                     /*20160818*/
  g.0LEADERS = '_:ABCDEFGHIJKLMNOPQRSTUVWXYZ' ||,
                 'abcdefghijklmnopqrstuvwxyz'
  g.0OTHERS  = g.0LEADERS'.-0123456789'

  self~_setDefaultEntities

  /* Not all of the following node types are used... */
  g.0ELEMENT_NODE            =  1; g.0NODETYPE.1 = 'Element'
  g.0ATTRIBUTE_NODE          =  2; g.0NODETYPE.2 = 'Attribute'
  g.0TEXT_NODE               =  3; g.0NODETYPE.3 = 'Text'
  g.0CDATA_SECTION_NODE      =  4; g.0NODETYPE.4 = 'CDATA Section'
  g.0ENTITY_REFERENCE_NODE   =  5     /* NOT USED */
  g.0ENTITY_NODE             =  6     /* NOT USED */
  g.0PROCESSING_INSTRUCTION_NODE = 7  /* NOT USED */
  g.0COMMENT_NODE            =  8; g.0NODETYPE.8 = 'Comment'
  g.0DOCUMENT_NODE           =  9; g.0NODETYPE.9 = 'Document'
  g.0DOCUMENT_TYPE_NODE      = 10    /* NOT USED */
  g.0DOCUMENT_FRAGMENT_NODE  = 11; g.0NODETYPE.11 = 'Document Fragment'
  g.0NOTATION_NODE           = 12    /* NOT USED */

  g.0ENDOFDOC = 0
return

/*-------------------------------------------------------------------*
 * Clean up parser
 *-------------------------------------------------------------------*/
::method destroyParser
  expose g.
  /* destroyParser: procedure expose g. */
  /* Note: it would be easy to just "drop g.", but this could
     possibly stuff up the caller who may be using other
     "g." variables...
     todo: revisit this one (parser may have to 'own' g. names)
  */
  drop g.?XML g.0ROOT g.0SYSTEM g.0PUBLIC g.0DTD
  do i = 1 to words(g.0PI)
    sName = word(g.0PI,i)
    drop g.0PI.sName
  end
  drop g.0PI
  do i = 1 to words(g.0ENTITIES)
    sName = word(g.0ENTITIES,i)
    drop g.0ENTITY.sName
  end
  drop g.0ENTITIES
  self~_setDefaultEntities
  
  if datatype(g.0NEXTID,'WHOLE')
  then do
    do i = 1 to g.0NEXTID
      drop g.0PARENT.i g.0FIRST.i g.0LAST.i g.0PREV.i,
           g.0NEXT.i g.0NAME.i g.0TEXT.i
    end
  end
  drop g.0NEXTID g.0STACK g.0ENDOFDOC
return


/*-------------------------------------------------------------------*
 * Read a file into a string
 *-------------------------------------------------------------------*/
::method parseFile
  expose g.
  /* parseFile: procedure expose g. */
  parse arg sFile
  parse source sSystem sInvocation sSourceFile . . . sInitEnv .
  sXmlData = ''
  select
    when sSystem = 'TSO' & sInitEnv = 'TSO' then do
      /* sFile is a dataset name */
      address TSO
      junk = OUTTRAP('junk.') /* Trap and discard messages */
      'ALLOCATE DD(INPUT) DSN('sFile')'
      'EXECIO * DISKR INPUT (FINIS'
      'FREE DD(INPUT)'
      address
      do queued()
        parse pull sLine
        sXmlData = sXmlData || sLine
      end
      junk = OUTTRAP('OFF')
    end
    when sSystem = 'TSO' & sInitEnv = 'MVS' then do
      /* sFile is a DD name */
      address MVS 'EXECIO * DISKR' sFile '(FINIS'
      do queued()
        parse pull sLine
        sXmlData = sXmlData || sLine
      end
    end
    otherwise do
      /* sXmlData = charin(sFile,,chars(sFile))    *20160818 */  
      fs=.Stream~new(sFile)                       /*20160818 */
      loop k over fs                              /*20160818 */
        sXmlData = sXmlData||k
      end k
    end
  end
return self~parseString(sXmlData)

/*-------------------------------------------------------------------*
 * Parse a string containing XML
 *-------------------------------------------------------------------*/
::method parseString
 expose g.
  /* parseString: procedure expose g. */
  parse arg g.0XML
  
  self~_parseXmlDecl
  do while pos('<',g.0XML) > 0
    parse var g.0XML sLeft'<'sData
    select
      when left(sData,1) = '?'         then self~_parsePI( sData)
      when left(sData,9) = '!DOCTYPE ' then self~_parseDocType(sData)
      when left(sData,3) = '!--'       then self~_parseComment(sData)
      otherwise                             self~_parseElement(sData)
    end
  end
return 0

/*-------------------------------------------------------------------*
 * <?xml version="1.0" encoding="..." ...?>
 *-------------------------------------------------------------------*/

::method _parseXmlDecl private
  expose g.
  /* _parseXmlDecl: procedure expose g. */
  if left(g.0XML,6) = '<?xml '
  then do
    parse var g.0XML '<?xml 'sXMLDecl'?>'g.0XML
    g.?xml = space(sXMLDecl)
    sTemp = self~_getNormalizedAttributes(g.?xml)
    parse var sTemp 'version='g.?xml.version'ff'x
    parse var sTemp 'encoding='g.?xml.encoding'ff'x
    parse var sTemp 'standalone='g.?xml.standalone'ff'x
  end
return

/*-------------------------------------------------------------------*
 * <?target string?>
 *-------------------------------------------------------------------*/
::method _parsePI private
  expose g.
  /* _parsePI: procedure expose g. */
  parse arg '?'sProcessingInstruction'?>'g.0XML
  self~_setProcessingInstruction(sProcessingInstruction)
return

/*-------------------------------------------------------------------*
 * <!DOCTYPE root SYSTEM "sysid">
 * <!DOCTYPE root SYSTEM "sysid" [internal dtd]>
 * <!DOCTYPE root PUBLIC "pubid" "sysid">
 * <!DOCTYPE root PUBLIC "pubid" "sysid" [internal dtd]>
 * <!DOCTYPE root [internal dtd]>
 *-------------------------------------------------------------------*/
::method _parseDocType private
   expose g.
  /* _parseDocType: procedure expose g. */
  parse arg '!DOCTYPE' sDocType'>'
  if g.0ROOT <> ''
  then self~_abort('XML002E Multiple "<!DOCTYPE" declarations')
  if pos('[',sDocType) > 0
  then do
    parse arg '!DOCTYPE' sDocType'['g.0DTD']>'g.0XML
    parse var sDocType g.0ROOT sExternalId
    if sExternalId <> '' then self~_parseExternalId(sExternalId)
    g.0DTD = strip(g.0DTD)
    self~_parseDTD(g.0DTD)
  end
  else do
    parse arg '!DOCTYPE' g.0ROOT sExternalId'>'g.0XML
    if sExternalId <> '' then self~_parseExternalId(sExternalId)
  end
  g.0ROOT = strip(g.0ROOT)
return

/*-------------------------------------------------------------------*
 * SYSTEM "sysid"
 * PUBLIC "pubid" "sysid"
 *-------------------------------------------------------------------*/
::method _parseExternalId private
  expose g.
  /* _parseExternalId: procedure expose g. */
  parse arg sExternalIdType .
  select
    when sExternalIdType = 'SYSTEM' then do
      parse arg . g.0SYSTEM
      g.0SYSTEM = self~removeQuotes(g.0SYSTEM)
    end
    when sExternalIdType = 'PUBLIC' then do
      parse arg . g.0PUBLIC g.0SYSTEM
      g.0PUBLIC = self~removeQuotes(g.0PUBLIC)
      g.0SYSTEM = self~removeQuotes(g.0SYSTEM)
    end
    otherwise do
       parse arg sExternalEntityDecl
       self~_abort('XML003E Invalid external entity declaration:',
                   sExternalEntityDecl)
    end
  end
return


/*-------------------------------------------------------------------*
 * <!ENTITY name "value">
 * <!ENTITY name SYSTEM "sysid">
 * <!ENTITY name PUBLIC "pubid" "sysid">
 * <!ENTITY % name pedef>
 * <!ELEMENT elementname contentspec>
 * <!ATTLIST elementname attrname attType DefaultDecl ...>
 * <!NOTATION name notationdef>
 *-------------------------------------------------------------------*/
::method _parseDTD private
  expose g.
  /* _parseDTD: procedure expose g. */
  parse arg sDTD
  do while pos('<!',sDTD) > 0
    parse var sDTD '<!'sDecl sName sValue'>'sDTD
    select
      when sDecl = 'ENTITY' then do
        parse var sValue sWord1 .
        select
          when sName = '%'       then nop
          when sWord1 = 'SYSTEM' then nop
          when sWord1 = 'PUBLIC' then nop
          otherwise do
            sValue = self~_resolveEntities(self~removeQuotes(sValue))
            self~_setEntity(sName,sValue)
          end
        end
      end
      otherwise nop /* silently ignore other possibilities for now */
    end
  end
return

/*-------------------------------------------------------------------*
 * <!-- comment -->
 *-------------------------------------------------------------------*/
::method _parseComment private
   expose g.
  /* _parseComment: procedure expose g. */
  parse arg sComment'-->'g.0XML
  /* silently ignore comments */
return

/*-------------------------------------------------------------------*
 * <tag attr1="value1" attr2="value2" ...>...</tag>
 * <tag attr1="value1" attr2="value2" .../>
 *-------------------------------------------------------------------*/
::method _parseElement private
  expose g.
  /* _parseElement: procedure expose g. */
  parse arg sXML

  if g.0ENDOFDOC
  then self~_abort('XML004E Only one top level element is allowed.',
                  'Found:' subword(g.0XML,1,3))
  self~_startDocument

  g.0XML = '<'sXML
  do while pos('<',g.0XML) > 0 & \g.0ENDOFDOC
    parse var g.0XML sLeft'<'sBetween'>'g.0XML

    if length(sLeft) > 0
    then self~_characters(sLeft)

    if g.0OPTION.DEBUG
    then say g.0STACK sBetween

    if left(sBetween,8) = '![CDATA[' 
    then do
      g.0XML = sBetween'>'g.0XML            /* ..back it out! */
      parse var g.0XML '![CDATA['sBetween']]>'g.0XML
      self~_characterData(sBetween)
    end
    else do
      sBetween = self~removeWhiteSpace(sBetween)    /*20090822*/
      select
        when left(sBetween,3) = '!--' then do    /* <!-- comment --> */
          if right(sBetween,2) <> '--'
          then do  /* backup a bit and look for end-of-comment */
            g.0XML = sBetween'>'g.0XML
            if pos('-->',g.0XML) = 0
            then self~_abort('XML005E End of comment missing after:',
                            '<'g.0XML)
            parse var g.0XML sComment'-->'g.0XML
          end
        end
        when left(sBetween,1) = '?' then do    /* <?target string?> */
          parse var sBetween '?'sProcessingInstruction'?'
          self~_setProcessingInstruction(sProcessingInstruction)
        end
        when left(sBetween,1) = '/' then do    /* </tag> */
          self~_endElement(substr(sBetween,2))   /* tag */
        end
        when  right(sBetween,1) = '/'  /* <tag ...attrs.../> */
        then do
          parse var sBetween sTagName sAttrs
          if length(sAttrs) > 0                            /*20031216*/
          then sAttrs = substr(sAttrs,1,length(sAttrs)-1)  /*20031216*/
          else parse var sTagName sTagName'/'     /* <tag/>  20031216*/
          sAttrs = self~_getNormalizedAttributes(sAttrs)
          self~_startElement(sTagName,sAttrs)
          self~_endElement(sTagName)
        end
        otherwise do              /* <tag ...attrs ...> ... </tag>  */
          parse var sBetween sTagName sAttrs
          sAttrs = self~_getNormalizedAttributes(sAttrs)
          if g.0ATTRSOK
          then do
            self~_startElement(sTagName,sAttrs)
          end
          else do /* back up a bit and look for the real end of tag */
            g.0XML = '<'sBetween'&gt;'g.0XML
            if pos('>',g.0XML) = 0
            then self~_abort('XML006E Missing end tag for:' sTagName)
            /* reparse on next cycle avoiding premature '>'...*/
          end
        end
      end
    end
  end

  self~_endDocument
return

::method _startDocument private
  expose g.
  /* _startDocument: procedure expose g. */
  g.0NEXTID = 0
  g.0STACK = 0
return

::method _startElement  private
  expose g.
  /* _startElement:  procedure expose g. */
  parse arg sTagName,sAttrs
  id = self~_getNextId()
  self~_updateLinkage(id)
  g.0NAME.id = sTagName
  g.0TYPE.id = g.0ELEMENT_NODE
  self~_addAttributes(id,sAttrs)
  cid = self~_pushElement(id)
return

::method _updateLinkage private
  expose g.
  /* _updateLinkage: procedure expose g. */
  parse arg id
  parent = self~_peekElement()
  g.0PARENT.id = parent
  parentsLastChild = g.0LAST.parent
  g.0NEXT.parentsLastChild = id
  g.0PREV.id = parentsLastChild
  g.0LAST.parent = id
  if g.0FIRST.parent = ''
  then g.0FIRST.parent = id
return

::method _characterData private
  expose g.
  
  /* _characterData: procedure expose g. */
  parse arg sChars
  id = self~_getNextId()
  self~_updateLinkage(id)
  g.0TEXT.id = sChars
  g.0TYPE.id = g.0CDATA_SECTION_NODE
return

::method _characters private
  expose g.
  /* _characters: procedure expose g. */
  parse arg sChars
  sText = self~_resolveEntities(sChars)
  if g.0OPTION.NOBLANKS & self~removeWhitespace(sText) = ''
  then return
  id = self~_getNextId()
  self~_updateLinkage(id)
  g.0TEXT.id = sText
  g.0TYPE.id = g.0TEXT_NODE
return

::method _endElement private
  expose g.
 
  /* _endElement: procedure expose g. */
  parse arg sTagName
  id = self~_popElement()
  g.0ENDOFDOC = id = 1
  if sTagName == g.0NAME.id
  then nop
  else self~_abort(,
           'XML007E Expecting </'g.0NAME.id'> but found </'sTagName'>')
return

::method _endDocument private
  expose g.
  /* _endDocument: procedure expose g. */
  id = self~_peekElement()
  if id <> 0
  then self~_abort('XML008E End of document tag missing: 'id self~getName(id))
  if g.0ROOT <> '' & g.0ROOT <> self~getName(self~getRoot())
  then self~_abort(,
                  'XML009E Root element name "'self~getName(self~getRoot())'"',
                  'does not match DTD root "'g.0ROOT'"')

  if g.0OPTION.DUMP
  then self~_displayTree
return

::method _displayTree private
  expose g.
  /* _displayTree: procedure expose g. */
  say   right('',4),
        right('',4),
        left('',12),
        right('',6),
        '--child--',
        '-sibling-',
        'attribute'
  say   right('id',4),
        right('type',4),
        left('name',12),
        right('parent',6),
        right('1st',4),
        right('last',4),
        right('prev',4),
        right('next',4),
        right('1st',4),
        right('last',4)
  do id = 1 to g.0NEXTID
    if g.0PARENT.id <> '' | id = 1 /* skip orphans */
    then do
      select
        when g.0TYPE.id = g.0CDATA_SECTION_NODE then sName = '#CDATA'
        when g.0TYPE.id = g.0TEXT_NODE          then sName = '#TEXT'
        otherwise                                    sName = g.0NAME.id
      end
      say right(id,4),
          right(g.0TYPE.id,4),
          left(sName,12),
          right(g.0PARENT.id,6),
          right(g.0FIRST.id,4),
          right(g.0LAST.id,4),
          right(g.0PREV.id,4),
          right(g.0NEXT.id,4),
          right(g.0FIRSTATTR.id,4),
          right(g.0LASTATTR.id,4),
          left(self~removeWhitespace(g.0TEXT.id),19)
    end
  end
return

::method _pushElement private
  expose g.
  /* _pushElement: procedure expose g. */
  parse arg id
  g.0STACK = g.0STACK + 1
  nStackDepth = g.0STACK
  g.0STACK.nStackDepth = id
return id

::method _popElement private
  expose g.
  /* _popElement: procedure expose g. */
  n = g.0STACK
  if n = 0
  then id = 0
  else do
    id = g.0STACK.n
    g.0STACK = g.0STACK - 1
  end
return id

::method _peekElement private
  expose g.
  /* _peekElement: procedure expose g. */
  n = g.0STACK
  if n = 0
  then id = 0
  else id = g.0STACK.n
return id

::method _getNextId private
  expose g.
  /* _getNextId: procedure expose g. */
  g.0NEXTID = g.0NEXTID + 1
return g.0NEXTID

::method _addAttributes private
  expose g.
  /* _addAttributes: procedure expose g. */
  parse arg id,sAttrs
  do while pos('ff'x,sAttrs) > 0
    parse var sAttrs sAttrName'='sAttrValue 'ff'x sAttrs
    sAttrName = self~removeWhitespace(sAttrName)
    self~_addAttribute(id,sAttrName,sAttrValue)
  end
return

::method _addAttribute private
  expose g.
  /* _addAttribute: procedure expose g. */
  parse arg id,sAttrName,sAttrValue
  aid = self~_getNextId()
  g.0TYPE.aid = g.0ATTRIBUTE_NODE
  g.0NAME.aid = sAttrName
  g.0TEXT.aid = self~_resolveEntities(sAttrValue)
  g.0PARENT.aid = id
  g.0NEXT.aid = ''
  g.0PREV.aid = ''
  if g.0FIRSTATTR.id = '' then g.0FIRSTATTR.id = aid
  if g.0LASTATTR.id <> ''
  then do
    lastaid = g.0LASTATTR.id
    g.0NEXT.lastaid = aid
    g.0PREV.aid = lastaid
  end
  g.0LASTATTR.id = aid
return

/*-------------------------------------------------------------------*
 * Resolve attributes to an internal normalized form:
 *   name1=value1'ff'x name2=value2'ff'x ...
 * This makes subsequent parsing of attributes easier.
 * Note: this design may fail for certain UTF-8 content
 *-------------------------------------------------------------------*/
::method _getNormalizedAttributes private
  expose g.
  
  /* _getNormalizedAttributes: procedure expose g. */
  parse arg sAttrs
  g.0ATTRSOK = 0
  sNormalAttrs = ''
  parse var sAttrs sAttr'='sAttrs
  do while sAttr <> ''
    sAttr = self~removeWhitespace(sAttr)
    select
      when left(sAttrs,1) = '"' then do
        if pos('"',sAttrs,2) = 0 /* if no closing "   */
        then return ''           /* then not ok       */
        parse var sAttrs '"'sAttrValue'"'sAttrs
      end
      when left(sAttrs,1) = "'" then do
        if pos("'",sAttrs,2) = 0 /* if no closing '   */
        then return ''           /* then not ok       */
        parse var sAttrs "'"sAttrValue"'"sAttrs
      end
      otherwise return ''        /* no opening ' or " */
    end
    sAttrValue = self~removeWhitespace(sAttrValue)
    sNormalAttrs = sNormalAttrs sAttr'='sAttrValue'ff'x
    parse var sAttrs sAttr'='sAttrs
  end
  g.0ATTRSOK = 1
  /* Note: always returns a leading blank and is required by
    this implementation */
return self~_resolveEntities(sNormalAttrs)


/*-------------------------------------------------------------------*
 *  entityref  := '&' entityname ';'
 *  entityname := ('_',':',letter) (letter,digit,'.','-','_',':')*
 *-------------------------------------------------------------------*/
::method _resolveEntities private
  expose g.
  /* _resolveEntities: procedure expose g. */
  parse arg sText
  if pos('&',sText) > 0
  then do
    sNewText = ''
    do while pos('&',sText) > 0
      parse var sText sLeft'&'sEntityRef
      if pos(left(sEntityRef,1),'#'g.0LEADERS) > 0
      then do
        n = verify(sEntityRef,g.0OTHERS,'NOMATCH',2)
        if n > 1
        then do
          if substr(sEntityRef,n,1) = ';'
          then do
            sEntityName = left(sEntityRef,n-1)
            sEntity = self~_getEntity(sEntityName)
            sNewText = sNewText || sLeft || sEntity
            sText = substr(sEntityRef,n+1)
          end
          else do
            sNewText = sNewText || sLeft'&'
            sText = sEntityRef
          end
        end
        else do
          sNewText = sNewText || sLeft'&'
          sText = sEntityRef
        end
      end
      else do
        sNewText = sNewText || sLeft'&'
        sText = sEntityRef
      end
    end
    sText = sNewText || sText
  end
return sText

/*-------------------------------------------------------------------*
 * &entityname;
 * &#nnnnn;
 * &#xXXXX;
 *-------------------------------------------------------------------*/
::method _getEntity private
  expose g.
  /* _getEntity: procedure expose g. */
  parse arg sEntityName
  if left(sEntityName,1) = '#' /* #nnnnn  OR  #xXXXX */
  then sEntity = self~_getCharacterEntity(sEntityName)
  else sEntity = self~_getStringEntity(sEntityName)
return sEntity

/*-------------------------------------------------------------------*
 * &#nnnnn;
 * &#xXXXX;
 *-------------------------------------------------------------------*/
::method _getCharacterEntity private
  expose g.
  /* _getCharacterEntity: procedure expose g. */
  parse arg sEntityName
  if substr(sEntityName,2,1) = 'x'
  then do
    parse arg 3 xEntity
    if datatype(xEntity,'XADECIMAL')
    then sEntity = x2c(xEntity)
    else self~_abort(,
              'XML010E Invalid hexadecimal character reference: ',
              '&'sEntityName';')
  end
  else do
    parse arg 2 nEntity
    if datatype(nEntity,'WHOLE')
    then sEntity = d2c(nEntity)
    else self~_abort(,
              'XML011E Invalid decimal character reference:',
              '&'sEntityName';')
  end
return sEntity

/*-------------------------------------------------------------------*
 * &entityname;
 *-------------------------------------------------------------------*/
::method _getStringEntity private
  expose g. 

   /* _getStringEntity: procedure expose g. */
  parse arg sEntityName
  if wordpos(sEntityName,g.0ENTITIES) = 0
  then self~_abort('XML012E Unable to resolve entity &'sEntityName';')
  sEntity = g.0ENTITY.sEntityName
return sEntity

::method _setDefaultEntities private
  expose g.

  /* _setDefaultEntities: procedure expose g. */
  g.0ENTITIES = ''
  g.0ESCAPES = '<>&"' || "'"
  sEscapes = 'lt gt amp quot apos'
  do i = 1 to length(g.0ESCAPES)
    c = substr(g.0ESCAPES,i,1)
    g.0ESCAPE.c = word(sEscapes,i)
  end
  self~_setEntity('amp','&')
  self~_setEntity('lt','<')
  self~_setEntity('gt','>')
  self~_setEntity('apos',"'")
  self~_setEntity('quot','"')
return

::method _setEntity private
  expose g.
  /* _setEntity: procedure expose g. */
  parse arg sEntityName,sValue
  if wordpos(sEntityName,g.0ENTITIES) = 0
  then g.0ENTITIES = g.0ENTITIES sEntityName
  g.0ENTITY.sEntityName = sValue
return

::method _setProcessingInstruction private
  expose g.
  /* _setProcessingInstruction: procedure expose g. */
  parse arg sTarget sInstruction
  if wordpos(sTarget,g.0PI) = 0
  then g.0PI = g.0PI sTarget
  g.0PI.sTarget = strip(sInstruction)
return

::method _abort private
  expose g.
  /* _abort: procedure expose g. */
  parse arg sMsg
  say 'ABORT:' sMsg
  self~destroyParser
exit 16

::method _clearNode private
  expose g.
  /* _clearNode: procedure expose g. */
  parse arg id
  g.0NAME.id       = '' /* The node's name */
  g.0PARENT.id     = '' /* The node's parent */
  g.0FIRST.id      = '' /* The node's first child */
  g.0LAST.id       = '' /* The node's last child */
  g.0NEXT.id       = '' /* The node's next sibling */
  g.0PREV.id       = '' /* The node's previous sibling */
  g.0TEXT.id       = '' /* The node's text content */
  g.0TYPE.id       = '' /* The node's type */
  g.0FIRSTATTR.id  = '' /* The node's first attribute */
  g.0LASTATTR.id   = '' /* The node's last attribute */
return

/*-------------------------------------------------------------------*
 * Utility API
 *-------------------------------------------------------------------*/
::method removeWhitespace
  expose g.
  /* removeWhitespace: procedure expose g. */
  parse arg sData
return space(translate(sData,'',g.0WHITESPACE))

::method removeQuotes
  expose g.
  /* removeQuotes: procedure expose g. */
  parse arg sValue
  c = left(sValue,1)
  select
    when c = '"' then parse var sValue '"'sValue'"'
    when c = "'" then parse var sValue "'"sValue"'"
    otherwise nop
  end
return sValue

/*-------------------------------------------------------------------*
 * Document Object Model ;-) API
 *-------------------------------------------------------------------*/
::method getRoot
 expose g. 
  /* getRoot: procedure expose g. * DEPRECATED * */
return 1

::method getDocumentElement
  expose g.
  /* getDocumentElement: procedure expose g. */
return 1

::method getName
  expose g.
  /* getName: getNodeName: procedure expose g. */
  parse arg id
return g.0NAME.id
::method getNodeName
  expose g.
  parse arg id
return g.0NAME.id

::method getText
  expose g.
  /* getText: getNodeValue: procedure expose g. */
  parse arg id
return g.0TEXT.id

::method getNodeValue
  expose g.
  parse arg id
return g.0TEXT.id

::method getNodeType
 expose g.
  /* getNodeType: procedure expose g. */
  parse arg id
return g.0TYPE.id

::method isElementNode
  expose g.
  /* isElementNode: procedure expose g. */
  parse arg id
return g.0TYPE.id = g.0ELEMENT_NODE

::method isTextNode
  expose g.
  /* isTextNode: procedure expose g. */
  parse arg id
return g.0TYPE.id = g.0TEXT_NODE

::method isCommentNode
  expose g.
  /* isCommentNode: procedure expose g. */
  parse arg id
return g.0TYPE.id = g.0COMMENT_NODE

::method isCDATA
  expose g.
  /* isCDATA: procedure expose g. */
  parse arg id
return g.0TYPE.id = g.0CDATA_SECTION_NODE

::method isDocumentNode
  expose g.
  /* isDocumentNode: procedure expose g. */
  parse arg id
return g.0TYPE.id = g.0DOCUMENT_NODE

::method isDocumentFragmentNode
  expose g.
  /* isDocumentFragmentNode: procedure expose g. */
  parse arg id
return g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE

/**
 * This is similar to the DOM API's NamedNodeMap concept, except that
 * the returned structure is built in global variables (so calling
 * it a second time will destroy the structure built on the first
 * call). The other difference is that you can access the attributes
 * by name or ordinal number. For example, g.0ATTRIBUTE.2 is the value
 * of the second attribute. If the second attribute was called 'x',
 * then you could also access it by g.0ATTRIBUTE.x (as long as x='x')
 * Note, g.0ATTRIBUTE.0 will always contain a count of the number of
 * attributes in the map.
 */
::method getAttributeMap
  expose g.
  /* getAttributeMap: procedure expose g. */
  parse arg id
  if datatype(g.0ATTRIBUTE.0,'WHOLE')  /* clear any existing map */
  then do
    do i = 1 to g.0ATTRIBUTE.0
      sName = g.0ATTRIBUTE.i
      drop g.0ATTRIBUTE.sName g.0ATTRIBUTE.i
    end
  end
  g.0ATTRIBUTE.0 = 0
  if \self~_canHaveAttributes(id) then return
  aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
  do i = 1 while aid <> ''
    sName = g.0NAME.aid
    sValue = g.0TEXT.aid
    g.0ATTRIBUTE.0 = i
    g.0ATTRIBUTE.i = sName
    g.0ATTRIBUTE.sName = sValue
    aid = g.0NEXT.aid /* id of next attribute */
  end
return

::method getAttributeCount
  expose g.
  /* getAttributeCount: procedure expose g. */
  parse arg id
  nAttributeCount = 0
  if self~_canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    do while aid <> ''
      nAttributeCount = nAttributeCount + 1
      aid = g.0NEXT.aid /* id of next attribute */
    end
  end
return nAttributeCount

::method getAttributeNames
  expose g.
  /* getAttributeNames: procedure expose g. */
  parse arg id
  sNames = ''
  if self~_canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    do while aid <> ''
      sNames = sNames g.0NAME.aid
      aid = g.0NEXT.aid /* id of next attribute */
    end
  end
return strip(sNames)

::method getAttribute
  expose g.
  /* getAttribute: procedure expose g. */
  parse arg id,sAttrName
  sValue = ''
  if self~_canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    if aid <> ''
    then do
      n = 1
      do while aid <> '' & (g.0NAME.aid <> sAttrName & n <> sAttrName)
        aid = g.0NEXT.aid
        n = n + 1
      end
      if g.0NAME.aid = sAttrName | n = sAttrName
      then sValue = g.0TEXT.aid
    end
  end
return sValue

::method getAttributeName
  expose g.
  /* getAttributeName: procedure expose g. */
  parse arg id,n
  sName = ''
  if self~_canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    if aid <> ''
    then do
      do i = 1 while aid <> '' & i < n
        aid = g.0NEXT.aid
      end
      if i = n then sName = g.0NAME.aid
    end
  end
return sName

::method hasAttribute
  expose g.
  /* hasAttribute: procedure expose g. */
  parse arg id,sAttrName
  bHasAttribute = 0
  if self~_canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id
    if aid <> ''
    then do
      do while aid <> '' & g.0NAME.aid <> sAttrName
        aid = g.0NEXT.aid
      end
      bHasAttribute = g.0NAME.aid = sAttrName
    end
  end
return bHasAttribute

::method _canHaveAttributes private
  expose g.
  /* _canHaveAttributes: procedure expose g. */
  parse arg id
return g.0TYPE.id = g.0ELEMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE

::method _canHaveChildren private
  expose g.
  /* _canHaveChildren: procedure expose g. */
  parse arg id
return g.0TYPE.parent <> g.0ELEMENT_NODE &,
       g.0TYPE.parent <> g.0DOCUMENT_NODE &,
       g.0TYPE.parent <> g.0DOCUMENT_FRAGMENT_NODE

::method getParent  
  expose g.
  parse arg id
return g.0PARENT.id
::method getParentNode
  expose g.

  parse arg id
return g.0PARENT.id

::method getFirstChild
  expose g.
  /* getFirstChild: procedure expose g. */
  parse arg id
return g.0FIRST.id

::method getLastChild
  expose g.
  /* getLastChild: procedure expose g. */
  parse arg id
return g.0LAST.id

::method getChildren
  expose g.

  parse arg id
return self~getChildNodes(id)
::method getChildNodes
  expose g.

  parse arg id
  ids = ''
  id = self~getFirstChild(id)
  do while id <> ''
    ids = ids id
    id = self~getNextSibling(id)
  end
return strip(ids)

::method getChildrenByName
  expose g.
  /* getChildrenByName: procedure expose g. */
  parse arg id,sName
  ids = ''
  id = self~getFirstChild(id)
  do while id <> ''
    if self~getName(id) = sName
    then ids = ids id
    id = self~getNextSibling(id)
  end
return strip(ids)

::method getElementsByTagName
  expose g.
  /* getElementsByTagName: procedure expose g. */
  parse arg id,sName
  ids = ''
  id = self~getFirstChild(id)
  do while id <> ''
    if self~getName(id) = sName
    then ids = ids id
    ids = ids self~getElementsByTagName(id,sName)
    id = self~getNextSibling(id)
  end
return space(ids)

::method getNextSibling
  expose g.
  /* getNextSibling: procedure expose g. */
  parse arg id
return g.0NEXT.id

::method getPreviousSibling
  expose g.
  /* getPreviousSibling: procedure expose g. */
  parse arg id
return g.0PREV.id

::method getProcessingInstruction
  expose g.
  /* getProcessingInstruction: procedure expose g. */
  parse arg sTarget
return g.0PI.sTarget

::method getProcessingInstructionList
  expose g.
  /* getProcessingInstructionList: procedure expose g. */
return g.0PI

::method hasChildren
  expose g.
  
  /* hasChildren: hasChildNodes: procedure expose g. */
  parse arg id
return g.0FIRST.id <> ''
  
::method hasChildNodes
  expose g.
  /* hasChildren: hasChildNodes: procedure expose g. */
  parse arg id
return g.0FIRST.id <> ''

::method createDocument
  expose g.
  /* createDocument: procedure expose g. */
  parse arg sName
  if sName = ''
  then self~_abort(,
            'XML013E Tag name omitted:',
            'createDocument('sName')')
  self~destroyParser
  g.0NEXTID = 0
  id = self~_getNextId()
  self~_clearNode(id)
  g.0TYPE.id = g.0DOCUMENT_NODE /* 20070323 */
  g.0NAME.id = sName
  g.0PARENT.id = 0
return id

::method createDocumentFragment
  expose g.
  /* createDocumentFragment: procedure expose g. * 20070323 */
  parse arg sName
  if sName = ''
  then self~_abort(,
            'XML014E Tag name omitted:',
            'createDocumentFragment('sName')')
  id = self~_getNextId()
  self~_clearNode(id)
  g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE
  g.0NAME.id = sName
  g.0PARENT.id = 0
return id

::method createElement
  expose g.
  /* createElement: procedure expose g. */
  parse arg sName
  id = self_getNextId()
  self~_clearNode(id)
  g.0TYPE.id = g.0ELEMENT_NODE
  g.0NAME.id = sName
return id

::method createCDATASection
  expose g.
  /* createCDATASection: procedure expose g. */
  parse arg sCharacterData
  id = self~_getNextId()
  self~_clearNode(id)
  g.0TYPE.id = g.0CDATA_SECTION_NODE
  g.0TEXT.id = sCharacterData
return id

::method createTextNode
  expose g.
  /* createTextNode: procedure expose g. */
  parse arg sData
  id = self~_getNextId()
  self~_clearNode(id)
  g.0TYPE.id = g.0TEXT_NODE
  g.0TEXT.id = sData
return id

::method appendChild
  expose g.
  /* appendChild: procedure expose g. */
  parse arg id, parent
  if \self~_canHaveChildren(parent)
  then self~_abort(,
            'XML015E' g.0NODETYPE.parent 'node cannot have children:',
            'appendChild('id','parent')')
  if g.0PARENT.id = ''
  then g.0PARENT.id = parent
  else self~_abort(,
            'XML016E Node <'self~getNodeName(id)'> is already a child',
            'of <'self~getNodeName(g.0PARENT.id)'>:',
            'appendChild('id','parent')')
  parentsLastChild = g.0LAST.parent
  g.0NEXT.parentsLastChild = id
  g.0PREV.id = parentsLastChild
  g.0LAST.parent = id
  if g.0FIRST.parent = ''
  then g.0FIRST.parent = id
return

::method insertBefore
  expose g.
  /* insertBefore: procedure expose g. */
  parse arg id, ref
  parent = g.0PARENT.ref
  if \self~_canHaveChildren(parent)
  then self~_abort(,
            'XML017E' g.0NODETYPE.parent 'node cannot have children:',
            'insertBefore('id','ref')')
  if g.0PARENT.id = ''
  then g.0PARENT.id = parent
  else self~_abort(,
            'XML018E Node <'self~getNodeName(id)'> is already a child',
            'of <'self~getNodeName(g.0PARENT.id)'>:',
            'insertBefore('id','ref')')
  g.0NEXT.id = ref
  g.0PREV.ref = id
  if g.0FIRST.parent = ref
  then g.0FIRST.parent = id
return

::method removeChild
  expose g.
  /* removeChild: procedure expose g. */
  parse arg id
  parent = g.0PARENT.id
  if \self~_canHaveChildren(parent)
  then self~_abort(,
            'XML019E' g.0NODETYPE.parent 'node cannot have children:',
            'removeChild('id')')
  next = g.0NEXT.id
  prev = g.0PREV.id
  g.0NEXT.prev = next
  g.0PREV.next = prev
  if g.0FIRST.parent = id
  then g.0FIRST.parent = next
  if g.0LAST.parent = id
  then g.0LAST.parent = prev
  g.0PARENT.id = ''
  g.0NEXT.id = ''
  g.0PREV.id = ''
return id

::method replaceChild
  expose g.
  /* replaceChild: procedure expose g. */
  parse arg id, extant
  parent = g.0PARENT.extant
  if \self~_canHaveChildren(parent)
  then self~_abort(,
            'XML020E' g.0NODETYPE.parent 'node cannot have children:',
            'replaceChild('id','extant')')
  g.0PARENT.id = parent
  g.0NEXT.id = g.0NEXT.extant
  g.0PREV.id = g.0PREV.extant
  if g.0FIRST.parent = extant
  then g.0FIRST.parent = id
  if g.0LAST.parent = extant
  then g.0LAST.parent = id
  g.0PARENT.extant = ''
  g.0NEXT.extant = ''
  g.0PREV.extant = ''
return extant

::method setAttribute
  expose g.
  /* setAttribute: procedure expose g. */
  parse arg id,sAttrName,sValue
  if \self~_canHaveAttributes(id)
  then self~_abort(,
            'XML021E' g.0NODETYPE.id 'node cannot have attributes:',
            'setAttribute('id','sAttrName','sValue')')
  aid = g.0FIRSTATTR.id
  do while aid <> '' & g.0NAME.aid <> sAttrName
    aid = g.0NEXT.aid
  end
  if aid <> '' & g.0NAME.aid = sAttrName
  then g.0TEXT.aid = sValue
  else self~_addAttribute(id,sAttrName,sValue)
return

::method setAttributes
  expose g.
  /* setAttributes: procedure expose g. */
  parse arg id /* ,name1,value1,name2,value2,...,namen,valuen */
  do i = 2 to arg() by 2
    sAttrName = arg(i)
    sValue = arg(i+1)
    self~setAttribute(id,sAttrName,sValue)
  end
return

::method removeAttribute
  expose g.
  /* removeAttribute: procedure expose g. */
  parse arg id,sAttrName
  if \self~_canHaveAttributes(id)
  then self~_abort(,
            'XML022E' g.0NODETYPE.id 'node cannot have attributes:',
            'removeAttribute('id','sAttrName')')
  aid = g.0FIRSTATTR.id
  do while aid <> '' & g.0NAME.aid <> sAttrName
    aid = g.0NEXT.aid
  end
  if aid <> '' & g.0NAME.aid = sAttrName
  then do
    prevaid = g.0PREV.aid
    nextaid = g.0NEXT.aid
    if prevaid = ''  /* if we are deleting the first attribute */
    then g.0FIRSTATTR.id = nextaid /* make next attr the first */
    else g.0NEXT.prevaid = nextaid /* link prev attr to next attr */
    if nextaid = '' /* if we are deleting the last attribute */
    then g.0LASTATTR.id  = prevaid /* make prev attr the last */
    else g.0PREV.nextaid = prevaid /* link next attr to prev attr */
    self~_clearNode(aid)
  end
return

::method toString
  expose g.
  /* toString: procedure expose g. */
  parse arg node
  if node = '' then node = self~getRoot()
  if node = self~getRoot()
  then sXML = self~_getProlog()self~_getNode(node)
  else sXML = self~_getNode(node)
return sXML

::method _getProlog private
  expose g.
  /* _getProlog: procedure expose g. */
  if g.?xml.version = ''
  then sVersion = '1.0'
  else sVersion = g.?xml.version
  if g.?xml.encoding = ''
  then sEncoding = 'UTF-8'
  else sEncoding = g.?xml.encoding
  if g.?xml.standalone = ''
  then sStandalone = 'yes'
  else sStandalone = g.?xml.standalone
  sProlog = '<?xml version="'sVersion'"',
            'encoding="'sEncoding'"',
            'standalone="'sStandalone'"?>'
return sProlog

::method _getNode private
  expose g.
  /* _getNode: procedure expose g. */
  parse arg node
  select
    when g.0TYPE.node = g.0ELEMENT_NODE then,
         sXML = self~_getElementNode(node)
    when g.0TYPE.node = g.0TEXT_NODE then,
         sXML = self~escapeText(self~removeWhitespace(self~getText(node)))
    when g.0TYPE.node = g.0ATTRIBUTE_NODE then,
         sXML = self~getName(node)'="'self~escapeText(self~getText(node))'"'
    when g.0TYPE.node = g.0CDATA_SECTION_NODE then,
         sXML = '<![CDATA['self~getText(node)']]>'
    otherwise sXML = '' /* TODO: throw an error here? */
  end
return sXML

::method _getElementNode private
  expose g.
  /* _getElementNode: procedure expose g. */
  parse arg node
  sName = self~getName(node)
  sAttrs = ''
  attr = g.0FIRSTATTR.node
  do while attr <> ''
    sAttrs = sAttrs self~_getNode(attr)
    attr = g.0NEXT.attr
  end
  if self~hasChildren(node)
  then do
    if sAttrs = ''
    then sXML = '<'sName'>'
    else sXML = '<'sName strip(sAttrs)'>'
    child = self~getFirstChild(node)
    do while child <> ''
      sXML = sXML || self~_getNode(child)
      child = self~getNextSibling(child)
    end
    sXML = sXML'</'sName'>'
  end
  else do
    if sAttrs = ''
    then sXML = '<'sName'/>'
    else sXML = '<'sName strip(sAttrs)'/>'
  end
return sXML

::method escapeText
  expose g.
  /* escapeText: procedure expose g. */
  parse arg sText
  n = verify(sText,g.0ESCAPES,'MATCH')
  if n > 0
  then do
    sNewText = ''
    do while n > 0
      sLeft = ''
      n = n - 1
      if n = 0
      then parse var sText c +1 sText
      else parse var sText sLeft +(n) c +1 sText
      sNewText = sNewText || sLeft'&'g.0ESCAPE.c';'
      n = verify(sText,g.0ESCAPES,'MATCH')
    end
    sText = sNewText || sText
  end
return sText

/*-------------------------------------------------------------------*
 * SYSTEM "sysid"
 * PUBLIC "pubid" "sysid"
 *-------------------------------------------------------------------*/
::method setDocType
  expose g.
  /* setDocType: procedure expose g. */
  parse arg sDocType
  g.0DOCTYPE = sDocType
return

::method getDocType
  expose g.
  /* getDocType: procedure expose g. */
return g.0DOCTYPE

::method createComment
  expose g.
  /* createComment: procedure expose g. */
  parse arg sData
  id = self~_getNextId()
  self~_clearNode(id)
  g.0TYPE.id = g.0COMMENT_NODE
  g.0TEXT.id = sData
return id

::method deepClone
  expose g.
  /* deepClone: procedure expose g. */
  parse arg node
return self~cloneNode(node,1)

::method cloneNode 
  expose g.
  /* cloneNode: procedure expose g. */
  parse arg node,bDeep
  clone = self~_getNextId()
  self~_clearNode(clone)
  g.0TYPE.clone = g.0TYPE.node
  g.0NAME.clone = g.0NAME.node
  g.0TEXT.clone = g.0TEXT.node
  /* clone any attributes...*/
  aidin = g.0FIRSTATTR.node
  do while aidin <> ''
    aid = self~_getNextId()
    g.0TYPE.aid = g.0TYPE.aidin
    g.0NAME.aid = g.0NAME.aidin
    g.0TEXT.aid = g.0TEXT.aidin
    g.0PARENT.aid = clone
    g.0NEXT.aid = ''
    g.0PREV.aid = ''
    if g.0FIRSTATTR.clone = '' then g.0FIRSTATTR.clone = aid
    if g.0LASTATTR.clone <> ''
    then do
      lastaid = g.0LASTATTR.clone
      g.0NEXT.lastaid = aid
      g.0PREV.aid = lastaid
    end
    g.0LASTATTR.clone = aid
    aidin = g.0NEXT.aidin
  end
  /* clone any children (if deep clone was requested)...*/
  if bDeep = 1
  then do
    childin = g.0FIRST.node /* first child of node being cloned */
    do while childin <> ''
      child = self~cloneNode(childin,bDeep)
      g.0PARENT.child = clone
      parentsLastChild = g.0LAST.clone
      g.0NEXT.parentsLastChild = child
      g.0PREV.child = parentsLastChild
      g.0LAST.clone = child
      if g.0FIRST.clone = ''
      then g.0FIRST.clone = child
      childin = g.0NEXT.childin /* next child of node being cloned */
    end
  end
return clone
/*REXX*****************************************************************
**                                                                   **
** NAME     - PRETTY    (Converted to ooRexx)                        **
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
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com     **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --------------------------------------------- **
**            20160818 PWD Changed to work with incumbent parsed     **
**                         parsed file.                              **
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
::method pretty
  expose g.
  parse arg sFileIn sFileOut' ('sOptions')'
  parse value sourceline(1) with . sVersion
  say 'PRP000I Pretty Printer' sVersion

  /* Initialise the parser */
  /* call initParser sOptions * <-- This is in PARSEXML rexx */

  /* Open the specified file and parse it */
  /* nParseRC = parseFile(sFileIn) */

  /* parse source g.0ENV . */
  if g.0ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.0LINES = 0
  end

  /* call prettyPrinter sFileOut,2 * 2 is the indentation amount */
  self~prettyPrinter(sFileOut,2)  

/* return nParseRC */
return

::method prettyPrinter
  expose g.
  /* prettyPrinter: procedure expose g. */
  parse arg sFileOut,g.0TAB,nRoot
  if g.0TAB = '' then g.0TAB = 2 /* indentation amount */
  if nRoot = '' then nRoot = self~getRoot()
  g.0INDENT = 0
  g.0FILEOUT = ''
  if sFileOut <> ''
  then do
    g.0FILEOUT = self~openFile(sFileOut,'OUTPUT')
    if g.0rc = 0
    then say 'PRP001I Creating' sFileOut
    else do
      say 'PRP002E Could not create' sFileOut'. Writing to console...'
      g.0FILEOUT = '' /* null handle means write to console */
    end
  end

  self~_setDefaultEntities

  self~emitProlog
  g.0INDENT = -g.0TAB
  self~showNode(nRoot)

  if g.0FILEOUT <> ''
  then do
    say 'PRP002I Created' sFileOut
    rc = self~closeFile(g.0FILEOUT)
  end
return


::method emitProlog private
  expose g.
  /* emitProlog: procedure expose g. */
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
  self~newSay('<?xml version="'sVersion'"',
                'encoding="'sEncoding'"',
              'standalone="'sStandalone'"?>')

  sDocType = self~getDocType()
  if sDocType <> ''
  then self~newSay('<!DOCTYPE' self~getName(,
                               self~getDocumentElement()) sDocType'>')
return

::method showNode private
  expose g.
  /* showNode: procedure expose g. */
  parse arg node
  g.0INDENT = g.0INDENT + g.0TAB
  select
    when self~isTextNode(node)    then self~emitTextNode(   node)
    when self~isCommentNode(node) then self~emitCommentNode(node)
    when self~isCDATA(node)       then self~emitCDATA(      node)
    otherwise                          self~emitElementNode(node)
  end
  g.0INDENT = g.0INDENT - g.0TAB
return

::method emitTextNode private
  expose g.
  /* emitTextNode: procedure expose g. */
  parse arg node
  if g.0PRESERVEWS = 1
  then self~newSay(self~escapeText(self~getText(node)))
  else self~newSay(self~escapeText(self~removeWhitespace(self~getText(node))))
return

::method emitCommentNode private
  expose g.
  /* emitCommentNode: procedure expose g. */
  parse arg node
  self~newSay('<!--'self~getText(node)' -->')
return

::method emitCDATA private
  expose g.
  /* emitCDATA: procedure expose g. */
  parse arg node
  self~newSay('<![CDATA['self~getText(node)']]>')
return

::method emitElementNode private
  expose g.
  /* emitElementNode: procedure expose g. */
  parse arg node
  sName = self~getName(node)
  sAttrs = ''
  do i = 1 to self~getAttributeCount(node)
    sAttrs = sAttrs self~getAttributeName(node,i)'="' ||,
                    self~escapeText(self~getAttribute(node,i))'"'
  end
  sChildren = self~getChildren(node)
  if sChildren = ''
  then do
    if sAttrs = ''
    then self~newSay('<'sName'/>')
    else self~newSay('<'sName strip(sAttrs)'/>')
  end
  else do
    if sAttrs = ''
    then self~newSay('<'sName'>')
    else self~newSay('<'sName strip(sAttrs)'>')
    child = self~getFirstChild(node)
    do while child <> ''
      self~showNode(child)
      child = self~getNextSibling(child)
    end
    self~newSay('</'sName'>')
  end
return

::method newSay private
  expose g.
  /* Say: procedure expose g. */
  parse arg sMessage
  sLine = copies(' ',g.0INDENT)sMessage
  if g.0FILEOUT = ''
  then say sLine
  else self~putLine(g.0FILEOUT,sLine)
return
/*REXX*****************************************************************
**                                                                   **
** NAME     - IO      (Converted to ooRexx)                          **
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

/*-------------------------------------------------------------------*
 * Open a file                                                       *
 *-------------------------------------------------------------------*/
::method openFile
  expose g.
  /* openFile: procedure expose g. */
  parse arg sFile,sOptions,sAttrs
  hFile = ''
  select
    when g.0ENV = 'TSO' then do
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
        g.0MEMBER.hFile = sMember
        'LMMFIND DATAID(&hFile) MEMBER('sMember') STATS(YES)'
        if bOutput
        then do
          if rc = 0
          then g.0STATS.hFile = zlvers','zlmod','zlc4date
          else g.0STATS.hFile = '1,0,0000/00/00'
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
                      'LRECL('g.0OPTION.WRAP.1 + 4')',
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
      g.0OPTIONS.hFile = sOptions
      g.0rc = rc /* Return code from LMOPEN */
    end
    otherwise do
      if wordpos('OUTPUT',sOptions) > 0
      then junk = stream(sFile,'COMMAND','OPEN WRITE REPLACE')
      else junk = stream(sFile,'COMMAND','OPEN READ')
      hFile = sFile
      if stream(sFile,'STATUS') = 'READY'
      then g.0rc = 0
      else g.0rc = 4
    end
  end
return hFile

/*-------------------------------------------------------------------*
 * Read a line from the specified file                               *
 *-------------------------------------------------------------------*/
::method getLine
  expose g.
  /* getLine: procedure expose g. */
  parse arg hFile
  sLine = ''
  select
    when g.0ENV = 'TSO' then do
      'LMGET DATAID(&hFile) MODE(INVAR)',
            'DATALOC(sLine) DATALEN(nLine) MAXLEN(32768)'
      g.0rc = rc
      sLine = strip(sLine,'TRAILING')
      if sLine = '' then sLine = ' '
    end
    otherwise do
      g.0rc = 0
      if chars(hFile) > 0
      then sLine = linein(hFile)
      else g.0rc = 4
    end
  end
return sLine

/*-------------------------------------------------------------------*
 * Append a line to the specified file                               *
 *-------------------------------------------------------------------*/
::method putLine
  expose g.
  /* putLine: procedure expose g. */
  parse arg hFile,sLine
  select
    when g.0ENV = 'TSO' then do
      g.0LINES = g.0LINES + 1
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
 * Close the specified file                                          *
 *-------------------------------------------------------------------*/

::method closeFile
  expose g.
  /* closeFile: procedure expose g. */
  parse arg hFile
  rc = 0
  select
    when g.0ENV = 'TSO' then do
      if g.0MEMBER.hFile <> '', /* if its a PDS */
      & wordpos('OUTPUT',g.0OPTIONS.hFile) > 0 /* opened for output */
      then do
        parse value date('STANDARD') with yyyy +4 mm +2 dd +2
        parse var g.0STATS.hFile zlvers','zlmod','zlc4date
        zlcnorc  = min(g.0LINES,65535)   /* Number of lines   */
        nVer = right(zlvers,2,'0')right(zlmod,2,'0')  /* vvmm */
        nVer = right(nVer+1,4,'0')       /* vvmm + 1          */
        parse var nVer zlvers +2 zlmod +2
        if zlc4date = '0000/00/00'
        then zlc4date = yyyy'/'mm'/'dd   /* Creation date     */
        zlm4date = yyyy'/'mm'/'dd        /* Modification date */
        zlmtime  = time()                /* Modification time */
        zluser   = userid()              /* Modification user */
        'LMMREP DATAID(&hFile) MEMBER('g.0MEMBER.hFile') STATS(YES)'
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
