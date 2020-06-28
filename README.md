# A REXX XML PARSER

## Function

This is a Rexx XML parser that you can append to your
own Rexx source. You can then parse xml files into an
in-memory model and access the model via a DOM-like
API.

This version has been tested on:
* z/OS v2.3 TSO (using TSO/REXX)
* Windows (using Regina Rexx 3.9.1)
* Linux (using Regina Rexx 3.9.1)


## Installation
   1. Copy the distribution library to your Rexx library.

   1. Execute the REXXPP INCLUDE pre-processor by running:

      `REXXPP yourlib(PRETTY) PRETTYPP`

      This will append PARSEXML to PRETTY and create PRETTYPP.
      You will be prompted for the location of each include
      file that cannot be found.
      Obviously, you can just use the editor if you prefer!

   1. Execute PRETTYPP to parse the TESTXML file by:

      `PRETTYPP yourlib(TESTXML)   (NOBLANKS`

      If you supply any options, be sure to put a space before
      the opening parenthesis. A closing parenthesis is
      optional.

   1. Repeat steps 2 and 3 for each of the other sample Rexx
      procedures if you want.


## Usage
   1. Initialize the parser by:

      `call initParser [options...]`

   1. Parse the XML file to build an in-memory model

      `returncode = parseFile('filename')`

      ...or...

      `returncode = parseString('xml in a string')`

   1. Navigate the in-memory model with the DOM API. For
      example:

            say 'The document element is called',
                                 getName(getDocumentElement())
            say 'Children of the document element are:'
            node = getFirstChild(getDocumentElement())
            do while node <> ''
               if isElementNode(node)
               then say 'Element node:' getName(node)
               else say '   Text node:' getText(node)
               node = getNextSibling(node)
            end

   1. Optionally, destroy the in-memory model:

      `call destroyParser`


## Input

The input to the parser consists of either an XML file or a string containing:

   1. An optional XML prolog:
      - 0 or 1 XML declaration:

               <?xml version="1.0" encoding="..." ...?>

      - 0 or more comments, PIs, and whitespace:

               <!-- a comment -->
               <?target string?>

      - 0 or 1 document type declaration. Formats:

               <!DOCTYPE root SYSTEM "sysid">
               <!DOCTYPE root PUBLIC "pubid" SYSTEM "sysid">
               <!DOCTYPE root [internal dtd]>

   1. An XML body:

      - 1 Document element containing 0 or more child
         elements. For example:

               <doc attr1="value1" attr2="value2"...>
                  Text of doc element
                  <child1 attr1="value1">
                  Text of child1 element
                  </child1>
                  More text of doc element
                  <!-- an empty child element follows -->
                  <child2/>
                  Even more text of doc element
               </doc>

      - Elements may contain:

         Unparsed character data:

               <![CDATA[...unparsed data...]]>
         
         Entity references:

               &name;
         
         Character references:

               &#nnnnn;
               &#xXXXX;

   1. An XML epilog (which is ignored):

      - 0 or more comments, Processing Instructions (PIs), and whitespace.


## Application Programming Interface

   1. The basic setup/teardown API calls are:

      `initParser [options]`

         Initialises the parser's global variables and
         remembers any runtime options you specify. The
         options recognized are:

            NOBLANKS - Suppress whitespace-only nodes
            DEBUG    - Display some debugging info
            DUMP     - Display the parse tree

      `parseFile(filename)`

         Parses the XML data in the specified filename and
         builds an in-memory model that can be accessed via
         the DOM API (see below).

      `parseString(text)`

         Parses the XML data in the specified string.

      `destroyParser`

         Destroys the in-memory model and miscellaneous
         global variables.

   1. In addition, the following utility API calls can be
      used:

      `removeWhitespace(text)`

         Returns the supplied text string but with all
         whitespace characters removed, multiple spaces
         replaced with single spaces, and leading and
         trailing spaces removed.

      `removeQuotes(text)`

         Returns the supplied text string but with any
         enclosing apostrophes or double-quotes removed.

      `escapeText(text)`

         Returns the supplied text string but with special
         characters encoded (for example, `<` becomes `&lt;`)

      `toString(node)`

         Walks the document tree (beginning at the specified
         node) and returns a string in XML format.

## DOM API

The DOM (or DOM-like) calls that you can use are
listed below:

   1. Document query/navigation API calls

      `getRoot()`
      
         Returns the node number of the root node. This
         can be used in calls requiring a node argument.
         In this implementation, `getDocumentElement()` and
         `getRoot()` are (incorrectly) synonymous - this may
         change, so you should use `getDocumentElement()`
         in preference to `getRoot()`.

      `getDocumentElement()`

         Returns the node number of the document element.
         The document element is the topmost element node.
         You should use this in preference to `getRoot()`
         (see above).

      `getName(node)`

         Returns the name of the specified node.

      `getNodeValue(node)` or `getText(node)`

         Returns the text content of an unnamed node. A
         node without a name can only contain text. It
         cannot have attributes or children.

      `getAttributeCount(node)`

         Returns the number of attributes present on the
         specified node.

      `getAttributeMap(node)`

         Builds a map of the attributes of the specified
         node. The map can be accessed via the following
         variables:

         | Variable | Content |
         | --- | --- |
         | g.0ATTRIBUTE.0 | The number of attributes mapped |
         | g.0ATTRIBUTE.n | The name of attribute number `n` (in order of appearance). Where `n` > 0 |
         | g.0ATTRIBUTE.name | The value of the attribute called `name` |

      `getAttributeName(node,n)`

         Returns the name of the nth attribute of the
         specified node (1 is first, 2 is second, etc).

      `getAttributeNames(node)`

         Returns a space-delimited list of the names of the
         attributes of the specified node.

      `getAttribute(node,name)`

         Returns the value of the attribute called `name` of
         the specified node.

      `getAttribute(node,n)`

         Returns the value of the `n`th attribute of the
         specified node (1 is first, 2 is second, etc).

      `setAttribute(node,name,value)`

         Updates the value of the attribute called 'name'
         of the specified node. If no attribute exists with
         that name, then one is created.

      `setAttributes(node,name1,value1,name2,value2,...)`

         Updates the attributes of the specified node. Zero
         or more name/value pairs are be specified as the
         arguments.

      `hasAttribute(node,name)`

         Returns 1 if the specified node has an attribute
         with the specified name, else 0.

      `getParentNode(node)` or `getParent(node)`

         Returns the node number of the specified node's
         parent. If the node number returned is 0, then the
         specified node is the root node.
         All nodes have a parent (except the root node).

      `getFirstChild(node)`

         Returns the node number of the specified node's
         first child node.

      `getLastChild(node)`

         Returns the node number of the specified node's
         last child node.

      `getChildNodes(node)` or `getChildren(node)`

         Returns a space-delimited list of node numbers of
         the children of the specified node. You can use
         this list to step through the children as follows:

            children = getChildren(node)
            say 'Node' node 'has' words(children) 'children'
            do i = 1 to words(children)
               child = word(children,i)
               say 'Node' child 'is' getName(child)
            end

      `getChildrenByName(node,name)`

         Returns a space-delimited list of node numbers of
         the immediate children of the specified `node` which
         are called `name`. Names are case-sensitive.

      `getElementsByTagName(node,name)`

         Returns a space-delimited list of node numbers of
         the descendants of the specified `node` which are
         called `name`. Names are case-sensitive.

      `getNextSibling(node)`

         Returns the node number of the specified node's
         next sibling node. That is, the next node sharing
         the same parent.

      `getPreviousSibling(node)`

         Returns the node number of the specified node's
         previous sibline node. That is, the previous node
         sharing the same parent.

      `getProcessingInstruction(name)`

         Returns the value of the Processing Instruction (PI) with the specified
         target name.

      `getProcessingInstructionList()`

         Returns a space-delimited list of the names of all
         PI target names.

      `getNodeType(node)`

         Returns a number representing the specified node's
         type. The possible values can be compared to the
         following global variables:


         | Variable | Content |
         | --- | --- |
         |   g.0ELEMENT_NODE                | 1 |
         |   g.0ATTRIBUTE_NODE              | 2 |
         |   g.0TEXT_NODE                   | 3 |
         |   g.0CDATA_SECTION_NODE          | 4 |
         |   g.0ENTITY_REFERENCE_NODE       | 5 |
         |   g.0ENTITY_NODE                 | 6 |
         |   g.0PROCESSING_INSTRUCTION_NODE | 7 |
         |   g.0COMMENT_NODE                | 8 |
         |   g.0DOCUMENT_NODE               | 9 |
         |   g.0DOCUMENT_TYPE_NODE          | 10 |
         |   g.0DOCUMENT_FRAGMENT_NODE      | 11 |
         |   g.0NOTATION_NODE               | 12 |

         Note: as this exposes internal implementation
         details, it is best not to use this routine.
         Consider using `isTextNode()` etc instead (see below).

      `isCDATA(node)`

         Returns 1 if the specified node is an unparsed
         character data (CDATA) node, else 0. CDATA nodes
         are used to contain content that you do not want
         to be treated as XML data. For example, HTML data.

      `isElementNode(node)`

         Returns 1 if the specified node is an element node,
         else 0.

      `isTextNode(node)`

         Returns 1 if the specified node is a text node,
         else 0.

      `isCommentNode(node)`

         Returns 1 if the specified node is a comment node,
         else 0. Note: when a document is parsed, comment
         nodes are ignored. This routine returns 1 iff a
         comment node has been inserted into the in-memory
         document tree by using `createComment()`.

      `hasChildren(node)`

         Returns 1 if the specified node has one or more
         child nodes, else 0.

      `getDocType(doctype)`

         Gets the text of the `<!DOCTYPE>` prolog node.

   1. Document creation/mutation API calls

      `createDocument(name)`

         Returns the node number of a new document node
         with the specified name.

      `createDocumentFragment(name)`

         Returns the node number of a new document fragment
         node with the specified name.

      `createElement(name)`

         Returns the node number of a new empty element
         node with the specified name. An element node can
         have child nodes.

      `createTextNode(data)`

         Returns the node number of a new text node. A text
         node can *not* have child nodes.

      `createCDATASection(data)`

         Returns the node number of a new Character Data
         (CDATA) node. A CDATA node can *not* have child
         nodes. CDATA nodes are used to contain content
         that you do not want to be treated as XML data.
         For example, HTML data.

      `createComment(data)`

         Returns the node number of a new comment node.
         A comment node can *not* have child nodes.

      `appendChild(node,parent)`

         Appends the specified node to the end of the list
         of children of the specified parent node.

      `insertBefore(node,refnode)`

         Inserts node `node` before the reference node
         `refnode`.

      `removeChild(node)`

         Removes the specified node from its parent and
         returns its node number. The removed child is now
         an orphan.

      `replaceChild(newnode,oldnode)`

         Replaces the old child `oldnode` with the new
         child `newnode` and returns the old child's node
         number. The old child is now an orphan.

      `setAttribute(node,attrname,attrvalue)`

         Adds or replaces the attribute called `attrname`
         on the specified node with the value `attrvalue`.

      `removeAttribute(node,attrname)`

         Removes the attribute called `attrname` from the
         specified node.

      `setDocType(doctype)`

         Sets the text of the `<!DOCTYPE>` prolog node.

      `cloneNode(node,[deep])`

         Creates a copy (a clone) of the specified node
         and returns its node number. If deep = 1 then
         all descendants of the specified node are also
         cloned, else only the specified node and its
         attributes are cloned.

## NOTES

   1. This parser creates global variables and so its
      operation may be severely jiggered if you update
      any of them accidentally (or on purpose). The
      variables you should avoid updating yourself are:

            g.0ATTRIBUTE.n
            g.0ATTRIBUTE.name
            g.0ATTRSOK
            g.0DTD
            g.0ENDOFDOC
            g.0ENTITIES
            g.0ENTITY.name
            g.0FIRST.n
            g.0LAST.n
            g.0NAME.n
            g.0NEXT.n
            g.0NEXTID
            g.0OPTION.name
            g.0OPTIONS
            g.0PARENT.n
            g.0PI
            g.0PI.name
            g.0PREV.n
            g.0PUBLIC
            g.0ROOT
            g.0STACK
            g.0SYSTEM
            g.0TEXT.n
            g.0TYPE.n
            g.0WHITESPACE
            g.0XML
            g.?XML
            g.?XML.VERSION
            g.?XML.ENCODING
            g.?XML.STANDALONE

   1. To reduce the incidence of name clashes, procedure
      names that are not meant to be part of the public
      API have been prefixed with '_'.
