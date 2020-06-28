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
** NAME     - IDL2WSDL                                               **
**                                                                   **
** FUNCTION - Converts an EntireX Interface Definition Language (IDL)**
**            file into a Web Services Description Language (WSDL)   **
**            file.  It may be useful for sites that want to         **
**            re-implement an EntireX application as a Web Service.  **
**            It takes the tedium of converting the relatively easy  **
**            to understand IDL file format into the hideously       **
**            complex WSDL file format.                              **
**                                                                   **
**                                                                   **
** USAGE    - You can run this Rexx on an IBM mainframe, or on a PC  **
**            by using Regina Rexx from:                             **
**                                                                   **
**               http://regina-rexx.sourceforge.net                  **
**                                                                   **
**                                                                   **
** SYNTAX     IDL2WSDL infile [url [ns  [ (options [)] ]]]'          **
**                                                                   **
**            Where,                                                 **
**            infile  = Name of your EntireX Interface Definition    **
**                      Language (IDL) file. For example:            **
**                      example.idl                                  **
**            url     = URL of the service. For example:             **
**                      http://10.1.2.3:8080/cics/cwba/soapima       **
**            ns      = Namespace of the service. For example:       **
**                      http://myservice.example.org                 **
**            options = RPC      - Remote Procedure Call (style)     **
**                      DOCUMENT - XML document (style)              **
**                      ENCODED  - Parameters defined inline (use)   **
**                      LITERAL  - Parameters defined by schema (use)**
**                      WRAPPED  - Special case of DOCUMENT LITERAL  **
**                      XML      - Create XML file (for debugging)   **
**                                                                   **
**            Valid style and use combinations are:                  **
**            WRAPPED            <-- This is the default             **
**            DOCUMENT LITERAL                                       **
**            RPC LITERAL                                            **
**            RPC ENCODED                                            **
**                                                                   **
** NOTES    - 1. This Rexx uses the Rexx XML parser in CBT FILE 647  **
**               from www.cbttape.org.                               **
**               You will have to either append the PARSEXML and     **
**               PRETTY source files manually to this file, or run   **
**               this file through the REXX rexx pre-processor.      **
**                                                                   **
**               To use the pre-processor on TSO, run:               **
**                                                                   **
**               tso rexxpp your.rexx.lib(idl2wsdl)                  **
**                                                                   **
**               To use the pre-processor on Windows, run:           **
**                                                                   **
**               rexx rexxpp idl2wsdl.rexx idl2wsdl.new              **
**                                                                   **
**               ...and then rename the .new file to .rexx           **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --- ----------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20060525 AJA Update documentation.                     **
**            20060216 AJA User must supply URL & namespace.         **
**            20051106 AJA Support RPC/DOC + ENC/LIT/WRAPPED.        **
**            20051102 AJA Intial version.                           **
**                                                                   **
**********************************************************************/

  parse arg sFileIn sURL sNamespace' ('sOptions')'

  numeric digits 16
  parse value sourceline(1) with . sVersion
  say 'IDL000I EntireX IDL to WSDL File Converter' sVersion
  if sFileIn = ''
  then do
    say 'Syntax:'
    say '   IDL2WSDL infile url ns (options'
    say
    say 'Where:'
    say '   infile  = EntireX IDL input file. For example:'
    say '             example.idl'
    say '   url     = URL of the service. For example:'
    say '             http://10.1.2.3:8080/cics/cwba/soapima'
    say '   ns      = Namespace of the service. For example:'
    say '             http://myservice.example.org'
    say '   options = RPC      - Remote Procedure Call (style)'
    say '             DOCUMENT - XML document (style)'
    say '             ENCODED  - Parameters defined inline (use)'
    say '             LITERAL  - Parameters defined by schema (use)'
    say '             WRAPPED  - Special case of DOCUMENT LITERAL'
    say '             XML      - Create XML file (for debugging)'
    say
    say '   Valid option combinations are:'
    say '     WRAPPED'
    say '     DOCUMENT LITERAL'
    say '     RPC LITERAL'
    say '     RPC ENCODED'
    exit
  end
  say 'IDL001I Reading EntireX IDL file in' sFileIn


  sOptions = 'NOBLANKS' translate(sOptions)
  call initParser sOptions /* DO THIS FIRST! Sets g. vars to '' */
  call setDocType /* we don't need a doctype declaration */

  g.0FILEIDL = sFileIn
  g.0URL = prompt(sURL,,
                  'Enter URL of this service',,
                  'http://10.1.2.3:8080/cics/cwba/soapima/')
  g.0NAMESPACE = prompt(sNamespace,,
                  'Enter XML namespace of this service',,
                  'http://myservice.example.org')

  parse source g.0ENV .
  if g.0ENV = 'TSO'
  then do
    address ISPEXEC
    'CONTROL ERRORS RETURN'
    g.0LINES = 0
  end

  call setOptions sOptions
  call Prolog

  /* Read the IDL file into an in-memory XML document */
  idl = scanEntireXIdlFile()

  sFileName = getFilenameWithoutExtension(sFileIn)
  libraries = getChildNodes(idl)
  do i = 1 to words(libraries)
    library = word(libraries,i)
    sLibrary = getAttribute(library,'name')
    call createWSDL sFileName'.'sLibrary,library
  end

  call Epilog
exit

prompt: procedure expose g.
  parse arg sReply,sPrompt,sDefault
  if sReply = ''
  then do
    say 'IDL000R' sPrompt '['sDefault']:'
    parse pull sReply
    if sReply = '' then sReply = sDefault
  end
return sReply


/*
<wsdl:definitions targetNamespace="yournamespace"
    xmlns:apachesoap="http://xml.apache.org/xml-soap"
    xmlns:impl="yournamespace"
    xmlns:intf="yournamespace"
    xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
    xmlns:wsdlsoap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    .
    .
</wsdl:definitions>
*/
createWSDL: procedure expose g.
  parse arg sFile,node
  if g.0OPTION.XML
  then call prettyPrinter sFile'.xml',,node

  /* Build the high-level WSDL file structure... */
  g.0DEFS     = createElement('wsdl:definitions')
  g.0TYPES    = createElement('wsdl:types')
  g.0PORTTYPE = createElement('wsdl:portType')
  g.0BINDING  = createElement('wsdl:binding')
  g.0SERVICE  = createElement('wsdl:service')

  /* The porttype, binding and service elements are more-or-less the
     same for all combinations of style and use, so build them now... */
  call defineDefinitions node
  call defineTypes node
  call definePortType node
  call defineBinding node
  call defineService node
  call appendChild g.0TYPES,g.0DEFS


  /* Now add message elements depending on style and use... */
  select
    when g.0OPTION.WRAPPED then,
      call createDocWrapped node
    when g.0OPTION.DOCUMENT & g.0OPTION.LITERAL then,
      call createDocLiteral node
    when g.0OPTION.RPC & g.0OPTION.LITERAL then,
      call createRpcLiteral node
    when g.0OPTION.RPC & g.0OPTION.ENCODED then,
      call createRpcEncoded node
    otherwise,
      call createDocWrapped node
  end

  call appendChild g.0PORTTYPE,g.0DEFS
  call appendChild g.0BINDING,g.0DEFS
  call appendChild g.0SERVICE,g.0DEFS

  /* Serialise the WSDL document to a file... */
  call prettyPrinter sFile'.wsdl',,g.0DEFS
return


defineDefinitions: procedure expose g.
  parse arg node
  call setAttributes g.0DEFS,,
       'targetNamespace',g.0NAMESPACE,,
       'xmlns:impl',g.0NAMESPACE,,
       'xmlns:intf',g.0NAMESPACE,,
       'xmlns:wsdl','http://schemas.xmlsoap.org/wsdl/',,
       'xmlns:wsdlsoap','http://schemas.xmlsoap.org/wsdl/soap/',,
       'xmlns:xsd','http://www.w3.org/2001/XMLSchema'

  if g.0OPTION.ENCODED
  then call setAttribute g.0DEFS,,
       'xmlns:soapenc','http://schemas.xmlsoap.org/soap/encoding/'

  call appendChild createComment('Created by EntireX IDL-to-WSDL',
       'converter V1.0 on' date() time() userid()),g.0DEFS

  if g.0OPTION.WRAPPED
  then call appendChild createComment('Style='getStyle() '(wrapped)',
            'Use='getUse()),g.0DEFS
  else call appendChild createComment('Style='getStyle(),
            'Use='getUse()),g.0DEFS
return

/*
<wsdl:types>
    <schema targetNamespace="yournamespace"
            xmlns="http://www.w3.org/2001/XMLSchema">
        <import
            namespace="http://schemas.xmlsoap.org/soap/encoding/"/>
        <complexType name="SecurityContext">
            <sequence>
                <element name="reason" nillable="true"
                         type="soapenc:string"/>
                <element name="reasonCode" nillable="true"
                         type="soapenc:int"/>
                <element name="returnCode" nillable="true"
                         type="soapenc:int"/>
                <element name="success" nillable="true"
                         type="soapenc:boolean"/>
                <element name="userid" nillable="true"
                         type="soapenc:string"/>
            </sequence>
        </complexType>
    </schema>
</wsdl:types>
*/
defineTypes: procedure expose g.
  parse arg node
  g.0SCHEMA = createElement('schema')
  call appendChild g.0SCHEMA,g.0TYPES
  if g.0OPTION.DOCUMENT | g.0OPTION.WRAPPED
  then call setAttribute g.0SCHEMA,'elementFormDefault','qualified'
  call setAttributes g.0SCHEMA,,
       'targetNamespace',g.0NAMESPACE,,
       'xmlns','http://www.w3.org/2001/XMLSchema'
  if g.0OPTION.ENCODED
  then do
    import = createElement('import')
    call appendChild import,g.0SCHEMA
    call setAttribute import,,
         'namespace','http://schemas.xmlsoap.org/soap/encoding/'
  end
  structuresnode = getChildrenByName(node,'structures')
  structures = getChildren(structuresnode)
  do i = 1 to words(structures)
    struct = word(structures,i)
    call appendComplexType struct,g.0SCHEMA
  end
return

/*
<wsdl:operation name="verify">
    <wsdl:input message="impl:verifyRequest"
                name="verifyRequest"/>
    <wsdl:output message="impl:verifyResponse"
                 name="verifyResponse"/>
</wsdl:operation>
*/
definePortType: procedure expose g.
  parse arg node
  sService = getAttribute(node,'name')
  call setAttribute g.0PORTTYPE,'name',sService
  programs = getChildrenByName(node,'programs')
  if programs <> ''
  then do
    programs = getChildren(programs)
    do i = 1 to words(programs)
      program = word(programs,i)
      sOperation = getAttribute(program,'name')
      operation = createElement('wsdl:operation')
      call appendChild operation,g.0PORTTYPE
      call setAttribute operation,'name',sOperation
      input = createElement('wsdl:input')
      call appendChild input,operation
      call setAttributes input,,
           'message','impl:'sOperation'Request',,
           'name',sOperation'Request'
      output = createElement('wsdl:output')
      call appendChild output,operation
      call setAttributes output,,
           'message','impl:'sOperation'Response',,
           'name',sOperation'Response'
    end
  end
return

/*
<wsdl:binding name="SecuritySoapBinding"
              type="impl:Security">
  <wsdlsoap:binding style="rpc"
                    transport="http://schemas.xmlsoap.org/soap/http"/>
  <wsdl:operation name="verify">
  <wsdlsoap:operation soapAction=""/>
    <wsdl:input name="verifyRequest">
        <wsdlsoap:body
            encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
            namespace="yournamespace"
            use="encoded"/>
    </wsdl:input>
    <wsdl:output name="verifyResponse">
        <wsdlsoap:body
            encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
            namespace="yournamespace"
            use="encoded"/>
    </wsdl:output>
  </wsdl:operation>
    .
    .
</wsdl:binding>
*/
defineBinding: procedure expose g.
  parse arg node
  sService = getAttribute(node,'name')
  call setAttributes g.0BINDING,,
       'name',sService'SoapBinding',,
       'type','impl:'sService
  soapbinding = createElement('wsdlsoap:binding')
  call appendChild soapbinding,g.0BINDING
  call setAttributes soapbinding,,
       'style',getStyle(),,
       'transport','http://schemas.xmlsoap.org/soap/http'
  programs = getChildrenByName(node,'programs')
  if programs <> ''
  then do
    programs = getChildren(programs)
    do i = 1 to words(programs)
      program = word(programs,i)
      sOperation = getAttribute(program,'name')
      operation = createElement('wsdl:operation')
      call setAttribute operation,'name',sOperation
      call appendChild operation,g.0BINDING
      soapoperation = createElement('wsdlsoap:operation')
      call appendChild soapoperation,operation
      call setAttribute soapoperation,'soapAction',''

      input = createElement('wsdl:input')
      call appendChild input,operation
      call setAttribute input,'name',sOperation'Request'
      body = createElement('wsdlsoap:body')
      call appendChild body,input
      if g.0OPTION.ENCODED
      then call setAttribute body,,
           'encodingStyle','http://schemas.xmlsoap.org/soap/encoding/'
      call setAttributes body,,
           'namespace',g.0NAMESPACE,,
           'use',getUse()

      output = createElement('wsdl:output')
      call appendChild output,operation
      call setAttribute output,'name',sOperation'Response'
      body = createElement('wsdlsoap:body')
      call appendChild body,output
      if g.0OPTION.ENCODED
      then call setAttribute body,,
           'encodingStyle','http://schemas.xmlsoap.org/soap/encoding/'
      if g.0OPTION.RPC
      then call setAttribute body,'namespace',g.0NAMESPACE
      call setAttribute body,'use',getUse()
    end
  end
return

getStyle: procedure expose g.
  if g.0OPTION.RPC
  then sStyle = 'rpc'
  else sStyle = 'document'
return sStyle

getUse: procedure expose g.
  if g.0OPTION.ENCODED
  then sUse = 'encoded'
  else sUse = 'literal'
return sUse

/*
<wsdl:service name="SecurityService">
    <wsdl:port binding="impl:SecuritySoapBinding"
               name="Security">
        <wsdlsoap:address
            location="http://10.9.2.31:5080/axis/services/Security"/>
    </wsdl:port>
</wsdl:service>
*/
defineService: procedure expose g.
  parse arg node
  sService = getAttribute(node,'name')
  call setAttribute g.0SERVICE,'name',sService'Service'
  port = createElement('wsdl:port')
  call appendChild port,g.0SERVICE
  call setAttributes port,,
       'binding','impl:'sService'SoapBinding',,
       'name',sService
  addr = createElement('wsdlsoap:address')
  call appendChild addr,port
  call setAttribute addr,,
       'location',g.0URL || sService
return

/*
style=document, use=literal [WS-I compliant, with restrictions]

Elements of the SOAP body are the names of XML Schema elements that
describe each parameter (there is no wrapper operation and no multi-ref)

   <soap:body>
     <arg1Element>5</arg1Element>
     <arg2Element>5.0</arg2Element>
   </soap:body>

*/
createDocLiteral: procedure expose g.
  parse arg node
  say 'IDL003I Generating WSDL style=DOCUMENT use=LITERAL'
  /*
  <wsdl:message name="changePasswordRequest">
      <wsdl:part name="userid" element="xsd:string"/>
      <wsdl:part name="password" element="xsd:string"/>
      <wsdl:part name="newPassword" element="xsd:string"/>
  </wsdl:message>
  <wsdl:message name="changePasswordResponse">
      <wsdl:part name="changePasswordReturn"
                 element="impl:SecurityContext"/>
  </wsdl:message>
      .
      .
  */
  programs = getChildrenByName(node,'programs')
  if programs <> ''
  then do
    programs = getChildren(programs)
    do i = 1 to words(programs)
      program = word(programs,i)
      sOperation = getAttribute(program,'name')
      request  = createElement('wsdl:message')
      call appendChild request,g.0DEFS
      call setAttribute request,'name',sOperation'Request'
      response = createElement('wsdl:message')
      call appendChild response,g.0DEFS
      call setAttribute response,'name',sOperation'Response'
      parms = getChildren(program)
      do j = 1 to words(parms)
        parm = word(parms,j)
        sType = getAttribute(parm,'type')
        if sType <> '' /* if it is not a group */
        then do
          sName = getAttribute(parm,'name')
          sDir  = getAttribute(parm,'direction')
          if wordpos('In',sDir) > 0
          then call appendPartSchema sName,sType,request
          if wordpos('Out',sDir) > 0
          then call appendPartSchema sOperation'Return',sType,response
        end
      end
    end
  end
return

/*
<wsdl:part name="userid1" element="impl:userid1"/>
                                         |
                  .----------------------'
                  |
                  V
<element name="userid1" type="xsd:string"/>
or
<element name="userid1" type="impl:schemaReference"/>
*/
appendPartSchema: procedure expose g.
  parse arg sName,sEntireXType,node
  sElementName = sName
  if g.0USED.sElementName = 1 /* If this name is already used */
  then do
    do i = 1 by 1 until g.0USED.sNameX = ''
      sNameX = sElementName || i
    end
    sElementName = sNameX
  end
  g.0USED.sElementName = 1
  element = createElement('element')
  call appendChild element,g.0SCHEMA
  call setAttributes element,,
       'name',sElementName,,
       'type',getSchemaEncoding(sEntireXType)
  part = createElement('wsdl:part')
  call appendChild part,node
  call setAttributes part,,
       'name',sName,,
       'element','impl:'sElementName
return


/*
style=wrapped

Special case of DOCLIT where there is only one parameter and it has the
same qname as the operation. In such cases, there is no actual type with
the name. The elements are treated as parameters to the operation

   <soap:body>
      <one-arg-same-name-as-operation>
         <arg1Element>5</arg1Element>
         <arg2Element>5.0</arg2Element>
      </one-arg-same-name-as-operation>
   </soap:body>

*/
createDocWrapped: procedure expose g.
  parse arg node
  say 'IDL003I Generating WSDL style=DOCUMENT (WRAPPED) use=LITERAL'
  /*
  <wsdl:message name="verifyRequest">
      <wsdl:part element="impl:verify" name="parameters"/>
  </wsdl:message>
  <wsdl:message name="verifyResponse">
      <wsdl:part element="impl:verifyResponse" name="parameters"/>
  </wsdl:message>
      .
      .
  */
  programs = getChildrenByName(node,'programs')
  if programs <> ''
  then do
    programs = getChildren(programs)
    do i = 1 to words(programs)
      program = word(programs,i)
      sOperation = getAttribute(program,'name')
      sRequestElement = sOperation
      sResponseElement = sOperation'Response'

      call appendMessage sOperation'Request',sRequestElement
      call appendMessage sOperation'Response',sResponseElement

      request  = getSequence(sRequestElement)
      response = getSequence(sResponseElement)
      parms = getChildren(program)
      do j = 1 to words(parms)
        parm = word(parms,j)
        sType = getAttribute(parm,'type')
        if sType <> '' /* if it is not a group */
        then do
          sName = getAttribute(parm,'name')
          sDir  = getAttribute(parm,'direction')
          if wordpos('In',sDir) > 0
          then call appendWrapped sName,sType,request
          if wordpos('Out',sDir) > 0
          then call appendWrapped sOperation'Return',sType,response
        end
      end
    end
  end
return

appendMessage: procedure expose g.
  parse arg sMessageName,sElementName
  message = createElement('wsdl:message')
  call appendChild message,g.0DEFS
  call setAttribute message,'name',sMessageName
  part = createElement('wsdl:part')
  call appendChild part,message
  call setAttributes part,,
       'name','parameters',,
       'element','impl:'sElementName
return

/*
  <element name="verify">
      <complexType>
          <sequence>
              <element name="userid" type="xsd:string"/>
              <element name="password" type="xsd:string"/>
          </sequence>
      </complexType>
  </element>
  <element name="verifyResponse">
      <complexType>
          <sequence>
              <element name="verifyReturn"
                       type="impl:SecurityContext"/>
          </sequence>
      </complexType>
  </element>
*/
getSequence: procedure expose g.
  parse arg sName
  element = createElement('element')
  call appendChild element,g.0SCHEMA
  call setAttribute element,'name',sName
  complexType = createElement('complexType')
  call appendChild complexType,element
  sequence = createElement('sequence')
  call appendChild sequence,complexType
return sequence

/*
   <element name="userid" type="xsd:string"/>
   or
   <element name="verifyReturn" type="impl:schemaReference"/>
*/
appendWrapped: procedure expose g.
  parse arg sName,sEntireXType,sequence
  element = createElement('element')
  call appendChild element,sequence
  call setAttributes element,,
       'name',sName,,
       'type',getSchemaEncoding(sEntireXType)
return

/*
style=document, use=encoded [NOT WS-I compliant]

There is no enclosing operation name element, but the parmeters are
encoded using SOAP encoding. This mode is not (well?) supported by
Apache Axis.

*/
createDocEncoded: procedure expose g.
  parse arg node
  say 'IDL099W WSDL style=DOCUMENT use=ENCODED not supported'
return

/*
style=rpc, use=literal

First element of the SOAP body is the operation.
The operation contains elements describing the parameters,
which are not serialized as encoded (and no multi-ref)

   <soap:body>
      <operation>
         <arg1>5</arg1>
         <arg2>5.0</arg2>
      </operation>
   </soap:body>

*/
createRpcLiteral: procedure expose g.
  parse arg node
  say 'IDL003I Generating WSDL style=RPC use=LITERAL'
  /*
  <wsdl:message name="changePasswordRequest">
      <wsdl:part name="userid" type="xsd:string"/>
      <wsdl:part name="password" type="xsd:string"/>
      <wsdl:part name="newPassword" type="xsd:string"/>
  </wsdl:message>
  <wsdl:message name="changePasswordResponse">
      <wsdl:part name="changePasswordReturn"
                 type="impl:SecurityContext"/>
  </wsdl:message>
      .
      .
  */
  programs = getChildrenByName(node,'programs')
  if programs <> ''
  then do
    programs = getChildren(programs)
    do i = 1 to words(programs)
      program = word(programs,i)
      sOperation = getAttribute(program,'name')
      request  = createElement('wsdl:message')
      call appendChild request,g.0DEFS
      call setAttribute request,'name',sOperation'Request'
      response = createElement('wsdl:message')
      call appendChild response,g.0DEFS
      call setAttribute response,'name',sOperation'Response'
      parms = getChildren(program)
      do j = 1 to words(parms)
        parm = word(parms,j)
        sType = getAttribute(parm,'type')
        if sType <> '' /* if it is not a group */
        then do
          sName = getAttribute(parm,'name')
          sDir  = getAttribute(parm,'direction')
          if wordpos('In',sDir) > 0
          then call appendPartType sName,sType,request
          if wordpos('Out',sDir) > 0
          then call appendPartType sOperation'Return',sType,response
        end
      end
    end
  end
return

/*
style=rpc, use=encoded [NOT WS-I compliant]

First element of the SOAP body is the operation.
The operation contains elements describing the parameters,
which are serialized as encoded (possibly multi-ref)

   <soap:body>
      <operation>
         <arg1 xsi:type="xsd:int">5</arg1>
         <arg2 xsi:type="xsd:float">5.0</arg2>
      </operation>
   </soap:body>

*/
createRpcEncoded: procedure expose g.
  parse arg node
  say 'IDL003I Generating WSDL style=RPC use=ENCODED'
  /*
  <wsdl:message name="changePasswordRequest">
      <wsdl:part name="userid" type="soapenc:string"/>
      <wsdl:part name="password" type="soapenc:string"/>
      <wsdl:part name="newPassword" type="soapenc:string"/>
  </wsdl:message>
  <wsdl:message name="changePasswordResponse">
      <wsdl:part name="changePasswordReturn"
                 type="impl:SecurityContext"/>
  </wsdl:message>
      .
      .
  */
  programs = getChildrenByName(node,'programs')
  if programs <> ''
  then do
    programs = getChildren(programs)
    do i = 1 to words(programs)
      program = word(programs,i)
      sOperation = getAttribute(program,'name')
      request  = createElement('wsdl:message')
      call appendChild request,g.0DEFS
      call setAttribute request,'name',sOperation'Request'
      response = createElement('wsdl:message')
      call appendChild response,g.0DEFS
      call setAttribute response,'name',sOperation'Response'
      parms = getChildren(program)
      do j = 1 to words(parms)
        parm = word(parms,j)
        sType = getAttribute(parm,'type')
        if sType <> '' /* if it is not a group */
        then do
          sName = getAttribute(parm,'name')
          sDir  = getAttribute(parm,'direction')
          if wordpos('In',sDir) > 0
          then call appendPartType sName,sType,request
          if wordpos('Out',sDir) > 0
          then call appendPartType sOperation'Return',sType,response
        end
      end
    end
  end
return

/*
<wsdl:part name="userid" type="soapenc:string"/>
or
<wsdl:part name="operationReturn" type="impl:schemaReference"/>
*/
appendPartType: procedure expose g.
  parse arg sName,sEntireXType,node
  part = createElement('wsdl:part')
  call appendChild part,node
  call setAttributes part,,
       'name',sName,,
       'type',getEncoding(sEntireXType)
return

/*
<complexType name="SecurityContext">
    <sequence>
        <element name="reason" nillable="true"
                 type="soapenc:string"/>
        <element name="reasonCode" nillable="true"
                 type="soapenc:int"/>
        <element name="returnCode" nillable="true"
                 type="soapenc:int"/>
        <element name="success" nillable="true"
                 type="soapenc:boolean"/>
        <element name="userid" nillable="true"
                 type="soapenc:string"/>
    </sequence>
</complexType>
*/
appendComplexType: procedure expose g.
  parse arg struct,schema
  sStructureName = getAttribute(struct,'name')
  complexType = createElement('complexType')
  call appendChild complexType,schema
  call setAttribute complexType,'name',sStructureName
  sequence = createElement('sequence')
  call appendChild sequence,complexType
  parms = getChildNodes(struct)
  do i = 1 to words(parms)
    parm = word(parms,i)
    nLevel = getAttribute(parm,'level')
    sName  = getAttribute(parm,'name')
    sType  = getAttribute(parm,'type')
    sDirection = getAttribute(parm,'direction')
    select
      when sType = '' then do
        /* ignore an EntireX grouping level */
      end
      when left(sType,1) = "'" then do
        parse var sType "'"sRef"'"
      end
      otherwise do
        call appendElement sName,sType,sequence
      end
    end
  end
return

/*
<sequence>
    <element name="reason" nillable="true"
             type="soapenc:string"/>
    <element name="reasonCode" nillable="true"
             type="soapenc:int"/>
    <element name="returnCode" nillable="true"
             type="soapenc:int"/>
    <element name="success" nillable="true"
             type="soapenc:boolean"/>
    <element name="userid" nillable="true"
             type="soapenc:string"/>
</sequence>
*/
appendElement: procedure expose g.
  parse arg sName,sEntireXType,sequence
  element = createElement('element')
  call appendChild element,sequence
  call setAttributes element,,
       'name',sName,,
       'nillable','true',,
       'type',getEncoding(sEntireXType)
return

getEncoding: procedure expose g.
  parse arg sEntireXType
  if g.0OPTION.ENCODED
  then sEncoding = getSoapEncoding(sEntireXType)
  else sEncoding = getSchemaEncoding(sEntireXType)
return sEncoding

/* Map an EntireX data type to a SOAP encoded type */
getSoapEncoding: procedure expose g.
  parse arg sEntireXType . 1 sType1 +1 1 sType2 +2
  select
    when sType1 = 'A' then do /* alphanumeric */
      if sType2 = 'AV'        /* variable length */
      then sEncoding = 'soapenc:string'
      else sEncoding = 'soapenc:string'
    end
    when sType1 = 'B' then do /* binary */
      if sType2 = 'BV'        /* variable length */
      then sEncoding = 'soapenc:int'
      else sEncoding = 'soapenc:int'
    end
    when sType1 = 'D' then do /* date */
      sEncoding = 'soapenc:date'
    end
    when sType1 = 'F' then do /* floating point */
      sEncoding = 'soapenc:float'
    end
    when sType1 = 'I' then do /* integer */
      sEncoding = 'soapenc:int'
    end
    when sType1 = 'L' then do /* logical */
      sEncoding = 'soapenc:boolean'
    end
    when sType1 = 'N' then do /* numeric */
      if sType2 = 'NU'        /* unsigned */
      then sEncoding = 'soapenc:decimal'
      else sEncoding = 'soapenc:decimal'
    end
    when sType1 = 'P' then do /* packed decimal */
      if sType2 = 'PU'        /* unsigned */
      then sEncoding = 'soapenc:decimal'
      else sEncoding = 'soapenc:decimal'
    end
    when sType1 = 'T' then do /* time */
      sEncoding = 'soapenc:time'
    end
    when sType1 = "'" then do /* reference to a struct */
      parse var sEntireXType "'"sReference"'"
      sEncoding = 'impl:'sReference
    end
    otherwise do
      sEncoding = 'soapenc:anyType'
    end
  end
return sEncoding

/* Map an EntireX data type to an XML schema data type */
getSchemaEncoding: procedure expose g.
  parse arg sEntireXType . 1 sType1 +1 1 sType2 +2
  select
    when sType1 = 'A' then do /* alphanumeric */
      if sType2 = 'AV'        /* variable length */
      then sEncoding = 'xsd:string'
      else sEncoding = 'xsd:string'
    end
    when sType1 = 'B' then do /* binary */
      if sType2 = 'BV'        /* variable length */
      then sEncoding = 'xsd:int'
      else sEncoding = 'xsd:int'
    end
    when sType1 = 'D' then do /* date */
      sEncoding = 'xsd:date'
    end
    when sType1 = 'F' then do /* floating point */
      sEncoding = 'xsd:float'
    end
    when sType1 = 'I' then do /* integer */
      sEncoding = 'xsd:int'
    end
    when sType1 = 'L' then do /* logical */
      sEncoding = 'xsd:boolean'
    end
    when sType1 = 'N' then do /* numeric */
      if sType2 = 'NU'        /* unsigned */
      then sEncoding = 'xsd:decimal'
      else sEncoding = 'xsd:decimal'
    end
    when sType1 = 'P' then do /* packed decimal */
      if sType2 = 'PU'        /* unsigned */
      then sEncoding = 'xsd:decimal'
      else sEncoding = 'xsd:decimal'
    end
    when sType1 = 'T' then do /* time */
      sEncoding = 'xsd:time'
    end
    when sType1 = "'" then do /* reference to a struct */
      parse var sEntireXType "'"sReference"'"
      sEncoding = 'impl:'sReference
    end
    otherwise do
      sEncoding = 'xsd:anyType'
    end
  end
return sEncoding


getFilenameWithoutExtension: procedure expose g.
  parse arg sFile
  parse value reverse(sFile) with '.'sRest
return reverse(sRest)

scanEntireXIdlFile: procedure expose g.
  idl = createElement('idl')
  g.0FILEIN = openFile(g.0FILEIDL)
  sLine = getNextLine()
  do while g.0RC = 0 & sLine <> '** End of file'
    parse var sLine sAction sName ' is'
    select
      when sAction = 'library' then do
        parse var sName sName':'sAlias
        sName  = strip(sName,'BOTH',"'")
        sAlias = strip(sAlias,'BOTH',"'")
        library = createElement('library')
        call setAttributes library,,
             'name',sName,,
             'alias',sAlias
        call appendChild library,idl
        structures = createElement('structures')
        call appendChild structures,library
        programs = createElement('programs')
        call appendChild programs,library
      end
      when sAction = 'program' then do
        parse var sName sName':'sAlias
        sName  = strip(sName,'BOTH',"'")
        sAlias = strip(sAlias,'BOTH',"'")
        program = createElement('program')
        call setAttributes program,,
             'name',sName,,
             'alias',sAlias
        call appendChild program,programs
        call getParameters program
      end
      when sAction = 'struct' then do
        parse var sName sName':'sAlias
        g.0STRUCT = sName
        sName  = strip(sName,'BOTH',"'")
        sAlias = strip(sAlias,'BOTH',"'")
        struct = createElement('struct')
        call setAttributes struct,,
             'name',sName,,
             'alias',sAlias
        call appendChild struct,structures
        call getParameters struct
      end
      otherwise do
        say 'IDL002E Unknown IDL file input line:' sLine
      end
    end
    sLine = getNextLine()
  end
  rc = closeFile(g.0FILEIN)
return idl

getParameters: procedure expose g.
  parse arg parent
  sLine = getLineContaining('define data parameter')
  if g.0RC <> 0 then return
  sLine = getNextLine()
  do while g.0RC = 0 & sLine <> 'end-define'
    parse var sLine nLevel sName '('sType')' sDirection
    parm = createElement('parm')
    call appendChild parm,parent
    call setAttributes parm,,
         'level',nLevel,,
         'name',strip(sName),,
         'type',sType
    if sDirection <> ''
    then call setAttribute parm,'direction',strip(sDirection)
    sLine = getNextLine()
  end
return

getLineContaining: procedure expose g.
  parse arg sSearchArg
  sLine = getLine(g.0FILEIN)
  do while g.0RC = 0 & pos(sSearchArg, sLine) = 0
    sLine = getLine(g.0FILEIN)
  end
return sLine

getNextLine: procedure expose g.
  sLine = removeWhiteSpace(getLine(g.0FILEIN))
  do while g.0RC = 0 & (sLine = '' | left(sLine,2) = '/*')
    sLine = removeWhiteSpace(getLine(g.0FILEIN))
  end
  if pos('/*',sLine) > 0
  then parse var sLine sLine '/*' .
return sLine

setOptions: procedure expose g.
  parse upper arg sOptions
  /* set default options... */
  g.0OPTION.DUMP     = 0
  g.0OPTION.XML      = 0
  g.0OPTION.RPC      = 0
  g.0OPTION.DOCUMENT = 0
  g.0OPTION.ENCODED  = 0
  g.0OPTION.LITERAL  = 0
  g.0OPTION.WRAPPED  = 0
  do i = 1 to words(sOptions)
    sOption = word(sOptions,i)
    g.0OPTION.sOption = 1
  end
  if g.0OPTION.RPC | g.0OPTION.DOCUMENT |,
     g.0OPTION.ENCODED | g.0OPTION.LITERAL | g.0OPTION.WRAPPED
  then nop
  else do /* Set the default style... */
    g.0OPTION.WRAPPED  = 1
  end
  if g.0OPTION.WRAPPED
  then do
    g.0OPTION.DOCUMENT = 1
    g.0OPTION.LITERAL  = 1
    g.0OPTION.RPC      = 0
    g.0OPTION.ENCODED  = 0
  end
  if g.0OPTION.DOCUMENT then g.0OPTION.RPC = 0
  if g.0OPTION.RPC      then g.0OPTION.DOCUMENT = 0
  if g.0OPTION.LITERAL  then g.0OPTION.ENCODED = 0
  if g.0OPTION.ENCODED  then g.0OPTION.LITERAL = 0
return

Prolog:
  if g.0ENV = 'TSO'
  then g.0LF = '15'x
  else g.0LF = '0A'x
  doc = createDocument('dummy') /* just to get structures in place */
return

Epilog: procedure expose g.
return

/*INCLUDE pretty.rex */
