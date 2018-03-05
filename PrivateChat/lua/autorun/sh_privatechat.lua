function _E( t, i )
	if not i then 
		i = 0 
	end
	t = player.GetAll()
	i = i + 1 
	local v = t[ i ] 
	if v then 
		return i, v 
	end 
	return nil
end 

CHAT_VERSION = "1.1.143 Release"
