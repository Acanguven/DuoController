local socket = require("socket")
local tcp = socket.tcp()
tcp:settimeout(10)
local ok,err = tcp:connect("localhost", 5000)
if not ok then
   print('Could not connect Error: ',err)
   return
else
   print("TCP connection succesful with Duo Controller Server")
end
--Connection Done

--Tcp Send
tcp:send("hello world");

--Tcp Recieve
lastTick = 0
function OnTick()
	tcpListen()
end

function tcpListen()
	local s, status, partial = tcp:receive()
	if #partial > 1 then
		print(partial)
	end
end
