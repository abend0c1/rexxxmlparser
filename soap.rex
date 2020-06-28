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

/* REXX ***************************************************************
**                                                                   **
** NAME     - SOAP                                                   **
**                                                                   **
** FUNCTION - This exec invokes a Web Service and displays the       **
**            response. It assumes you are running the Apache Axis   **
**            SOAP server on the specified host and port. Other SOAP **
**            servers should also work but have not been tested.     **
**                                                                   **
**            Each time you invoke the client, you specify the SOAP  **
**            server hostname and port, and the name of the service  **
**            that you want to use. The client will then retrieve    **
**            the Web Services Definition Language (WSDL) definitions**
**            for that service from the SOAP server. If there is     **
**            only one operation defined for that service then that  **
**            operation is invoked automatically, else you will be   **
**            prompted to select the operation to be invoked. If the **
**            operation requires one or more parameters then you     **
**            will be prompted for each parameter. No attempt is     **
**            made to validate the input you supply. The operation   **
**            is invoked and the response is displayed.              **
**                                                                   **
** NOTES    - 1. You will have to either append the PARSEXML and     **
**               PRETTY source files manually to this file, or run   **
**               this file through the REXX rexx pre-processor.      **
**                                                                   **
**               To use the pre-processor, run:                      **
**                                                                   **
**               tso rexxpp your.rexx.lib(soap)                      **
**                                                                   **
**            2. You can download Apache Axis from:                  **
**               http://ws.apache.org/axis/                          **
**                                                                   **
**            3. Start the Apache Axis server by issuing the         **
**               following command (all on one line with no line     **
**               breaks):                                            **
**                                                                   **
**               java org.apache.axis.transport.http.SimpleAxisServer**
**                    -p 8080                                        **
**                                                                   **
**               ...you will need to have the Axis jar files in your **
**               classpath, of course.                               **
**                                                                   **
**            4. If you need to go through a proxy server, then      **
**               specify the proxy server hostname and port number   **
**               in the z.!PROXYHOST and z.!PROXYPORT variables      **
**               (see below).                                        **
**                                                                   **
**            5. If you have access to the Internet, you can try the **
**               SOAP client out by running:                         **
**                                                                   **
**               soap vizier.cfa.harvard.edu:8080 UCD                **
**                                                                   **
**                                                                   **
**                                                                   **
**                                                                   **
** SYNTAX   - SOAP url [service] [(options...]                       **
**                                                                   **
**            Where,                                                 **
**            url       = The URL of the Axis SOAP server. Format is:**
**                        hostname:port/path                         **
**                        hostname - Axis SOAP server hostname       **
**                        port - default is 80                       **
**                        path - default is axis/services            **
**            service   = Service name (default is Version). This    **
**                        name is case-sensitive.                    **
**            options   = One or more options:                       **
**                        TRACE - Trace network I/O                  **
**                        DEBUG - Dump message contents in hex       **
**                        XML   - Display messages contents in XML   **
**                        NOPROXY - Do not use proxy host.           **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong+sf@gmail.com>    **
**                                                                   **
** HISTORY  - Date     By  Reason (most recent at the top please)    **
**            -------- --- ----------------------------------------- **
**            20090822 AJA Changed from GPL to BSD license.          **
**            20050602 AJA Retrieve WSDL from SOAP server and prompt **
**                         user for the operation and parameters.    **
**            20050601 AJA Added proxy host support.                 **
**            20050531 AJA Original version.                         **
**                                                                   **
**********************************************************************/

  parse arg sURL sService . '('sOptions')'
  sOptions = translate(sOptions) /* convert to upper case */
  
  parse value sourceline(1) with . sVersion
  say 'SOAP000I Rexx SOAP client' sVersion
  
  z. = '' /* g. is used by the XML parser */

  z.!PROXYHOST = 'proxy.example.org'
  z.!PROXYPORT = '8080'

  if pos('://',sURL) > 0
  then parse var sURL sScheme'://'sURL    /* ignore protocol (scheme) */
  parse var sURL sHost'/'sPath
  parse var sHost sHost':'nPort
  if sHost    = '' then sHost    = 'axisserver.example.org'
  if \datatype(nPort,'WHOLE') then nPort  = 80
  if sPath    = '' then sPath    = 'axis/services'
  if sService = '' then sService = 'Version'

  say 'SOAP001I Host='sHost
  say 'SOAP002I Port='nPort
  say 'SOAP003I Path='sPath
  say 'SOAP004I Service='sService

  call initParser 'NOBLANKS' /* <-- This is in PARSEXML rexx */
  z.!DEBUG   = wordpos('DEBUG',sOptions) <> 0
  z.!TRACE   = wordpos('TRACE',sOptions) <> 0
  z.!XML     = wordpos('XML',sOptions) <> 0
  z.!NOPROXY = wordpos('NOPROXY',sOptions) <> 0

  if z.!NOPROXY
  then do
    z.!PROXYHOST = ''
    z.!PROXYPORT = ''
  end

  say 'SOAP005I Proxy Host='z.!PROXYHOST
  say 'SOAP006I Proxy Port='z.!PROXYPORT
  call Prolog

/*
 *--------------------------------------------------------------------*
 * Contact the SOAP server and retrieve the WSDL for this service
 *--------------------------------------------------------------------*
*/
  nSocket = Connect(sHost,nPort)
  say 'SOAP007I Retrieving WSDL for' sService 'service'
  if z.!PROXYHOST <> ''
  then sURL = 'http://'sHost':'nPort'/'sPath'/'sService'?wsdl'
  else sURL = '/'sPath'/'sService'?wsdl'
  say 'SOAP008I GET' sURL
  sHeader =  'GET' sURL 'HTTP/1.1' || z.!CRLFCRLF

  sMsg = sHeader
  if z.!DEBUG then call Dump sMsg,'Sending'
  sWrite = write(nSocket,sMsg)
/*
 *--------------------------------------------------------------------*
 * Read the response from the SOAP server
 *--------------------------------------------------------------------*
*/
  say 'SOAP009I Reading WSDL response'
  sReply = Slurp(nSocket)
  sDisc = Disconnect(nSocket)
  parse var sReply sHeader (z.!CRLFCRLF) sXML
  if z.!DEBUG then call Dump sHeader,'Header'
  if z.!DEBUG then call Dump sXML,'Payload'
  parse var sHeader . nCode . 0 . sReason (z.!CRLF)
  if nCode <> 200
  then call Abort 'SOAP021E HTTP GET failed:' sReason
/*
 *--------------------------------------------------------------------*
 * Parse the WSDL
 *--------------------------------------------------------------------*
*/
  rc = parseString(sXML)
  doc = getDocumentElement()
  if getName(doc) <> 'wsdl:definitions'
  then do
    say 'SOAP010E Could not retrieve WSDL for' sService,
        'service on' sHost
    say 'SOAP011I The reply received was:'
    call showResponse doc
    call Abort
  end
  porttype   = getChildrenByName(doc,'wsdl:portType')
  operations = getChildrenByName(porttype,'wsdl:operation')
  messages   = getChildrenByName(doc,'wsdl:message')
  do i = 1 to words(messages)
    message = word(messages,i)
    sMsgName = getAttribute(message,'name')
    z.!MSG.sMsgName = message
    z.!MSG.message  = sMsgName
  end
  z.!OP.0  = words(operations)          /* number of operations */
  if z.!OP.0 = 0
  then call Abort 'Service' sService 'supports no operations'
  do i = 1 to z.!OP.0  /* for each operation of this service...*/
    operation = word(operations,i)
    input  = getChildrenByName(operation,'wsdl:input')
    output = getChildrenByName(operation,'wsdl:output')
    sInputMsgName = getAttribute(input,'name')
    sOutputMsgName = getAttribute(output,'name')
    z.!OP.i  = operation                /* operation node */
    z.!IN.i  = z.!MSG.sInputMsgName     /* input parms node */
    z.!OUT.i = z.!MSG.sOutputMsgName    /* output parms node */
  end

  if z.!OP.0 > 1 /* More than one operation to choose from? */
  then do
    say 'SOAP012A Which' sService 'operation do you want to invoke?'
    do i = 1 to z.!OP.0
      say i'.' getAttribute(z.!OP.i,'name')
    end
    pull n
    if n = '' then call Abort 'Operation cancelled'
    if \datatype(n,'WHOLE') | n < 1 | n > z.!OP.0 then n = 1
  end
  else n = 1

  sOperation = getAttribute(z.!OP.n,'name')
  sExpectedResponse = getAttribute(z.!OUT.n,'name')
  say 'SOAP013I About to invoke operation:' sOperation
  parameters = getChildrenByName(z.!IN.n,'wsdl:part')
  z.!PARM.0  = words(parameters) /* number of defined parameters */
  do i = 1 to z.!PARM.0
    parameter = word(parameters,i)
    sParmName = getAttribute(parameter,'name')
    sParmType = getAttribute(parameter,'type')
    say 'SOAP014A Enter value for' sParmName '(type is' sParmType'):'
    parse pull reply
    z.!PARM.i     = reply
    z.!PARMNAME.i = sParmName
  end

/*
 *--------------------------------------------------------------------*
 * Create a SOAP request message roughly like:
 *  <soapenv:Envelope>
 *    <soapenv:Body>
 *      <getVersion/>
 *    </soapenv:Body>
 *  </soapenv:Envelope>
 *--------------------------------------------------------------------*
*/
  call initParser 'NOBLANKS'
  doc = createDocument('soapenv:Envelope')
  call setAttribute doc,'xmlns:soapenv',,
                        'http://schemas.xmlsoap.org/soap/envelope/'
  call setAttribute doc,'xmlns:xsd',,
                        'http://www.w3.org/2001/XMLSchema'
  call setAttribute doc,'xmlns:xsi',,
                        'http://www.w3.org/2001/XMLSchema-instance'
  body = createElement('soapenv:Body')
  call appendChild body,doc
  op   = createElement(sOperation)
  call appendChild op,body
  do i = 1 to z.!PARM.0
    sParmName  = z.!PARMNAME.i
    sParmValue = z.!PARM.i
    parm = createElement(sParmName)
    call appendChild createTextNode(sParmValue),parm
    call appendChild parm,op
  end
  nSocket = Connect(sHost,nPort)
  sContent = toString(getRoot())
  say 'SOAP015I Sending' sOperation 'message to' sService 'service'
  if z.!XML then say sContent
/*
 *--------------------------------------------------------------------*
 * Build an HTTP header and send the message
 *--------------------------------------------------------------------*
*/
  if z.!PROXYHOST <> ''
  then sURL = 'http://'sHost':'nPort'/'sPath'/'sService
  else sURL = '/'sPath'/'sService
  say 'SOAP020I POST' sURL
  sHeader =  'POST' sURL 'HTTP/1.0' || z.!CRLF ||,
    'Content-Type: text/xml; charset=utf-8' || z.!CRLF ||,
    'Accept: application/soap+xml, application/dime,',
            'multipart/related, text/*' || z.!CRLF ||,
    'User-Agent: EpistAxis/1.2' || z.!CRLF ||,
    'Host:' sHost':'nPort || z.!CRLF ||,
    'Cache-Control: no-cache' || z.!CRLF ||,
    'Pragma: no-cache' || z.!CRLF ||,
    'SOAPAction: ""' || z.!CRLF ||,
    'Content-Length:' length(sContent) || z.!CRLF || z.!CRLF

  sMsg = sHeader || sContent
  if z.!DEBUG then call Dump sMsg,'Sending'
  sWrite = write(nSocket,sMsg)
/*
 *--------------------------------------------------------------------*
 * Read the response from the SOAP server
 *--------------------------------------------------------------------*
*/
  sReply = Slurp(nSocket)
  parse var sReply sHeader (z.!CRLFCRLF) sXML
  if z.!DEBUG then call Dump sHeader,'Header'
  if z.!DEBUG then call Dump sXML,'Payload'
  parse var sHeader . nCode . 0 . sReason (z.!CRLF)
  if nCode <> 200
  then call Abort 'SOAP021E HTTP POST failed:' sReason

/*
 *--------------------------------------------------------------------*
 * Now parse the response message.
 * If it worked, the response will look like:
 *
 * <soapenv:Envelope>
 *   <soapenv:Body>
 *     <getVersionResponse>
 *       <getVersionReturn>
 *         version information
 *       </getVersionReturn>
 *     </getVersionResponse>
 *   </soapenv:Body>
 * </soapenv:Envelope>
 *
 * If it failed, the response will look like:
 *
 * <soapenv:Envelope>
 *   <soapenv:Body>
 *     <soapenv:Fault>
 *       <faultcode>code</faultcode>
 *       <faultstring>string</faultstring>
 *       <detail>
 *         <stackTrace>stack trace information</stackTrace>
 *         <hostname>hostname of SOAP server</hostname>
 *       </detail>
 *     </soapenv:Fault>
 *   </soapenv:Body>
 * </soapenv:Envelope>
 *--------------------------------------------------------------------*
*/
  call initParser 'NOBLANKS'
  rc = parseString(sXML)
  if z.!XML then call prettyPrinter

/*
 *--------------------------------------------------------------------*
 * Extract the payload from the response
 *--------------------------------------------------------------------*
*/
  doc  = getDocumentElement() /* SOAP envelope */
  body = getFirstChild(doc)   /* SOAP body */
  resp = getFirstChild(body)  /* SOAP server response */
  select
    when getName(resp) = sExpectedResponse then do
      say 'SOAP016I Received "'sExpectedResponse'" response:'
      call showResponse resp
    end
    when getName(resp) = 'soapenv:Fault'      then do
      say 'SOAP017E Received "'getName(resp)'" response:'
      call showResponse resp
    end
    otherwise do
      say 'SOAP018W Received unexpected response:'
      say toString(resp)
    end
  end

  call Epilog
exit

showResponse: procedure expose z. g.
  parse arg node,sPad
  if isElementNode(node)
  then do
    if hasAttribute(node,'xsi:type')
    then do
      say sPad || getName(node),
                  getAttribute(node,'xsi:type') ||,
                  '="'getText(getFirstChild(node))'"'
    end
    else do
      say sPad || getName(node)
      if isTextNode(getFirstChild(node))
      then say sPad'  'getText(getFirstChild(node))
    end
  end
  children = getChildren(node)
  do i = 1 to words(children)
    child = word(children,i)
    call showResponse child,sPad'  '
  end
return

showParameters: procedure expose z. g.
  parse arg sMsgName
  message = z.!MSG.sMsgName
  parts = getChildrenByName(message,'wsdl:part')
  do k = 1 to words(parts)
    part = word(parts,k)
    say '    parameter:' getAttribute(part,'name'),
                 'type:' getAttribute(part,'type')
  end
return

Connect: procedure expose z.
  parse arg sHost,nPort
  say 'SOAP019I Connecting to' sHost 'port' nPort
  if z.!PROXYHOST <> '' then sHost = z.!PROXYHOST
  if z.!PROXYPORT <> '' then nPort = z.!PROXYPORT
  sShutdown = Socket('Shutdown', z.!SOCKET)
  sClose    = Socket('Close', z.!SOCKET)
  nSocket   = Socket('Socket','AF_INET','SOCK_STREAM','TCP')
  sSockOpt  = Socket('SetSockOpt',nSocket,'IPPROTO_TCP','SO_ASCII','ON')
  sConnect  = Socket('Connect',nSocket,'AF_INET' nPort sHost)
  if z.!RC <> 0 then call ABORT sConnect
return nSocket

Slurp: procedure expose z.
  parse arg nSocket
  sReply = ''
  sRead  = read(nSocket)
  do while length(sRead) > 0
    sReply = sReply || sRead
    sRead  = read(nSocket)
  end
return sReply

Disconnect: procedure expose z.
  parse arg nSocket
  sShutdown= Socket('Shutdown', nSocket)
  sResp = Socket('Close', nSocket)
return sResp

Abort: procedure expose z.
  parse arg sMsg
  say sMsg
  call Epilog
  exit
return

Write: procedure expose z.
  parse arg nSocket,sMsg
  if z.!TRACE then call Dump sMsg,'-->'
  sWrite    = Socket('Write',nSocket,sMsg)
return sWrite

Read: procedure expose z.
  parse arg nSocket
  sRead     = Socket('Read',nSocket)
  parse var sRead nLen sData
  if z.!TRACE then call Dump sData,'<--'
return sData

Dump: procedure expose z.
  parse arg sData,sPrefix,nPad
  if \datatype(nPad,'WHOLE') then nPad = 8
  sPrefix = left(sPrefix,nPad)
  lastline = length(sData)%16*16+1
  do i = 1 to length(sData) by 16
    if i = lastline
    then sChunk = substr(sData,i)
    else sChunk = substr(sData,i,16)
    xChunk = left(c2x(sChunk),32)
    say sPrefix,
        substr(xChunk, 1,8),
        substr(xChunk, 9,8),
        substr(xChunk,17,8),
        substr(xChunk,25,8),
        '*'left(sChunk,16)'*'
    sPrefix = right('+'d2x(i+15,6),nPad)
  end
return

Prolog:
  z.!CR = '0D'x /* EBCDIC Carriage Return */
  z.!LF = '25'x /* EBCDIC Line Feed */
  z.!CRLF = '0D25'x
  z.!CRLFCRLF = z.!CRLF || z.!CRLF
  sResp = Socket('Terminate') /* Kill any previous socket set */
  sResp = Socket('Initialize', 'MySet')
  if z.!RC <> 0 then exit z.!RC
return

Epilog:
  sDisc = Disconnect(nSocket)
  sResp = Socket('Terminate')
return sResp

Socket: procedure expose z.
  parse arg a,c,d,e,f,g,h,i,j,k
  if z.!TRACE
  then say 'Socket('strip(a','c','d','e','f','g','h','i','j','k,'T',",")')'

  parse value 'SOCKET'(a,c,d,e,f,g,h,i,j,k) with nRC sResp
  z.!RC = nRC

  if z.!TRACE
  then do
    say '      Return code <'nRC'>'
    say '      Response    <'sResp'>'
  end
return sResp

/*INCLUDE pretty.rex */
