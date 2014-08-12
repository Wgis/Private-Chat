////////////////////
// cl_privatechat //
////////////////////


MsgN( "Private Chat by YVL Loaded (Version " .. CHAT_VERSION .. ")" )

CreateClientConVar( "chat_show_overlay", "1", FCVAR_ARCHIVE )
CreateClientConVar( "chat_enable_calling_sounds", "1", FCVAR_ARCHIVE )
CreateClientConVar( "chat_enable_ringing_sounds", "1", FCVAR_ARCHIVE )
CreateClientConVar( "chat_enable_hangup_sounds", "1", FCVAR_ARCHIVE )
CreateClientConVar( "chat_enable_busy_sounds", "1", FCVAR_ARCHIVE )
CreateClientConVar( "chat_allow_calls", "1", FCVAR_ARCHIVE )
CreateClientConVar( "chat_button_sounds", "1", FCVAR_ARCHIVE )
CreateClientConVar( "chat_notify_sounds", "1", FCVAR_ARCHIVE )


surface.CreateFont( "rtfont1", {
	font = "Arial",
	size = 16,
	antialias = true,
	shadow = true
} )

surface.CreateFont( "asdf1", {
	font = "Arial",
	size = 20,
	antialias = true
} )

surface.CreateFont( "name1", {
	font = "Arial",
	size = 30,
	antialias = true
} )	

surface.CreateFont( "test1", {
	font = "Century Gothic",
	size = 40,
	weight = 1,
	antialias = true
} )		

surface.CreateFont( "panel", {
	font = "Century Gothic",
	size = 25,
	weight = 1,
	antialias = true
} )	

surface.CreateFont( "Settings", {
	font = "Century Gothic",
	size = 18,
	italic = true,
	antialias = true,
	weight = 1
} )


--[[
	If the panel is open when the file refreshes, it will error like crazy 
	so we have to remove the panel upon refresh.
]]

if CHAT then

	if CHAT.main then
		CHAT.main:Remove()
	end
	
	CHAT.main = nil
	CHAT = nil
	
	chat.AddText( "Private Chat has been reloaded (Version " .. CHAT_VERSION .. ")" )
	
end

CHAT = {} 					-- Main table to store all clientside info
CHAT.BGColor 				= Color( 28, 28, 28, 255 ) -- Don't edit these colors
CHAT.PropertyColor 			= Color( 43, 43, 43, 255 )
CHAT.TextBoxColor 			= Color( 89, 89, 89, 255 )
CHAT.TextHighlightColor		= Color( 210, 71, 38, 255 )
CHAT.TabUnfocusedColor		= Color( 170, 170, 170, 255 )
CHAT.TabFocusedColor		= Color( 255, 255, 255, 255 )
CHAT.KeyDown = false		-- Determines if you are holding down the toggle key ^
CHAT.main = nil				-- Stores the main panel
CHAT.TABS = {}				-- Holds info about player chats
CHAT.PanelQueue = {}		-- Holds queued panels (when someone messages you and you dont have the menu open or a panel initialized with them)
CHAT.LastTabUsed = nil		-- Stores the last tab you had open
CHAT.CurrentNotify = nil	-- Determines if there is a notification visible
CHAT.CurrentError = nil		-- Determines if there is an error visible
CHAT.NotifyQueue = {}		-- Holds notificaion panels
CHAT.ErrorQueue = {}		-- Holds error panels
CHAT.VoiceChatting = nil	-- Determines if you are in a voice chat
CHAT.InGroupVoiceChat = nil	-- Determines if you are in a group voice chat
CHAT.Offline = {}			-- Holds offline panels
CHAT.GROUPS = {} 			-- Holds info for groups
CHAT.CLGROUPS = {} 			-- Holds panel info for groups
CHAT.Invites = {}			-- Group invites

-- Things you can touch:
	CHAT.OpenKey = KEY_F6 		-- This can be changed - the key to toggle the menu. If you change this change the notify string below too
	CHAT.NotifyString = "Press F6 to view"
	CHAT.NotificationSound = "garrysmod/content_downloaded.wav"
--

util.PrecacheSound( "chat/voice_busy.wav" )
util.PrecacheSound( "chat/voice_dialing.wav" )
util.PrecacheSound( "chat/voice_ringing.wav" )
util.PrecacheSound( "chat/voice_hangup1.wav" )

--[[----------------------------------------------------------
	Main vgui
----------------------------------------------------------]]--

function CHAT.OpenChatWindow()

	CHAT.main = vgui.Create( "DFrame", vgui.GetWorldPanel() )
	CHAT.main:SetSize( 650, 450 )
	CHAT.main:Center()	
	CHAT.main:SetTitle( "" )
	CHAT.main:MakePopup()
	CHAT.main:ShowCloseButton( false )
	CHAT.main:SetDraggable( true )
	CHAT.main:SetSizable( true )
	CHAT.main:SetAlpha( 0 )
	CHAT.main:AlphaTo( 255, 0.3, 0, function() end )
	
	function CHAT.main:Paint()
		surface.SetDrawColor( CHAT.BGColor )
		surface.DrawRect( 0, 0, self:GetSize() )	
	end
	
	local al = 0
	hook.Add( "HUDPaint", "DrawFade", function()
		
		if GetConVar( "chat_show_overlay" ):GetInt() == 0 then
			al = 0
			return
		end
		
		if ValidPanel( CHAT.main ) then
		
			surface.SetDrawColor( 0, 0, 0, al )
			surface.DrawRect( 0, 0, ScrW(), ScrH() )
			surface.SetTextColor( color_white )
			surface.SetFont( "test1" )
			surface.SetTextPos( 10, 5 )
			surface.DrawText( os.date( "%I:%M:%S %p" ) )
			surface.SetTextColor( color_white )
			surface.SetFont( "test1" )
			surface.SetTextPos( 10, 39 )
			surface.DrawText( math.floor( system.AppTime() / 60 ) .. " minutes - current session" )
			
			al = al + 10
			if al > 200 then
				al = 200
			end
			
		else
		
			surface.SetDrawColor( 0, 0, 0, al )
			surface.DrawRect( 0, 0, ScrW(), ScrH() )
			
			if al > 0 then
				al = al - 10
				if al <= 0 then
					hook.Remove( "HUDPaint", "DrawFade" )
				end
			end
			
		end
		
	end )
	
	CHAT.close = vgui.Create( "DButton", CHAT.main )
	CHAT.close:SetPos( CHAT.main:GetWide() - 44, 0 )
	CHAT.close:SetSize( 44, 20 )
	CHAT.close:SetText( "" )
	
	function CHAT.close:Think()
		self:SetPos( CHAT.main:GetWide() - 44, 0 )
	end
	
	CHAT.colorv = CHAT.PropertyColor
	function CHAT.PaintClose()
		if not CHAT.main then 
			return 
		end
		surface.SetDrawColor( CHAT.colorv )
		surface.DrawRect( 1, 1, CHAT.close:GetWide() - 2, CHAT.close:GetTall() - 2 )	
		surface.SetFont( "asdf1" )
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( 19, 0 ) 
		surface.DrawText( "x" )
		return true
	end
	
	CHAT.close.Paint = CHAT.PaintClose		
	CHAT.close.OnCursorEntered = function()
		CHAT.colorv = Color( 195, 75, 0, 250 )
		CHAT.PaintClose()
	end	
	
	CHAT.close.OnCursorExited = function()
		CHAT.colorv = CHAT.PropertyColor
		CHAT.PaintClose()
	end	
	
	CHAT.close.OnMousePressed = function()
		CHAT.colorv = Color( 170, 0, 0, 250 )
		CHAT.PaintClose()
	end	
	
	CHAT.close.OnMouseReleased = function()
		CHAT.main:AlphaTo( 0, 0.3, 0, function() 
			CHAT.main:Close()			
		end )
	end	
	
	CHAT.tabs = vgui.Create( "DPropertySheet", CHAT.main )
	CHAT.tabs:SetPos( 1, 20 )
	CHAT.tabs:SetSize( CHAT.main:GetWide() - 2, CHAT.main:GetTall() - 60 )
	
	function CHAT.tabs:Think()
		self:SetSize( CHAT.main:GetWide() - 2, CHAT.main:GetTall() - 60 )
	end
	
	function CHAT.tabs:Paint()
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 20, self:GetWide(), self:GetTall() - 18 )
	end
	
	--Set the last used tab when we close the panel
	function CHAT.main:OnClose()
	
		local t = CHAT.GetTabs()
		local active = CHAT.tabs:GetActiveTab()
		local actual
		
		for k, v in next, t do
			if v.Tab == active then
				actual = v
			end
		end
		
		if actual then
			CHAT.LastTabUsed = actual.Player
		else
		
			if CHAT.test1.Tab == active then
				CHAT.LastTabUsed = nil
				return
			end
			
			for k, v in next, CHAT.CLGROUPS do
				if v.Tab == active then
					CHAT.LastTabUsed = v.Name
				end
			end
			
		end
		
	end
	
	CHAT.text = vgui.Create( "DTextEntry", CHAT.main )
	CHAT.text:SetPos( 1, CHAT.main:GetTall() - 39 )
	CHAT.text:SetSize( CHAT.main:GetWide() - 2, 38 )
	CHAT.text:SetMultiline( true )
	CHAT.text:SetTextColor( color_white )
	CHAT.text:SetEnterAllowed( true )
	CHAT.text:SetKeyboardInputEnabled( true )
	CHAT.text.LastInput = CurTime()
	CHAT.text.HasSent = false
	
	--"Player is typing" message
	function CHAT.text:Think()
		
		local isGroup
		local tab = CHAT.tabs:GetActiveTab()
		for k, v in next, CHAT.CLGROUPS do 
			if v.Tab == tab then 
				isGroup = true
			end 
		end

		self:SetPos( 1, CHAT.main:GetTall() - 39 )
		self:SetSize( CHAT.main:GetWide() - 2, 38 )
		
		if CurTime() - self.LastInput >= 2 and self.HasSent == false and not isGroup then
		
			self.HasSent = true -- To prevent an overflow of net messages
			
			local t = CHAT.GetTabs()
			local active = CHAT.tabs:GetActiveTab()
			local send
			
			for k, v in next, t do
				if v.Tab == active then
					send = v
				end
			end
			
			if send then
				net.Start( "TypingStatus" )
					net.WriteBit( false )
					net.WriteEntity( send.Player )
				net.SendToServer()
			end
			
		end
		
		if self:GetValue():len() > 500 then
			self:SetText( string.sub( self:GetValue(), 1, 500 ) )
			self:SetCaretPos( 500 )
		end
		
	end
	
	function CHAT.text:OnTextChanged()
	
		local tab = CHAT.tabs:GetActiveTab()
		for k, v in next, CHAT.CLGROUPS do 
			if v.Tab == tab then 
				return
			end 
		end		
		
		if self:GetText():len() > 1 then
		
			self.HasSent = false
			local t = CHAT.GetTabs()
			local active = CHAT.tabs:GetActiveTab()
			local send
			
			for k, v in next, t do
				if v.Tab == active then
					send = v
				end
			end
			
			net.Start( "TypingStatus" )
				net.WriteBit( true )
				net.WriteEntity( send.Player )
			net.SendToServer()
			
			CHAT.text.LastInput = CurTime()
			
		end
		
	end
	
	function CHAT.text:Paint()
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawRect( 0, 0, self:GetSize() )
		self:DrawTextEntryText( color_white, CHAT.TextHighlightColor, color_white )
	end
	
	function CHAT.text:PaintOver()
		surface.SetTextColor( color_white )
		surface.SetFont( "Marlett" )
		surface.SetTextPos( self:GetWide() - 15, self:GetTall() - 15 )
		surface.DrawText( "o" )
	end
	
	function CHAT.text:Clear()
		self:SetText( "" )
	end
	
	function CHAT.SendText( str )
		
		-- The '#####' string functions as a separator for the method I use to apply colors to messages using string.Split
		-- You also can't have '#####' in your steam name, it will remove it from your name in gmod so it works out well
		
		local tab = CHAT.tabs:GetActiveTab()
		for k, v in next, CHAT.CLGROUPS do 
			if v.Tab == tab then 
				net.Start( "SendGroupMessage" )
					net.WriteString( v.Name )
					net.WriteString( os.date( "%I:%M %p" ) .. " - #####" .. LocalPlayer():Name() .. "#####: " .. string.Trim( str ) )
				net.SendToServer()
				return
			end 
		end		
		
		local t = CHAT.GetTabs()
		local active = CHAT.tabs:GetActiveTab()
		local send
		
		for k, v in next, t do
			if v.Tab == active then
				send = v
			end
		end
		
		table.insert( send.Text, os.date( "%I:%M %p" ) .. " - #####" .. LocalPlayer():Name() .. "#####: " .. string.Trim( str ) )
		
		local txtX = os.date( "%I:%M %p" ) .. " - #####" .. LocalPlayer():Name() .. "#####: " .. string.Trim( str )
		--send.Panel.RT:AppendText( os.date( "%I:%M %p" ) .. " - " .. LocalPlayer():Name() .. ": " .. string.Trim( str ) .. "\n" )
		local str_tab = string.Split( txtX, "#####" )
		send.Panel.RT:InsertColorChange( 55, 133, 236, 255 )
		send.Panel.RT:AppendText( str_tab[ 1 ] )
		send.Panel.RT:InsertColorChange( 155, 220, 0, 255 )
		send.Panel.RT:AppendText( str_tab[ 2 ] )
		send.Panel.RT:InsertColorChange( 255, 255, 255, 255 )
		send.Panel.RT:AppendText( str_tab[ 3 ] .. "\n" )
		send.Panel.RT:InsertColorChange( 255, 255, 255, 255 )
		
		if send.Player:IsBot() then
			send.Panel.RT:InsertColorChange( 255, 0, 0, 255 )
			send.Panel.RT:AppendText( "This player is a bot and is not able to respond.\n" )
			send.Panel.RT:InsertColorChange( 255, 255, 255, 255 )
		else
			net.Start( "SendReply" )
				net.WriteString( str )
				net.WriteEntity( send.Player )
			net.SendToServer()
		end
		
	end
	
	--[[
		When you press control and enter it will do a newline, like in steam chat
		However you can't check for keys being held down, just key presses,
		so it gives you a 0.2 second window to press enter after you type control
	]]
	
	CHAT.text.CtrlTime = CurTime()
	CHAT.text.LastSent = CurTime()
	
	function CHAT.text:OnKeyCode( code )
	
		if code == KEY_LCONTROL then
			self.CtrlTime = CurTime()
		end
		
		if code == KEY_ENTER then
		
			local t1 = CHAT.GetTabs()
			local active1 = CHAT.tabs:GetActiveTab()
			local send1
			
			for k, v in next, t1 do
				if v.Tab == active1 then
					send1 = v
				end
			end
			
			if send1 then
				if send1.Offline == true then
					self:Clear()
					return
				end
			end
			
			if CurTime() - self.CtrlTime >= 0.2 then
				if string.Trim( self:GetValue() ):len() > 0 then
					if CurTime() - self.LastSent > 1 then
						CHAT.SendText( self:GetValue() )
						self:Clear()
						self.LastSent = CurTime()
					else
						timer.Simple( 0, function()
							self:SetText( string.Trim( self:GetText() ) )
							self:SetCaretPos( self:GetText():len() )
						end )
						return
					end
				else
					self:Clear()
				end
			else
				self:OnEnter()
			end
			
		end
		
	end
	
	--Creating the panel for the start menu
	CHAT.start = vgui.Create( "DPanel", CHAT.tabs )
	CHAT.start:Dock( FILL )
	local x1 = -15
	
	-- ballin' animations are below
	function CHAT.start:Paint()	
	
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 0, self:GetSize() )
		
		local x, y = CHAT.start:GetSize()
		local reps = 82
		
		for i = 1, reps do
			local alpha
			
			if math.floor( x1 ) == i then
				alpha = 255
			else
				if math.floor( x1 ) == ( i + 1 ) or math.floor( x1 ) == ( i - 1 ) then
					alpha = 200
				elseif math.floor( x1 ) == ( i + 2 ) or math.floor( x1 ) == ( i - 2 ) then
					alpha = 150
				elseif math.floor( x1 ) == ( i + 3 ) or math.floor( x1 ) == ( i - 3 ) then
					alpha = 100
				else
					alpha = 60
				end
			end
			
			surface.DrawCircle( x, y, 10 * i, Color( 89, 89, 89, alpha ) )
		end
		
		x1 = x1 + .75
		if x1 > reps * 2 + 5 then 
			x1 = 0
		end
		
		surface.SetFont( "test1" )
		surface.SetTextPos( 4, self:GetTall() - 38 )
		surface.SetTextColor( 255, 255, 255, 35 )
		surface.DrawText( "start" )
		
	end
	
	function CHAT.start:Think()
		if ValidPanel( self ) then
			CHAT.text:SetKeyBoardInputEnabled( false )
			CHAT.text:SetMouseInputEnabled( false )
		end
	end
	
	CHAT.start.Settings = CHAT.start:Add( "DFrame" )
	CHAT.start.Settings:SetPos( CHAT.main:GetWide() - 100, 0 )
	CHAT.start.Settings:SetSize( 300, CHAT.main:GetTall() - 90 )
	CHAT.start.Settings:SetTitle( "" )
	CHAT.start.Settings:ShowCloseButton( false )
	
	CHAT.start.Settings.Using = false
	CHAT.start.Settings.Num = 0		
	CHAT.start.Settings.Alpha = 0
	
	function CHAT.start.Settings:Think()
		if not CHAT.start.Settings.OpenTab.AnimInProgress then
			self:SetPos( CHAT.main:GetWide() - 100, 0 )
			self:SetSize( 300, CHAT.main:GetTall() - 90 )
		end
	end
	
	function CHAT.start.Settings:Paint()
	
		surface.SetDrawColor( CHAT.BGColor )
		surface.DrawRect( 100, 0, self:GetWide() - 100, self:GetTall() )
		
		if self.Num > 0 then
		
			local origin = { x = 100, y = 35 }
			
			for i = 1, self.Num do
				surface.DrawCircle( origin.x - i, origin.y, 15, CHAT.BGColor )
			end
			
			surface.SetFont( "Settings" )
			surface.SetTextColor( Color( 255, 255, 255, self.Alpha ) )
			surface.SetTextPos( 9, 25 )
			surface.DrawText( "settings" )
			
		end
		
	end
	
	CHAT.start.Settings.OpenTab = CHAT.start.Settings:Add( "DButton" )
	CHAT.start.Settings.OpenTab:SetPos( 80, 20 )
	CHAT.start.Settings.OpenTab:SetSize( 20, 30 )
	CHAT.start.Settings.OpenTab:SetText( "" )
	CHAT.start.Settings.OpenTab.Alpha = 75
	CHAT.start.Settings.OpenTab.AnimInProgress = false
	
	function CHAT.start.Settings.OpenTab:Paint()
	
		surface.SetDrawColor( CHAT.BGColor )
		local radius = self:GetTall() / 2
		
		for i = 1, self:GetWide() do
			surface.DrawCircle( radius + i, radius, radius, CHAT.BGColor )
		end
		
		surface.SetTextColor( Color( 255, 255, 255, self.Alpha ) )
		surface.SetTextPos( 4, 8 )
		surface.SetFont( "Marlett" )
		
		if self:GetParent().Using then
			surface.DrawText( "4" )
		else
			surface.DrawText( "3" )
		end
		
	end
	
	CHAT.start.Settings.OpenTab.Think = function() 
		return
	end
	
	function CHAT.start.Settings.OpenTab:OnCursorEntered()
	
		self.Alpha = 200
		
		if self:GetParent().Using or self.AnimInProgress then
			return
		end
		
		CHAT.start.Settings.OpenTab.Think = function()
		
			self:GetParent().Num = self:GetParent().Num + 25
			
			if self:GetParent().Num > 85 then
			
				self:GetParent().Num = 85
				self:GetParent().Alpha = self:GetParent().Alpha + 50
				
				if self:GetParent().Alpha > 255 then
					self:GetParent().Alpha = 255
				end
				
			end
			
		end
		
	end
	
	function CHAT.start.Settings.OpenTab:OnCursorExited()
	
		self.Alpha = 75
		
		CHAT.start.Settings.OpenTab.Think = function()
		
			if self:GetParent().Alpha == 0 then
			
				self:GetParent().Num = self:GetParent().Num - 25
				
				if self:GetParent().Num < 0 then
					self:GetParent().Num = 0
				end
				
			else
			
				self:GetParent().Alpha = self:GetParent().Alpha - 50
				
				if self:GetParent().Alpha < 0 then
					self:GetParent().Alpha = 0 
				end
				
			end
			
		end
		
	end
	
	function CHAT.start.Settings.OpenTab:DoClick()
	
		if self:GetParent().Using then
		
			local pos = Vector( CHAT.main:GetWide() - 300, 0 )
			
			CHAT.start.Settings:MoveTo( pos.x + 200, pos.y, 0.25, 0, 1, function()
				self:SetDisabled( false )
				self:GetParent().Using = false
				
				self.AnimInProgress = false					
			end )
			
		else
		
			if self:GetParent().Num == 0 and self:GetParent().Alpha == 0 then
			
				self:SetDisabled( true )
				local pos = Vector( CHAT.main:GetWide() - 100, 0 )
				
				CHAT.start.Settings:MoveTo( pos.x - 200, pos.y, 0.25, 0, 1, function()
					self:SetDisabled( false )
					self:GetParent().Using = true
				end )
				
			else
			
				CHAT.start.Settings.OpenTab:OnCursorExited()
				self:SetDisabled( true )
				self.AnimInProgress = true
				
				hook.Add( "Think", "Queue", function()
				
					if not ValidPanel( self ) then
						hook.Remove( "Think", "Queue" )
						return
					end
					
					if self:GetParent().Num == 0 and self:GetParent().Alpha == 0 then
						hook.Remove( "Think", "Queue" )
						self:DoClick()							
					end
					
				end )
				
			end
			
		end
		
	end
	
	-- Create the custom checkbox 
	do
		local PANEL = {}

		AccessorFunc( PANEL, "m_bChecked", "Checked", FORCE_BOOL )
		Derma_Install_Convar_Functions( PANEL )

		function PANEL:Init()

			self:SetSize( 40, 20 )
			self:SetText( "" )
			
			self.PosXR = 1
			self.PosYR = 1
			self.PosXG = self:GetWide()
			self.PosYG = 1	
			
		end

		function PANEL:IsEditing()
			return self.Depressed
		end

		function PANEL:SetValue( val )

			val = tobool( val )
			
			self:SetChecked( val )
			self.m_bValue = val

			self:OnChange( val )

			if ( val ) then 
				val = "1" 
			else 
				val = "0" 
			end	
			
			self:ConVarChanged( val )
			
		end

		function PANEL:Paint()
			draw.RoundedBox( 4, 0, 0, self:GetWide(), self:GetTall(), Color( 13, 13, 13, 255 ) ) 
			draw.RoundedBox( 4, self.PosXR, self.PosYR, self:GetWide() - 2, self:GetTall() - 2, Color( 255, 0, 0, 255 ) ) 
			draw.RoundedBox( 4, self.PosXG, self.PosYG, self:GetWide() - 2, self:GetTall() - 2, Color( 0, 255, 0, 255 ) ) 
		end

		function PANEL:DoClick()
			
			if self.Anim then
				return
			end
			CHAT.Tick()
			self:Toggle()
		end

		function PANEL:Toggle()
			if ( self:GetChecked() == nil ) or ( not self:GetChecked() ) then
				self:SetValue( true )
			else
				self:SetValue( false )
			end
		end

		function PANEL:OnChange( val )
		
			local str = "MoveBox"
			for i = 1, 10000 do
				if timer.Exists( str ) then
					str = str .. i
					if not timer.Exists( str ) then
						str = str
						break
					end
				end
			end

			self.Anim = true
			
			if val then
			
				if self.PosXG == 1 then
					self.Anim = false
					return
				end
				
				timer.Create( str, 0.01, self:GetWide() / 8, function()
				
					self.PosXR = self.PosXR - 4
					self.PosXG = self.PosXG - 4

					if self.PosXG < 1 then
						self.PosXG = 1
					end
					
					if timer.RepsLeft( str ) == 0 then
					
						if self.PosXG ~= 1 then
							self.PosXG = 1
							self.PosXR = -self:GetWide()
						end
						
						timer.Stop( str )
						self.Anim = false
					end
					
				end )
				
			else
			
				if self.PosXR == 1 then
					self.Anim = false
					return
				end
				

				timer.Create( str, 0.01, self:GetWide() / 8, function()
				
					self.PosXR = self.PosXR + 4
					self.PosXG = self.PosXG + 4
				
					if self.PosXR > self:GetWide() then
						self.PosXR = self:GetWide()
					end
					
					if timer.RepsLeft( str ) == 0 then
					
						if self.PosXR ~= 1 then
							self.PosXR = 1
							self.posXG = self:GetWide()
						end	
						
						timer.Stop( str )
						self.Anim = false
					end		
					
				end )
				
			end
			
		end

		function PANEL:Think()
			self:ConVarStringThink()
		end

		derma.DefineControl( "DColoredCheckbox", "Colored Checkbox", PANEL, "DButton" )

	end
	
	CHAT.start.Settings.PanelList = vgui.Create( "DPanelList", CHAT.start.Settings )
	CHAT.start.Settings.PanelList:SetPos( 104, 4 )
	CHAT.start.Settings.PanelList:SetSize( 200, 500 )
	CHAT.start.Settings.PanelList:EnableVerticalScrollbar( true )
	CHAT.start.Settings.PanelList:SetSpacing( 0 )

	function CHAT.start.Settings.PanelList:AddSpacer( h )
	
		local pnl = vgui.Create( "DPanel" )
		pnl:SetSize( 0, h )
		pnl.Paint = function()
			return
		end
		
		self:AddItem( pnl ) 
		
	end
	
	function CHAT.start.Settings.PanelList:AddSetting( name, cvar )
		
		if not ConVarExists( cvar ) then
			print( "Error: ConVar doesn't exist: " .. cvar )
			return
		end
		
		local pnl = vgui.Create( "DPanel" )
		pnl:SetSize( 200, 30 )
		
		function pnl:Paint()
			draw.RoundedBox( 4, 0, 0, 192, 30, CHAT.TextBoxColor )
			draw.RoundedBox( 4, 1, 1, 190, 28, CHAT.BGColor )
		end
		
		local label = vgui.Create( "DLabel", pnl )
		label:SetPos( 5, 7 )
		label:SetText( name )
		label:SetTextColor( color_white )
		label:SizeToContents()
		
		local box = vgui.Create( "DColoredCheckbox", pnl )
		box:SetPos( self:GetWide() - 52, 5 )
		box:SetSize( 40, 20 )
		box:SetConVar( cvar )
		
		self:AddItem( pnl )
		self:AddSpacer( 5 )
		
	end
	
	CHAT.start.Settings.PanelList:AddSetting( "Draw Overlay", "chat_show_overlay" )
	CHAT.start.Settings.PanelList:AddSetting( "Allow players to call you", "chat_allow_calls" )
	CHAT.start.Settings.PanelList:AddSetting( "Enable ringing sounds", "chat_enable_ringing_sounds" )
	CHAT.start.Settings.PanelList:AddSetting( "Enable calling sounds", "chat_enable_calling_sounds" )
	CHAT.start.Settings.PanelList:AddSetting( "Enable busy sounds", "chat_enable_busy_sounds" )
	CHAT.start.Settings.PanelList:AddSetting( "Enable hangup sounds", "chat_enable_hangup_sounds" )
	CHAT.start.Settings.PanelList:AddSetting( "Enable click sounds", "chat_button_sounds" )
	CHAT.start.Settings.PanelList:AddSetting( "Enable notification sounds", "chat_notify_sounds" )
	
	CHAT.start.Player = CHAT.start:Add( "DPanelList" )
	CHAT.start.Player:SetPos( 5, 5 )
	CHAT.start.Player:SetSize( 180, 200 )
	CHAT.start.Player:SetSpacing( 1 )
	CHAT.start.Player:EnableVerticalScrollbar( true )
	CHAT.start.Player.Cur = nil
	
	function CHAT.start.Player:AddSpacer( h )
	
		local pnl = vgui.Create( "DPanel" )
		pnl:SetSize( 0, h )
		pnl.Spacer = true
		pnl.Paint = function()
			return
		end
		
		self:AddItem( pnl ) 
		
	end	
	
	function CHAT.start.Player:Paint()
		surface.SetDrawColor( CHAT.BGColor )
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
	end
	
	local function populate()

		CHAT.start.Player:Clear()
		
		local plys = {}
		for k, v in _E do
			if v == LocalPlayer() or CHAT[ v ] ~= nil then
				continue
			end
			table.insert( plys, v )
		end
		
		if table.getn( plys ) == 0 then
		
			CHAT.start.Player:AddSpacer( 80 )
			
			local pnl = vgui.Create( "DButton" )
			pnl:SetSize( 200, 30 )
			pnl:SetFont( "asdf1" )
			pnl:SetTextColor( color_white )
			pnl:SetText( "No users available" )
			pnl.Spacer = true
			
			function pnl:Paint()
				return
			end
			
			function pnl:Think()
				self:SetCursor( "arrow" )
			end
			
			CHAT.start.Player:AddItem( pnl )
			
			return
		end
		
		for k, v in _E do
			
			if v == LocalPlayer() or CHAT[ v ] ~= nil then
				continue
			end
			
			local pnl = vgui.Create( "DButton" )
			pnl:SetSize( 198, 25 )
			pnl:SetFont( "asdf1" )
			pnl:SetTextColor( CHAT.BGColor )
			pnl:SetText( v:Name() )
			pnl.Player = v
			
			pnl.Paint = function( self )
				surface.SetDrawColor( CHAT.TextBoxColor )
				surface.DrawRect( 0, 0, self:GetSize() )
				surface.SetDrawColor( CHAT.BGColor )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )		
			end
			
			function pnl:DoClick()
			
				CHAT.start.Player.Cur = self.Player
				
				pnl.Paint = function( self )
					surface.SetDrawColor( CHAT.TextBoxColor )
					surface.DrawRect( 0, 0, self:GetSize() )
					surface.SetDrawColor( color_white )
					surface.DrawOutlinedRect( 0, 0, self:GetSize() )
				end
				
				for k, v in next, CHAT.start.Player:GetItems() do
				
					if v == pnl then
						continue
					end
					
					v.Paint = function( self )
						surface.SetDrawColor( CHAT.TextBoxColor )
						surface.DrawRect( 0, 0, self:GetSize() )
						surface.SetDrawColor( CHAT.BGColor )
						surface.DrawOutlinedRect( 0, 0, self:GetSize() )	
					end
				end
				
				CHAT.Tick()
			end
			
			CHAT.start.Player:AddItem( pnl )
		end
	end
	populate()
	
	function CHAT.start.Player:_Rebuild()
		self:Clear()
		populate()
	end
	
	function CHAT.start.Player:Think()
		for k, v in next, self:GetItems() do
			if not v.Spacer then
				if not IsValid( v.Player ) or v.Player == NULL then
					self:_Rebuild()
				end
			end
		end
	end		
	
	CHAT.start.Exec = CHAT.start:Add( "DButton" )
	CHAT.start.Exec:SetPos( 5, 210 )
	CHAT.start.Exec:SetSize( 180, 25 )
	CHAT.start.Exec:SetText( "Start Chat" )
	CHAT.start.Exec:SetTextColor( color_white )
	
	function CHAT.start.Exec:Paint()
	
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawRect( 0, 0, self:GetSize() )
		
		if CHAT.start.Player.Cur then
			surface.SetDrawColor( color_white )
		else
			surface.SetDrawColor( CHAT.BGColor )
		end
		
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		
	end
	
	function CHAT.start.Exec:Think()
		if CHAT.start.Player.Cur then
			self:SetDisabled( false )
		else
			self:SetDisabled( true )
		end
	end
	
	function CHAT.start.Exec:DoClick()
		CHAT.StartPanel( CHAT.start.Player.Cur )
		CHAT.tabs:SetActiveTab( CHAT[ CHAT.start.Player.Cur ].Tab )
		CHAT.start.Player:_Rebuild()
		CHAT.start.Player.Cur = nil
		CHAT.Tick()
	end
	
	CHAT.start.Group = CHAT.start:Add( "DPanelList" )
	CHAT.start.Group:SetPos( 190, 5 )
	CHAT.start.Group:SetSize( 180, 200 )
	CHAT.start.Group:SetSpacing( 1 )
	CHAT.start.Group:EnableVerticalScrollbar( true )
	CHAT.start.Group.Cur = nil
	
	function CHAT.start.Group:AddSpacer( h )
	
	
		local pnl = vgui.Create( "DPanel" )
		pnl:SetSize( 0, h )
		pnl.Spacer = true
		pnl.Paint = function()
			return
		end
		
		self:AddItem( pnl )
		
	end	
	
	function CHAT.start.Group:Paint()
		surface.SetDrawColor( CHAT.BGColor )
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
	end

	local function populategroups()
		
		local tab = {}
		for k, v in next, CHAT.GROUPS do
		
			if v.Private or table.HasValue( v.Members, LocalPlayer() ) then
				continue
			end
			
			tab[ k ] = v
			
		end
		
		if table.Count( tab ) == 0 then

			CHAT.start.Group:AddSpacer( 80 )
			
			local pnl = vgui.Create( "DButton" )
			pnl:SetSize( 200, 30 )
			pnl:SetFont( "asdf1" )
			pnl:SetTextColor( color_white )
			pnl:SetText( "No groups available" )
			pnl.Spacer = true
			
			function pnl:Paint()
				return
			end
			
			function pnl:Think()
				self:SetCursor( "arrow" )
			end
			
			CHAT.start.Group:AddItem( pnl )
			
			return
		end	

		for k, v in next, CHAT.GROUPS do
			
			if table.HasValue( CHAT.GROUPS[ k ].Members, LocalPlayer() ) or CHAT.GROUPS[ k ].Private == true then
				continue
			end
			
			local pnl = vgui.Create( "DButton" )
			pnl:SetSize( 198, 25 )
			pnl:SetFont( "asdf1" )
			pnl:SetTextColor( CHAT.BGColor )
			pnl:SetText( CHAT.GROUPS[ k ].Name .. " [" .. table.Count( CHAT.GROUPS[ k ].Members ) .. "]" )
			pnl.Group = v
			
			pnl.Paint = function( self )
				surface.SetDrawColor( CHAT.TextBoxColor )
				surface.DrawRect( 0, 0, self:GetSize() )
				surface.SetDrawColor( CHAT.BGColor )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )		
			end
			
			function pnl:DoClick()
			
				CHAT.start.Group.Cur = self.Group
				
				pnl.Paint = function( self )
					surface.SetDrawColor( CHAT.TextBoxColor )
					surface.DrawRect( 0, 0, self:GetSize() )
					surface.SetDrawColor( color_white )
					surface.DrawOutlinedRect( 0, 0, self:GetSize() )
				end
				
				for k, v in next, CHAT.start.Group:GetItems() do
				
					if v == pnl then
						continue
					end
					
					v.Paint = function( self )
						surface.SetDrawColor( CHAT.TextBoxColor )
						surface.DrawRect( 0, 0, self:GetSize() )
						surface.SetDrawColor( CHAT.BGColor )
						surface.DrawOutlinedRect( 0, 0, self:GetSize() )	
					end
				end
				
				CHAT.Tick()
			end
			
			CHAT.start.Group:AddItem( pnl )
		end
		
	end
	populategroups()
	
	function CHAT.start.Group:_Rebuild()
		self:Clear()
		populategroups()
	end
	
	CHAT.start.GExec = CHAT.start:Add( "DButton" )
	CHAT.start.GExec:SetPos( 190, 210 )
	CHAT.start.GExec:SetSize( 180, 25 )
	CHAT.start.GExec:SetText( "Join group" )
	CHAT.start.GExec:SetTextColor( color_white )
	
	function CHAT.start.GExec:Paint()
	
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawRect( 0, 0, self:GetSize() )
		
		if CHAT.start.Group.Cur then
			surface.SetDrawColor( color_white )
		else
			surface.SetDrawColor( CHAT.BGColor )
		end
		
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		
	end
	
	function CHAT.start.GExec:Think()
		if CHAT.start.Group.Cur then
			self:SetDisabled( false )
		else
			self:SetDisabled( true )
		end
	end
	
	function CHAT.start.GExec:DoClick()
		CHAT.Tick()
		net.Start( "JoinGroup" )
			net.WriteTable( CHAT.start.Group.Cur )
		net.SendToServer()
	end

	CHAT.start.GCreate = CHAT.start:Add( "DButton" )
	CHAT.start.GCreate:SetPos( 190, 240 )
	CHAT.start.GCreate:SetSize( 180, 25 )
	CHAT.start.GCreate:SetText( "Create group" )
	CHAT.start.GCreate:SetTextColor( color_white )
	CHAT.start.GCreate.InMenu = false
	
	function CHAT.start.GCreate:Paint()
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawRect( 0, 0, self:GetSize() )
		surface.SetDrawColor( color_white )
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
	end
	
	function CHAT.start.GCreate:DoClick()
	
		if CHAT.start.GCreate.InMenu then
			return
		end
		
		CHAT.start.GCreate.InMenu = true
		CHAT.Tick()
		
		local name = vgui.Create( "DTextEntry", CHAT.start )
		local pos = Vector( CHAT.start.GCreate:GetPos() )
		name:SetPos( pos.x, pos.y )
		name:SetSize( 88, 20 )
		name:SetText( "Name" )
		name:MoveToBack()
		
		function name:Paint()
			surface.SetDrawColor( color_white )
			surface.DrawOutlinedRect( 0, 0, self:GetSize() )
			self:DrawTextEntryText( color_white, CHAT.TextHighlightColor, color_white )
		end
		
		local private = vgui.Create( "DCheckBox", CHAT.start )
		private:SetPos( pos.x + 93, pos.y + 2 )
		private:SetValue( false )
		private:MoveToBack()
		
		local privatetext = vgui.Create( "DLabel", CHAT.start )
		privatetext:SetPos( pos.x + 112, pos.y )
		privatetext:SetSize( 40, 22 )
		privatetext:SetTextColor( color_white )
		privatetext:MoveToBack()
		privatetext:SetText( "Private" )
		privatetext:SizeToContents()
		
		local cancel = vgui.Create( "DButton", CHAT.start )
		cancel:SetPos( pos.x + 93, pos.y )
		cancel:SetSize( 88, 20 )
		cancel:SetTextColor( color_white )
		cancel:SetText( "Cancel" )
		cancel:MoveToBack()
		
		function cancel:Paint()
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 0, 0, self:GetSize() )
			surface.SetDrawColor( Color( 180, 0, 0, 230 ) )
			surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		end
		
		local exec 
		
		function cancel:DoClick()
		
			CHAT.Tick()
			name:KillFocus()
			name:MoveToBack()
			
			cancel:MoveTo( pos.x + 90, pos.y, 0.15, 0, 1, function()
				cancel:Remove()
				
				exec:MoveTo( pos.x, pos.y, 0.15, 0, 1, function()
					exec:Remove()
					
					privatetext:MoveTo( pos.x + 112, pos.y, 0.15, 0, 1, function()
						privatetext:Remove()
						
						private:MoveTo( pos.x + 93, pos.y + 2, 0.15, 0, 1, function()
							private:Remove()
							
							name:MoveTo( pos.x, pos.y, 0.15, 0, 1, function()
								name:Remove()
							
								CHAT.start.GCreate.InMenu = false
								
							end )
							
						end )
						
					end )
					
				end )
				
			end )
			
		end
		
		exec = vgui.Create( "DButton", CHAT.start )
		exec:SetPos( pos.x, pos.y )
		exec:SetSize( 88, 20 )
		exec:SetTextColor( color_white )
		exec:SetText( "Create" )
		exec:MoveToBack()
		exec.clicked = false
		
		function exec:Paint()
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 0, 0, self:GetSize() )
			surface.SetDrawColor( Color( 0, 200, 0, 230 ) )
			surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		end
		
		function exec:DoClick()
		
			if exec.clicked then
				return
			end
			
			exec.clicked = true
			CHAT.Tick()
			
			name:KillFocus()
			name:MoveToBack()
			
			net.Start( "CreateServerGroup" )
				net.WriteString( string.Trim( name:GetValue() ) )
				net.WriteBit( private:GetChecked() )
			net.SendToServer()
			
			net.Receive( "CreateServerGroupCallback", function()
			
				local bool = tobool( net.ReadBit() )
				local err = net.ReadString()
				
				if bool and err == "" then
				
					cancel:DoClick()
					CHAT.CreateGroupPanel( string.Trim( name:GetValue() ), { LocalPlayer() } )
					
					timer.Simple( 0, function()
						name:SetPos( pos.x, pos.y )
						private:SetPos( pos.x + 93, pos.y + 2 )
						privatetext:SetPos( pos.x + 112, pos.y )
						exec:SetPos( pos.x, pos.y )
						cancel:SetPos( pos.x + 93, pos.y )
						CHAT.start.GCreate.InMenu = false
						CHAT.tabs:SetActiveTab( CHAT.CLGROUPS[ string.Trim( name:GetValue() ) ].Tab )
					end )
					
				else
					exec.clicked = false
					CHAT.Error( err )
				end
				
			end )
			
		end
		
		name:MoveTo( pos.x, pos.y + 32, 0.15, 0, 1, function()
		
			private:MoveTo( pos.x + 93, pos.y + 34, 0.15, 0, 1, function()
			
				privatetext:MoveTo( pos.x + 112, pos.y + 35, 0.15, 0, 1, function()
				
					exec:MoveTo( pos.x, pos.y + 60, 0.15, 0, 1, function()
					
						cancel:MoveTo( pos.x + 92, pos.y + 60, 0.15, 0, 1, function()
						end )
						
					end )
					
				end )
				
			end )
			
		end )
		
	end
	
	CHAT.start.IBox = CHAT.start:Add( "DButton" )
	CHAT.start.IBox:SetPos( 380, 5 )
	CHAT.start.IBox:SetSize( 150, 20 )
	CHAT.start.IBox:SetTextColor( color_white )
	CHAT.start.IBox:MoveToBack()
	
	function CHAT.start.IBox:Paint()
	
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		
		local alpha = 0
		if table.Count( CHAT.Invites ) > 0 then
			alpha = math.abs( math.sin( CurTime() * 2.5 ) * 255 )
		else
			alpha = 0
		end
		
		surface.SetDrawColor( Color( 200, 0, 0, alpha ) )
		surface.DrawRect( 0, 0, self:GetSize() )
		
	end
	
	function CHAT.start.IBox:Think()
		self:SetText( "Invites: " .. table.Count( CHAT.Invites ) )
	end
	
	CHAT.start.IPanel = CHAT.start:Add( "DPanelList" )
	CHAT.start.IPanel:SetPos( 380, 27 )
	CHAT.start.IPanel:SetSize( 150, 200 )
	CHAT.start.IPanel:SetVerticalScrollbarEnabled( true )
	CHAT.start.IPanel:SetSpacing( 3 )
	CHAT.start.IPanel:MoveToBack()
	CHAT.start.IPanel.NumInvites = table.Count( CHAT.Invites )
	
	function CHAT.start.IPanel:Think()
		if CHAT.start.Settings.Using then
			self:MoveToBack()
		else
			self:MoveToFront()
		end
	end
	
	function CHAT.start.IPanel:_Rebuild()

		for k, v in next, CHAT.Invites do
		
			local sender = v[ 1 ]
			local group = v[ 2 ]
			
			local pnl = vgui.Create( "DPanel" )
			pnl:SetSize( 150, 30 )
			
			function pnl:Paint()
				surface.SetDrawColor( CHAT.TextBoxColor )
				surface.DrawRect( 0, 0, self:GetSize() )
				surface.SetDrawColor( color_white )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )
			end
			
			local name = pnl:Add( "DLabel" )
			name:SetPos( 3, 2 )
			name:SetTextColor( color_white )
			name:SetText( "Invite to: " .. group )
			
			local from = pnl:Add( "DLabel" )
			from:SetPos( 3, 13 )
			from:SetTextColor( color_white )
			from:SetText( "From " .. sender:Name() )
			
			from:SizeToContents()
			name:SizeToContents()
			
			local yes = pnl:Add( "DButton" )
			yes:SetPos( pnl:GetWide() - 34, 5 )
			yes:SetSize( 15, 20 )
			yes:SetTextColor( color_white )
			yes:SetText( "Y" )
			
			function yes:Paint()
				surface.SetDrawColor( color_white )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )
			end
			
			function yes:DoClick()
			
				net.Start( "InviteUsersNotifyCallback" )
					net.WriteString( group )
					net.WriteBit( true )
				net.SendToServer()
				
				for k, v in next, CHAT.Invites do
					if v[ 2 ] == group then
						table.remove( CHAT.Invites, k )
					end
				end
				
				timer.Simple( 0.2, function()
					CHAT.CreateGroupPanel( group, CHAT.GROUPS[ group ].Members, CHAT.GROUPS[ group ].Text )
				end )
				
			end
			
			local no = pnl:Add( "DButton" )
			no:SetPos( pnl:GetWide() - 17, 5 )
			no:SetSize( 15, 20 )
			no:SetTextColor( color_white )
			no:SetText( "N" )
			
			function no:Paint()
				surface.SetDrawColor( color_white )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )
			end		

			function no:DoClick()
				for k, v in next, CHAT.Invites do
					if v[ 2 ] == group then
						table.remove( CHAT.Invites, k )
					end
				end					
			end				
			
			self:AddItem( pnl )
		end
		
	end
	
	CHAT.start.IPanel:_Rebuild()
	
	hook.Add( "Think", "Rebuild", function()
	
		if not ValidPanel( CHAT.main ) then
			return
		end
		
		if table.Count( CHAT.Invites ) ~= CHAT.start.IPanel.NumInvites then
			CHAT.start.IPanel:Clear()
			CHAT.start.IPanel.NumInvites = table.Count( CHAT.Invites )
			CHAT.start.IPanel:_Rebuild()
		end
		
	end )
	
	
	--Create the start menu first
	--This started out as a test panel but I'm too lazy change the name
	CHAT.test1 = CHAT.AddTab( "+", CHAT.start, nil, "Start a new chat" )
	
	--Start panel adds/queues, if there are any
	local cpy = table.Copy( CHAT.TABS )
	table.Empty( CHAT.TABS )

	for k, v in next, cpy do
	
		if v.Name == "+" or not IsValid( v.Player ) then
			continue
		end
		
		local txt = {}
		local voice = CHAT[ v.Player ]._VoiceRequest
		local voice1 = CHAT[ v.Player ]._SentVoiceRequest
		
		if CHAT[ v.Player ] then
			if table.getn( CHAT[ v.Player ].Text ) > 0 then
				for q, w in next, CHAT[ v.Player ].Text do
					table.insert( txt, w )
				end
			end
			CHAT[ v.Player ] = nil
		end
		
		CHAT.StartPanel( v.Player, txt )
		
		if voice then
			CHAT[ v.Player ]._VoiceRequest = voice
		end
		if voice1 then
			CHAT[ v.Player ]._SentVoiceRequest = voice1
		end		
		
	end
	
	if table.Count( CHAT.PanelQueue ) > 0 then

		for k, v in next, CHAT.PanelQueue do
		
			local ply = v[ 1 ]
			local textTable = v[ 2 ]
			
			CHAT.StartPanel( ply, textTable )
			CHAT.RemoveQueuedPanel( ply )
			
			if v.VoiceRequest then
				CHAT.SetPanelVoiceRequest( ply )
			end
			
		end
		
	end
	
	-- offline tabs

	if table.Count( CHAT.Offline ) > 0 then
		for k, v in next, CHAT.Offline do
		
			local tab = v
			local id = tab.ID
			
			for q, w in _E do
				if w:SteamID() == id then
					CHAT.StartPanel( w, tab.Text )
					return
				end
			end
			
			CHAT.CreateOfflinePanel( tab.ID, tab.Text, tab.Name )
			
		end
	end
	
	if table.Count( CHAT.GROUPS ) > 0 then
		for k, v in next, CHAT.GROUPS do
		
			if not table.HasValue( v.Members, LocalPlayer() ) then
				continue
			end
			
			CHAT.CreateGroupPanel( v.Name, v.Members, v.Text )
			
		end
	end
	
	--Set last used tab
	if CHAT.LastTabUsed then
	
		local t = CHAT.GetTabs()
		local LastUsedPly = CHAT.LastTabUsed
		
		if not isstring( LastUsedPly ) then
		
			for k, v in next, t do
				if v.Player == LastUsedPly then
					CHAT.tabs:SetActiveTab( v.Tab )
				end
			end
			
		else
		
			for k, v in next, CHAT.CLGROUPS do
				if v.Name == LastUsedPly then
					CHAT.tabs:SetActiveTab( v.Tab )
				end
			end
			
		end
		
	end
	
end		

--[[----------------------------------------------------------
	Notifications
----------------------------------------------------------]]--

function CHAT.QueuePanel( ply, text, voice )

	if not CHAT.PanelQueue[ ply ] then
	
		CHAT.PanelQueue[ ply ] = { ply, { os.date( "%I:%M %p" ) .. " - #####" .. ply:Name() .. "#####: " .. string.Trim( text ) } }
		
		if voice then
			CHAT.PanelQueue[ ply ].VoiceRequest = true
		end
		
	else
	
		table.insert( CHAT.PanelQueue[ ply ][ 2 ],  os.date( "%I:%M %p" ) .. " - #####" .. ply:Name() .. "#####: " .. string.Trim( text ) )
		
		if voice then
			if not CHAT.PanelQueue[ ply ].VoiceRequest then
				CHAT.PanelQueue[ ply ].VoiceRequest = true
			end
		end
		
	end
	
end

function CHAT.RemoveQueuedPanel( ply )
	CHAT.PanelQueue[ ply ] = nil
end

function CHAT.QueueNotification( ply, str )
	table.insert( CHAT.NotifyQueue, { ply, str } )
end

hook.Add( "NotifyBox.EndAnim", "SetNextQueue", function()

	CHAT.CurrentNotify = nil
	
	if table.getn( CHAT.NotifyQueue ) > 0 then
		local tab = CHAT.NotifyQueue[ table.GetFirstKey( CHAT.NotifyQueue ) ]
		CHAT.Notify( tab[ 1 ], tab[ 2 ] )
		table.remove( CHAT.NotifyQueue, table.GetFirstKey( CHAT.NotifyQueue ) )
	end
	
end )

function CHAT.CreateNotifyBox( ply, str, isVoice )

	local main = vgui.Create( "DPanel", vgui.GetWorldPanel() )
	main:SetSize( ScrW() / 4, 45 )
	
	function main:Paint()
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 0, self:GetWide(), self:GetTall() - 10 )
		surface.SetTextColor( CHAT.PropertyColor )
		surface.SetFont( "DermaDefault" )
		surface.SetTextPos( 1, 34 )
		surface.DrawText( CHAT.NotifyString )					
		surface.SetTextColor( color_white )
		surface.SetFont( "DermaDefault" )
		surface.SetTextPos( 0, 33 )
		surface.DrawText( CHAT.NotifyString )	
	end
	
	local avatar = main:Add( "AvatarImage" )
	avatar:SetPos( 2, 2 )
	avatar:SetSize( 27, 27 )
	avatar:SetPlayer( ply, 64 )
	
	local text = main:Add( "DLabel" )
	text:SetFont( "asdf1" )
	text:SetTextColor( color_white )
	
	local tx
	if isVoice then
		tx = str
	else
		tx = ply:Name() .. ": " .. str
	end
	
	surface.SetFont( "asdf1" )
	local x, y = surface.GetTextSize( tx )
	text:SetPos( 30, 2 + ( avatar:GetTall() / 2 ) - ( y / 2 ) )
	local width = main:GetWide() - avatar:GetWide() - 15
	
	--Cut the message off if it's too large
	if x > width then
	
		for i = 1, tx:len() do
		
			surface.SetFont( "asdf1" )
			tx = tx:sub( 1, -2 )
			
			local x, y = surface.GetTextSize( tx )
			
			if x < width then
				break
			end
			
		end 
		
		tx = tx .. "..."
	end
	
	text:SetText( tx )		
	function text:Think()
		self:SizeToContents()
	end
	
	return main
end

function CHAT.Notify( ply, str )

	str = string.Trim( str )
	
	if not CHAT.CurrentNotify then
	
		CHAT.CurrentNotify = true
		
		if GetConVar( "chat_notify_sounds" ):GetBool() then
			surface.PlaySound( CHAT.NotificationSound )
		end
		
		local box = CHAT.CreateNotifyBox( ply, str )
		
		box:SetPos( ScrW() / 2 - ( box:GetWide() / 2 ), 0 - box:GetTall() )
		
		box:MoveTo( ScrW() / 2 - ( box:GetWide() / 2 ), 0, 0.25, 0,  1, function()
			timer.Simple( 2.5, function()
				box:MoveTo( ScrW() / 2 - ( box:GetWide() / 2 ), 0 - box:GetTall(), 0.25, 0, 1, function()
					box:Remove()
					hook.Run( "NotifyBox.EndAnim" )
				end )
			end )
		end	)
		
	else
		CHAT.QueueNotification( ply, str )
	end		
	
end

function CHAT.NotifyVoice( ply )

	local str = ply:Name() .. " would like to voice chat"
	
	if not CHAT.CurrentNotify then
	
		CHAT.CurrentNotify = true
		
		if GetConVar( "chat_notify_sounds" ):GetBool() then
			surface.PlaySound( CHAT.NotificationSound )
		end
		
		local box = CHAT.CreateNotifyBox( ply, str, true )
		
		box:SetPos( ScrW() / 2 - ( box:GetWide() / 2 ), 0 - box:GetTall() )
		box:MoveTo( ScrW() / 2 - ( box:GetWide() / 2 ), 0, 0.25, 0,  1, function()
			timer.Simple( 2, function()
				box:MoveTo( ScrW() / 2 - ( box:GetWide() / 2 ), 0 - box:GetTall(), 0.25, 0, 1, function()
					box:Remove()
					hook.Run( "NotifyBox.EndAnim" )
				end )
			end )
		end	)
		
	else
		CHAT.QueueNotification( ply, str )
	end	
	
end

function CHAT.QueueError( str )
	table.insert( CHAT.ErrorQueue, str )
end

hook.Add( "ErrorBox.EndAnim", "SetNextErrorQueue", function()

	CHAT.CurrentError = nil
	
	if table.getn( CHAT.ErrorQueue ) > 0 then
		local tab = CHAT.ErrorQueue[ table.GetFirstKey( CHAT.ErrorQueue ) ]
		CHAT.Error( tab )
		table.remove( CHAT.ErrorQueue, table.GetFirstKey( CHAT.ErrorQueue ) )
	end
	
end )

function CHAT.CreateErrorBox( str )

	local main1 = vgui.Create( "DPanel", vgui.GetWorldPanel() )
	main1:SetSize( CHAT.main:GetWide(), 30 )
	
	function main1:Paint()
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 0, self:GetSize() )
		draw.SimpleText( str, "asdf1", self:GetWide() / 2, self:GetTall() / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	
	function main1:Think()
		self:SetWide( CHAT.main:GetWide() )
	end
	
	return main1
end

function CHAT.Error( str )

	if not ValidPanel( CHAT.main ) then
		return
	end
	
	if not CHAT.CurrentError then
	
		CHAT.CurrentError = true
		local box = CHAT.CreateErrorBox( str )
		local pos = Vector( CHAT.main:GetPos() )
		
		box:SetPos( pos.x, pos.y )
		box:MoveTo( pos.x, pos.y - 30, 0.25, 0, 1, function()
			timer.Simple( 1.5, function()
				box:MoveTo( pos.x, pos.y, 0.25, 0, 1, function()
					box:Remove()
					hook.Run( "ErrorBox.EndAnim" )
				end )
			end )
		end	)
		
		function box:Think()
		
			if not ValidPanel( CHAT.main ) then
				return
			end
			
			if ValidPanel( CHAT.main ) then
				pos = Vector( CHAT.main:GetPos() )
			else
				return
			end
			
		end
		
	else
		CHAT.QueueError( str )
	end	
	
end

function CHAT.AddGroupInvite( sender, name )

	local exists = false
	for k, v in next, CHAT.Invites do
		if v[ 1 ] == sender then
			exists = true
		end
	end
	
	if exists then
		return
	end
	
	table.insert( CHAT.Invites, { sender, name } )
	
end 


--[[----------------------------------------------------------
	Tab functions
----------------------------------------------------------]]--

function CHAT.AddTab( name, panel, material, tooltip, ply )

	local temp = CHAT.tabs:AddSheet( name, panel, material, false, false, tooltip )
	local tab = temp.Tab
	
	function tab:Paint()
	
		if not CHAT.tabs then
			return
		end
		
		if CHAT.tabs:GetActiveTab() ~= self then
			self:SetTextColor( CHAT.TabUnfocusedColor )
			surface.SetDrawColor( CHAT.BGColor )
			surface.DrawRect( 0, 0, self:GetSize() )
		else
			self:SetTextColor( CHAT.TabFocusedColor )
			surface.SetDrawColor( CHAT.PropertyColor )
			surface.DrawRect( 0, 0, self:GetWide(), self:GetTall() - 8 )
		end
		
	end
	
	local id
	if not ply then
		id = "NULL"
	else
		id = ply:SteamID()
	end
	
	local RET = { 
		Sheet = temp,
		Tab = tab,
		Panel = panel,
		Player = ply,
		Text = {},
		Material = material,
		Tooltip = tooltip,
		Name = name,
		ID = id
	}
	
	local exists = false
	
	for k, v in next, CHAT.TABS do
		if v.Player == ply then
			exists = true
		end
	end
	
	if not exists then
		table.insert( CHAT.TABS, RET )
	end
	
	return RET
end

function CHAT.RemoveTab( panel )

	if not ValidPanel( CHAT.tabs ) then
	
		local key
		for k, v in next, CHAT.TABS do
			if v.Tab == panel then
				key = k
				CHAT[ v.Player ] = nil
			end
		end
		
		table.remove( CHAT.TABS, key )		
		
		return
	end
	
	local key
	
	for k, v in next, CHAT.TABS do
		if v.Tab == panel then
			key = k
			CHAT[ v.Player ] = nil
		end
	end
	
	table.remove( CHAT.TABS, key )
	CHAT.tabs:CloseTab( panel, true )
	
end

function CHAT.GetTabs()
	return CHAT.TABS
end

local _PLY = FindMetaTable( "Player" )
function _PLY:GetIcon()

	local admin = "icon16/user_gray.png" 
	local user = "icon16/user.png" 
	local talking = "icon16/sound.png"
	
	if CHAT.VoiceChatting then
		if self == CHAT.VoiceChatting then
			return talking
		else
			return self:IsAdmin() and admin or user
		end
	else	
		return self:IsAdmin() and admin or user
	end
	
end

function CHAT.StartPanel( ply, tText )

	if CHAT[ ply ] then
		CHAT.tabs:SetActiveTab( CHAT[ ply ].Tab )
	else
	
		local PNL = vgui.Create( "DPanel", CHAT.tabs )
		PNL:SetPos( 0, 0 )
		PNL:SetSize( CHAT.tabs:GetSize() )
		
		function PNL:Paint() 
			surface.SetDrawColor( CHAT.PropertyColor )
			surface.DrawRect( 0, 0, self:GetSize() )
		end
		
		function PNL:Think()
			if ValidPanel( self ) then
				CHAT.text:SetKeyBoardInputEnabled( true )
				CHAT.text:SetMouseInputEnabled( true )
			end
		end
		
		PNL.Top = PNL:Add( "DPanel" )
		PNL.Top:SetPos( 0, 0 )
		PNL.Top:SetSize( PNL:GetWide(), 50 )
		
		function PNL.Top:Think()
			self:SetSize( PNL:GetWide(), 50 )
		end
		
		function PNL.Top:Paint() 
			surface.SetDrawColor( CHAT.PropertyColor )
			surface.DrawRect( 0, 0, self:GetSize() )
		end		
		
		PNL.Top.Avatar = PNL.Top:Add( "AvatarImage" )
		PNL.Top.Avatar:SetPos( 5, 5 )
		PNL.Top.Avatar:SetSize( 40, 40 )
		PNL.Top.Avatar:SetPlayer( ply, 64 )
		
		PNL.Top.PlayerName = PNL.Top:Add( "DLabel" )
		PNL.Top.PlayerName:SetPos( 50, 17 )
		PNL.Top.PlayerName:SetFont( "name1" )
		PNL.Top.PlayerName:SetTextColor( color_white )
		PNL.Top.PlayerName:SetText( ply:Name() )
		PNL.Top.PlayerName:SizeToContents()
		
		PNL.Top.Settings = PNL.Top:Add( "DButton" )
		PNL.Top.Settings:SetSize( 100, 20 )
		PNL.Top.Settings:SetText( "Options" )
		PNL.Top.Settings:SetTextColor( color_white )
		
		function PNL.Top.Settings:Paint()
			surface.SetDrawColor( CHAT.PropertyColor )
			surface.DrawRect( 0, 0, self:GetSize() )
			surface.SetDrawColor( color_white )
			surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		end
		
		function PNL.Top.Settings:Think()
			self:SetPos( PNL.Top:GetWide() - 100, 0 )
		end
		
		function PNL.Top.Settings:OnCursorEntered()
			self:SetTextColor( CHAT.TextHighlightColor )
		end
		
		function PNL.Top.Settings:OnCursorExited()
			self:SetTextColor( color_white )
		end		
		
		function PNL.Top.Settings:DoClick()
		
			CHAT.Tick()
			
			local menu = vgui.Create( "DMenu", PNL )
			
				menu:AddOption( "Start Voice Chat", function()
					
					if CHAT[ ply ]._VoiceRequest or CHAT[ ply ]._SentVoiceRequest then
						CHAT.Error( "You cannot send a voice chat request right now." )
						return
					elseif CHAT.VoiceChatting then
						if ply == CHAT.VoiceChatting then
							CHAT.Error( "You are already in a call with this person." )
							return
						else
							CHAT.Error( "You are already in a call with " .. CHAT.VoiceChatting:Name() )
							return
						end
					elseif CHAT.InGroupVoiceChat then
						CHAT.Error( "You are in a group voice chat with " .. CHAT.InGroupVoiceChat )
						return
					end
					
					net.Start( "RequestVoiceChat" )
						net.WriteEntity( ply ) -- with
					net.SendToServer()
					
					net.Receive( "RequestVoiceChatSenderCallback", function()
					
						if not CHAT[ ply ] then
							return
						end
						
						local bool = tobool( net.ReadBit() )
						
						if bool == true then
						
							CHAT[ ply ]._SentVoiceRequest = true
							CHAT[ ply ].Panel.RT:AppendText( "Voice chat request sent to " .. ply:Name() .. "\n" )
							
							if GetConVar( "chat_enable_calling_sounds" ):GetBool() then
								CHAT.LoopSound( "chat/voice_dialing.wav", 0 )
							end
							
						else
						
							CHAT[ ply ].Panel.RT:InsertColorChange( 255, 0, 0, 255 )
							CHAT[ ply ].Panel.RT:AppendText( ply:Nick() .. " is not available to chat right now\n" )
							CHAT[ ply ].Panel.RT:InsertColorChange( 255, 255, 255, 255 )
							
							if GetConVar( "chat_enable_busy_sounds" ):GetBool() then
								CHAT.LoopSound( "chat/voice_busy.wav", 3 )
							end
							
						end
						
					end )
					
				end ):SetIcon( "icon16/telephone.png" )
				
				menu:AddSpacer()
				
				menu:AddOption( "Exit chat", function()
					
					CHAT.Tick()		
					if CHAT[ ply ]._VoiceRequest or CHAT[ ply ]._SentVoiceRequest or CHAT.VoiceChatting == ply then
						CHAT.Error( "You cannot exit this chat while in a call." )
						return
					end
					
					CHAT.RemoveTab( CHAT[ ply ].Tab )
					timer.Simple( 0, function()
						CHAT.start.Player:_Rebuild()
					end )
					
				end ):SetIcon( "icon16/page_delete.png" )
				
			menu:SetMinimumWidth( 200 )
			local pos = Vector( CHAT.main:GetPos() )
			menu:Open( pos.x + CHAT.main:GetWide() - 200 - 8, pos.y + self:GetTall() + 49 )
			
			function menu:Paint()
				surface.SetDrawColor( CHAT.TextBoxColor )
				surface.DrawRect( 0, 0, self:GetSize() )
				surface.SetDrawColor( color_black )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )
			end
			
		end
		
		PNL.Top.ASettings = PNL.Top:Add( "DButton" )
		PNL.Top.ASettings:SetSize( 100, 20 )
		PNL.Top.ASettings:SetText( "Admin Options" )
		PNL.Top.ASettings:SetTextColor( color_white )
		
		function PNL.Top.ASettings:Paint()
			surface.SetDrawColor( CHAT.PropertyColor )
			surface.DrawRect( 0, 0, self:GetSize() )
			surface.SetDrawColor( color_white )
			surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		end
		
		function PNL.Top.ASettings:Think()
			self:SetPos( PNL.Top:GetWide() - 100, 22 )
			self:Think2()
		end		
		
		function PNL.Top.ASettings:OnCursorEntered()
			self:SetTextColor( CHAT.TextHighlightColor )
		end
		
		function PNL.Top.ASettings:OnCursorExited()
			self:SetTextColor( color_white )
		end		
		
		function PNL.Top.ASettings:DoClick()
		
			CHAT.Tick()
			
			local menu = vgui.Create( "DMenu", PNL )
			
				local function remove( self, pos )
					self:MoveToBack()
					self:MoveTo( pos.x + CHAT.main:GetWide() - 150, pos.y, 0.5, 0, 5, function()
						self:Remove()
					end )	
				end			
				
				menu:AddOption( "Kick", function()
				
					CHAT.Tick()
					
					if ValidPanel( CHAT.ban ) then	
						remove( CHAT.ban, Vector( CHAT.main:GetPos() ) )
					end			
					
					CHAT.kick = vgui.Create( "DFrame", vgui.GetWorldPanel() )
					CHAT.kick:SetSize( 150, 75 )
					CHAT.kick.StartAnimFinished = false
					CHAT.kick.removing = false
					CHAT.kick:SetTitle( "" )
					CHAT.kick:ShowCloseButton( false )
					CHAT.kick:MakePopup()
					CHAT.kick:MoveToBack()
					
					local pos = Vector( CHAT.main:GetPos() )
					CHAT.kick:SetPos( pos.x + CHAT.main:GetWide() - 150, pos.y )
					CHAT.kick:MoveTo( pos.x + CHAT.main:GetWide(), pos.y, 0.25, 0, 5, function()
						self.StartAnimFinished = true
					end )
					
					function CHAT.kick:Think()
					
						if not ValidPanel( CHAT.main ) then
							self:Remove()
							return
						end
						
						if not IsValid( ply ) then
							if not self.removing then
								self.removing = true
								remove( self, Vector( CHAT.main:GetPos() ) )
							end
						end
						
						if self.StartAnimFinished and not self.removing then
							local pos = Vector( CHAT.main:GetPos() )
							self:SetPos( pos.x + CHAT.main:GetWide(), pos.y )
						end
						
					end
					
					local name = ply:Name()
					function CHAT.kick:Paint()
						surface.SetDrawColor( CHAT.PropertyColor )
						surface.DrawRect( 0, 0, self:GetSize() )
						surface.SetFont( "DermaDefault" )
						surface.SetTextColor( color_white )
						surface.SetTextPos( 5, 5 )
						surface.DrawText( "Kicking " .. name .. "..." )
					end
					
					local close = vgui.Create( "DImageButton", CHAT.kick )
					close:SetPos( CHAT.kick:GetWide() - 18, 3 )
					close:SetSize( 16, 16 )
					close:SetImage( "icon16/control_rewind.png" )
					close.DoClick = function()
						remove( CHAT.kick, Vector( CHAT.main:GetPos() ) )
						CHAT.Tick()
					end		
					
					local reason = CHAT.kick:Add( "DTextEntry" )
					reason:SetPos( 5, 22 )
					reason:SetSize( CHAT.kick:GetWide() - 10, 20 )
					reason:SetText( "Reason" )
					reason:SetTextColor( color_white )
					reason:SetEditable( true )
					reason:AllowInput( true )
					reason:SetEnterAllowed( true )
					reason:SetKeyBoardInputEnabled( true )
					reason:SetMouseInputEnabled( true )
					
					function reason:Paint()
						surface.SetDrawColor( CHAT.PropertyColor )
						surface.DrawRect( 0, 0, self:GetSize() )
						surface.SetDrawColor( color_white )
						surface.DrawOutlinedRect( 0, 0, self:GetSize() )
						self:DrawTextEntryText( Color( 255, 255, 255, 255 ), CHAT.TextHighlightColor, Color( 255, 255, 255, 255 ) )
					end
					
					function reason:OnCursorEntered()
						if self:GetText() == "Reason" then
							self:SetText( "" )
						end
					end
					
					function reason:OnCursorExited()
						if self:GetText() == "" then
							self:SetText( "Reason" )
						end
					end		

					local exec = vgui.Create( "DButton", CHAT.kick )
					exec:SetPos( 5, 47 )
					exec:SetSize( reason:GetSize() )
					exec:SetText( "Kick" )
					
					function exec:Paint()
						self:SetTextColor( color_white )
						surface.SetDrawColor( color_white )
						surface.DrawOutlinedRect( 0, 0, self:GetSize() )
					end
					
					function exec:DoClick()
						local text = reason:GetText()
						if text:len() == 0 then
							return
						end
						RunConsoleCommand( "ulx", "kick", name, text )
						CHAT.Tick()
					end
					
					function reason:OnEnter()
						exec:DoClick()
					end
					
				end ):SetIcon( "icon16/disconnect.png" )
				
				menu:AddOption( "Ban", function()
				
					CHAT.Tick()
					
					if ValidPanel( CHAT.kick ) then	
						remove( CHAT.kick, Vector( CHAT.main:GetPos() ) )
					end
					
					CHAT.ban = vgui.Create( "DFrame", vgui.GetWorldPanel() )
					CHAT.ban:SetSize( 150, 130 )
					CHAT.ban.StartAnimFinished = false
					CHAT.ban.removing = false
					CHAT.ban:SetTitle( "" )
					CHAT.ban:ShowCloseButton( false )
					CHAT.ban:MakePopup()
					CHAT.ban:MoveToBack()
					
					local pos = Vector( CHAT.main:GetPos() )
					CHAT.ban:SetPos( pos.x + CHAT.main:GetWide() - 150, pos.y )
					
					CHAT.ban:MoveTo( pos.x + CHAT.main:GetWide(), pos.y, 0.25, 0, 5, function()
						self.StartAnimFinished = true
					end )
					
					function CHAT.ban:Think()
					
						if not ValidPanel( CHAT.main ) then
							self:Remove()
							return
						end
						
						if not IsValid( ply ) then
							if not self.removing then
								self.removing = true
								remove( self, Vector( CHAT.main:GetPos() ) )
							end
						end
						
						if self.StartAnimFinished and not self.removing then
							local pos = Vector( CHAT.main:GetPos() )
							self:SetPos( pos.x + CHAT.main:GetWide(), pos.y )
						end
						
					end
					
					local name = ply:Name()
					
					function CHAT.ban:Paint()
						surface.SetDrawColor( CHAT.PropertyColor )
						surface.DrawRect( 0, 0, self:GetSize() )
						surface.SetFont( "DermaDefault" )
						surface.SetTextColor( color_white )
						surface.SetTextPos( 5, 5 )
						surface.DrawText( "Banning " .. name .. "..." )
					end
					
					local close = vgui.Create( "DImageButton", CHAT.ban )
					close:SetPos( CHAT.ban:GetWide() - 18, 3 )
					close:SetSize( 16, 16 )
					close:SetImage( "icon16/control_rewind.png" )
					
					close.DoClick = function()
						remove( CHAT.ban, Vector( CHAT.main:GetPos() ) )
						CHAT.Tick()
					end
					
					local reason = vgui.Create( "DTextEntry", CHAT.ban )
					reason:SetPos( 5, 22 )
					reason:SetSize( CHAT.ban:GetWide() - 10, 20 )
					reason:SetText( "Reason" )
					reason:SetTextColor( color_white )
					reason:SetEditable( true )
					reason:AllowInput( true )
					reason:SetEnterAllowed( true )
					reason:SetKeyBoardInputEnabled( true )
					reason:SetMouseInputEnabled( true )
					
					function reason:OnCursorEntered()
						if self:GetText() == "Reason" then
							self:SetText( "" )
						end
					end
					
					function reason:OnCursorExited()
						if self:GetText() == "" then
							self:SetText( "Reason" )
						end
					end
					
					function reason:Paint()
						surface.SetDrawColor( CHAT.PropertyColor )
						surface.DrawRect( 0, 0, self:GetSize() )
						surface.SetDrawColor( color_white )
						surface.DrawOutlinedRect( 0, 0, self:GetSize() )
						self:DrawTextEntryText( Color( 255, 255, 255, 255 ), CHAT.TextHighlightColor, Color( 255, 255, 255, 255 ) )
					end
					
					local combo = vgui.Create( "DComboBox", CHAT.ban )
					combo:SetPos( 5, 45 )
					combo:SetSize( CHAT.ban:GetWide() - 10, 20 )
					combo:SetTextColor( color_white )
					
					function combo:Paint()	
						self:SetTextColor( 255, 255, 255, 255 )
						surface.SetDrawColor( color_white )
						surface.DrawOutlinedRect( 0, 0, self:GetSize() )
					end
					
					function combo:OpenMenu( control )	
					
						if control then
							if control == self.TextEntry then
								return
							end
						end

						if table.getn( self.Choices ) == 0 then 
							return 
						end

						if IsValid( self.Menu ) then
							self.Menu:Remove()
							self.Menu = nil
						end

						self.Menu = DermaMenu()

						for k, v in next, self.Choices do
							self.Menu:AddOption( v, function() 
								self:ChooseOption( v, k ) 
							end )
						end

						local x, y = self:LocalToScreen( 0, self:GetTall() )
						
						function self.Menu:Paint()
							surface.SetDrawColor( CHAT.TextBoxColor )
							surface.DrawRect( 0, 0, self:GetSize() )
							surface.SetDrawColor( color_black )
							surface.DrawOutlinedRect( 0, 0, self:GetSize() )
						end
						
						self.Menu:SetMinimumWidth( self:GetWide() )
						self.Menu:Open( x, y, false, self )	
						
						return true
					end
					
					combo:AddChoice( "Permanent", 0, true )
					combo:AddChoice( "Minutes", 1 )
					combo:AddChoice( "Hours", 60 )
					combo:AddChoice( "Days", 1440 )
					combo:AddChoice( "Weeks", 10080 )
					combo:AddChoice( "Years", 43829 )
					
					function combo:OnSelect( index, value )
						local data = self.Data[ index ]
						self.curChoice = data
					end
					
					local slider = vgui.Create( "Slider", CHAT.ban )
					slider:SetPos( 5, 68 )
					slider:SetSize( CHAT.ban:GetWide() + 10, 20 )
					slider:SetDecimals( 0 )
					slider:SetMin( 0 )
					slider:SetMax( 100 )
					slider:SetValue( 1 )
					slider:SetDark( false )
					
					function slider:SetDisabled( value )
						if value then
							self:SetMouseInputEnabled( false )
						else
							self:SetMouseInputEnabled( true )
						end
					end
					
					function slider:Think()
					
						if combo:GetText() == "Permanent" then	
							self:SetMax( 1 )
							self:SetDisabled( true )
							return
						else
							self:SetDisabled( false )
						end
						
						if combo:GetText() == "Minutes" then
							self:SetMax( 1440 )
						elseif combo:GetText() == "Hours" then	
							self:SetMax( 168 )
						elseif combo:GetText() == "Days" then	
							self:SetMax( 120 )
						elseif combo:GetText() == "Weeks" then	
							self:SetMax( 52 )
						elseif combo:GetText() == "Years" then
							self:SetMax( 10 )
						end
						
						if self:GetValue() > self:GetMax() then
							self:SetValue( self:GetMax() )
						elseif self:GetValue() < self:GetMin() then	
							self:SetValue( self:GetMin() )
						end
						
					end
					
					local exec = vgui.Create( "DButton", CHAT.ban )
					exec:SetPos( 5, 100 )
					exec:SetSize( reason:GetSize() )
					exec:SetText( "Ban" )
					
					function exec:Paint()
						self:SetTextColor( color_white )
						surface.SetDrawColor( color_white )
						surface.DrawOutlinedRect( 0, 0, self:GetSize() )
					end
					
					function exec:DoClick()
					
						local text = reason:GetText()
						
						if text:len() == 0 then
							return
						end
						
						RunConsoleCommand( "ulx", "ban", name, tostring( slider:GetValue() * combo.curChoice ), text )
						CHAT.Tick()
						
					end
					
					function reason:OnEnter()
						exec:DoClick()
					end
					
				end ):SetIcon( "icon16/user_delete.png" )
				
				menu:AddOption( "Slay", function()
					CHAT.Tick()
					RunConsoleCommand( "ulx", "slay", ply:Name() )
				end ):SetIcon( "icon16/cut_red.png" )
				
				if ply:IsFrozen() then
				
					menu:AddOption( "Unfreeze", function()
						CHAT.Tick()
						RunConsoleCommand( "ulx", "unfreeze", ply:Name() )
					end ):SetIcon( "icon16/wand.png" )	
					
				else
				
					menu:AddOption( "Freeze", function()
						CHAT.Tick()
						RunConsoleCommand( "ulx", "freeze", ply:Name() )
					end ):SetIcon( "icon16/wand.png" )	
					
				end
				
			menu:SetMinimumWidth( 200 )
			local pos = Vector( CHAT.main:GetPos() )
			menu:Open( pos.x + CHAT.main:GetWide() - 200 - 8, pos.y + ( self:GetTall() * 2 + 1 ) + 50  )
			
			function menu:Paint()
				surface.SetDrawColor( CHAT.TextBoxColor )
				surface.DrawRect( 0, 0, self:GetSize() )
				surface.SetDrawColor( color_black )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )
			end		
			
		end			
		
		function PNL.Top.ASettings:Think2()

			if LocalPlayer():IsAdmin() then
				self:SetVisible( true )
			else
				self:SetVisible( false )
			end
			
		end
		
		PNL.VoiceStatus = PNL.Top:Add( "DLabel" )
		PNL.VoiceStatus:SetPos( 50, 3 )
		PNL.VoiceStatus:SetText( "" )
		PNL.VoiceStatus:SetFont( "DermaDefault" )
		
		function PNL.VoiceStatus:Think()
			self:SizeToContents()
			self:Think2()
		end
		
		function PNL.VoiceStatus:Think2()

			if not IsValid( ply ) then
				return
			end

			if CHAT[ ply ] then

				if not IsValid( ply ) then
					return
				end		

				if CHAT[ ply ]._VoiceRequest then
				
					self:SetText( ply:Name() .. " would like to voice chat" )
					PNL.VoiceRequestButtonYes:SetVisible( true )
					PNL.VoiceRequestButtonNo:SetVisible( true )
					
				elseif CHAT[ ply ]._SentVoiceRequest then
				
					self:SetText( "Voice request to " .. ply:Name() .. " pending..." )
					PNL.VoiceRequestButtonYes:SetVisible( false )
					PNL.VoiceRequestButtonNo:SetVisible( false )	
					
				elseif CHAT.VoiceChatting == ply and CHAT[ ply ]._SentVoiceRequest == nil and CHAT[ ply ]._VoiceRequest == nil then
				
					self:SetText( "Voice chatting with " .. ply:Name() )
					PNL.VoiceRequestButtonYes:SetVisible( false )
					PNL.VoiceRequestButtonNo:SetVisible( true )	
					
				else
				
					self:SetText( "" )
					PNL.VoiceRequestButtonYes:SetVisible( false )
					PNL.VoiceRequestButtonNo:SetVisible( false )	
					
				end

			end

		end
		
		PNL.VoiceRequestButtonNo = PNL:Add( "DButton" )
		PNL.VoiceRequestButtonNo:SetSize( 25, 20 )
		PNL.VoiceRequestButtonNo:SetTextColor( color_white )
		PNL.VoiceRequestButtonNo:SetText( "No" )
		
		function PNL.VoiceRequestButtonNo:Paint()
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 0, 0, self:GetSize() )
			surface.SetDrawColor( color_white )
			surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		end
		
		function PNL.VoiceRequestButtonNo:Think()

			self:SetPos( PNL.Top:GetWide() - 130 )

			if CHAT.VoiceChatting then
				self:SetText( "End" )
			else
				self:SetText( "No" )
			end

		end
		
		function PNL.VoiceRequestButtonNo:OnCursorEntered()
			self:SetTextColor( CHAT.TextHighlightColor )
		end
		
		function PNL.VoiceRequestButtonNo:OnCursorExited()
			self:SetTextColor( color_white )
		end	
		
		function PNL.VoiceRequestButtonNo:DoClick()

			if CHAT.VoiceChatting then
				net.Start( "EndVoiceChat" )
					net.WriteEntity( CHAT.VoiceChatting )
				net.SendToServer()
			else
				net.Start( "RequestVoiceChatCallback" )
					net.WriteEntity( ply )
					net.WriteBit( false )
				net.SendToServer()
			end

			CHAT.Tick()
			
		end
		
		PNL.VoiceRequestButtonYes = PNL:Add( "DButton" )
		PNL.VoiceRequestButtonYes:SetSize( 25, 20 )
		PNL.VoiceRequestButtonYes:SetTextColor( color_white )
		PNL.VoiceRequestButtonYes:SetText( "Yes" )
		
		function PNL.VoiceRequestButtonYes:Paint()
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 0, 0, self:GetSize() )
			surface.SetDrawColor( color_white )
			surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		end
		
		function PNL.VoiceRequestButtonYes:Think()
			self:SetPos( PNL.Top:GetWide() - 157 )
		end		
		
		function PNL.VoiceRequestButtonYes:OnCursorEntered()
			self:SetTextColor( CHAT.TextHighlightColor )
		end
		
		function PNL.VoiceRequestButtonYes:OnCursorExited()
			self:SetTextColor( color_white )
		end			
		
		function PNL.VoiceRequestButtonYes:DoClick()

			net.Start( "RequestVoiceChatCallback" )
				net.WriteEntity( ply )
				net.WriteBit( true )
			net.SendToServer()

			CHAT.Tick()
			
		end
		
		PNL.Line = PNL:Add( "DPanel" )
		local pos = Vector( PNL.Top:GetPos() )
		PNL.Line:SetPos( 0, pos.y + PNL.Top:GetTall() )
		PNL.Line:SetSize( PNL:GetWide(), 1 )
		
		function PNL.Line:Think()
			self:SetSize( PNL:GetWide(), 1 )
		end
		
		function PNL.Line:Paint()
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 0, 0, self:GetSize() )
		end
		
		PNL.RT = PNL:Add( "RichText" )
		PNL.RT:SetPos( 0, 51 )
		
		function PNL.RT:Think()
			self:SetSize( PNL:GetWide(), PNL:GetTall() - PNL.Top:GetTall() - 16 )
		end
		
		function PNL.RT:Paint()
			self.m_FontName = "rtfont1"
			self:SetFontInternal( "rtfont1" )	
		end
		
		PNL.RT:InsertColorChange( 255, 255, 255, 255 )	
		
		PNL.StatusLine = PNL:Add( "DPanel" )
		PNL.StatusLine:SetPos( 0, PNL:GetTall() - 15 )
		PNL.StatusLine:SetSize( PNL:GetWide(), 1 )
		
		function PNL.StatusLine:Paint()
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 0, 0, self:GetSize() )
		end
		
		function PNL.StatusLine:Think()
			PNL.StatusLine:SetPos( 0, PNL:GetTall() - 15 )
			PNL.StatusLine:SetSize( PNL:GetWide(), 1 )	
		end
		
		PNL.Status = PNL:Add( "DLabel" )
		PNL.Status:SetPos( 0, PNL:GetTall() - 13 )
		PNL.Status:SetTextColor( color_white )
		PNL.Status:SetFont( "DermaDefault" )
		PNL.Status:SetText( "" )
		
		function PNL.Status:Think()
			self:SetPos( 0, PNL:GetTall() - 13 )
			self:SizeToContents()
		end
		
		function PNL.Status:SetStatus( str )
			PNL.Status:SetText( str )
		end
		PNL.Status:SetStatus( "" )
		
		CHAT[ ply ] = CHAT.AddTab( ply:Name(), PNL, ply:GetIcon(), "Chat with " .. ply:Name(), ply )
		
		if tText then
			for k, v in next, tText do
				local str_tab = string.Split( v, "#####" )
				PNL.RT:InsertColorChange( 55, 133, 236, 255 )
				PNL.RT:AppendText( str_tab[ 1 ] )
				PNL.RT:InsertColorChange( 155, 220, 0, 255 )
				PNL.RT:AppendText( str_tab[ 2 ] )
				PNL.RT:InsertColorChange( 255, 255, 255, 255 )
				PNL.RT:AppendText( str_tab[ 3 ] .. "\n" )
				PNL.RT:InsertColorChange( 255, 255, 255, 255 )
				table.insert( CHAT[ ply ].Text, v )
			end
			PNL.RT:GotoTextEnd()
		end		
		
	end
	
end

function CHAT.SetPanelVoiceRequest( ply )

	if not CHAT[ ply ] then
		return
	end
	
	CHAT[ ply ]._VoiceRequest = true		
end

hook.Add( "Think", "CheckIcons", function()

	if not ValidPanel( CHAT.main ) then
		return
	end
	
	for k, v in _E do
	
		if CHAT[ v ] then
		
			local icon = v:GetIcon()
			
			if not CHAT[ v ].Tab.Image:GetImage() == icon then
				CHAT[ v ].Tab.Image:SetImage( icon )
			end
			
		end
		
	end
	
end )

--[[----------------------------------------------------------
	Sound utilities
----------------------------------------------------------]]--

function CHAT.LoopSound( sound, numLoops )

	local duration = SoundDuration( sound )
	surface.PlaySound( sound )
	
	if numLoops ~= 1 then
		timer.Create( "CHAT.LoopSound", duration, numLoops - 1, function()
			surface.PlaySound( sound )
		end )
	end
	
end

function CHAT.StopSound()
	timer.Destroy( "CHAT.LoopSound" )
end

function CHAT.Tick()

	if GetConVarNumber( "chat_button_sounds" ) == 0 then
		return
	end
	
	chat.PlaySound()
	
end

--[[----------------------------------------------------------
	Networking
----------------------------------------------------------]]--

net.Receive( "SendReply2", function()

	local str = net.ReadString()
	local ply = net.ReadEntity()
	
	if ( not CHAT[ ply ] ) and ( not ValidPanel( CHAT.main ) ) then
	
		CHAT.Notify( ply, str )
		CHAT.QueuePanel( ply, str )
		
	elseif ( CHAT[ ply ] ) and ( not ValidPanel( CHAT.main ) ) then
	
		CHAT.Notify( ply, str )
		table.insert( CHAT[ ply ].Text, os.date( "%I:%M %p" ) .. " - #####" .. ply:Name() .. "#####: " .. string.Trim( str ) )
		
	elseif ( not CHAT[ ply ] ) and ValidPanel( CHAT.main ) then
	
		CHAT.StartPanel( ply, { os.date( "%I:%M %p" ) .. " - " .. ply:Name() .. ": " .. string.Trim( str ) } )
		
	elseif CHAT[ ply ] and ValidPanel( CHAT.main ) then
	
		table.insert( CHAT[ ply ].Text, os.date( "%I:%M %p" ) .. " - #####" .. ply:Name() .. "#####: " .. string.Trim( str ) )
		local txtX1 = os.date( "%I:%M %p" ) .. " - #####" .. ply:Name() .. "#####: " .. string.Trim( str )
		--CHAT[ ply ].Panel.RT:AppendText( os.date( "%I:%M %p" ) .. " - #####" .. ply:Name() .. "#####: " .. string.Trim( str ) .. "\n" )
		local str_tab = string.Split( txtX1, "#####" )
		CHAT[ ply ].Panel.RT:InsertColorChange( 55, 133, 236, 255 )
		CHAT[ ply ].Panel.RT:AppendText( str_tab[ 1 ] )
		CHAT[ ply ].Panel.RT:InsertColorChange( 155, 220, 0, 255 )
		CHAT[ ply ].Panel.RT:AppendText( str_tab[ 2 ] )
		CHAT[ ply ].Panel.RT:InsertColorChange( 255, 255, 255, 255 )
		CHAT[ ply ].Panel.RT:AppendText( str_tab[ 3 ] .. "\n" )
		CHAT[ ply ].Panel.RT:InsertColorChange( 255, 255, 255, 255 )
		
	end
	
end )

net.Receive( "TypingStatus2", function()

	local bool = tobool( net.ReadBit() )
	local ply = net.ReadEntity()
	
	if not ( CHAT[ ply ] and ValidPanel( CHAT.main ) ) then
		return
	end
	
	if bool == true then
		CHAT[ ply ].Panel.Status:SetStatus( ply:Name() .. " is typing..." )
	elseif bool == false then
		CHAT[ ply ].Panel.Status:SetStatus( "" )
	end
	
end )

net.Receive( "RequestVoiceChat2", function() --todo: add chat messages to these?

	local ply = net.ReadEntity()
	
	if ( not CHAT[ ply ] ) and ( not ValidPanel( CHAT.main ) ) then
	
		CHAT.NotifyVoice( ply )
		CHAT.QueuePanel( ply, ply:Name() .. " would like to voice chat", true )
		
		if GetConVar( "chat_enable_ringing_sounds" ):GetBool() then
			CHAT.LoopSound( "chat/voice_ringing.wav", 0 )
		end
		
	elseif ( CHAT[ ply ] ) and ( not ValidPanel( CHAT.main ) ) then
	
		CHAT.NotifyVoice( ply )
		CHAT.SetPanelVoiceRequest( ply )
		
		if GetConVar( "chat_enable_ringing_sounds" ):GetBool() then
			CHAT.LoopSound( "chat/voice_ringing.wav", 0 )
		end
		
	elseif ( not CHAT[ ply ] ) and ValidPanel( CHAT.main ) then
	
		CHAT.StartPanel( ply, nil )
		CHAT.SetPanelVoiceRequest( ply )
		
		if GetConVar( "chat_enable_ringing_sounds" ):GetBool() then
			CHAT.LoopSound( "chat/voice_ringing.wav", 0 )
		end
		
	elseif CHAT[ ply ] and ValidPanel( CHAT.main ) then
	
		CHAT.SetPanelVoiceRequest( ply )	
		
		if GetConVar( "chat_enable_ringing_sounds" ):GetBool() then
			CHAT.LoopSound( "chat/voice_ringing.wav", 0 )		
		end
		
	end
	
end )

net.Receive( "VoiceChatDecision", function()

	local sent_to = net.ReadEntity()
	local requested = net.ReadEntity()
	local bool = tobool( net.ReadBit() )
	
	if sent_to == LocalPlayer() then
	
		if bool == true then
		
			CHAT.VoiceChatting = requested
			CHAT[ requested ]._VoiceRequest = nil
			CHAT.StopSound()
			
			if ValidPanel( CHAT.main ) then
				CHAT[ CHAT.VoiceChatting ].Tab.Image:SetImage( "icon16/sound.png" )
			end
			
		else
		
			CHAT[ requested ].Panel.RT:InsertColorChange( 255, 0, 0, 255 )
			CHAT[ requested ].Panel.RT:AppendText( "You declined the request from " .. requested:Name() .. "\n" )
			CHAT[ requested ].Panel.RT:InsertColorChange( 255, 255, 255, 255 )
			CHAT[ requested ]._VoiceRequest = nil
			
			CHAT.StopSound()
			
		end
		
	else
	
		if bool == true then
		
			CHAT.VoiceChatting = sent_to
			CHAT[ sent_to ]._SentVoiceRequest = nil
			CHAT.StopSound()
			
			if ValidPanel( CHAT.main ) then
				CHAT[ CHAT.VoiceChatting ].Tab.Image:SetImage( "icon16/sound.png" )		
			end
			
		else
		
			CHAT[ sent_to ].Panel.RT:InsertColorChange( 255, 0, 0, 255 )
			CHAT[ sent_to ].Panel.RT:AppendText( sent_to:Name() .. " has declined your chat request.\n" )
			CHAT[ sent_to ].Panel.RT:InsertColorChange( 255, 255, 255, 255 )
			CHAT[ sent_to ]._SentVoiceRequest = nil	
			
			CHAT.StopSound()	
			
		end
		
	end
	
end )

net.Receive( "EndVoiceChatCL", function()

	local ply1 = net.ReadEntity()
	local ply2 = net.ReadEntity()
	
	local ply
	
	if ply2 == LocalPlayer() then
		ply = ply1
	else
		ply = ply2 
	end
	
	if ValidPanel( CHAT.main ) then
		CHAT[ ply ].Panel.RT:AppendText( "The voice chat has ended.\n" )
	end
	
	timer.Simple( 0.1, function()
		if ValidPanel( CHAT.main ) then
			CHAT[ ply ].Tab.Image:SetImage( ply:GetIcon() )		
		end
	end )		
	
	CHAT.VoiceChatting = nil
	
	if GetConVar( "chat_enable_hangup_sounds" ):GetBool() then
		surface.PlaySound( "chat/voice_hangup1.wav" )
	end
	
end )

-- Separate function for disconnected players
net.Receive( "EndVoiceChatDC", function()

	local id = net.ReadString()
	
	if CHAT.Offline[ id ] then
		CHAT.Offline[ id ].Panel.RT:AppendText( "The voice chat has ended." )
	end
	
	CHAT.VoiceChatting = nil
	
	if GetConVar( "chat_enable_hangup_sounds" ):GetBool() then
		surface.PlaySound( "chat/voice_hangup1.wav" )	
	end
	
end )	


-- When someone leaves who has a panel, replace it with an offline version
net.Receive( "Disconnect", function()
	
	if ValidPanel( CHAT.main ) then
		CHAT.start.Player:_Rebuild()
	end
	
	local id = net.ReadString()
	
	for k, v in next, CHAT do
	
		if istable( v ) then
		
			local id1 = v.ID
			if id == id1 then
			
				local tab = v
				if CHAT.ValidSteamID( tab.ID ) then
				
					CHAT.RemoveTab( tab.Tab )
					CHAT.Offline[ id1 ] = table.Copy( tab )
					
					if ValidPanel( CHAT.main ) then
						CHAT.CreateOfflinePanel( tab.ID, tab.Text, tab.Name )
						CHAT.tabs:SetActiveTab( CHAT.Offline[ tab.ID ].Tab )
					end
					
				else -- No offline panels for null ids (i.e. bots), and the start menu
				
					if tab.Name == "+" then
						print( "returning") 
						continue
					end
					
					CHAT.tabs:CloseTab( tab.Tab, true )
					
				end
				
			end
			
		end
		
	end
	
end )

-- When someone joines who has an offline panel, replace it with a normal one
net.Receive( "Connect", function()
	
	if ValidPanel( CHAT.main ) then
		timer.Simple( 2, function() -- wait for the player to be valid
			CHAT.start.Player:_Rebuild()
		end )
	end
	
	local ply = net.ReadEntity()
	
	if IsValid( ply ) then
	
		if CHAT.Offline[ ply:SteamID() ] then
		
			if ValidPanel( CHAT.main ) then
			
				local text = CHAT.Offline[ ply:SteamID() ].Text
				
				CHAT.tabs:CloseTab( CHAT.Offline[ ply:SteamID() ].Tab, true )
				CHAT.Offline[ ply:SteamID() ] = nil
				CHAT.StartPanel( ply, text )
				CHAT.tabs:SetActiveTab( CHAT[ ply ].Tab )
				
			else
			
				CHAT.Offline[ ply:SteamID() ] = nil
				
			end
			
		end
		
	end
	
end )

net.Receive( "GetInfo", function()

	local info = net.ReadString()
	local bool = GetConVar( info ):GetBool()
	
	net.Start( "GetInfoCallback" )
		net.WriteBit( bool )
	net.SendToServer()
	
end )

net.Receive( "NetworkGroupsTable", function()

	local tab = net.ReadTable()
	CHAT.GROUPS = tab
	
	for k, v in next, CHAT.GROUPS do
		if CHAT.CLGROUPS[ k ] then
			local text = v.Text
			CHAT.CLGROUPS[ k ].Text = text
		end
	end
	
	for k, v in next, CHAT.CLGROUPS do
		if ValidPanel( v.Panel ) then
			v.Panel.Users.List:_Rebuild()
		end
	end
	
	if ValidPanel( CHAT.main ) then
		CHAT.start.Group:_Rebuild()
	end
	
end )

net.Receive( "InviteUsersNotify", function()

	local sender = net.ReadEntity()
	local name = net.ReadString()
	
	CHAT.AddGroupInvite( sender, name )
	
	CHAT.Notify( sender, "Group Invite to \'" .. name .. "\'" )
end )

--[[----------------------------------------------------------
	Hooks
----------------------------------------------------------]]--

-- Remove the voice panels for you and the person/people you are talking to
hook.Add( "PlayerStartVoice", "OverrideChatNotifications", function( ply )
	if ( ply == LocalPlayer() and CHAT.VoiceChatting ~= nil ) or ( CHAT.VoiceChatting and ply == CHAT.VoiceChatting ) or 
	( CHAT.InGroupVoiceChat and table.HasValue( CHAT.GROUPS[ CHAT.InGroupVoiceChat ].Voice, ply ) ) then
		GAMEMODE:PlayerEndVoice( ply )
		return true
	end
end )


hook.Add( "Think", "CHAT.ThinkOpen", function()

	if input.IsKeyDown( CHAT.OpenKey ) then
		if not CHAT.KeyDown then
			CHAT.KeyDown = true
			if ValidPanel( CHAT.main ) then
				CHAT.main:AlphaTo( 0, 0.3, 0, function() 
					CHAT.main:Close()			
				end )
			else
				CHAT.OpenChatWindow()
			end
		end
	else
		CHAT.KeyDown = false
	end	
	
end )
surface.CreateFont( "GroupPanel", {
	font = "Century Gothic",
	size = 22,
	antialias = true
} )
-- Draw the hud panel on the side to show who you are talking to
hook.Add( "HUDPaint", "ShowPrivateChat", function()
	
	if not ( CHAT.VoiceChatting ) then
	
		if CHAT.InGroupVoiceChat then
		
			local num = table.getn( CHAT.GROUPS[ CHAT.InGroupVoiceChat ].Voice )
			local plys = {}
			
			for k, v in next, CHAT.GROUPS[ CHAT.InGroupVoiceChat ].Voice do
				table.insert( plys, v )
			end
			
			local y = ScrH() / 2
			local totalheight = 35 * num + ( 5 * ( num - 1 ) )
			local starth = y - ( totalheight / 2 )
			
			for k, v in next, plys do
			
				if not IsValid( v ) then
					continue
				end
				
				local txt = v:Name()
				surface.SetFont( "GroupPanel" )
				local w, h = surface.GetTextSize( txt )
				local min = 175
				
				if w > ( min - 10 ) then
					for i = 1, ScrW() do
						min = min + 1
						if w < ( min - 10 ) then
							break
						end
					end
				end
				
				surface.SetDrawColor( CHAT.PropertyColor )
				surface.DrawRect( ScrW() - min - 10, starth, min, 35 )
				
				if CHAT.VRDown() and v == LocalPlayer() then
					draw.SimpleTextOutlined( "Talking in-game", "DermaDefault", ScrW() - min - 95, starth + 21, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, CHAT.PropertyColor )
				end
				
				local vol = v:VoiceVolume()
				
				surface.SetDrawColor( color_white )
				surface.DrawRect( ScrW() - min - 10, starth, min * vol, 35 )

				draw.SimpleTextOutlined( v:Name(), "GroupPanel", ScrW() - 15, starth + 15, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, CHAT.PropertyColor )
				starth = starth + 40
				
			end	
			
		end
		
		return
		
	end
	
	surface.SetFont( "panel" )
	
	if not IsValid( CHAT.VoiceChatting ) then
		return
	end
	
	local txt = CHAT.VoiceChatting:Name()
	
	local w, h = surface.GetTextSize( txt )
	local min = 175
	
	if w > ( min - 10 ) then
		for i = 1, ScrW() do
			min = min + 1
			if w < ( min - 10 ) then
				break
			end
		end
	end
	
	surface.SetDrawColor( CHAT.PropertyColor )
	surface.DrawRect( ScrW() - min - 10, ScrH() / 2 - 100, min, 40 )
	
	if CHAT.VRDown() then
		draw.SimpleTextOutlined( "Talking in-game", "DermaDefault", ScrW() - min - 10, ScrH() / 2 - 110, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, CHAT.PropertyColor )
	end
	
	local vol = CHAT.VoiceChatting:VoiceVolume()
	
	surface.SetDrawColor( color_white )
	surface.DrawRect( ScrW() - min - 10, ScrH() / 2 - 100, min * vol, 40 )

	draw.SimpleTextOutlined( CHAT.VoiceChatting:Name(), "panel", ScrW() - 15, ScrH() / 2 - 80, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 1, CHAT.PropertyColor )

end )

--[[----------------------------------------------------------
	Binds
----------------------------------------------------------]]--

-- Associate key numbers with their strings
CHAT.Enums = {
	{ KEY_0, 1, "0" },
	{ KEY_1, 2, "1" },
	{ KEY_2, 3, "2" },
	{ KEY_3, 4, "3" },
	{ KEY_4, 5, "4" },
	{ KEY_5, 6, "5" },
	{ KEY_6, 7, "6" },
	{ KEY_7, 8, "7" },
	{ KEY_8, 9, "8" },
	{ KEY_9, 10, "9" },
	{ KEY_A, 11, "a" }, 
	{ KEY_APOSTROPHE, 56, "\'" },
	{ KEY_APP, 87, "app" },
	{ KEY_B, 12, "b" },
	{ KEY_BACKSLASH, 61, "\\" },
	{ KEY_BACKSPACE, 66, "backspace" },
	{ KEY_BREAK, 78, "pause" },
	{ KEY_C, 13, "c" },
	{ KEY_CAPSLOCK, 68, "capslock" },
	{ KEY_COMMA, 58, "," },
	{ KEY_D, 14, "d" },
	{ KEY_DELETE, 73, "del" },
	{ KEY_DOWN, 90, "downarrow" },
	{ KEY_E, 15, "e" },
	{ KEY_END, 75, "end" },
	{ KEY_ENTER, 64, "enter" },
	{ KEY_EQUAL, 63, "=" },
	{ KEY_F, 16, "f" },
	{ KEY_F1, 92, "f1" },
	{ KEY_F10, 101, "f10" },
	{ KEY_F11, 102, "f11" },
	{ KEY_F12, 103, "f12" },
	{ KEY_F2, 93, "f2" },
	{ KEY_F3, 94, "f3" },
	{ KEY_F4, 95, "f4" },
	{ KEY_F5, 96, "f5" },
	{ KEY_F6, 97, "f6" },
	{ KEY_F7, 98, "f7" },
	{ KEY_F8, 99, "f8" },
	{ KEY_F9, 100, "f9" },
	{ KEY_G, 17, "g" },
	{ KEY_H, 18, "h" },
	{ KEY_HOME, 74, "home" },
	{ KEY_I, 19, "i" },
	{ KEY_INSERT, 72, "ins" },
	{ KEY_J, 20, "j" },
	{ KEY_K, 21, "k" },
	{ KEY_L, 22, "l" },
	{ KEY_LALT, 81, "alt" },
	{ KEY_LBRACKET, 53, "[" },
	{ KEY_LCONTROL, 83, "ctrl" },
	{ KEY_LEFT, 89, "leftarrow" },
	{ KEY_LSHIFT, 79, "shift" },
	{ KEY_M, 23, "m" },
	{ KEY_MINUS, 62, "-" },
	{ KEY_N, 24, "n" },
	{ KEY_NUMLOCK, 69, "numlock" },
	{ KEY_O, 25, "o" },
	{ KEY_P, 26, "p" },
	{ KEY_PAD_0, 37, "kp_ins" },
	{ KEY_PAD_1, 38, "kp_end" },
	{ KEY_PAD_2, 39, "kp_downarrow" },
	{ KEY_PAD_3, 40, "kp_pgdn" },
	{ KEY_PAD_4, 41, "kp_leftarrow" },
	{ KEY_PAD_5, 42, "kp_5" },
	{ KEY_PAD_6, 43, "kp_rightarrow" },
	{ KEY_PAD_7, 44, "kp_home" },
	{ KEY_PAD_8, 45, "kp_uparrow" },
	{ KEY_PAD_9, 46, "kp_pgup" },
	{ KEY_PAD_DECIMAL, 52, "kp_del" },
	{ KEY_PAD_DIVIDE, 47, "kp_slash" },
	{ KEY_PAD_ENTER, 51, "kp_enter" },
	{ KEY_PAD_MINUS, 49, "kp_minus" },
	{ KEY_PAD_MULTIPLY, 48, "kp_multiply" },
	{ KEY_PAD_PLUS, 50, "kp_plus" },
	{ KEY_PAGEDOWN, 77, "kp_pgdn" },
	{ KEY_PAGEUP, 76, "kp_pgup" },
	{ KEY_PERIOD, 59, "." },
	{ KEY_Q, 27, "q" },
	{ KEY_R, 28, "r" },
	{ KEY_RALT, 82, "ralt" },
	{ KEY_RBRACKET, 54, "]" },
	{ KEY_RCONTROL, 84, "rctrl" },
	{ KEY_RIGHT, 91, "rightarrow" },
	{ KEY_RSHIFT, 80, "rshift" },
	{ KEY_S, 29, "s" },
	{ KEY_SEMICOLON, 55, "semicolon" },
	{ KEY_SLASH, 60, "/" },
	{ KEY_SPACE, 65, "space" },
	{ KEY_T, 30, "t" },
	{ KEY_TAB, 67, "tab" },
	{ KEY_U, 31, "u" },
	{ KEY_UP, 88, "uparrow" },
	{ KEY_V, 32, "v" },
	{ KEY_W, 33, "w" },
	{ KEY_X, 34, "x" },
	{ KEY_Y, 35, "y" },
	{ KEY_Z, 36, "z" }
}

-- We need this function and the table above because input.LookupBinding only returns a string
function CHAT.LookupBinding( str )

	local key = input.LookupBinding( str )
	
	if not key then
		return
	end
	
	for k, v in next, CHAT.Enums do
		if key == v[ 3 ] then
			return v[ 1 ]
		end
	end
	
	return
end

function CHAT.IsBindingDown( str )

	local key = CHAT.LookupBinding( str )
	if not key then
		return
	end
	
	return input.IsKeyDown( key )
end

local IsVRDown = false

hook.Add( "Think", "CheckVoicerecord", function()
	if CHAT.IsBindingDown( "voicerecord" ) and IsVRDown == false then
		hook.Run( "VoicerecordPressed" )
		IsVRDown = true
	elseif not CHAT.IsBindingDown( "voicerecord" ) and IsVRDown == true then
		hook.Run( "VoicerecordReleased" )
		IsVRDown = false
	end
end )

function CHAT.VRDown()
	return IsVRDown
end

hook.Add( "VoicerecordPressed", "SendNetworkedStatus", function()
	net.Start( "VRPressed" )
	net.SendToServer()
end )

hook.Add( "VoicerecordReleased", "SendNetworkedStatus", function()
	net.Start( "VRReleased" )
	net.SendToServer()
end )	

function CHAT.GetPlayerFromUserID( id )

	local pl
	
	for k, v in _E do	
		if v:UserID() == id then	
			pl = v
		end
	end
	
	return pl
	
end

function CHAT.ValidSteamID( id )
	return string.match( id, "^STEAM_%d:%d:%d+$" ) ~= nil -- because not everyone has ulib
end

--[[----------------------------------------------------------
	Offline Tabs
----------------------------------------------------------]]--	

function CHAT.AddOfflineTab( name, panel, material, tooltip, steamid, text )

	local temp = CHAT.tabs:AddSheet( name, panel, material, false, false, tooltip )
	local tab = temp.Tab
	
	function tab:Paint()
		if CHAT.tabs:GetActiveTab() ~= self then
			self:SetTextColor( CHAT.TabUnfocusedColor )
			surface.SetDrawColor( CHAT.BGColor )
			surface.DrawRect( 0, 0, self:GetSize() )
		else
			self:SetTextColor( CHAT.TabFocusedColor )
			surface.SetDrawColor( CHAT.PropertyColor )
			surface.DrawRect( 0, 0, self:GetWide(), self:GetTall() - 8 )
		end
	end
	
	local RET = { 
		Sheet = temp,
		Tab = tab,
		Panel = panel,
		Text = text or {},
		Material = material,
		Tooltip = tooltip,
		Name = name,
		ID = steamid,
		Offline = true
	}
	
	return RET
end

function CHAT.CreateOfflinePanel( ply, text, name ) -- ply is a steamid

	local PNL = vgui.Create( "DPanel", CHAT.tabs )
	PNL:SetPos( 0, 0 )
	PNL:SetSize( CHAT.tabs:GetSize() )
	
	function PNL:Paint() 
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 0, self:GetSize() )
	end
	
	function PNL:Think()
		if ValidPanel( self ) then
			CHAT.text:SetKeyBoardInputEnabled( false )
			CHAT.text:SetMouseInputEnabled( false )
		end
	end
	
	PNL.Top = PNL:Add( "DPanel" )
	PNL.Top:SetPos( 0, 0 )
	PNL.Top:SetSize( PNL:GetWide(), 50 )
	
	function PNL.Top:Think()
		self:SetSize( PNL:GetWide(), 50 )
	end
	
	function PNL.Top:Paint() 
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 0, self:GetSize() )
	end		
	
	PNL.Top.Avatar = PNL.Top:Add( "AvatarImage" )
	PNL.Top.Avatar:SetPos( 5, 5 )
	PNL.Top.Avatar:SetSize( 40, 40 )
	PNL.Top.Avatar:SetSteamID( util.SteamIDTo64( ply ), 64 )
	
	PNL.Top.PlayerName = PNL.Top:Add( "DLabel" )
	PNL.Top.PlayerName:SetPos( 50, 17 )
	PNL.Top.PlayerName:SetFont( "name1" )
	PNL.Top.PlayerName:SetTextColor( color_white )
	PNL.Top.PlayerName:SetText( name )
	PNL.Top.PlayerName:SizeToContents()
	
	PNL.Top.Settings = PNL.Top:Add( "DButton" )
	PNL.Top.Settings:SetSize( 100, 20 )
	PNL.Top.Settings:SetText( "Options" )
	PNL.Top.Settings:SetTextColor( color_white )
	
	function PNL.Top.Settings:Paint()
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 0, self:GetSize() )
		surface.SetDrawColor( color_white )
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
	end
	
	function PNL.Top.Settings:Think()
		self:SetPos( PNL.Top:GetWide() - 100, 0 )
	end
	
	function PNL.Top.Settings:OnCursorEntered()
		self:SetTextColor( CHAT.TextHighlightColor )
	end
	
	function PNL.Top.Settings:OnCursorExited()
		self:SetTextColor( color_white )
	end	
	
	function PNL.Top.Settings:DoClick()
	
		local menu = vgui.Create( "DMenu", PNL )
			
			menu:AddOption( "Exit chat", function()
				CHAT.Tick()
				CHAT.tabs:CloseTab( CHAT.Offline[ ply ].Sheet.Tab, true )
				CHAT.Offline[ ply ] = nil
				CHAT.start.Player:_Rebuild()
			end ):SetIcon( "icon16/page_delete.png" )
			
		menu:SetMinimumWidth( 200 )
		local pos = Vector( CHAT.main:GetPos() )
		menu:Open( pos.x + CHAT.main:GetWide() - 200 - 8, pos.y + self:GetTall() + 49 )
		
		function menu:Paint()
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 0, 0, self:GetSize() )
			surface.SetDrawColor( color_black )
			surface.DrawOutlinedRect( 0, 0, self:GetSize() )
		end
		
	end
	
	PNL.VoiceStatus = PNL.Top:Add( "DLabel" )
	PNL.VoiceStatus:SetPos( 50, 3 )
	PNL.VoiceStatus:SetText( "This user is offline." )
	PNL.VoiceStatus:SetFont( "DermaDefault" )
	
	function PNL.VoiceStatus:Think()
		self:SizeToContents()
	end
	
	PNL.Line = PNL:Add( "DPanel" )
	local pos = Vector( PNL.Top:GetPos() )
	PNL.Line:SetPos( 0, pos.y + PNL.Top:GetTall() )
	PNL.Line:SetSize( PNL:GetWide(), 1 )
	
	function PNL.Line:Think()
		self:SetSize( PNL:GetWide(), 1 )
	end
	
	function PNL.Line:Paint()
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawRect( 0, 0, self:GetSize() )
	end
	
	PNL.RT = PNL:Add( "RichText" )
	PNL.RT:SetPos( 0, 51 )
	
	function PNL.RT:Think()
		self:SetSize( PNL:GetWide(), PNL:GetTall() - PNL.Top:GetTall() - 16 )
	end
	
	function PNL.RT:Paint()
		self.m_FontName = "rtfont1"
		self:SetFontInternal( "rtfont1" )	
	end
	
	PNL.RT:InsertColorChange( 255, 255, 255, 255 )	
	
	PNL.StatusLine = PNL:Add( "DPanel" )
	PNL.StatusLine:SetPos( 0, PNL:GetTall() - 15 )
	PNL.StatusLine:SetSize( PNL:GetWide(), 1 )
	
	function PNL.StatusLine:Paint()
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawRect( 0, 0, self:GetSize() )
	end
	
	function PNL.StatusLine:Think()
		PNL.StatusLine:SetPos( 0, PNL:GetTall() - 15 )
		PNL.StatusLine:SetSize( PNL:GetWide(), 1 )	
	end
	
	PNL.Status = PNL:Add( "DLabel" )
	PNL.Status:SetPos( 0, PNL:GetTall() - 13 )
	PNL.Status:SetTextColor( color_white )
	PNL.Status:SetFont( "DermaDefault" )
	PNL.Status:SetText( "" )
	
	function PNL.Status:Think()
		self:SetPos( 0, PNL:GetTall() - 13 )
		self:SizeToContents()
	end
	
	function PNL.Status:SetStatus( str )
		PNL.Status:SetText( str )
	end
	
	PNL.Status:SetStatus( "" )
	
	CHAT.Offline[ ply ] = CHAT.AddOfflineTab( name, PNL, "icon16/disconnect.png", "Chat with " .. name, ply, text )
	
	if text then
		for k, v in next, text do
			local str_tab = string.Split( v, "#####" )
			PNL.RT:InsertColorChange( 55, 133, 236, 255 )
			PNL.RT:AppendText( str_tab[ 1 ] )
			PNL.RT:InsertColorChange( 155, 220, 0, 255 )
			PNL.RT:AppendText( str_tab[ 2 ] )
			PNL.RT:InsertColorChange( 255, 255, 255, 255 )
			PNL.RT:AppendText( str_tab[ 3 ] .. "\n" )
			PNL.RT:InsertColorChange( 255, 255, 255, 255 )
		end
		PNL.RT:GotoTextEnd()
	end		
	
end

--[[----------------------------------------------------------
	Group Tabs
----------------------------------------------------------]]--	

function CHAT.AddGroupTab( name, panel, material, tooltip, users, text )

	local temp = CHAT.tabs:AddSheet( name, panel, material, false, false, tooltip )
	local tab = temp.Tab
	
	function tab:Paint()
	
		if not CHAT.tabs then
			return
		end
		
		if CHAT.tabs:GetActiveTab() ~= self then
			self:SetTextColor( CHAT.TabUnfocusedColor )
			surface.SetDrawColor( CHAT.BGColor )
			surface.DrawRect( 0, 0, self:GetSize() )
		else
			self:SetTextColor( CHAT.TabFocusedColor )
			surface.SetDrawColor( CHAT.PropertyColor )
			surface.DrawRect( 0, 0, self:GetWide(), self:GetTall() - 8 )
		end
		
	end
	
	local RET = { 
		Sheet = temp,
		Tab = tab,
		Panel = panel,
		Text = text or {},
		Material = material,
		Tooltip = tooltip,
		Name = name,
		Users = users
	}
	
	return RET
end

function CHAT.CreateGroupPanel( name, users, textX )
	
	local PNL = vgui.Create( "DPanel", CHAT.tabs )
	PNL:SetPos( 0, 0 )
	PNL:SetSize( CHAT.tabs:GetSize() )
	
	function PNL:Paint() 
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 0, self:GetSize() )
	end
	
	function PNL:Think()
		if ValidPanel( self ) then
			CHAT.text:SetKeyBoardInputEnabled( true )
			CHAT.text:SetMouseInputEnabled( true )
		end
	end
	
	PNL.Top = PNL:Add( "DPanel" )
	PNL.Top:SetPos( 0, 0 )
	PNL.Top:SetSize( PNL:GetWide(), 30 )
	
	function PNL.Top:Think()
		self:SetSize( PNL:GetWide(), 30 )
	end
	
	function PNL.Top:Paint() 
		surface.SetDrawColor( CHAT.PropertyColor )
		surface.DrawRect( 0, 0, self:GetSize() )
	end	
	
	PNL.Top.Invite = PNL.Top:Add( "DButton" )
	PNL.Top.Invite:SetPos( PNL.Top:GetWide() - 100, 0 )
	PNL.Top.Invite:SetSize( 100, 20 )
	PNL.Top.Invite:SetText( "Invite Users" )
	PNL.Top.Invite:SetTextColor( color_white )
	PNL.Top.Invite.out = false
	
	function PNL.Top.Invite:Think()
		self:SetPos( PNL.Top:GetWide() - 100, 0 )
	end
	
	function PNL.Top.Invite:Paint()
		surface.SetDrawColor( color_white )
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
	end
	
	function PNL.Top.Invite:DoClick()
	
		if self.out then
			return
		end
		
		CHAT.Tick()
		self.out = true
		
		local slide = vgui.Create( "DFrame" )
		local pos = Vector( CHAT.main:GetPos() )
		
		slide:SetPos( pos.x + CHAT.main:GetWide() - 150, pos.y )
		slide:SetSize( 150, CHAT.main:GetTall() )
		slide:SetTitle( "" )
		slide:ShowCloseButton( false )
		slide.out = false
		
		slide:MoveTo( pos.x + CHAT.main:GetWide(), pos.y, 0.3, 0, 1, function()
			slide.out = true
		end )
		
		function slide:Paint()
			surface.SetDrawColor( CHAT.PropertyColor )
			surface.DrawRect( 0, 0, self:GetSize() )
		end
		
		-- This is literally the only way i could get it to not error
		function slide:Think()
		
			if not ValidPanel( CHAT.main ) then
				self:Remove() 
			end
			
			if self.out then
			
				if not ValidPanel( CHAT.main ) then
					self:Remove() 
				end
				
				local pos
				if ValidPanel( CHAT.main ) then
					pos = Vector( CHAT.main:GetPos() )
				else
					self:Remove()
				end
				
				if ValidPanel( CHAT.main ) then
					self:SetPos( pos.x + CHAT.main:GetWide(), pos.y )
				else
					self:Remove()
				end
				
				if ValidPanel( CHAT.main ) then
					self:SetSize( 150, CHAT.main:GetTall() )
				else
					self:Remove()
				end
				
			end
			
		end
		
		local users1 = slide:Add( "DPanelList" )
		users1:Dock( FILL )
		users1:EnableVerticalScrollbar( true )
		users1:SetSpacing( 2 )
		
		for k, v in _E do
		
			if not table.HasValue( CHAT.GROUPS[ name ].Members, v ) then
			
				local pnl = vgui.Create( "DButton" )
				pnl:SetSize( 148, 25 )
				pnl:SetText( "" )
				pnl.Selected = false
				pnl.User = v
				
				function pnl:DoClick()
					self.Selected = not self.Selected
					CHAT.Tick()
				end
				
				function pnl:Paint()
				
					if not self.Selected then
						surface.SetDrawColor( CHAT.TextBoxColor )
						surface.DrawRect( 0, 0, self:GetSize() )
					else
						surface.SetDrawColor( CHAT.TextBoxColor )
						surface.DrawRect( 0, 0, self:GetSize()	)
						surface.SetDrawColor( color_white )
						surface.DrawOutlinedRect( 0, 0, self:GetSize() )
					end
					
				end
				
				local av = pnl:Add( "AvatarImage" )
				av:SetPos( 2, 2 )
				av:SetSize( 21, 21 )
				av:SetPlayer( v )
				
				local name = pnl:Add( "DLabel" )
				name:SetPos( 25, 4 )
				name:SetFont( "asdf1" )
				name:SetTextColor( color_white )
				name:SetText( v:Name() )
				name:SizeToContents()
				
				users1:AddItem( pnl )
				
			end
			
		end
		
		local add = slide:Add( "DButton" )
		add:SetPos( 2, 2 )
		add:SetSize( 146, 17 )
		add:SetTextColor( color_white )
		add:SetText( "Invite" )
		add.canclick = false
		
		function add:Paint()
		
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 0, 0, self:GetSize() )
			
			if self.canclick then
				surface.SetDrawColor( color_white )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )
			end
			
		end
		
		function add:Think()
		
			if not ValidPanel( users1 ) then
				return
			end
			
			local num = 0
			for k, v in next, users1:GetItems() do
				if v.Selected then
					num = num + 1
				end
			end
			
			if num > 0 then
				self.canclick = true
				self:SetText( "Invite (" .. num .. ")" )
			else
				self.canclick = false
				self:SetText( "Invite (0)" )
			end
			
		end
		
		function add:DoClick()
		
			slide.out = false
			PNL.Top.Invite.out = false
			self.out = false
			
			CHAT.Tick()
			
			local pos = Vector( CHAT.main:GetPos() )
			
			slide:MoveTo( pos.x + CHAT.main:GetWide() - 150, pos.y, 0.3, 0, 1, function()
				slide:Remove()
			end )
			
			local tab = {}
			for k, v in next, users1:GetItems() do
				table.insert( tab, v.User )
			end
			
			if table.getn( tab ) > 0 then
			
				net.Start( "InviteUsers" )
					net.WriteString( name )
					net.WriteTable( tab )
				net.SendToServer()
				
			end
			
		end
		
	end				
	
	PNL.Top.Leave = PNL.Top:Add( "DButton" )
	PNL.Top.Leave:SetPos( PNL.Top:GetWide() - 210, 0 )
	PNL.Top.Leave:SetSize( 100, 20 )
	PNL.Top.Leave:SetText( "Leave Group" )
	PNL.Top.Leave:SetTextColor( color_white )
	
	function PNL.Top.Leave:Think()
		self:SetPos( PNL.Top:GetWide() - 210, 0 )
	end
	
	function PNL.Top.Leave:Paint()
		surface.SetDrawColor( color_white )
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
	end
	
	function PNL.Top.Leave:DoClick()
		
		if CHAT.InGroupVoiceChat then
			PNL.Top.VoiceBtn:DoClick()
		end
		
		CHAT.Tick()
		CHAT.tabs:CloseTab( CHAT.CLGROUPS[ name ].Tab, true )
		CHAT.CLGROUPS[ name ] = nil
		
		net.Start( "LeaveGroup" )
			net.WriteString( name )
		net.SendToServer()
		
	end
	
	PNL.Top.VoiceBtn = PNL.Top:Add( "DButton" )
	PNL.Top.VoiceBtn:SetPos( PNL.Top:GetWide() - 320, 0 )
	PNL.Top.VoiceBtn:SetSize( 100, 20 )
	
	function PNL.Top.VoiceBtn:Think()
	
		self:SetPos( PNL.Top:GetWide() - 320, 0 )
		self:SetTextColor( color_white )
		
		if CHAT.InGroupVoiceChat then
			self:SetText( "Leave Voice" )
		else
			self:SetText( "Start Voice" )
		end
		
	end
	
	function PNL.Top.VoiceBtn:Paint()
		surface.SetDrawColor( color_white )
		surface.DrawOutlinedRect( 0, 0, self:GetSize() )
	end
	
	function PNL.Top.VoiceBtn:DoClick()
	
		CHAT.Tick()
		
		if CHAT.VoiceChatting then
			CHAT.Error( "You are already in a voice chat with " .. CHAT.VoiceChatting:Name() .. "!" )
			return
		end
		
		if CHAT._SentVoiceRequest or CHAT._VoiceRequest then
			CHAT.Error( "You already have a pending voice chat request" )
			return
		end
		
		if CHAT.InGroupVoiceChat ~= nil and CHAT.InGroupVoiceChat ~= name then
			CHAT.Error( "You are already in a voice chat with group " .. CHAT.InGroupVoiceChat .. "!" )
			return
		end
		
		if not CHAT.InGroupVoiceChat then
			net.Start( "JoinGroupVoice" )
				net.WriteString( name )
			net.SendToServer()
		else
			net.Start( "LeaveGroupVoice" )
				net.WriteString( name )
			net.SendToServer()
		end
		
	end
	
	PNL.Line = PNL:Add( "DPanel" )
	local pos = Vector( PNL.Top:GetPos() )
	PNL.Line:SetPos( 0, pos.y + PNL.Top:GetTall() )
	PNL.Line:SetSize( PNL:GetWide(), 1 )
	
	function PNL.Line:Think()
		self:SetSize( PNL:GetWide(), 1 )
	end
	
	function PNL.Line:Paint()
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawRect( 0, 0, self:GetSize() )
	end
	
	PNL.RT = PNL:Add( "RichText" )
	PNL.RT:SetPos( 0, 31 )
	
	function PNL.RT:Think()
		self:SetSize( PNL:GetWide() - 200, PNL:GetTall() - PNL.Top:GetTall() - 16 )
		self:Think2()
	end
	
	function PNL.RT:Think2()
		
	end
	
	function PNL.RT:Paint()
		self.m_FontName = "rtfont1"
		self:SetFontInternal( "rtfont1" )	
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawLine( self:GetWide() - 1, -1, self:GetWide() - 1, self:GetTall() )
	end
	
	PNL.RT:InsertColorChange( 255, 255, 255, 255 )	
	
	PNL.Users = PNL:Add( "DPanel" )
	PNL.Users:SetPos( PNL:GetWide() - 199, pos.y + PNL.Top:GetTall() )
	PNL.Users:SetSize( 198, PNL:GetTall() - 50 )
	
	function PNL.Users:Think()
		self:SetPos( PNL:GetWide() - 199, pos.y + PNL.Top:GetTall() + 2 )
		self:SetSize( 198, PNL:GetTall() - 50 )
	end
	
	function PNL.Users:Paint()
		return
	end
	
	PNL.Users.Title = PNL.Users:Add( "DLabel" )
	
	local _text = "Users"
	surface.SetFont( "asdf1" )
	local x = surface.GetTextSize( _text )
	
	PNL.Users.Title:SetPos( ( PNL.Users:GetWide() / 2 ) - ( x / 2 ) )
	PNL.Users.Title:SetFont( "asdf1" )
	PNL.Users.Title:SetTextColor( CHAT.TextBoxColor )
	PNL.Users.Title:SetText( "Users" )
	
	PNL.Users.List = PNL.Users:Add( "DPanelList" )
	PNL.Users.List:SetPos( 0, 20 )
	PNL.Users.List:SetSize( PNL.Users:GetWide() - 2, PNL.Users:GetTall() - 20 )
	PNL.Users.List:EnableVerticalScrollbar( true )
	PNL.Users.List:SetSpacing( 3 )
	
	PNL.Users.List.Paint = function( self )
		return
	end
	
	function PNL.Users.List:Think() 
		self:SetSize( PNL.Users:GetWide() - 2, PNL.Users:GetTall() - 20 )
	end
	
	function PNL.Users.List:AddUserPanel( ply )
	
		local pnl = vgui.Create( "DPanel" )
		pnl:SetSize( 200, 40 )
		
		function pnl:Paint()
		
			surface.SetDrawColor( CHAT.TextBoxColor )
			surface.DrawRect( 5, 0, self:GetSize() )
			
			if CHAT.GROUPS[ name ].Creator == ply then
			
				surface.SetDrawColor( Color( 200, 0, 0 ) )
				surface.DrawRect( self:GetWide() - 5, 0, 5, self:GetTall() )
				
				surface.SetDrawColor( CHAT.TextBoxColor )
				surface.DrawLine( self:GetWide() - 2, -1, self:GetWide() - 2, self:GetTall() )
				surface.DrawLine( self:GetWide() - 4, -1, self:GetWide() - 4, self:GetTall() )
				
			end
			
		end
		
		local av = pnl:Add( "AvatarImage" )
		av:SetPos( 7, 2 )
		av:SetSize( 36, 36 )
		av:SetPlayer( ply, 64 )
		
		local _name = pnl:Add( "DLabel" )
		_name:SetPos( 46, 3 )
		_name:SetFont( "asdf1" )
		_name:SetTextColor( color_white )
		_name:SetText( ply:Name() )
		_name:SetSize( 155, 20 )
		
		local inchat = pnl:Add( "DLabel" )
		inchat:SetPos( 47, 23 )
		if not table.HasValue( CHAT.GROUPS[ name ].Voice, ply ) then
			inchat:SetTextColor( CHAT.BGColor )
			inchat:SetText( "Not using voice chat" )				
		else
			inchat:SetTextColor( Color( 0, 255, 0, 255 ) )	
			inchat:SetText( "Using voice chat" )
		end
		inchat:SizeToContents()
		
		local btn = pnl:Add( "DButton" )
		btn:SetPos( 5, 0 )
		btn:SetSize( pnl:GetWide() - 5, pnl:GetTall() )
		btn:SetText( "" )
		
		function btn:Paint()
			return
		end
		
		function btn:DoRightClick()
		
			CHAT.Tick()
			
			local menu = vgui.Create( "DMenu", PNL )
			
				local function remove( self, pos )
				
					self:MoveToBack()
					
					self:MoveTo( pos.x + CHAT.main:GetWide() - 150, pos.y, 0.5, 0, 5, function()
						self:Remove()
					end )	
					
				end		
				
				if ULib.ucl.query( LocalPlayer(), "ulx kick" ) then
					menu:AddOption( "Kick", function()
					
						CHAT.Tick()
						
						if ValidPanel( CHAT.ban ) then	
							remove( CHAT.ban, Vector( CHAT.main:GetPos() ) )
						end			
						
						CHAT.kick = vgui.Create( "DFrame", vgui.GetWorldPanel() )
						CHAT.kick:SetSize( 150, 75 )
						CHAT.kick.StartAnimFinished = false
						CHAT.kick.removing = false
						CHAT.kick:SetTitle( "" )
						CHAT.kick:ShowCloseButton( false )
						CHAT.kick:MakePopup()
						CHAT.kick:MoveToBack()
						
						local pos = Vector( CHAT.main:GetPos() )
						CHAT.kick:SetPos( pos.x + CHAT.main:GetWide() - 150, pos.y )
						
						CHAT.kick:MoveTo( pos.x + CHAT.main:GetWide(), pos.y, 0.25, 0, 5, function()
							self.StartAnimFinished = true
						end )
						
						function CHAT.kick:Think()
						
							if not ValidPanel( CHAT.main ) then
								self:Remove()
								return
							end
							
							if not IsValid( ply ) then
								if not self.removing then
									self.removing = true
									remove( self, Vector( CHAT.main:GetPos() ) )
								end
							end
							
							if self.StartAnimFinished and not self.removing then
								local pos = Vector( CHAT.main:GetPos() )
								self:SetPos( pos.x + CHAT.main:GetWide(), pos.y )
							end
							
						end
						
						local name = ply:Name()
						function CHAT.kick:Paint()
							surface.SetDrawColor( CHAT.PropertyColor )
							surface.DrawRect( 0, 0, self:GetSize() )
							surface.SetFont( "DermaDefault" )
							surface.SetTextColor( color_white )
							surface.SetTextPos( 5, 5 )
							surface.DrawText( "Kicking " .. name .. "..." )
						end
						
						local close = vgui.Create( "DImageButton", CHAT.kick )
						close:SetPos( CHAT.kick:GetWide() - 18, 3 )
						close:SetSize( 16, 16 )
						close:SetImage( "icon16/control_rewind.png" )
						
						close.DoClick = function()
							remove( CHAT.kick, Vector( CHAT.main:GetPos() ) )
							CHAT.Tick()
						end		
						
						local reason = CHAT.kick:Add( "DTextEntry" )
						reason:SetPos( 5, 22 )
						reason:SetSize( CHAT.kick:GetWide() - 10, 20 )
						reason:SetText( "Reason" )
						reason:SetTextColor( color_white )
						reason:SetEditable( true )
						reason:AllowInput( true )
						reason:SetEnterAllowed( true )
						reason:SetKeyBoardInputEnabled( true )
						reason:SetMouseInputEnabled( true )
						
						function reason:Paint()
							surface.SetDrawColor( CHAT.PropertyColor )
							surface.DrawRect( 0, 0, self:GetSize() )
							surface.SetDrawColor( color_white )
							surface.DrawOutlinedRect( 0, 0, self:GetSize() )
							self:DrawTextEntryText( Color( 255, 255, 255, 255 ), CHAT.TextHighlightColor, Color( 255, 255, 255, 255 ) )
						end
						
						function reason:OnCursorEntered()
							if self:GetText() == "Reason" then
								self:SetText( "" )
							end
						end
						
						function reason:OnCursorExited()
							if self:GetText() == "" then
								self:SetText( "Reason" )
							end
						end		

						local exec = vgui.Create( "DButton", CHAT.kick )
						exec:SetPos( 5, 47 )
						exec:SetSize( reason:GetSize() )
						exec:SetText( "Kick" )
						
						function exec:Paint()
							self:SetTextColor( color_white )
							surface.SetDrawColor( color_white )
							surface.DrawOutlinedRect( 0, 0, self:GetSize() )
						end
						
						function exec:DoClick()
						
							local text = reason:GetText()
							
							if text:len() == 0 then
								return
							end
							
							RunConsoleCommand( "ulx", "kick", name, text )
							CHAT.Tick()
							
						end
						
						function reason:OnEnter()
							exec:DoClick()
						end
						
					end ):SetIcon( "icon16/disconnect.png" )
				end
				
				if ULib.ucl.query( LocalPlayer(), "ulx ban" ) then
					menu:AddOption( "Ban", function()
					
						CHAT.Tick()
						
						if ValidPanel( CHAT.kick ) then	
							remove( CHAT.kick, Vector( CHAT.main:GetPos() ) )
						end
						
						CHAT.ban = vgui.Create( "DFrame", vgui.GetWorldPanel() )
						CHAT.ban:SetSize( 150, 130 )
						CHAT.ban.StartAnimFinished = false
						CHAT.ban.removing = false
						CHAT.ban:SetTitle( "" )
						CHAT.ban:ShowCloseButton( false )
						CHAT.ban:MakePopup()
						CHAT.ban:MoveToBack()
						
						local pos = Vector( CHAT.main:GetPos() )
						CHAT.ban:SetPos( pos.x + CHAT.main:GetWide() - 150, pos.y )
						
						CHAT.ban:MoveTo( pos.x + CHAT.main:GetWide(), pos.y, 0.25, 0, 5, function()
							self.StartAnimFinished = true
						end )
						
						function CHAT.ban:Think()
						
							if not ValidPanel( CHAT.main ) then
								self:Remove()
								return
							end
							
							if not IsValid( ply ) then
								if not self.removing then
									self.removing = true
									remove( self, Vector( CHAT.main:GetPos() ) )
								end
							end
							
							if self.StartAnimFinished and not self.removing then
								local pos = Vector( CHAT.main:GetPos() )
								self:SetPos( pos.x + CHAT.main:GetWide(), pos.y )
							end
							
						end
						
						local name = ply:Name()
						function CHAT.ban:Paint()
							surface.SetDrawColor( CHAT.PropertyColor )
							surface.DrawRect( 0, 0, self:GetSize() )
							surface.SetFont( "DermaDefault" )
							surface.SetTextColor( color_white )
							surface.SetTextPos( 5, 5 )
							surface.DrawText( "Banning " .. name .. "..." )
						end
						
						local close = vgui.Create( "DImageButton", CHAT.ban )
						close:SetPos( CHAT.ban:GetWide() - 18, 3 )
						close:SetSize( 16, 16 )
						close:SetImage( "icon16/control_rewind.png" )
						
						close.DoClick = function()
							remove( CHAT.ban, Vector( CHAT.main:GetPos() ) )
							CHAT.Tick()
						end
						
						local reason = vgui.Create( "DTextEntry", CHAT.ban )
						reason:SetPos( 5, 22 )
						reason:SetSize( CHAT.ban:GetWide() - 10, 20 )
						reason:SetText( "Reason" )
						reason:SetTextColor( color_white )
						reason:SetEditable( true )
						reason:AllowInput( true )
						reason:SetEnterAllowed( true )
						reason:SetKeyBoardInputEnabled( true )
						reason:SetMouseInputEnabled( true )
						
						function reason:OnCursorEntered()
							if self:GetText() == "Reason" then
								self:SetText( "" )
							end
						end
						
						function reason:OnCursorExited()
							if self:GetText() == "" then
								self:SetText( "Reason" )
							end
						end
						
						function reason:Paint()
							surface.SetDrawColor( CHAT.PropertyColor )
							surface.DrawRect( 0, 0, self:GetSize() )
							surface.SetDrawColor( color_white )
							surface.DrawOutlinedRect( 0, 0, self:GetSize() )
							self:DrawTextEntryText( Color( 255, 255, 255, 255 ), CHAT.TextHighlightColor, Color( 255, 255, 255, 255 ) )
						end
						
						local combo = vgui.Create( "DComboBox", CHAT.ban )
						combo:SetPos( 5, 45 )
						combo:SetSize( CHAT.ban:GetWide() - 10, 20 )
						combo:SetTextColor( color_white )
						
						function combo:Paint()	
							self:SetTextColor( 255, 255, 255, 255 )
							surface.SetDrawColor( color_white )
							surface.DrawOutlinedRect( 0, 0, self:GetSize() )
						end
						
						function combo:OpenMenu( control )	
						
							if control then
								if control == self.TextEntry then
									return
								end
							end

							if table.getn( self.Choices ) == 0 then 
								return 
							end

							if IsValid( self.Menu ) then
								self.Menu:Remove()
								self.Menu = nil
							end

							self.Menu = DermaMenu()

							for k, v in pairs( self.Choices ) do
								self.Menu:AddOption( v, function() 
									self:ChooseOption( v, k ) 
								end )
							end

							local x, y = self:LocalToScreen( 0, self:GetTall() )
							
							function self.Menu:Paint()
								surface.SetDrawColor( CHAT.TextBoxColor )
								surface.DrawRect( 0, 0, self:GetSize() )
								surface.SetDrawColor( color_black )
								surface.DrawOutlinedRect( 0, 0, self:GetSize() )
							end
							
							self.Menu:SetMinimumWidth( self:GetWide() )
							self.Menu:Open( x, y, false, self )	
							
							return true
							
						end
						
						combo:AddChoice( "Permanent", 0, true )
						combo:AddChoice( "Minutes", 1 )
						combo:AddChoice( "Hours", 60 )
						combo:AddChoice( "Days", 1440 )
						combo:AddChoice( "Weeks", 10080 )
						combo:AddChoice( "Years", 43829 )
						
						function combo:OnSelect( index, value )
							local data = self.Data[ index ]
							self.curChoice = data
						end
						
						local slider = vgui.Create( "Slider", CHAT.ban )
						slider:SetPos( 5, 68 )
						slider:SetSize( CHAT.ban:GetWide() + 10, 20 )
						slider:SetDecimals( 0 )
						slider:SetMin( 0 )
						slider:SetMax( 100 )
						slider:SetValue( 1 )
						slider:SetDark( false )
						
						function slider:SetDisabled( value )
							if value then
								self:SetMouseInputEnabled( false )
							else
								self:SetMouseInputEnabled( true )
							end
						end
						
						function slider:Think()
						
							if combo:GetText() == "Permanent" then	
							
								self:SetMax( 1 )
								self:SetDisabled( true )
								
								return
							else
								self:SetDisabled( false )
							end
							
							if combo:GetText() == "Minutes" then
								self:SetMax( 1440 )
							elseif combo:GetText() == "Hours" then	
								self:SetMax( 168 )
							elseif combo:GetText() == "Days" then	
								self:SetMax( 120 )
							elseif combo:GetText() == "Weeks" then	
								self:SetMax( 52 )
							elseif combo:GetText() == "Years" then
								self:SetMax( 10 )
							end
							
							if self:GetValue() > self:GetMax() then
								self:SetValue( self:GetMax() )
							elseif self:GetValue() < self:GetMin() then	
								self:SetValue( self:GetMin() )
							end
							
						end
						
						local exec = vgui.Create( "DButton", CHAT.ban )
						exec:SetPos( 5, 100 )
						exec:SetSize( reason:GetSize() )
						exec:SetText( "Ban" )
						
						function exec:Paint()
							self:SetTextColor( color_white )
							surface.SetDrawColor( color_white )
							surface.DrawOutlinedRect( 0, 0, self:GetSize() )
						end
						
						function exec:DoClick()
						
							local text = reason:GetText()
							
							if text:len() == 0 then
								return
							end
							
							RunConsoleCommand( "ulx", "ban", name, tostring( slider:GetValue() * combo.curChoice ), text )
							CHAT.Tick()
							
						end
						
						function reason:OnEnter()
							exec:DoClick()
						end
						
					end ):SetIcon( "icon16/user_delete.png" )
				end
				
				if ULib.ucl.query( LocalPlayer(), "ulx slay" ) then
					menu:AddOption( "Slay", function()
						CHAT.Tick()
						RunConsoleCommand( "ulx", "slay", ply:Name() )
					end ):SetIcon( "icon16/cut_red.png" )
				end
				
				if ULib.ucl.query( LocalPlayer(), "ulx freeze" ) then
					if ply:IsFrozen() then
					
						menu:AddOption( "Unfreeze", function()
							CHAT.Tick()
							RunConsoleCommand( "ulx", "unfreeze", ply:Name() )
						end ):SetIcon( "icon16/wand.png" )		
						
					else
					
						menu:AddOption( "Freeze", function()
							CHAT.Tick()
							RunConsoleCommand( "ulx", "freeze", ply:Name() )
						end ):SetIcon( "icon16/wand.png" )		
						
					end
				end
				
				if ply ~= LocalPlayer() and CHAT.GROUPS[ name ].Creator == LocalPlayer() then
					menu:AddOption( "Kick from group", function()
						net.Start( "KickFromGroup" )
							net.WriteString( name )
							net.WriteEntity( ply )
						net.SendToServer()
					end ):SetIcon( "icon16/door_in.png" )
				end
				
			menu:SetMinimumWidth( 200 )
			local pos = Vector( CHAT.main:GetPos() )
			--menu:Open( pos.x + CHAT.main:GetWide() - 200 - 11, pos.y + ( self:GetTall() * 2 + 1 ) + 60 )
			menu:Open()
			
			function menu:Paint()
				surface.SetDrawColor( CHAT.TextBoxColor )
				surface.DrawRect( 0, 0, self:GetSize() )
				surface.SetDrawColor( color_black )
				surface.DrawOutlinedRect( 0, 0, self:GetSize() )
			end		
			
		end			

		self:AddItem( pnl )
	end
	
	function PNL.Users.List:_Rebuild()
	
		self:Clear()
		
		for k, v in next, CHAT.GROUPS[ name ].Members do
			self:AddUserPanel( v )
		end
		
	end
	
	PNL.Users.List:_Rebuild()
	
	PNL.StatusLine = PNL:Add( "DPanel" )
	PNL.StatusLine:SetPos( 0, PNL:GetTall() - 15 )
	PNL.StatusLine:SetSize( PNL:GetWide(), 1 )
	
	function PNL.StatusLine:Paint()
		surface.SetDrawColor( CHAT.TextBoxColor )
		surface.DrawRect( 0, 0, self:GetSize() )
	end
	
	function PNL.StatusLine:Think()
		PNL.StatusLine:SetPos( 0, PNL:GetTall() - 15 )
		PNL.StatusLine:SetSize( PNL:GetWide(), 1 )	
	end
	
	PNL.Status = PNL:Add( "DLabel" )
	PNL.Status:SetPos( 0, PNL:GetTall() - 13 )
	PNL.Status:SetTextColor( color_white )
	PNL.Status:SetFont( "DermaDefault" )
	PNL.Status:SetText( "" )
	
	function PNL.Status:Think()
		self:SetPos( 0, PNL:GetTall() - 13 )
		self:SizeToContents()
	end
	
	function PNL.Status:SetStatus( str )
		PNL.Status:SetText( str )
	end
	PNL.Status:SetStatus( "" )
	
	CHAT.CLGROUPS[ name ] = CHAT.AddGroupTab( name, PNL, "icon16/group.png", "Group Chat", users, textX )
	
	if textX then
		for k, v in next, textX do
		
			local str_tab = string.Split( v, "#####" )
			PNL.RT:InsertColorChange( 55, 133, 236, 255 )
			PNL.RT:AppendText( str_tab[ 1 ] )
			PNL.RT:InsertColorChange( 155, 220, 0, 255 )
			PNL.RT:AppendText( str_tab[ 2 ] )
			PNL.RT:InsertColorChange( 255, 255, 255, 255 )
			PNL.RT:AppendText( str_tab[ 3 ] .. "\n" )
			PNL.RT:InsertColorChange( 255, 255, 255, 255 )
			
		end
		PNL.RT:GotoTextEnd()
	end		

end

net.Receive( "NetworkGroupMessages", function()

	local name = net.ReadString()
	local text = net.ReadString()
	
	if CHAT.CLGROUPS[ name ] and ValidPanel( CHAT.main ) then
	
		local str_tab = string.Split( text, "#####" )
		CHAT.CLGROUPS[ name ].Panel.RT:InsertColorChange( 55, 133, 236, 255 )
		CHAT.CLGROUPS[ name ].Panel.RT:AppendText( str_tab[ 1 ] )
		CHAT.CLGROUPS[ name ].Panel.RT:InsertColorChange( 155, 220, 0, 255 )
		CHAT.CLGROUPS[ name ].Panel.RT:AppendText( str_tab[ 2 ] )
		CHAT.CLGROUPS[ name ].Panel.RT:InsertColorChange( 255, 255, 255, 255 )
		CHAT.CLGROUPS[ name ].Panel.RT:AppendText( str_tab[ 3 ] .. "\n" )
		CHAT.CLGROUPS[ name ].Panel.RT:InsertColorChange( 255, 255, 255, 255 )
		
	end
	
end )

net.Receive( "KickFromGroupCL", function()

	local name = net.ReadString()
	
	if CHAT.InGroupVoiceChat == name then
		CHAT.CLGROUPS[ name ].Panel.Top.VoiceBtn:DoClick()
	end
	
	CHAT.tabs:CloseTab( CHAT.CLGROUPS[ name ].Tab, true )
	CHAT.CLGROUPS[ name ] = nil

	if ValidPanel( CHAT.main ) then
		CHAT.Error( "You have been kicked from group \'" .. name .. "\'" )
	end
	
end )

net.Receive( "JoinGroupCL", function()

	local tab = net.ReadTable()
	CHAT.CreateGroupPanel( tab.Name, tab.Members, tab.Text )
	
	timer.Simple( 0, function()
		CHAT.tabs:SetActiveTab( CHAT.CLGROUPS[ tab.Name ].Tab )
	end )
	
end )

net.Receive( "JoinGroupVoiceCallback", function()

	local succ = tobool( net.ReadBit() )
	local err = net.ReadString()
	local name = net.ReadString()
	
	if ( not succ ) and err ~= "" then
		CHAT.Error( err )
		return
	end
	
	CHAT.InGroupVoiceChat = name
	
end )

net.Receive( "LeaveGroupVoiceCallback", function()
	CHAT.InGroupVoiceChat = nil
end )	

