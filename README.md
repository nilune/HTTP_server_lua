# HTTP_server_lua

### Simple http server written on Lua

This application is a http server written on Lua in conjunction with a Tarantool. Implemented kv-storage. The server can be accessed via the links:
  - Create object - url: "/kv", method: POST, body: { "key": "test", "value": json }
  - Update object - url: "/kv/{id}", method: PUT, body: { "value": json }
  - Get object - url: "/kv/{id}", method: GET
  - Delete object - url: "/kv/{id}", method: DELETE


To deploy the application, install the tarantool and the necessary libraries - make install && make build.
The launch is carried out by the command "make up".
All database files are listed in "./db".
Logs is in "./logs".

A good program for quickly sending various requests to the server - "Postman".
