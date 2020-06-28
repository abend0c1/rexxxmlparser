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

/**********************************************************************
**                                                                   **
** ALL CODE BELOW THIS POINT BELONGS TO THE XML PARSER. YOU MUST     **
** APPEND IT TO ANY REXX SOURCE FILE THAT REQUIRES AN XML PARSING    **
** CAPABILITY. SINCE REXX HAS NO 'LIBRARY' FUNCTIONALITY, A WAY TO   **
** AVOID HAVING DIFFERENT VERSIONS OF THE PARSER IN EACH OF YOUR     **
** REXX PROCS IS TO DYNAMICALLY APPEND A CENTRAL VERSION TO EACH OF  **
** YOUR REXX PROCS BEFORE EXECUTION.                                 **
**                                                                   **
** THE EXACT PROCEDURE TO FOLLOW DEPENDS ON YOUR PLATFORM, BUT...    **
** TO HELP YOU DO THIS, I HAVE INCLUDED A REXX PRE-PROCESSOR CALLED  **
** REXXPP THAT CAN BE USED TO SEARCH FOR 'INCLUDE' DIRECTIVES AND    **
** REPLACE THEM WITH THE SPECIFIED FILE CONTENTS. IT HAS BEEN TESTED **
** ON TSO, AND ON WIN32 USING REGINA REXX VERSION 3.3.               **
**                                                                   **
**********************************************************************/

/*REXX*****************************************************************
**                                                                   **
** NAME     - PARSEXML                                               **
**                                                                   **
** FUNCTION - A Rexx XML parser. It is non-validating, so DTDs and   **
**            XML schemas are ignored. Ok, DTD entities are processed**
**            but that's all.                                        **
**                                                                   **
** USAGE    - 1. Initialize the parser by:                           **
**                                                                   **
**               call initParser [options...]                        **
**                                                                   **
**            2. Parse the XML file to build an in-memory model      **
**                                                                   **
**               returncode = parseFile('filename')                  **
**                ...or...                                           **
**               returncode = parseString('xml in a string')         **
**                                                                   **
**            3. Navigate the in-memory model with the DOM API. For  **
**               example:                                            **
**                                                                   **
**               say 'The document element is called',               **
**                                   getName(getDocumentElement())   **
**               say 'Children of the document element are:'         **
**               node = getFirstChild(getDocumentElement())          **
**               do while node <> ''                                 **
**                 if isElementNode(node)                            **
**                 then say 'Element node:' getName(node)            **
**                 else say '   Text node:' getText(node)            **
**                 node = getNextSibling(node)                       **
**               end                                                 **
**                                                                   **
**            4. Optionally, destroy the in-memory model:            **
**                                                                   **
**               call destroyParser                                  **
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
** NOTES    - 1. This parser creates global variables and so its     **
**               operation may be severely jiggered if you update    **
**               any of them accidentally (or on purpose). The       **
**               variables you should avoid updating yourself are:   **
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
**            2. To reduce the incidence of name clashes, procedure  **
**               names that are not meant to be part of the public   **
**               API have been prefixed with '_'.                    **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** CONTRIBUTORS -                                                    **
**            Alessandro Battilani                                   **
**              <alessandro.battilani@bancaintesa.it>                **
**                                                                   **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top pls)       **
**            -------- --------------------------------------------- **
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

  parse source . . sSourceFile .
  parse value sourceline(1) with . sVersion
  say 'Rexx XML Parser' sVersion
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
 * Set up global variables for the parser
 *-------------------------------------------------------------------*/

initParser: procedure expose g.
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

  g.0LEADERS = '_:ABCDEFGHIJKLMNOPQRSTUVWXYZ' ||,
                 'abcdefghijklmnopqrstuvwxyz'
  g.0OTHERS  = g.0LEADERS'.-0123456789'

  call _setDefaultEntities

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

destroyParser: procedure expose g.
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
  call _setDefaultEntities
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

parseFile: procedure expose g.
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
      sXmlData = charin(sFile,,chars(sFile))
    end
  end
return parseString(sXmlData)

/*-------------------------------------------------------------------*
 * Parse a string containing XML
 *-------------------------------------------------------------------*/

parseString: procedure expose g.
  parse arg g.0XML
  call _parseXmlDecl
  do while pos('<',g.0XML) > 0
    parse var g.0XML sLeft'<'sData
    select
      when left(sData,1) = '?'         then call _parsePI      sData
      when left(sData,9) = '!DOCTYPE ' then call _parseDocType sData
      when left(sData,3) = '!--'       then call _parseComment sData
      otherwise                             call _parseElement sData
    end
  end
return 0

/*-------------------------------------------------------------------*
 * <?xml version="1.0" encoding="..." ...?>
 *-------------------------------------------------------------------*/

_parseXmlDecl: procedure expose g.
  if left(g.0XML,6) = '<?xml '
  then do
    parse var g.0XML '<?xml 'sXMLDecl'?>'g.0XML
    g.?xml = space(sXMLDecl)
    sTemp = _getNormalizedAttributes(g.?xml)
    parse var sTemp 'version='g.?xml.version'ff'x
    parse var sTemp 'encoding='g.?xml.encoding'ff'x
    parse var sTemp 'standalone='g.?xml.standalone'ff'x
  end
return

/*-------------------------------------------------------------------*
 * <?target string?>
 *-------------------------------------------------------------------*/

_parsePI: procedure expose g.
  parse arg '?'sProcessingInstruction'?>'g.0XML
  call _setProcessingInstruction sProcessingInstruction
return

/*-------------------------------------------------------------------*
 * <!DOCTYPE root SYSTEM "sysid">
 * <!DOCTYPE root SYSTEM "sysid" [internal dtd]>
 * <!DOCTYPE root PUBLIC "pubid" "sysid">
 * <!DOCTYPE root PUBLIC "pubid" "sysid" [internal dtd]>
 * <!DOCTYPE root [internal dtd]>
 *-------------------------------------------------------------------*/

_parseDocType: procedure expose g.
  parse arg '!DOCTYPE' sDocType'>'
  if g.0ROOT <> ''
  then call _abort 'XML002E Multiple "<!DOCTYPE" declarations'
  if pos('[',sDocType) > 0
  then do
    parse arg '!DOCTYPE' sDocType'['g.0DTD']>'g.0XML
    parse var sDocType g.0ROOT sExternalId
    if sExternalId <> '' then call _parseExternalId sExternalId
    g.0DTD = strip(g.0DTD)
    call _parseDTD g.0DTD
  end
  else do
    parse arg '!DOCTYPE' g.0ROOT sExternalId'>'g.0XML
    if sExternalId <> '' then call _parseExternalId sExternalId
  end
  g.0ROOT = strip(g.0ROOT)
return

/*-------------------------------------------------------------------*
 * SYSTEM "sysid"
 * PUBLIC "pubid" "sysid"
 *-------------------------------------------------------------------*/

_parseExternalId: procedure expose g.
  parse arg sExternalIdType .
  select
    when sExternalIdType = 'SYSTEM' then do
      parse arg . g.0SYSTEM
      g.0SYSTEM = removeQuotes(g.0SYSTEM)
    end
    when sExternalIdType = 'PUBLIC' then do
      parse arg . g.0PUBLIC g.0SYSTEM
      g.0PUBLIC = removeQuotes(g.0PUBLIC)
      g.0SYSTEM = removeQuotes(g.0SYSTEM)
    end
    otherwise do
       parse arg sExternalEntityDecl
       call _abort 'XML003E Invalid external entity declaration:',
                   sExternalEntityDecl
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

_parseDTD: procedure expose g.
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
            sValue = _resolveEntities(removeQuotes(sValue))
            call _setEntity sName,sValue
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

_parseComment: procedure expose g.
  parse arg sComment'-->'g.0XML
  /* silently ignore comments */
return

/*-------------------------------------------------------------------*
 * <tag attr1="value1" attr2="value2" ...>...</tag>
 * <tag attr1="value1" attr2="value2" .../>
 *-------------------------------------------------------------------*/

_parseElement: procedure expose g.
  parse arg sXML

  if g.0ENDOFDOC
  then call _abort 'XML004E Only one top level element is allowed.',
                  'Found:' subword(g.0XML,1,3)
  call _startDocument

  g.0XML = '<'sXML
  do while pos('<',g.0XML) > 0 & \g.0ENDOFDOC
    parse var g.0XML sLeft'<'sBetween'>'g.0XML

    if length(sLeft) > 0
    then call _characters sLeft

    if g.0OPTION.DEBUG
    then say g.0STACK sBetween

    if left(sBetween,8) = '![CDATA[' 
    then do
      g.0XML = sBetween'>'g.0XML            /* ..back it out! */
      parse var g.0XML '![CDATA['sBetween']]>'g.0XML
      call _characterData sBetween
    end
    else do
      sBetween = removeWhiteSpace(sBetween)                /*20090822*/
      select
        when left(sBetween,3) = '!--' then do    /* <!-- comment --> */
          if right(sBetween,2) <> '--'
          then do  /* backup a bit and look for end-of-comment */
            g.0XML = sBetween'>'g.0XML
            if pos('-->',g.0XML) = 0
            then call _abort 'XML005E End of comment missing after:',
                            '<'g.0XML
            parse var g.0XML sComment'-->'g.0XML
          end
        end
        when left(sBetween,1) = '?' then do    /* <?target string?> */
          parse var sBetween '?'sProcessingInstruction'?'
          call _setProcessingInstruction sProcessingInstruction
        end
        when left(sBetween,1) = '/' then do    /* </tag> */
          call _endElement substr(sBetween,2)   /* tag */
        end
        when  right(sBetween,1) = '/'  /* <tag ...attrs.../> */
        then do
          parse var sBetween sTagName sAttrs
          if length(sAttrs) > 0                            /*20031216*/
          then sAttrs = substr(sAttrs,1,length(sAttrs)-1)  /*20031216*/
          else parse var sTagName sTagName'/'     /* <tag/>  20031216*/
          sAttrs = _getNormalizedAttributes(sAttrs)
          call _startElement sTagName sAttrs
          call _endElement sTagName
        end
        otherwise do              /* <tag ...attrs ...> ... </tag>  */
          parse var sBetween sTagName sAttrs
          sAttrs = _getNormalizedAttributes(sAttrs)
          if g.0ATTRSOK
          then do
            call _startElement sTagName sAttrs
          end
          else do /* back up a bit and look for the real end of tag */
            g.0XML = '<'sBetween'&gt;'g.0XML
            if pos('>',g.0XML) = 0
            then call _abort 'XML006E Missing end tag for:' sTagName
            /* reparse on next cycle avoiding premature '>'...*/
          end
        end
      end
    end
  end

  call _endDocument
return

_startDocument: procedure expose g.
  g.0NEXTID = 0
  g.0STACK = 0
return

_startElement:  procedure expose g.
  parse arg sTagName sAttrs
  id = _getNextId()
  call _updateLinkage id
  g.0NAME.id = sTagName
  g.0TYPE.id = g.0ELEMENT_NODE
  call _addAttributes id,sAttrs
  cid = _pushElement(id)
return

_updateLinkage: procedure expose g.
  parse arg id
  parent = _peekElement()
  g.0PARENT.id = parent
  parentsLastChild = g.0LAST.parent
  g.0NEXT.parentsLastChild = id
  g.0PREV.id = parentsLastChild
  g.0LAST.parent = id
  if g.0FIRST.parent = ''
  then g.0FIRST.parent = id
return

_characterData: procedure expose g.
  parse arg sChars
  id = _getNextId()
  call _updateLinkage id
  g.0TEXT.id = sChars
  g.0TYPE.id = g.0CDATA_SECTION_NODE
return

_characters: procedure expose g.
  parse arg sChars
  sText = _resolveEntities(sChars)
  if g.0OPTION.NOBLANKS & removeWhitespace(sText) = ''
  then return
  id = _getNextId()
  call _updateLinkage id
  g.0TEXT.id = sText
  g.0TYPE.id = g.0TEXT_NODE
return

_endElement: procedure expose g.
  parse arg sTagName
  id = _popElement()
  g.0ENDOFDOC = id = 1
  if sTagName == g.0NAME.id
  then nop
  else call _abort,
           'XML007E Expecting </'g.0NAME.id'> but found </'sTagName'>'
return

_endDocument: procedure expose g.
  id = _peekElement()
  if id <> 0
  then call _abort 'XML008E End of document tag missing: 'id getName(id)
  if g.0ROOT <> '' & g.0ROOT <> getName(getRoot())
  then call _abort 'XML009E Root element name "'getName(getRoot())'"',
                  'does not match DTD root "'g.0ROOT'"'

  if g.0OPTION.DUMP
  then call _displayTree
return

_displayTree: procedure expose g.
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
          left(removeWhitespace(g.0TEXT.id),19)
    end
  end
return

_pushElement: procedure expose g.
  parse arg id
  g.0STACK = g.0STACK + 1
  nStackDepth = g.0STACK
  g.0STACK.nStackDepth = id
return id

_popElement: procedure expose g.
  n = g.0STACK
  if n = 0
  then id = 0
  else do
    id = g.0STACK.n
    g.0STACK = g.0STACK - 1
  end
return id

_peekElement: procedure expose g.
  n = g.0STACK
  if n = 0
  then id = 0
  else id = g.0STACK.n
return id

_getNextId: procedure expose g.
  g.0NEXTID = g.0NEXTID + 1
return g.0NEXTID

_addAttributes: procedure expose g.
  parse arg id,sAttrs
  do while pos('ff'x,sAttrs) > 0
    parse var sAttrs sAttrName'='sAttrValue 'ff'x sAttrs
    sAttrName = removeWhitespace(sAttrName)
    call _addAttribute id,sAttrName,sAttrValue
  end
return

_addAttribute: procedure expose g.
  parse arg id,sAttrName,sAttrValue
  aid = _getNextId()
  g.0TYPE.aid = g.0ATTRIBUTE_NODE
  g.0NAME.aid = sAttrName
  g.0TEXT.aid = _resolveEntities(sAttrValue)
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

_getNormalizedAttributes: procedure expose g.
  parse arg sAttrs
  g.0ATTRSOK = 0
  sNormalAttrs = ''
  parse var sAttrs sAttr'='sAttrs
  do while sAttr <> ''
    sAttr = removeWhitespace(sAttr)
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
    sAttrValue = removeWhitespace(sAttrValue)
    sNormalAttrs = sNormalAttrs sAttr'='sAttrValue'ff'x
    parse var sAttrs sAttr'='sAttrs
  end
  g.0ATTRSOK = 1
  /* Note: always returns a leading blank and is required by
    this implementation */
return _resolveEntities(sNormalAttrs)


/*-------------------------------------------------------------------*
 *  entityref  := '&' entityname ';'
 *  entityname := ('_',':',letter) (letter,digit,'.','-','_',':')*
 *-------------------------------------------------------------------*/


_resolveEntities: procedure expose g.
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
            sEntity = _getEntity(sEntityName)
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

_getEntity: procedure expose g.
  parse arg sEntityName
  if left(sEntityName,1) = '#' /* #nnnnn  OR  #xXXXX */
  then sEntity = _getCharacterEntity(sEntityName)
  else sEntity = _getStringEntity(sEntityName)
return sEntity

/*-------------------------------------------------------------------*
 * &#nnnnn;
 * &#xXXXX;
 *-------------------------------------------------------------------*/

_getCharacterEntity: procedure expose g.
  parse arg sEntityName
  if substr(sEntityName,2,1) = 'x'
  then do
    parse arg 3 xEntity
    if datatype(xEntity,'XADECIMAL')
    then sEntity = x2c(xEntity)
    else call _abort,
              'XML010E Invalid hexadecimal character reference: ',
              '&'sEntityName';'
  end
  else do
    parse arg 2 nEntity
    if datatype(nEntity,'WHOLE')
    then sEntity = d2c(nEntity)
    else call _abort,
              'XML011E Invalid decimal character reference:',
              '&'sEntityName';'
  end
return sEntity

/*-------------------------------------------------------------------*
 * &entityname;
 *-------------------------------------------------------------------*/

_getStringEntity: procedure expose g.
  parse arg sEntityName
  if wordpos(sEntityName,g.0ENTITIES) = 0
  then call _abort 'XML012E Unable to resolve entity &'sEntityName';'
  sEntity = g.0ENTITY.sEntityName
return sEntity

_setDefaultEntities: procedure expose g.
  g.0ENTITIES = ''
  g.0ESCAPES = '<>&"' || "'"
  sEscapes = 'lt gt amp quot apos'
  do i = 1 to length(g.0ESCAPES)
    c = substr(g.0ESCAPES,i,1)
    g.0ESCAPE.c = word(sEscapes,i)
  end
  call _setEntity 'amp','&'
  call _setEntity 'lt','<'
  call _setEntity 'gt','>'
  call _setEntity 'apos',"'"
  call _setEntity 'quot','"'
return

_setEntity: procedure expose g.
  parse arg sEntityName,sValue
  if wordpos(sEntityName,g.0ENTITIES) = 0
  then g.0ENTITIES = g.0ENTITIES sEntityName
  g.0ENTITY.sEntityName = sValue
return

_setProcessingInstruction: procedure expose g.
  parse arg sTarget sInstruction
  if wordpos(sTarget,g.0PI) = 0
  then g.0PI = g.0PI sTarget
  g.0PI.sTarget = strip(sInstruction)
return

_abort: procedure expose g.
  parse arg sMsg
  say 'ABORT:' sMsg
  call destroyParser
exit 16

_clearNode: procedure expose g.
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

removeWhitespace: procedure expose g.
  parse arg sData
return space(translate(sData,'',g.0WHITESPACE))

removeQuotes: procedure expose g.
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

getRoot: procedure expose g. /* DEPRECATED */
return 1

getDocumentElement: procedure expose g.
return 1

getName: getNodeName: procedure expose g.
  parse arg id
return g.0NAME.id

getText: getNodeValue: procedure expose g.
  parse arg id
return g.0TEXT.id

getNodeType: procedure expose g.
  parse arg id
return g.0TYPE.id

isElementNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0ELEMENT_NODE

isTextNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0TEXT_NODE

isCommentNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0COMMENT_NODE

isCDATA: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0CDATA_SECTION_NODE

isDocumentNode: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0DOCUMENT_NODE

isDocumentFragmentNode: procedure expose g.
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
getAttributeMap: procedure expose g.
  parse arg id
  if datatype(g.0ATTRIBUTE.0,'WHOLE')  /* clear any existing map */
  then do
    do i = 1 to g.0ATTRIBUTE.0
      sName = g.0ATTRIBUTE.i
      drop g.0ATTRIBUTE.sName g.0ATTRIBUTE.i
    end
  end
  g.0ATTRIBUTE.0 = 0
  if \_canHaveAttributes(id) then return
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

getAttributeCount: procedure expose g.
  parse arg id
  nAttributeCount = 0
  if _canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    do while aid <> ''
      nAttributeCount = nAttributeCount + 1
      aid = g.0NEXT.aid /* id of next attribute */
    end
  end
return nAttributeCount

getAttributeNames: procedure expose g.
  parse arg id
  sNames = ''
  if _canHaveAttributes(id)
  then do
    aid = g.0FIRSTATTR.id /* id of first attribute of element 'id' */
    do while aid <> ''
      sNames = sNames g.0NAME.aid
      aid = g.0NEXT.aid /* id of next attribute */
    end
  end
return strip(sNames)

getAttribute: procedure expose g.
  parse arg id,sAttrName
  sValue = ''
  if _canHaveAttributes(id)
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

getAttributeName: procedure expose g.
  parse arg id,n
  sName = ''
  if _canHaveAttributes(id)
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

hasAttribute: procedure expose g.
  parse arg id,sAttrName
  bHasAttribute = 0
  if _canHaveAttributes(id)
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

_canHaveAttributes: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0ELEMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE

_canHaveChildren: procedure expose g.
  parse arg id
return g.0TYPE.id = g.0ELEMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_NODE |,
       g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE

getParent: getParentNode: procedure expose g.
  parse arg id
return g.0PARENT.id

getFirstChild: procedure expose g.
  parse arg id
return g.0FIRST.id

getLastChild: procedure expose g.
  parse arg id
return g.0LAST.id

getChildren: getChildNodes: procedure expose g.
  parse arg id
  ids = ''
  id = getFirstChild(id)
  do while id <> ''
    ids = ids id
    id = getNextSibling(id)
  end
return strip(ids)

getChildrenByName: procedure expose g.
  parse arg id,sName
  ids = ''
  id = getFirstChild(id)
  do while id <> ''
    if getName(id) = sName
    then ids = ids id
    id = getNextSibling(id)
  end
return strip(ids)

getElementsByTagName: procedure expose g.
  parse arg id,sName
  ids = ''
  id = getFirstChild(id)
  do while id <> ''
    if getName(id) = sName
    then ids = ids id
    ids = ids getElementsByTagName(id,sName)
    id = getNextSibling(id)
  end
return space(ids)

getNextSibling: procedure expose g.
  parse arg id
return g.0NEXT.id

getPreviousSibling: procedure expose g.
  parse arg id
return g.0PREV.id

getProcessingInstruction: procedure expose g.
  parse arg sTarget
return g.0PI.sTarget

getProcessingInstructionList: procedure expose g.
return g.0PI

hasChildren: hasChildNodes: procedure expose g.
  parse arg id
return g.0FIRST.id <> ''

createDocument: procedure expose g.
  parse arg sName
  if sName = ''
  then call _abort,
            'XML013E Tag name omitted:',
            'createDocument('sName')'
  call destroyParser
  g.0NEXTID = 0
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0DOCUMENT_NODE /* 20070323 */
  g.0NAME.id = sName
  g.0PARENT.id = 0
return id

createDocumentFragment: procedure expose g. /* 20070323 */
  parse arg sName
  if sName = ''
  then call _abort,
            'XML014E Tag name omitted:',
            'createDocumentFragment('sName')'
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0DOCUMENT_FRAGMENT_NODE
  g.0NAME.id = sName
  g.0PARENT.id = 0
return id

createElement: procedure expose g.
  parse arg sName
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0ELEMENT_NODE
  g.0NAME.id = sName
return id

createCDATASection: procedure expose g.
  parse arg sCharacterData
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0CDATA_SECTION_NODE
  g.0TEXT.id = sCharacterData
return id

createTextNode: procedure expose g.
  parse arg sData
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0TEXT_NODE
  g.0TEXT.id = sData
return id

appendChild: procedure expose g.
  parse arg id, parent
  if \_canHaveChildren(parent)
  then call _abort,
            'XML015E' g.0NODETYPE.parent 'node cannot have children:',
            'appendChild('id','parent')'
  if g.0PARENT.id = ''
  then g.0PARENT.id = parent
  else call _abort,
            'XML016E Node <'getNodeName(id)'> is already a child',
            'of <'getNodeName(g.0PARENT.id)'>:',
            'appendChild('id','parent')'
  parentsLastChild = g.0LAST.parent
  g.0NEXT.parentsLastChild = id
  g.0PREV.id = parentsLastChild
  g.0LAST.parent = id
  if g.0FIRST.parent = ''
  then g.0FIRST.parent = id
return

insertBefore: procedure expose g.
  parse arg id, ref
  parent = g.0PARENT.ref
  if \_canHaveChildren(parent)
  then call _abort,
            'XML017E' g.0NODETYPE.parent 'node cannot have children:',
            'insertBefore('id','ref')'
  if g.0PARENT.id = ''
  then g.0PARENT.id = parent
  else call _abort,
            'XML018E Node <'getNodeName(id)'> is already a child',
            'of <'getNodeName(g.0PARENT.id)'>:',
            'insertBefore('id','ref')'
  g.0NEXT.id = ref
  oldprev = g.0PREV.ref
  g.0PREV.ref = id
  g.0NEXT.oldprev = id
  g.0PREV.id = oldprev
  if g.0FIRST.parent = ref
  then g.0FIRST.parent = id
return

removeChild: procedure expose g.
  parse arg id
  parent = g.0PARENT.id
  if \_canHaveChildren(parent)
  then call _abort,
            'XML019E' g.0NODETYPE.parent 'node cannot have children:',
            'removeChild('id')'
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

replaceChild: procedure expose g.
  parse arg id, extant
  parent = g.0PARENT.extant
  if \_canHaveChildren(parent)
  then call _abort,
            'XML020E' g.0NODETYPE.parent 'node cannot have children:',
            'replaceChild('id','extant')'
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

setAttribute: procedure expose g.
  parse arg id,sAttrName,sValue
  if \_canHaveAttributes(id)
  then call _abort,
            'XML021E' g.0NODETYPE.id 'node cannot have attributes:',
            'setAttribute('id','sAttrName','sValue')'
  aid = g.0FIRSTATTR.id
  do while aid <> '' & g.0NAME.aid <> sAttrName
    aid = g.0NEXT.aid
  end
  if aid <> '' & g.0NAME.aid = sAttrName
  then g.0TEXT.aid = sValue
  else call _addAttribute id,sAttrName,sValue
return

setAttributes: procedure expose g.
  parse arg id /* ,name1,value1,name2,value2,...,namen,valuen */
  do i = 2 to arg() by 2
    sAttrName = arg(i)
    sValue = arg(i+1)
    call setAttribute id,sAttrName,sValue
  end
return

removeAttribute: procedure expose g.
  parse arg id,sAttrName
  if \_canHaveAttributes(id)
  then call _abort,
            'XML022E' g.0NODETYPE.id 'node cannot have attributes:',
            'removeAttribute('id','sAttrName')'
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
    call _clearNode aid
  end
return

toString: procedure expose g.
  parse arg node
  if node = '' then node = getRoot()
  if node = getRoot()
  then sXML = _getProlog()_getNode(node)
  else sXML = _getNode(node)
return sXML

_getProlog: procedure expose g.
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

_getNode: procedure expose g.
  parse arg node
  select
    when g.0TYPE.node = g.0ELEMENT_NODE then,
         sXML = _getElementNode(node)
    when g.0TYPE.node = g.0TEXT_NODE then,
         sXML = escapeText(removeWhitespace(getText(node)))
    when g.0TYPE.node = g.0ATTRIBUTE_NODE then,
         sXML = getName(node)'="'escapeText(getText(node))'"'
    when g.0TYPE.node = g.0CDATA_SECTION_NODE then,
         sXML = '<![CDATA['getText(node)']]>'
    otherwise sXML = '' /* TODO: throw an error here? */
  end
return sXML

_getElementNode: procedure expose g.
  parse arg node
  sName = getName(node)
  sAttrs = ''
  attr = g.0FIRSTATTR.node
  do while attr <> ''
    sAttrs = sAttrs _getNode(attr)
    attr = g.0NEXT.attr
  end
  if hasChildren(node)
  then do
    if sAttrs = ''
    then sXML = '<'sName'>'
    else sXML = '<'sName strip(sAttrs)'>'
    child = getFirstChild(node)
    do while child <> ''
      sXML = sXML || _getNode(child)
      child = getNextSibling(child)
    end
    sXML = sXML'</'sName'>'
  end
  else do
    if sAttrs = ''
    then sXML = '<'sName'/>'
    else sXML = '<'sName strip(sAttrs)'/>'
  end
return sXML

escapeText: procedure expose g.
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
setDocType: procedure expose g.
  parse arg sDocType
  g.0DOCTYPE = sDocType
return

getDocType: procedure expose g.
return g.0DOCTYPE

createComment: procedure expose g.
  parse arg sData
  id = _getNextId()
  call _clearNode id
  g.0TYPE.id = g.0COMMENT_NODE
  g.0TEXT.id = sData
return id

deepClone: procedure expose g.
  parse arg node
return cloneNode(node,1)

cloneNode: procedure expose g.
  parse arg node,bDeep
  clone = _getNextId()
  call _clearNode clone
  g.0TYPE.clone = g.0TYPE.node
  g.0NAME.clone = g.0NAME.node
  g.0TEXT.clone = g.0TEXT.node
  /* clone any attributes...*/
  aidin = g.0FIRSTATTR.node
  do while aidin <> ''
    aid = _getNextId()
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
      child = cloneNode(childin,bDeep)
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
