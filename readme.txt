NAME     - PARSEXML

TITLE    - A REXX XML PARSER

VERSION  - 2.0.0

FUNCTION - This is a Rexx XML parser that you can append to your
           own Rexx source. You can then parse xml files into an
           in-memory model and access the model via a DOM-like
           API.

           This version has been tested on TSO (using TSO/REXX) and
           on Win32 and Ubuntu Linux 6.06 LTS (using Regina Rexx 3.3).


MEMBERS  - The list of members in the distribution PDS are:

           readme.txt   - This file.
           assert.rex   - Unit test assertion plumbing.
           devisio.rex  - An example of removing unwanted XML tags.
           idlfile.txt  - An example IDL input for for IDL2WSDL rexx.
           idl2wsdl.rex - EntireX IDL to WSDL file converter.
           io.rex       - Basic Rexx I/O routines.
           jcl2xml.rex  - JCL to XML and GraphML file converter.
           parsexml.rex - The Rexx parser source.
           pretty.rex   - A pretty printer showing how to use the parser.
           rexxpp.rex   - A Rexx INCLUDE pre-processor.
           soap.rex     - A Rexx SOAP client.
           testmod.rex  - Unit tests for XML modification API
           testnew.rex  - Unit tests for XML creation API
           test.xml     - A sample xml file

INSTALL  - 1. Copy the distribution library to your Rexx library.

           2. Execute the REXXPP INCLUDE pre-processor by running:

              REXXPP yourlib(PRETTY) PRETTYPP

              This will append PARSEXML to PRETTY and create PRETTYPP.
              You will be prompted for the location of each include
              file that cannot be found.
              Obviously, you can just use the editor if you prefer!

           3. Execute PRETTYPP to parse the TESTXML file by:

              PRETTYPP yourlib(TESTXML)   (NOBLANKS

              If you supply any options, be sure to put a space before
              the opening parenthesis. A closing parenthesis is
              optional.

           4. Repeat steps 2 and 3 for each of the other sample Rexx
              procedures if you want.

USAGE      - See the PARSEXML rexx procedure for more information