---------------------------------------------------------------------
-- XML-RPC over HTTP.
-- See Copyright Notice in license.html
---------------------------------------------------------------------

local error, tonumber, tostring, unpack, type = error, tonumber, tostring, unpack, type

local ltn12   = require"ltn12"
local request = require"socket.http".request
local string  = require"string"
local table   = require"table"
local xmlrpc  = require"xmlrpc"

module("xmlrpc.http")

---------------------------------------------------------------------
-- Call a remote method.
-- @param url String with the location of the server.
-- @param method String with the name of the method to be called.
-- @return Table with the response (could be a `fault' or a `params'
--	XML-RPC element).
---------------------------------------------------------------------
function call (url_or_table, method, ...)
	local request_sink, tbody = ltn12.sink.table()
	local request_body = xmlrpc.clEncode(method, ...)

	local reqt
	if type(url_or_table) == 'string' then
		reqt = { }
		reqt.url = url_or_table
	elseif type(url_or_table) == 'table' then
		reqt = url_or_table
	end
	
	reqt.method = reqt.method or "POST"
	reqt.source = reqt.source or ltn12.source.string (request_body)
	reqt.sink   =  reqt.sink  or request_sink
	reqt.headers = reqt.headers or { }
	local h = reqt.headers
	h["User-agent"]     = h["User-agent"]     or xmlrpc._PKGNAME .. " " .. xmlrpc._VERSION
	h["Content-type"]   = h["Content-type"]   or "text/xml"
	h["content-length"] = h["content-length"] or tostring (string.len (request_body))

	local err, code, headers, status = request(reqt)
	local body = table.concat (tbody)
	if tonumber (code) == 200 then
	   -- "return xmlrpc.clDecode(body), headers" can not work
	   -- and I don't want to change any existing code.
	   local ret, result = xmlrpc.clDecode(body)
	   return  ret, result, headers
	else
		error (tostring (err or code).."\n\n"..tostring(body))
	end
end
