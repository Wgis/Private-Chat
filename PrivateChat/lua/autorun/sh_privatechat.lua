////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Gmod private text/voice/group chat    																											  //
// Created by YVL (http://steamcommunity.com/id/__yvl/)		                 																		  //
// Design inspired by Metro For Steam	     																										  //
// http://metroforsteam.com/            																										  	  //
//                                      																											  //
// Special thanks to:																																  //
// - rbreslow for the lua cache decrypter because I almost lost this project halfway through thanks to ftp clients crashing and deleting my files	  //
// - Leystryku for linking me to the ^thread so I didn't have to go and google it																	  //
// - Valve for the cool voice chat sounds																											  //
// - Ian, Angus, Tim, Scott, and LuaTenshi for helping test, because I only have one computer														  //
//																																					  //
// !!BE CAREFUL WHAT YOU CHANGE IN THESE FILES!! 																										  //
// There is no config - All settings are handled clientside in-game																					  //
// With the exception of the toggle key variable which can be found in the clientside file															  //
// If you screw something up, re-install.																											  //
// If you find an error/glitch, add me on steam or create a support ticket. Please don't post it in the comments.									  //
//																																					  //
// To the buyer:																																	  //
// There is nothing I can do to stop you from leaking this,																							  //
// But it took me a long time to make, so use your best judgement.																					  //
// Put yourself in my shoes. I wear blue and white asics running shoes, you can probably find them at Dick's Sporting Goods.						  //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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