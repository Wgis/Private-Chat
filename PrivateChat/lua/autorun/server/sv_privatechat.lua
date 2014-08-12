////////////////////
// sv_privatechat //
////////////////////


ServerLog( "Private Chat by YVL Loaded" )

local NWStrings = {
	"SendReply",
	"SendReply2", 
	"TypingStatus",
	"TypingStatus2",
	"RequestVoiceChat",
	"RequestVoiceChat2",
	"RequestVoiceChatCallback",
	"RequestVoiceChatSenderCallback",
	"VoiceChatDecision",
	"EndVoiceChat",
	"EndVoiceChatCL",
	"VRPressed",
	"VRReleased",
	"Disconnect",
	"Connect",
	"EndVoiceChatDC",
	"GetInfo",
	"GetInfoCallback",
	"NetworkGroupsTable",
	"NetworkGroupMessages",
	"CreateServerGroup",
	"CreateServerGroupCallback",
	"InviteUsers",
	"InviteUsersNotify",
	"InviteUsersNotifyCallback",
	"SendGroupMessage",
	"LeaveGroup",
	"KickFromGroup",
	"KickFromGroupCL",
	"JoinGroup",
	"JoinGroupCL",
	"JoinGroupVoice",
	"JoinGroupVoiceCallback",
	"LeaveGroupVoice",
	"LeaveGroupVoiceCallback"		
}

for k, v in next, NWStrings do
	util.AddNetworkString( v )
end

local meta = FindMetaTable( "Player" )

resource.AddFile( "sound/chat/voice_dialing.wav" )
resource.AddFile( "sound/chat/voice_ringing.wav" )
resource.AddFile( "sound/chat/voice_hangup1.wav" )
resource.AddFile( "sound/chat/voice_busy.wav" )

--[[----------------------------------------------------------
	Networking
----------------------------------------------------------]]--

net.Receive( "SendReply", function( _, ply )

	local str = net.ReadString()
	local toSend = net.ReadEntity()
	
	net.Start( "SendReply2" )
		net.WriteString( str )
		net.WriteEntity( ply )
	net.Send( toSend )
	
	net.Start( "TypingStatus2" )
		net.WriteBit( false )
		net.WriteEntity( ply )
	net.Send( toSend )
	
end )

net.Receive( "TypingStatus", function( _, ply )

	local bool = tobool( net.ReadBit() )
	local toSend = net.ReadEntity()
	
	net.Start( "TypingStatus2" )
		net.WriteBit( bool )
		net.WriteEntity( ply )
	net.Send( toSend )
	
end )

net.Receive( "RequestVoiceChat", function( _, ply )

	local sendingTo = net.ReadEntity()	
	
	net.Start( "GetInfo" )
		net.WriteString( "chat_allow_calls" )
	net.Send( sendingTo )
	
	local received = false
	
	net.Receive( "GetInfoCallback", function()
	
		local bool = tobool( net.ReadBit() )
		received = true
		
		if not bool then
			net.Start( "RequestVoiceChatSenderCallback" )
				net.WriteBit( false )
			net.Send( ply )	
			return			
		end
		
		if sendingTo.TalkingTo or ( not IsValid( sendingTo ) ) or sendingTo.Pending or sendingTo:IsBot() then
			net.Start( "RequestVoiceChatSenderCallback" )
				net.WriteBit( false )
			net.Send( ply )	
			return
		else
		
			for k, v in next, GROUPS do
				if table.HasValue( v.Voice, sendingTo ) then
					net.Start( "RequestVoiceChatSenderCallback" )
						net.WriteBit( false )
					net.Send( ply )	
					return		
				end
			end
			
			net.Start( "RequestVoiceChatSenderCallback" )
				net.WriteBit( true )
			net.Send( ply )
			
			sendingTo.Pending = true
			ply.Pending = true
		end
		
		net.Start( "RequestVoiceChat2" )
			net.WriteEntity( ply )
		net.Send( sendingTo )
		
	end )
	
	net.Receive( "RequestVoiceChatCallback", function( _, ply1 )
	
		local ent = net.ReadEntity()
		local accept = tobool( net.ReadBit() )
		
		if accept == true then
		
			ply1.TalkingTo = ent
			ply1.Pending = nil
			ent.TalkingTo = ply1
			ent.Pending = nil
			
			-- Turn on mics with +voicerecord
			timer.Create( "voicerecord" .. ply1:EntIndex(), 0.5, 0, function()
				ply1:SendLua( [[LocalPlayer():ConCommand( "+voicerecord" )]] )
			end )
			
			timer.Create( "voicerecord" .. ent:EntIndex(), 0.5, 0, function()
				ent:SendLua( [[LocalPlayer():ConCommand( "+voicerecord" )]] )
			end )				

			net.Start( "VoiceChatDecision" )
				net.WriteEntity( ply1 ) -- sent to
				net.WriteEntity( ply )  -- sender
				net.WriteBit( true )
			net.Send( { ply, ply1 } )				
		else
			net.Start( "VoiceChatDecision" )
				net.WriteEntity( ply1 ) -- sent to
				net.WriteEntity( ply )  -- sender
				net.WriteBit( false )
			net.Send( { ply, ply1 } )
		end
		
	end )
	
	timer.Simple( 2, function()
	
		if not received then
			net.Start( "RequestVoiceChatSenderCallback" )
				net.WriteBit( false )
			net.Send( ply )	
		end
		
	end )
	
end )

net.Receive( "EndVoiceChat", function( _, ply )

	local ply1 = net.ReadEntity()
	
	ply1.TalkingTo = nil
	ply.TalkingTo = nil
	
	-- Turn off mics
	ply1:SendLua( [[LocalPlayer():ConCommand( "-voicerecord" )]] )
	ply:SendLua( [[LocalPlayer():ConCommand( "-voicerecord" )]] )		
	
	timer.Destroy( "voicerecord" .. ply:EntIndex() )
	timer.Destroy( "voicerecord" .. ply1:EntIndex() )
	
	net.Start( "EndVoiceChatCL" )
		net.WriteEntity( ply )
		net.WriteEntity( ply1 )
	net.Send( { ply, ply1 } )
	
end )



--[[
	This is an important networked var that allows us to determine whether or not 
	the player is holding down their mic in-game, which would allow other players 
	to hear them normally - this is used in the hook below
]]

net.Receive( "VRPRessed", function( _, ply )
	ply.VRDown = true
end )

net.Receive( "VRReleased", function( _, ply )
	ply.VRDown = false
end )		

--[[----------------------------------------------------------
	Hooks
----------------------------------------------------------]]--

hook.Add( "PlayerCanHearPlayersVoice", "PrivateChat", function( listener, talker )
	if talker.TalkingTo then
		if talker.VRDown then
			-- Let the gamemode handle it because the player is talking in-game
		else
			if listener == talker.TalkingTo then
				return true
			else
				return false
			end				
		end
	else
		-- Let the gamemode handle it because the player is not in a chat, or let the hook below handle it
	end
end )

hook.Add( "PlayerCanHearPlayersVoice", "PrivateGroupChat", function( listener, talker )
	for k, v in next, GROUPS do
		local plys = v.Voice
		if table.getn( v.Voice ) > 0 then
			if table.HasValue( plys, talker ) then
				if talker.VRDown then
					-- Let the gamemode handle it because the player is talking in-game
				else
					if table.HasValue( plys, listener ) then
						return true
					else
						return false
					end
				end
			end
		end
	end
end )	

hook.Add( "PlayerDisconnected", "BroadcastDC", function( ply )
	
	local id
	if ply:IsBot() then
		id = "NULL"
	else
		id = ply:SteamID()
	end
	
	net.Start( "Disconnect" )
		net.WriteString( id )
	net.Broadcast()
	
	-- If they were in a voice chat, end it
	if ply.TalkingTo then
	
		local ply1 = ply.TalkingTo
		ply1.TalkingTo = nil
		ply1:SendLua( [[LocalPlayer():ConCommand( "-voicerecord" )]] )	
		
		timer.Destroy( "voicerecord" .. ply:EntIndex() )
		timer.Destroy( "voicerecord" .. ply1:EntIndex() )
		
		net.Start( "EndVoiceChatDC" )
			net.WriteString( ply:SteamID() )
		net.Send( ply1 )
		
	end
	
end )

hook.Add( "PlayerInitialSpawn", "BroadcastC", function( ply )
	net.Start( "Connect" )
		net.WriteEntity( ply )
	net.Broadcast()
end )	

--[[----------------------------------------------------------
	Groups
----------------------------------------------------------]]--
GROUPS = {}

--[[
	Instead of storing group info clientside, groups are handled by the server
	and the table is networked.
]]

function NetworkGroupsTable()

	net.Start( "NetworkGroupsTable" )
		net.WriteTable( GROUPS )
	net.Broadcast()
	
end

--[[
	Only numbers, letters, spaces, and dashes/underscores are allowed in group names to
	prevent people from doing any stupid shit to mess up networking, kids these days man
]]

function GroupNameIsValid( name )
	
	local regex = "[^A-Za-z0-9_ %-]"
	if string.match( name, regex ) then
		return false, "Name contains invalid characters: " .. string.match( string.Trim( name ), regex )
	end
	
	if string.Trim( name ):len() < 3 then
		return false, "Name must be at least 3 characters"
	end
	
	if string.Trim( name ):len() > 16 then
		return false, "Name must be less than 16 characters"
	end
	
	for k, v in next, GROUPS do
		if k == name then
			return false, "Group already exists"
		end
	end
	
	return true
end

function UserCanJoinGroupChat( group, user )

	if not IsValid( user ) then
		return false, "User is no longer valid"
	end
	
	if table.HasValue( GROUPS[ group ].Members, user ) then
		return false, "User is already in that group"
	end
	
	return true
end

function UserCanJoinGroupVoice( group, user )

	if not IsValid( user ) then
		return false, "User is no longer valid"
	end
	
	if not table.HasValue( GROUPS[ group ].Members, user ) then
		return false, "User is not in that group"
	end	
	
	if table.HasValue( GROUPS[ group ].Voice, user ) then
		return false, "User is already in that group's voice chat"
	end
	
	if user.TalkingTo then
		return false, "User is already in a voice chat"
	end
	
	if user.Pending then
		return false, "User already has a pending voice chat request"
	end
	
	return true
end


function CreateGroup( name, creator, members, private )

	if GROUPS[ name ] then
		return false, "Group with that name already exists!"
	end
	
	local RET = {
		Name = string.Trim( name ),
		Creator = creator, 
		Members = members or {},
		Text = {},
		Private = private,
		Voice = {}
	}
	
	if not table.HasValue( RET.Members, creator ) then
		table.insert( RET.Members, creator )
	end
	
	GROUPS[ name ] = RET
	NetworkGroupsTable()
	
	return true, RET
end

function AddUserToGroup( name, user )

	if not IsValid( user ) then
		return false, "Invalid target"
	end
	
	if not GROUPS[ name ] then
		return false, "Group no longer exists"
	end
	
	table.insert( GROUPS[ name ].Members, user )
	NetworkGroupsTable()
	
	return true
end

function RemoveUserFromGroup( name, user )

	if not IsValid( user ) then
		return false, "Invalid target"
	end
	
	if not GROUPS[ name ] then
		return false, "Group no longer exists"
	end
	
	local users = GROUPS[ name ].Members
	local key
	
	for k, v in next, users do
		if user == v then
			key = k
			break
		end
	end
	
	if not key then
		return false, "User could not be found"
	end
	
	table.remove( GROUPS[ name ].Members, key )
	NetworkGroupsTable()
	
	return true
end

function RemoveGroup( name )

	if not GROUPS[ name ] then
		return false, "Group no longer exists"
	end
	
	GROUPS[ name ] = nil
	NetworkGroupsTable()
	
	return true
end

function GroupExists( name )
	return GROUPS[ name ] ~= nil
end

net.Receive( "CreateServerGroup", function( _, ply )

	local name = net.ReadString()
	local private = tobool( net.ReadBit() )
	local succ, err = GroupNameIsValid( name )
	
	if succ then
		CreateGroup( name, ply, {}, private )
	else
	
		net.Start( "CreateServerGroupCallback" )
			net.WriteBit( false )
			net.WriteString( err )
		net.Send( ply )
		
		return
		
	end
	
	net.Start( "CreateServerGroupCallback" )
		net.WriteBit( true )
		net.WriteString( "" )
	net.Send( ply )
	
end )

net.Receive( "InviteUsers", function( _, ply )

	local group = net.ReadString()
	local ent = net.ReadTable()
	
	for k, v in next, ent do
	
		if not IsValid( v ) then
			continue
		end
		
		net.Start( "InviteUsersNotify" )
			net.WriteEntity( ply )
			net.WriteString( group )
		net.Send( v )
		
	end
	
end )

net.Receive( "InviteUsersNotifyCallback", function( _, ply )

	local str = net.ReadString()
	local bool = tobool( net.ReadBit() )
	
	if bool then
		if UserCanJoinGroupChat( str, ply ) then
			AddUserToGroup( str, ply )
		end
	end
	
end )

net.Receive( "SendGroupMessage", function( _, ply )

	local groupname = net.ReadString()
	local msg = net.ReadString()
	
	if not GroupExists( groupname ) then
		return
	end
	
	table.insert( GROUPS[ groupname ].Text, msg )
	
	net.Start( "NetworkGroupMessages" )
		net.WriteString( groupname )
		net.WriteString( msg )
	net.Broadcast()
	
	NetworkGroupsTable()
	
end )

net.Receive( "LeaveGroup", function( _, ply )

	local group = net.ReadString()
	
	RemoveUserFromGroup( group, ply )
	
	if table.Count( GROUPS[ group ].Members ) == 0 then
		RemoveGroup( group )
		return
	end
	
	if ply == GROUPS[ group ].Creator and table.Count( GROUPS[ group ].Members ) > 0 then
		GROUPS[ group ].Creator = table.Random( GROUPS[ group ].Members )
		NetworkGroupsTable()
	end
	
end )

net.Receive( "KickFromGroup", function( _, ply )

	local group = net.ReadString()
	local pl = net.ReadEntity()
	
	RemoveUserFromGroup( group, pl )
	
	if table.Count( GROUPS[ group ].Members ) == 0 then
		RemoveGroup( group )
		NetworkGroupsTable()
	end		
	
	net.Start( "KickFromGroupCL" )
		net.WriteString( group )
	net.Send( pl )
	
end )

hook.Add( "PlayerDisconnected", "RemoveUsers", function( ply )

	for k, v in next, GROUPS do
	
		if table.HasValue( v.Members, ply ) then
		
			RemoveUserFromGroup( k, ply )
			
			if table.HasValue( v.Voice, ply ) then
			
				for k, v in next, v.Voice do
				
					if v == ply then
					
						table.remove( v.Voice, k )
						timer.Destroy( "voicerecord_g" .. ply:EntIndex() )
						
						timer.Simple( 0, function()
						
							for k, v in next, v.Voice do
								if not IsValid( v ) or v == NULL then
									table.remove( v.Voice, k )
								end
							end
							
							NetworkGroupsTable()
							
						end )
						
					end
					
				end
				
			end
			
			if table.Count( GROUPS[ group ].Members ) == 0 then
				RemoveGroup( group )
				return
			end
			
			if ply == GROUPS[ group ].Creator and table.Count( GROUPS[ group ].Members ) > 0 then
				GROUPS[ group ].Creator = table.Random( GROUPS[ group ].Members )
				NetworkGroupsTable()
			end		
			
		end
		
	end
	
end )

net.Receive( "JoinGroup", function( _, ply )

	local g = net.ReadTable()
	AddUserToGroup( g.Name, ply )
	
	net.Start( "JoinGroupCL" )
		net.WriteTable( g )
	net.Send( ply )
	
end )

net.Receive( "JoinGroupVoice", function( _, ply )

	local group = net.ReadString()
	local canjoin, err = UserCanJoinGroupVoice( group, ply )
	
	if canjoin and not err then
	
		table.insert( GROUPS[ group ].Voice, ply )
		ply:SendLua( [[LocalPlayer():ConCommand( "+voicerecord" )]] )
		
		timer.Create( "voicerecord_g" .. ply:EntIndex(), 0.5, 0, function()	
			ply:SendLua( [[LocalPlayer():ConCommand( "+voicerecord" )]] )
		end )
		
	end
	
	net.Start( "JoinGroupVoiceCallback" )
	
		net.WriteBit( canjoin )
		
		if err then
			net.WriteString( err )
		else
			net.WriteString( "" )
		end
		
		net.WriteString( group )
		
	net.Send( ply )

	for k, v in next, GROUPS[ group ].Voice do
		if not IsValid( v ) or v == NULL then
			table.remove( GROUPS[ group ].Voice, k )
		end
	end
	
	NetworkGroupsTable()
	
end )

net.Receive( "LeaveGroupVoice", function( _, ply )
	
	local group = net.ReadString()
	
	if table.HasValue( GROUPS[ group ].Voice, ply ) then
	
		for k, v in next, GROUPS[ group ].Voice do
			if v == ply then
				table.remove( GROUPS[ group ].Voice, k )
			end
		end
		
		ply:SendLua( [[LocalPlayer():ConCommand( "-voicerecord" )]] )
		timer.Destroy( "voicerecord_g" .. ply:EntIndex() )
		
		net.Start( "LeaveGroupVoiceCallback" )
		net.Send( ply )
		
		NetworkGroupsTable()
		
	end		
	
end )

