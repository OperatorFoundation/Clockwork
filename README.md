# Clockwork

Clockwork is a tool to generate remote procedure call (RPC) plumbing for Swift projects

```
clockwork <source> <output>
```

source is the directory to look for .swift files
output is the directory to put the generated files

For each public class found, each of the public (non-static) functions will be exposed via RPC.

Three files will be generated: messages, client, and server.

The messages file is only used internally by the client and server.

The client is a library that provides the same API as the original class, but instead of running the code
locally, it calls the server over RPC.

The server is a library that connects the RPC to your business logic class.

Both the client and server require some additional work in order to use them. The client requires a
network connection to the server to be pass into the constructor. The server requires a network listener
and an instance of your business logic class.

Please note that while the API of the client mimics the API of your business logic class, all client
functions can throw, even if your business logic class function does not throw. This is because RPC
functions can always fail (due to network outages or other RPC-related problems) even if your busines logic
functions can never fail.

It should also be noted that Clockwork was developed as a proof-of-concept and does not use a Swift syntax
parser to parse your business logic function signatures. It uses simple regular expressions. The reason for
this is that the Swift parsers are hard to use and writing this with them would be labor-intensive. The
downside of the simple parsing method used is that there are many constraints on your code, both semantically
and syntactically. Deviating from the narrow format that is allowed will likely result in failure of the
tool to execute, generated code that will not compile, or generated code that is incorrect. On the bright
side, it's quite short, less than 1000 lines on the first pass.
