# Nimrod wrapper of 0mq
# Generated by c2nim with modifications and enhancement from Andreas Rumpf
# Original licence follows:

#
#    Copyright (c) 2007-2011 iMatix Corporation
#    Copyright (c) 2007-2011 Other contributors as noted in the AUTHORS file
#
#    This file is part of 0MQ.
#
#    0MQ is free software; you can redistribute it and/or modify it under
#    the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation; either version 3 of the License, or
#    (at your option) any later version.
#
#    0MQ is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Generated from zmq version 2.1.5

## Nimrod 0mq wrapper. This file contains the low level C wrappers as well as
## some higher level constructs. The higher level constructs are easily
## recognizable because they are the only ones that have documentation.
##
## Example of a client:
## 
## .. code-block:: nimrod
##   import zmq
##   
##   var connection = zmq.open("tcp://localhost:5555", server=false)
##   echo("Connecting...")
##   for i in 0..10:
##     echo("Sending hello...", i)
##     send(connection, "Hello")
##     var reply = receive(connection)
##     echo("Received ...", reply)
##   close(connection)
##
## Example of a server:
##
## .. code-block:: nimrod
##   
##   import zmq
##   var connection = zmq.open("tcp://*:5555", server=true)
##   while True:
##     var request = receive(connection)
##     echo("Received: ", request)
##     send(connection, "World")
##   close(connection)

{.deadCodeElim: on.}
when defined(windows): 
  const 
    zmqdll* = "zmq.dll"
elif defined(macosx): 
  const 
    zmqdll* = "libzmq.dylib"
else:
  const 
    zmqdll* = "libzmq.so"

# A number random enough not to collide with different errno ranges on      
# different OSes. The assumption is that error_t is at least 32-bit type.  
const 
  HAUSNUMERO* = 156384712
  # On Windows platform some of the standard POSIX errnos are not defined.    
  ENOTSUP* = (HAUSNUMERO + 1)
  EPROTONOSUPPORT* = (HAUSNUMERO + 2)
  ENOBUFS* = (HAUSNUMERO + 3)
  ENETDOWN* = (HAUSNUMERO + 4)
  EADDRINUSE* = (HAUSNUMERO + 5)
  EADDRNOTAVAIL* = (HAUSNUMERO + 6)
  ECONNREFUSED* = (HAUSNUMERO + 7)
  EINPROGRESS* = (HAUSNUMERO + 8)
  # Native 0MQ error codes.  
  EFSM* = (HAUSNUMERO + 51)
  ENOCOMPATPROTO* = (HAUSNUMERO + 52)
  ETERM* = (HAUSNUMERO + 53)
  EMTHREAD* = (HAUSNUMERO + 54)
  #  Maximal size of "Very Small Message". VSMs are passed by value            
  #  to avoid excessive memory allocation/deallocation.                        
  #  If VMSs larger than 255 bytes are required, type of 'vsm_size'            
  #  field in msg_t structure should be modified accordingly.
  MAX_VSM_SIZE* = 30

  POLLIN* = 1
  POLLOUT* = 2
  POLLERR* = 4

  STREAMER* = 1
  FORWARDER* = 2
  QUEUE* = 3

  PAIR* = 0
  PUB* = 1
  SUB* = 2
  REQ* = 3
  REP* = 4
  DEALER* = 5
  ROUTER* = 6
  PULL* = 7
  PUSH* = 8
  XPUB* = 9
  XSUB* = 10
  XREQ* = DEALER      #  Old alias, remove in 3.x               
  XREP* = ROUTER      #  Old alias, remove in 3.x               
  UPSTREAM* = PULL    #  Old alias, remove in 3.x               
  DOWNSTREAM* = PUSH  #  Old alias, remove in 3.x        

type
  #  Message types. These integers may be stored in 'content' member of the    
  #  message instead of regular pointer to the data. 
  TMsgTypes* = enum
    DELIMITER = 31,
    VSM = 32
  #  Message flags. MSG_SHARED is strictly speaking not a message flag     
  #  (it has no equivalent in the wire format), however, making  it a flag     
  #  allows us to pack the stucture tighter and thus improve performance.   
  TMsgFlags* = enum 
    MSG_MORE = 1,
    MSG_SHARED = 128,
    MSG_MASK = 129         # Merges all the flags 
  #  A message. Note that 'content' is not a pointer to the raw data.          
  #  Rather it is pointer to zmq::msg_content_t structure                      
  #  (see src/msg_content.hpp for its definition).    
  TMsg*{.pure, final.} = object 
    content*: pointer
    flags*: char
    vsm_size*: char
    vsm_data*: array[0..MAX_VSM_SIZE - 1, char]

  TFreeFn = proc (data, hint: pointer) {.noconv.}

  TContext {.final, pure.} = object
  PContext* = ptr TContext
  
  # Socket Types
  TSocket {.final, pure.} = object
  PSocket* = ptr TSocket       

  #  Socket options.                                                           
  TSockOptions* = enum
    HWM = 1,
    SWAP = 3,
    AFFINITY = 4,
    IDENTITY = 5,
    SUBSCRIBE = 6,
    UNSUBSCRIBE = 7,
    RATE = 8,
    RECOVERY_IVL = 9,
    MCAST_LOOP = 10,
    SNDBUF = 11,
    RCVBUF = 12,
    RCVMORE = 13,
    FD = 14,
    EVENTS = 15,
    theTYPE = 16,
    LINGER = 17,
    RECONNECT_IVL = 18,
    BACKLOG = 19,
    RECOVERY_IVL_MSEC = 20, #  opt. recovery time, reconcile in 3.x   
    RECONNECT_IVL_MAX = 21

  #  Send/recv options.                                                        
  TSendRecvOptions* = enum
    NOBLOCK, SNDMORE
  
  TPollItem*{.pure, final.} = object 
    socket*: PSocket
    fd*: cint
    events*: cshort
    revents*: cshort
  
#  Run-time API version detection                                            

proc version*(major: var cint, minor: var cint, patch: var cint){.cdecl, 
    importc: "zmq_version", dynlib: zmqdll.}
#****************************************************************************
#  0MQ errors.                                                               
#****************************************************************************

#  This function retrieves the errno as it is known to 0MQ library. The goal 
#  of this function is to make the code 100% portable, including where 0MQ   
#  compiled with certain CRT library (on Windows) is linked to an            
#  application that uses different CRT library.                              

proc errno*(): cint{.cdecl, importc: "zmq_errno", dynlib: zmqdll.}
#  Resolves system errors and 0MQ errors to human-readable string.

proc strerror*(errnum: cint): cstring {.cdecl, importc: "zmq_strerror", 
    dynlib: zmqdll.}
#****************************************************************************
#  0MQ message definition.                                                   
#****************************************************************************

proc msg_init*(msg: var TMsg): cint{.cdecl, importc: "zmq_msg_init", 
    dynlib: zmqdll.}
proc msg_init*(msg: var TMsg, size: int): cint{.cdecl, 
    importc: "zmq_msg_init_size", dynlib: zmqdll.}
proc msg_init*(msg: var TMsg, data: cstring, size: int, 
               ffn: TFreeFn, hint: pointer): cint{.cdecl, 
    importc: "zmq_msg_init_data", dynlib: zmqdll.}
proc msg_close*(msg: var TMsg): cint {.cdecl, importc: "zmq_msg_close", 
    dynlib: zmqdll.}
proc msg_move*(dest, src: var TMsg): cint{.cdecl, 
    importc: "zmq_msg_move", dynlib: zmqdll.}
proc msg_copy*(dest, src: var TMsg): cint{.cdecl, 
    importc: "zmq_msg_copy", dynlib: zmqdll.}
proc msg_data*(msg: var TMsg): cstring {.cdecl, importc: "zmq_msg_data", 
    dynlib: zmqdll.}
proc msg_size*(msg: var TMsg): int {.cdecl, importc: "zmq_msg_size", 
    dynlib: zmqdll.}
    
#****************************************************************************
#  0MQ infrastructure (a.k.a. context) initialisation & termination.         
#****************************************************************************

proc init*(io_threads: cint): PContext {.cdecl, importc: "zmq_init", 
    dynlib: zmqdll.}
proc term*(context: PContext): cint {.cdecl, importc: "zmq_term", 
                                        dynlib: zmqdll.}
#****************************************************************************
#  0MQ socket definition.                                                    
#****************************************************************************                                                         

proc socket*(context: PContext, theType: cint): PSocket {.cdecl, 
    importc: "zmq_socket", dynlib: zmqdll.}
proc close*(s: PSocket): cint{.cdecl, importc: "zmq_close", dynlib: zmqdll.}
proc setsockopt*(s: PSocket, option: cint, optval: pointer, 
                     optvallen: int): cint {.cdecl, importc: "zmq_setsockopt", 
    dynlib: zmqdll.}
proc getsockopt*(s: PSocket, option: cint, optval: pointer, 
                 optvallen: ptr int): cint{.cdecl, 
    importc: "zmq_getsockopt", dynlib: zmqdll.}
proc bindAddr*(s: PSocket, address: cstring): cint{.cdecl, importc: "zmq_bind", 
    dynlib: zmqdll.}
proc connect*(s: PSocket, address: cstring): cint{.cdecl, 
    importc: "zmq_connect", dynlib: zmqdll.}
proc send*(s: PSocket, msg: var TMsg, flags: cint): cint{.cdecl, 
    importc: "zmq_send", dynlib: zmqdll.}
proc recv*(s: PSocket, msg: var TMsg, flags: cint): cint{.cdecl, 
    importc: "zmq_recv", dynlib: zmqdll.}
#****************************************************************************
#  I/O multiplexing.                                                         
#****************************************************************************

proc poll*(items: ptr TPollItem, nitems: cint, timeout: int): cint{.
    cdecl, importc: "zmq_poll", dynlib: zmqdll.}
    
#****************************************************************************
#  Built-in devices                                                          
#****************************************************************************

proc device*(device: cint, insocket, outsocket: PSocket): cint{.
    cdecl, importc: "zmq_device", dynlib: zmqdll.}
    
type
  EZmq* = object of ESynch ## exception that is raised if something fails
  TConnection* {.pure, final.} = object ## a connection
    c*: PContext  ## the embedded context
    s*: PSocket   ## the embedded socket
  
  TConnectionMode* = enum ## connection mode
    conPAIR = 0,
    conPUB = 1,
    conSUB = 2,
    conREQ = 3,
    conREP = 4,
    conDEALER = 5,
    conROUTER = 6,
    conPULL = 7,
    conPUSH = 8,
    conXPUB = 9,
    conXSUB = 10
  
proc zmqError*() {.noinline, noreturn.} =
  ## raises EZmq with error message from `zmq.strerror`.
  var e: ref EZmq
  new(e)
  e.msg = $strerror(errno())
  raise e
  
proc open*(address: string, server: bool, mode: TConnectionMode = conDEALER,
           numthreads = 4): TConnection =
  ## opens a new connection. If `server` is true, it uses `bindAddr` for the
  ## underlying socket, otherwise it opens the socket with `connect`.
  result.c = init(cint(numthreads))
  if result.c == nil: zmqError()
  result.s = socket(result.c, cint(ord(mode)))
  if result.s == nil: zmqError()
  if server:
    if bindAddr(result.s, address) != 0'i32: zmqError()
  else:
    if connect(result.s, address) != 0'i32: zmqError()
  
proc close*(c: TConnection) =
  ## closes the connection.
  if close(c.s) != 0'i32: zmqError()
  if term(c.c) != 0'i32: zmqError()
  
proc send*(c: TConnection, msg: string) =
  ## sends a message over the connection.
  var m: TMsg
  if msg_init(m, msg.len) != 0'i32: zmqError()
  copyMem(msg_data(m), cstring(msg), msg.len)
  if send(c.s, m, 0'i32) != 0'i32: zmqError()
  discard msg_close(m)
  
proc receive*(c: TConnection): string =
  ## receives a message from a connection.
  var m: TMsg
  if msg_init(m) != 0'i32: zmqError()
  if recv(c.s, m, 0'i32) != 0'i32: zmqError()
  result = newString(msg_size(m))
  copyMem(addr(result[0]), msg_data(m), result.len)
  discard msg_close(m)
