-- TSerial v1.2, a simple table serializer which turns tables into Lua script
-- by Taehl (SelfMadeSpirit@gmail.com)

-- Usage: table = TSerial.unpack( TSerial.pack(table) )
TSerial = {}
function TSerial.pack(t)
	assert(type(t) == "table", "Can only TSerial.pack tables.")
	if not t then return nil end
	local s = "{"
	for k, v in pairs(t) do
		local tk, tv = type(k), type(v)
		if tk == "string" then
		elseif tk == "number" then k = "["..k.."]"
		elseif tk == "boolean" then k = k and "true" or "false"
		else error("Attempted to Tserialize a table with an invalid key: "..tostring(k))
		end
		if tv == "number" then
		elseif tv == "string" then v = string.format("%q", v)
		elseif tv == "table" then v = TSerial.pack(v)
		elseif tv == "boolean" then v = v and "true" or "false"
		else error("Attempted to Tserialize a table with an invalid value: "..tostring(v))
		end
		s = s..k.."="..v..","
	end
	return s.."}"
end

function TSerial.unpack(s)
	assert(type(s) == "string", "Can only TSerial.unpack strings.")
	loadstring("TSerial.table="..s)()
	local t = TSerial.table
	TSerial.table = nil
	return t
end