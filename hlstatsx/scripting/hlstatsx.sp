/**
 * HLstatsX Community Edition - SourceMod plugin to display ingame messages
 * http://www.hlxcommunity.com/
 * Copyright (C) 2008 Nicholas Hastings
 * Copyright (C) 2007-2008 TTS Oetzel & Goerz GmbH
 * Modified by Nicholas Hastings (psychonic) for use with HLstatsX Community Edition
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
 
#define REQUIRE_EXTENSIONS 
#include <sourcemod>
#include <keyvalues>
#include <menus>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
 
#define VERSION "1.5.6.7 | ECV (v3)"
#define CSS 1
#define DODS 2
#define L4D 3
#define TF 4
#define HL2MP 5
#define INSMOD 6
#define FF 7
#define ZPS 8
#define AOC 9
#define FOF 10
#define GES 11
#define EMPIRES 12

new gamemod = 0;
new String: team_list[16][64];

new Handle: hlx_block_chat_commands;
new Handle: hlx_message_prefix;
new Handle: hlx_protect_address;
new String: blocked_commands[][] = { "rank", "skill", "points", "place", "session", "session_data", 
                                     "kpd", "kdratio", "kdeath", "next", "load", "status", "servers", 
                                     "top20", "top10", "top5", "clans", "cheaters", "statsme", "weapons", 
                                     "weapon", "action", "actions", "accuracy", "targets", "target", "kills", 
                                     "kill", "player_kills", "cmd", "cmds", "command", "hlx_display 0", 
                                     "hlx_display 1", "hlx_teams 0", "hlx_teams 1", "hlx_hideranking", 
                                     "hlx_chat 0", "hlx_chat 1", "hlx_menu", "servers 1", "servers 2", 
                                     "servers 3", "hlx", "hlstatsx" };

new Handle:HLstatsXMenuMain;
new Handle:HLstatsXMenuAuto;
new Handle:HLstatsXMenuEvents;

new Handle: PlayerColorArray;

new ct_player_color   = -1;
new ts_player_color   = -1;
new blue_player_color = -1;
new red_player_color  = -1;

new String: message_cache[192];
new String: parsed_message_cache[192];
new cached_color_index;

new String: ct_models[4][] = {"models/player/ct_urban.mdl", 
                              "models/player/ct_gsg9.mdl", 
                              "models/player/ct_sas.mdl", 
                              "models/player/ct_gign.mdl"};
                                
new String: ts_models[4][] = {"models/player/t_phoenix.mdl", 
                              "models/player/t_leet.mdl", 
                              "models/player/t_arctic.mdl", 
                              "models/player/t_guerilla.mdl"};

new String: logmessage_ignore[512];
new String: message_prefix[64];

public Plugin:myinfo = {
	name = "HLstatsX CE Ingame Plugin",
	author = "psychonic | ECV by Recon",
	description = "Provides ingame functionality for interaction from an HLstatsX CE installation",
	version = VERSION,
	url = "http://www.hlxcommunity.com"
};


public OnPluginStart() 
{
	get_server_mod();

	CreateHLstatsXMenuMain(HLstatsXMenuMain);
	CreateHLstatsXMenuAuto(HLstatsXMenuAuto);
	CreateHLstatsXMenuEvents(HLstatsXMenuEvents);

	clear_message_cache();

	RegServerCmd("hlx_sm_psay",          hlx_sm_psay);
	RegServerCmd("hlx_sm_psay2",         hlx_sm_psay2);
	RegServerCmd("hlx_sm_bulkpsay",      hlx_sm_bulkpsay);
	RegServerCmd("hlx_sm_csay",          hlx_sm_csay);
	RegServerCmd("hlx_sm_msay",          hlx_sm_msay);
	RegServerCmd("hlx_sm_tsay",          hlx_sm_tsay);
	RegServerCmd("hlx_sm_hint",          hlx_sm_hint);
	RegServerCmd("hlx_sm_browse",        hlx_sm_browse);
	RegServerCmd("hlx_sm_swap",          hlx_sm_swap);
	RegServerCmd("hlx_sm_redirect",      hlx_sm_redirect);
	RegServerCmd("hlx_sm_player_action", hlx_sm_player_action);
	RegServerCmd("hlx_sm_team_action",   hlx_sm_team_action);
	RegServerCmd("hlx_sm_world_action",  hlx_sm_world_action);

	if (gamemod == INSMOD)
	{
		RegConsoleCmd("say",                 hlx_block_commands);
		RegConsoleCmd("say2",                hlx_block_commands);
		RegConsoleCmd("say_team",            hlx_block_commands);
	}
	else
	{
		RegConsoleCmd("say",                 hlx_block_commands);
		RegConsoleCmd("say_team",            hlx_block_commands);
	}

	HookEvent("player_death", HLstatsX_Event_PlyDeath, EventHookMode_Pre);
	HookEvent("player_team",  HLstatsX_Event_PlyTeamChange, EventHookMode_Pre);
	
	CreateConVar("hlxce_plugin_version", VERSION, "HLstatsX CE Ingame Plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("hlx_webpage", "http://www.hlxcommunity.com", "http://www.hlxcommunity.com", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hlx_block_chat_commands = CreateConVar("hlx_block_commands", "1", "If activated HLstatsX commands are blocked from the chat area", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hlx_message_prefix = CreateConVar("hlx_message_prefix", "", "Define the prefix displayed on every HLstatsX ingame message");
	HookConVarChange(hlx_message_prefix, OnMessagePrefixChange);
	hlx_protect_address = CreateConVar("hlx_protect_address", "", "Address to be protected for logging/forwarding");
	HookConVarChange(hlx_protect_address, OnProtectAddressChange);
	
	RegServerCmd("log", ProtectLoggingChange);
	RegServerCmd("logaddress_del", ProtectForwardingChange);
	RegServerCmd("logaddress_delall", ProtectForwardingDelallChange);
	RegServerCmd("hlx_message_prefix_clear", MessagePrefixClear);

	PlayerColorArray = CreateArray();
	
	CreateTimer(1.0, LogMap);
}


public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("CS_SwitchTeam");
	MarkNativeAsOptional("CS_RespawnPlayer");
	
	return true;
}


public OnMapStart()
{
	if (gamemod == 0)
		get_server_mod();

	//psychonic - added other supported games to team tracking
	if ((gamemod == CSS) || (gamemod == TF) || (gamemod == DODS) || (gamemod == HL2MP) || (gamemod == FF) || (gamemod == ZPS) || (gamemod == AOC) || (gamemod == L4D) || (gamemod == GES) || (gamemod == EMPIRES))
	{
		new max_teams_count = GetTeamCount();
		for (new team_index = 0; (team_index < max_teams_count); team_index++)
		{
			decl String: team_name[64];
			GetTeamName(team_index, team_name, 64);
			if (strcmp(team_name, "") != 0)
			{
				team_list[team_index] = team_name;
			}
		}
	}
	
	clear_message_cache();

	if (gamemod == CSS)
	{
		ct_player_color = -1;
		ts_player_color = -1;
		find_player_team_slot("CT");
		find_player_team_slot("TERRORIST");
	}
	else if (gamemod == TF)
	{
		blue_player_color = -1;
		red_player_color = -1;
		find_player_team_slot("Blue");
		find_player_team_slot("Red");
	}
}


get_server_mod()
{
	if (gamemod == 0)
	{
		new String: game_description[64];
		GetGameDescription(game_description, 64, true);
	
		if (StrContains(game_description, "Counter-Strike", false) != -1)
		{
			gamemod = CSS;
		}
		else if (StrContains(game_description, "Day of Defeat", false) != -1)
		{
			gamemod = DODS;
		}
		else if (StrContains(game_description, "Half-Life 2 Deathmatch", false) != -1)
		{
			gamemod = HL2MP;
		}
		else if (StrContains(game_description, "Team Fortress", false) != -1)
		{
			gamemod = TF;
		}
		else if (StrContains(game_description, "L4D", false) != -1)
		{
			gamemod = L4D;
		}
		else if (StrContains(game_description, "Insurgency", false) != -1)
		{
			gamemod = INSMOD;

		//psychonic - added detection for more supported games
		}
		else if (StrContains(game_description, "Fortress Forever", false) != -1)
		{
			gamemod = FF;
		}
		else if (StrContains(game_description, "ZPS", false) != -1)
		{
			gamemod = ZPS;
		}
		else if (StrContains(game_description, "Age of Chivalry", false) != -1)
		{
			gamemod = AOC;
		}
		
		// game mod could not detected, try further
		if (gamemod == 0)
		{
			new String: game_folder[64];
			GetGameFolderName(game_folder, 64);

			if (StrContains(game_folder, "cstrike", false) != -1)
			{
				gamemod = CSS;
			}
			else if (StrContains(game_folder, "dod", false) != -1)
			{
				gamemod = DODS;
			}
			else if (StrContains(game_folder, "hl2mp", false) != -1)
			{
				gamemod = HL2MP;
			}
			else if (StrContains(game_folder, "fistful_of_frags", false) != -1)
			{
				gamemod = FOF;
			}
			else if (StrContains(game_folder, "tf", false) != -1)
			{
				gamemod = TF;
			}
			else if (StrContains(game_folder, "left4dead", false) != -1)
			{
				gamemod = L4D;
			}
			else if (StrContains(game_folder, "insurgency", false) != -1)
			{
				gamemod = INSMOD;

			//psychonic - added detection for more supported games
			}
			else if (StrContains(game_folder, "FortressForever", false) != -1)
			{
				gamemod = FF;
			}
			else if (StrContains(game_folder, "zps", false) != -1)
			{
				gamemod = ZPS;
			}
			else if (StrContains(game_folder, "ageofchivalry", false) != -1)
			{
				gamemod = AOC;
			}
			else if (StrContains(game_folder, "gesource", false) != -1)
			{
				gamemod = GES;
			}
			else if (StrContains(game_folder, "empires", false) != -1)
			{
				gamemod = EMPIRES;
			}
			else
			{
				LogToGame("Mod Detection (HLstatsX): Failed (%s, %s)", game_description, game_folder);
			}
		}

		//psychonic - Hook log in AOC to handle headshots
		if ((gamemod == CSS) || (gamemod == DODS) || (gamemod == AOC) || (gamemod == FOF) || (gamemod == EMPIRES))
		{
			AddGameLogHook(HLstatsX_Event_GameLog);
		}

		if (gamemod == L4D)
		{
			HookEvent("survivor_rescued", HLstatsX_Event_RescueSurvivor);
			HookEvent("heal_success", HLstatsX_Event_Heal);
			HookEvent("revive_success", HLstatsX_Event_Revive);
			HookEvent("witch_harasser_set", HLstatsX_Event_StartleWitch);
			HookEvent("lunge_pounce", HLstatsX_Event_Pounce);
			HookEvent("player_now_it", HLstatsX_Event_Boomered);
			HookEvent("friendly_fire", HLstatsX_Event_L4DFF);
			HookEvent("award_earned", HLstatsX_Event_L4DAward);
		}
		else if (gamemod == TF)
		{
			//octo - added sound hook for sandvich event
			AddNormalSoundHook(NormalSHook:sound_hook);
			HookEvent("player_stealsandvich", HLstatsX_Event_StealSandvich);
			HookEvent("player_stunned", HLstatsX_Event_Stunned);
			HookEvent("player_extinguished", HLstatsX_Event_Extinguish);
			HookEvent("player_teleported", HLstatsX_Event_Teleport);
			HookEvent("player_jarated", HLstatsX_Event_Jarated);
		}
		else if (gamemod == AOC || gamemod == INSMOD)
		{
			//psychonic - Hook round end event to generate Round_Win action in log
			HookEvent("round_end",    HLstatsX_Event_RoundEnd);
		}
		else if (gamemod == GES)
		{
			//psychonic - Hook round end event to generate Round_Win action in log
			HookEvent("round_end",    HLstatsX_Event_GESRoundEnd);
			HookEvent("player_changeident",	HLstatsX_Event_GESRoleChange);
		}
		if (gamemod > 0)
		{
			LogToGame("Mod Detection (HLstatsX): %s [%d]", game_description, gamemod);
		}
	}
}

public Action:LogMap(Handle:timer)
{
	// Called 1 second after OnPluginStart since srcds does not log the first map loaded. Idea from Stormtrooper's "mapfix.sp" for psychostats
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	LogToGame("Loading map \"%s\"", map);
}

public OnProtectAddressChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, "") != 0)
	{
		decl String: log_command[192];
		Format(log_command, 192, "logaddress_add %s", newVal);
		LogToGame("Command: %s", log_command);
		ServerCommand(log_command);
	}
}

// octo - generate sandvich action in log
public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	new player_index = clients[0];
	if(StrEqual(sample,"vo/SandwichEat09.wav") && (player_index == entity))
	{
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			log_player_event(player_index, "triggered", "sandvich");
		}
	}
}
//end octo

public Action:ProtectLoggingChange(args)
{
	if (hlx_protect_address != INVALID_HANDLE)
	{
		decl String: protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0)
		{
			if (args >= 1)
			{
				decl String: log_action[192];
				GetCmdArg(1, log_action, 192);
				if ((strcmp(log_action, "off") == 0) || (strcmp(log_action, "0") == 0))
				{
					LogToGame("HLstatsX address protection active, logging reenabled!");
					ServerCommand("log 1");
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action:ProtectForwardingChange(args)
{
	if (hlx_protect_address != INVALID_HANDLE)
	{
		decl String: protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0)
		{
			if (args == 1)
			{
				decl String: log_action[192];
				GetCmdArg(1, log_action, 192);
				if (strcmp(log_action, protect_address) == 0)
				{
					decl String: log_command[192];
					Format(log_command, 192, "logaddress_add %s", protect_address);
					LogToGame("HLstatsX address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			}
			else if (args > 1)
			{
				new String: log_action[192];
				for(new i = 1; i <= args; i++)
				{
					decl String: temp_argument[192];
					GetCmdArg(i, temp_argument, 192);
					strcopy(log_action[strlen(log_action)], 192, temp_argument);
				}
				if (strcmp(log_action, protect_address) == 0)
				{
					decl String: log_command[192];
					Format(log_command, 192, "logaddress_add %s", protect_address);
					LogToGame("HLstatsX address protection active, logaddress readded!");
					ServerCommand(log_command);
				}
			
			}
		}
	}
	return Plugin_Continue;
}


public Action:ProtectForwardingDelallChange(args)
{
	if (hlx_protect_address != INVALID_HANDLE)
	{
		decl String: protect_address[192];
		GetConVarString(hlx_protect_address, protect_address, 192);
		if (strcmp(protect_address, "") != 0)
		{
			decl String: log_command[192];
			Format(log_command, 192, "logaddress_add %s", protect_address);
			LogToGame("HLstatsX address protection active, logaddress readded!");
			ServerCommand(log_command);
		}
	}
	return Plugin_Continue;
}


public OnMessagePrefixChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	strcopy(message_prefix, 64, newVal);
}


public Action:MessagePrefixClear(args)
{
	message_prefix = "";
}

log_player_event(client, String: verb[32], String: player_event[192], display_location = 0)
{
	if (client > 0)
	{
		decl String: player_name[32];
		if (!GetClientName(client, player_name, 32))
		{
			strcopy(player_name, 32, "UNKNOWN");
		}

		decl String: player_authid[32];
		if (!GetClientAuthString(client, player_authid, 32))
		{
			strcopy(player_authid, 32, "UNKNOWN");
		}
		new player_team_index = GetClientTeam(client);
		decl String: player_team[64];
		
		//trawa - since INSMOD does not return team names correctly
		if (gamemod == INSMOD)
		{
			get_insmod_teamname(player_team_index, player_team, sizeof(player_team));
		}
		else
		{
			player_team = team_list[player_team_index];
		}
		new user_id = GetClientUserId(client);
		
		if (display_location > 0)
		{
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);
			Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" %s \"%s\"", player_name, user_id, player_authid, player_team, verb, player_event); 
			LogToGame("\"%s<%d><%s><%s>\" %s \"%s\" (position \"%d %d %d\")", player_name, user_id, player_authid, player_team, verb, player_event, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		}
		else
		{
			LogToGame("\"%s<%d><%s><%s>\" %s \"%s\"", player_name, user_id, player_authid, player_team, verb, player_event); 
		}
	}
}

log_playerplayer_event(client, victim, String: verb[32], String: player_event[192], display_location = 0)
{
	if (client > 0 && victim > 0)
	{
		decl String: player_name[32];
		if (!GetClientName(client, player_name, 32))
		{
			strcopy(player_name, 32, "UNKNOWN");
		}
		decl String: victim_name[32];
		if (!GetClientName(victim, victim_name, 32))
		{
			strcopy(victim_name, 32, "UNKNOWN");
		}

		decl String: player_authid[32];
		if (!GetClientAuthString(client, player_authid, 32))
		{
			strcopy(player_authid, 32, "UNKNOWN");
		}
		decl String: victim_authid[32];
		if (!GetClientAuthString(victim, victim_authid, 32))
		{
			strcopy(victim_authid, 32, "UNKNOWN");
		}
		new player_team_index = GetClientTeam(client);
		decl String: player_team[64];
		new victim_team_index = GetClientTeam(victim);
		decl String: victim_team[64];
		
		if (gamemod == INSMOD)
		{
			get_insmod_teamname(player_team_index, player_team, sizeof(player_team));
			get_insmod_teamname(victim_team_index, victim_team, sizeof(victim_team));
		}
		else
		{
			player_team = team_list[player_team_index];
			victim_team = team_list[victim_team_index];
		}
		new player_user_id = GetClientUserId(client);
		new victim_user_id = GetClientUserId(victim);
		
		if (display_location > 0)
		{
			new Float: player_origin[3];
			GetClientAbsOrigin(client, player_origin);
			Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" %s \"%s\" against \"%s<%d><%s><%s>\"", player_name, player_user_id, player_authid, player_team, verb, player_event, victim_name, victim_user_id, victim_authid, victim_team); 
			LogToGame("\"%s<%d><%s><%s>\" %s \"%s\" against \"%s<%d><%s><%s>\" (position \"%d %d %d\")", player_name, player_user_id, player_authid, player_team, verb, player_event, victim_name, victim_user_id, victim_authid, victim_team, RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2])); 
		}
		else
		{
			LogToGame("\"%s<%d><%s><%s>\" %s \"%s\" against \"%s<%d><%s><%s>\"", player_name, player_user_id, player_authid, player_team, verb, player_event, victim_name, victim_user_id, victim_authid, victim_team); 
		}
	}
}

get_insmod_teamname(team_index, String:team_name[], maxlen)
{
	//trawa - since INSMOD does not return team names correctly
	switch(team_index)
	{
		case 1:
			strcopy(team_name, maxlen, "U.S. Marines");
		case 2:
			strcopy(team_name, maxlen, "Iraqi Insurgents");
		case 3:
			strcopy(team_name, maxlen, "SPECTATOR");
		default:
			strcopy(team_name, maxlen, "Unassigned");
	}
}

// not used yet
stock log_admin_event(client, const String: admin_event[])
{
	if (client > 0)
	{
		decl String: player_name[32];
		if (!GetClientName(client, player_name, 32))
		{
			strcopy(player_name, 32, "UNKNOWN");
		}

		decl String: player_authid[32];
		if (!GetClientAuthString(client, player_authid, 32))
		{
			strcopy(player_authid, 32, "UNKNOWN");
		}

		new player_team_index = GetClientTeam(client);
		decl String: player_team[64];
		player_team = team_list[player_team_index];

		LogToGame("[SOURCEMOD]: \"%s<%s><%s>\" %s \"%s\"", player_name, player_authid, player_team, "executed", admin_event); 
	}
	else
	{
		LogToGame("[SOURCEMOD]: \"<SERVER>\" %s \"%s\"", "executed", admin_event); 
	}
}


find_player_team_slot(String: team[64]) 
{
	if ((gamemod == CSS) || (gamemod == TF))
	{
		new team_index = get_team_index(team);
		if (team_index > -1)
		{
			if (strcmp(team, "CT") == 0)
			{
				ct_player_color = -1;
			}
			else if (strcmp(team, "TERRORIST") == 0)
			{
				ts_player_color = -1;
			}
			else if (strcmp(team, "Blue") == 0)
			{
				blue_player_color = -1;
			}
			else if (strcmp(team, "Red") == 0)
			{
				red_player_color = -1;
			}

			new max_clients = GetMaxClients();
			for(new i = 1; i <= max_clients; i++)
			{
				new player_index = i;
				if ((IsClientConnected(player_index)) && (IsClientInGame(player_index)))
				{
					new player_team_index = GetClientTeam(player_index);
					if (player_team_index == team_index)
					{
						if (strcmp(team, "CT") == 0)
						{
							ct_player_color = player_index;
							if (ts_player_color == ct_player_color)
							{
								ct_player_color = -1;
								ts_player_color = -1;
							}
							break;
						}
						else if (strcmp(team, "TERRORIST") == 0)
						{
							ts_player_color = player_index;
							if (ts_player_color == ct_player_color)
							{
								ct_player_color = -1;
								ts_player_color = -1;
							}
							break;
						}
						else if (strcmp(team, "Blue") == 0)
						{
							blue_player_color = player_index;
							if (red_player_color == blue_player_color)
							{
								blue_player_color = -1;
								red_player_color = -1;
							}
							break;
						} else if (strcmp(team, "Red") == 0)
						{
							red_player_color = player_index;
							if (red_player_color == blue_player_color)
							{
								blue_player_color = -1;
								red_player_color = -1;
							}
							break;
						}
					}
				}
			}
		}
	}
}


stock validate_team_colors() 
{
	if (gamemod == CSS)
	{
		if (ct_player_color > -1)
		{
			if ((IsClientConnected(ct_player_color)) && (IsClientInGame(ct_player_color)))
			{
				new player_team_index = GetClientTeam(ct_player_color);
				decl String: player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("CT", player_team) != 0)
				{
					ct_player_color = -1;
				}
			}
			else
			{
				ct_player_color = -1;
			}
		}
		else if (ts_player_color > -1)
		{
			if ((IsClientConnected(ts_player_color)) && (IsClientInGame(ts_player_color)))
			{
				new player_team_index = GetClientTeam(ts_player_color);
				decl String: player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("TERRORIST", player_team) != 0)
				{
					ts_player_color = -1;
				}
			}
			else
			{
				ts_player_color = -1;
			}
		}
		if ((ct_player_color == -1) || (ts_player_color == -1))
		{
			if (ct_player_color == -1)
			{
				find_player_team_slot("CT");
			}
			if (ts_player_color == -1)
			{
				find_player_team_slot("TERRORIST");
			}
		}
	}
	else if (gamemod == TF)
	{
		if (blue_player_color > -1)
		{
			if ((IsClientConnected(blue_player_color)) && (IsClientInGame(blue_player_color)))
			{
				new player_team_index = GetClientTeam(blue_player_color);
				decl String: player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("Blue", player_team) != 0)
				{
					blue_player_color = -1;
				}
			}
			else
			{
				blue_player_color = -1;
			}
		}
		else if (red_player_color > -1)
		{
			if ((IsClientConnected(red_player_color)) && (IsClientInGame(red_player_color)))
			{
				new player_team_index = GetClientTeam(red_player_color);
				decl String: player_team[64];
				player_team = team_list[player_team_index];
				if (strcmp("Red", player_team) != 0) 
				{
					red_player_color = -1;
				}
			}
			else
			{
				red_player_color = -1;
			}
		}
		if ((blue_player_color == -1) || (red_player_color == -1))
		{
			if (blue_player_color == -1)
			{
				find_player_team_slot("Blue");
			}
			if (red_player_color == -1)
			{
				find_player_team_slot("Red");
			}
		}
	}
}


add_message_cache(String: message[192], String: parsed_message[192], color_index)
{
	message_cache = message;
	parsed_message_cache = parsed_message;
	cached_color_index = color_index;
}


is_message_cached(String: message[192])
{
	if (strcmp(message, message_cache) == 0)
	{
		return 1;
	}
	return 0;
}


clear_message_cache()
{
	message_cache = "";
	parsed_message_cache = "";
	cached_color_index = -1;
}


public OnClientDisconnect(client)
{
	if (client > 0)
	{
		if (gamemod == CSS)
		{
			if ((ct_player_color == -1) || (client == ct_player_color))
			{
				ct_player_color = -1;
				clear_message_cache();
			}
			else if ((ts_player_color == -1) || (client == ts_player_color))
			{
				ts_player_color = -1;
				clear_message_cache();
			}
		}
		else if (gamemod == TF)
		{
			if ((blue_player_color == -1) || (client == blue_player_color))
			{
				blue_player_color = -1;
				clear_message_cache();
			}
			else if ((red_player_color == -1) || (client == red_player_color))
			{
				red_player_color = -1;
				clear_message_cache();
			}
		}
	}
}


color_player(color_type, player_index, String: client_message[192]) 
{
	new color_player_index = -1;
	if ((gamemod == CSS) || (gamemod == TF) || (gamemod == ZPS) || (gamemod == GES))
	{
		decl String: client_name[192];
		GetClientName(player_index, client_name, 192);
		
		if (color_type == 1)
		{
			decl String: colored_player_name[192];
			switch (gamemod)
			{
				case ZPS:
					Format(colored_player_name, 192, "\x05%s\x01", client_name);
				case GES:
					Format(colored_player_name, 192, "\x04%s\x01", client_name);
				default:
					Format(colored_player_name, 192, "\x03%s\x01", client_name);
			}
			if (ReplaceString(client_message, 192, client_name, colored_player_name) > 0)
			{
				return player_index;
			}
		}
		else
		{
			decl String: colored_player_name[192];
			switch (gamemod)
			{
				case ZPS:
					Format(colored_player_name, 192, "\x05%s\x01", client_name);
				case GES:
					Format(colored_player_name, 192, "\x05%s\x01", client_name);
				default:
					Format(colored_player_name, 192, "\x04%s\x01", client_name);
			}
			ReplaceString(client_message, 192, client_name, colored_player_name);
		}
	}
	else if (gamemod == FF)
	{
		decl String: client_name[192];
		GetClientName(player_index, client_name, 192);
		
		new team = GetClientTeam(player_index);
		if (team > 1 && team < 6)
		{
			decl String: colored_player_name[192];
			Format(colored_player_name, 192, "^%d%s^0", (team-1), client_name);
			if (ReplaceString(client_message, 192, client_name, colored_player_name) > 0)
			{
				return player_index;
			}
		}
	}
	return color_player_index;
}


color_all_players(String: message[192]) 
{
	new color_index = -1;
	if (PlayerColorArray != INVALID_HANDLE)
	{
		ClearArray(PlayerColorArray);
		if ((gamemod == CSS) || (gamemod == TF) || (gamemod == ZPS) || (gamemod == FF) || (gamemod == GES))
		{

			new lowest_matching_pos = 192;
			new lowest_matching_pos_client = -1;

			new max_clients = GetMaxClients();
			for(new i = 1; i <= max_clients; i++) {
				new client = i;
				if ((IsClientConnected(client)) && (IsClientInGame(client)))
				{
					decl String: client_name[32];
					GetClientName(client, client_name, 32);
					new message_pos = StrContains(message, client_name);
					if (message_pos > -1)
					{
						if (lowest_matching_pos > message_pos)
						{
							lowest_matching_pos = message_pos;
							lowest_matching_pos_client = client;
						}
						new TempPlayerColorArray[1];
						TempPlayerColorArray[0] = client;
						PushArrayArray(PlayerColorArray, TempPlayerColorArray);
					}
				}
			}
			new size = GetArraySize(PlayerColorArray);
			for (new i = 0; i < size; i++)
			{
				new temp_player_array[1];
				GetArrayArray(PlayerColorArray, i, temp_player_array);
				new temp_client = temp_player_array[0];
				if (temp_client == lowest_matching_pos_client)
				{
					new temp_color_index = color_player(1, temp_client, message);
					color_index = temp_color_index;
				}
				else
				{
					color_player(0, temp_client, message);
				}
			}
			ClearArray(PlayerColorArray);
		}
	}
	
	return color_index;
}


get_team_index(String: team_name[])
{
	new loop_break = 0;
	new index = 0;
	while ((loop_break == 0) && (index < sizeof(team_list)))
	{
   	    if (strcmp(team_name, team_list[index], true) == 0)
		{
       		loop_break++;
        }
   	    index++;
	}
	if (loop_break == 0)
	{
		return -1;
	}
	else
	{
		return index - 1;
	}
}


remove_color_entities(String: message[192])
{
	ReplaceString(message, 192, "x05", "");
	ReplaceString(message, 192, "x04", "");
	ReplaceString(message, 192, "x03", "");
	ReplaceString(message, 192, "x01", "");
}


color_entities(String: message[192])
{
	ReplaceString(message, 192, "x05", "\x05");
	ReplaceString(message, 192, "x04", "\x04");
	ReplaceString(message, 192, "x03", "\x03");
	ReplaceString(message, 192, "x01", "\x01");
}


color_team_entities(String: message[192])
{
	if (gamemod == CSS)
	{
		if (ts_player_color > -1)
		{
			if (ReplaceString(message, 192, "TERRORIST", "\x03TERRORIST\x01") == 0)
			{
				if (ct_player_color > -1)
				{
					if (ReplaceString(message, 192, "CT", "\x03CT\x01") > 0)
					{
						return ct_player_color;
					}
				}
			}
			else
			{
				return ts_player_color;
			}
		}
		else
		{
			if (ct_player_color > -1)
			{
				if (ReplaceString(message, 192, "CT", "\x03CT\x01") > 0)
				{
					return ct_player_color;
				}
			}
		}
	}
	else if (gamemod == TF)
	{
		if (red_player_color > -1)
		{
			if (ReplaceString(message, 192, "Red", "\x03Red\x01") == 0)
			{
				if (blue_player_color > -1)
				{
					if (ReplaceString(message, 192, "Blue", "\x03Blue\x01") > 0)
					{
						return blue_player_color;
					}
				}
			}
			else
			{
				return red_player_color;
			}
		}
		else
		{
			if (blue_player_color > -1)
			{
				if (ReplaceString(message, 192, "Blue", "\x03Blue\x01") > 0)
				{
					return blue_player_color;
				}
			}
		}
	}
	
	return -1;
}


display_menu(player_index, time, String: full_message[1024], need_handler = 0)
{
	new String: display_message[1024];
	new offset = 0;
	new message_length = strlen(full_message); 
	for(new i = 0; i < message_length; i++)
	{
		if (i > 0)
		{
			if ((full_message[i-1] == 92) && (full_message[i] == 110))
			{
				new String: buffer[1024];
				strcopy(buffer, (i - offset), full_message[offset]);
				if (strlen(display_message) == 0)
				{
					strcopy(display_message[strlen(display_message)], strlen(buffer) + 1, buffer); 
				}
				else
				{
					display_message[strlen(display_message)] = 10;
					strcopy(display_message[strlen(display_message)], strlen(buffer) + 1, buffer); 
				}
				i++;
				offset = i;
			}
		}
	}
	if (need_handler == 0)
	{
		InternalShowMenu(player_index, display_message, time);
	}
	else
	{
		InternalShowMenu(player_index, display_message, time, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9), InternalMenuHandler);
	}
}


public InternalMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	if ((IsClientConnected(client)) && (IsClientInGame(client)))
	{
		if (action == MenuAction_Select)
		{
			decl String: player_event[192];
			IntToString(param2, player_event, 192);
			log_player_event(client, "selected", player_event);
		}
		else if (action == MenuAction_Cancel)
		{
			new String: player_event[192] = "cancel";
			log_player_event(client, "selected", player_event);
		}
	}
}

public Action:hlx_sm_bulkpsay(args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_bulkpsay <X,X,X,X,X,X,X,X> - sends private message to multiple users (replace each X with a userid or with nothing ex. (24,28,33,,,,,)");
		return Plugin_Handled;
	}
	new String:client_ids[8][6];
	decl String: client_id_list[48];
	GetCmdArg(1, client_id_list, sizeof(client_id_list));
	ExplodeString(client_id_list, ",", client_ids, sizeof(client_ids), sizeof(client_ids[]));

	decl String: colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new is_colored = 0;
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0)
	{
		is_colored = 1;
		ignore_param = 1;
	}
	if (strcmp(colored_param, "0") == 0)
	{
		ignore_param = 1;
	}

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = (1 + ignore_param); i < argument_count; i++)
	{
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);

		if (i > (1 + ignore_param))
		{
			if ((191 - strlen(client_message)) > strlen(temp_argument))
			{
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125))
				{
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				}
				else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44))
				{
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0))
					{
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
				else
				{
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		}
		else
		{
			if ((192 - strlen(client_message)) > strlen(temp_argument))
			{
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}
	for (new i = 0; i < 8; i++)
	{
		new client = StringToInt(client_ids[i]);
		if (client > 0)
		{
			new player_index = GetClientOfUserId(client);
			if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
			{
				new color_index = player_index;
				decl String: display_message[192];
				if ((gamemod == CSS) || (gamemod == TF) || (gamemod == ZPS) || (gamemod == GES) || (gamemod == EMPIRES))
				{
					if (is_colored > 0)
					{
						if (is_message_cached(client_message) > 0)
						{
							client_message = parsed_message_cache;
							color_index = cached_color_index;
						}
						else
						{
							decl String: client_message_backup[192];
							strcopy(client_message_backup, 192, client_message);
							
							validate_team_colors();
							color_index = color_team_entities(client_message);
							color_entities(client_message);
							add_message_cache(client_message_backup, client_message, color_index);
						}
					}
					if (strcmp(message_prefix, "") == 0)
					{
						Format(display_message, 192, "\x01%s", client_message);
					}
					else
					{
						Format(display_message, 192, "\x04%s\x01 %s", message_prefix, client_message);
					}
					if ((gamemod == CSS) || (gamemod == TF))
					{
						new Handle:hBf;
						hBf = StartMessageOne("SayText2", player_index);
						if (hBf != INVALID_HANDLE)
						{
							BfWriteByte(hBf, color_index); 
							BfWriteByte(hBf, 0); 
							BfWriteString(hBf, display_message);
							EndMessage();
						}
					}
					else
					{
						PrintToChat(player_index, display_message);
					}
				}
				else if (gamemod == INSMOD)
				{
					new prefix = 0;
					if (strcmp(message_prefix, "") != 0)
					{
						prefix = 1;
						Format(display_message, 192, "%s: %s", message_prefix, client_message);
					}
					// thanks to Fyren and IceMatrix for help with this
					new Handle:hBf;
					hBf = StartMessageOne("SayText", player_index);
					if (hBf != INVALID_HANDLE)
					{
						BfWriteByte(hBf, 1); 
						BfWriteBool(hBf, true);
						BfWriteByte(hBf, player_index); 
						
						if (prefix == 0)
						{
							BfWriteString(hBf, client_message);
						}
						else
						{
							BfWriteString(hBf, display_message);
						}
						EndMessage();
					}
				}
				else if (gamemod == FF)
				{
					// thanks to hlstriker for help with this

					if (strcmp(message_prefix, "") == 0)
					{
						Format(display_message, 192, "\x02^4%s\x0D\x0A", client_message);
					}
					else
					{
						Format(display_message, 192, "\x02^4%s: %s\x0D\x0A", message_prefix, client_message);
					}
					
					new Handle:hBf;
					hBf = StartMessageOne("SayText", player_index);
					if (hBf != INVALID_HANDLE)
					{
						BfWriteString(hBf, display_message);
						BfWriteByte(hBf, 1);
						EndMessage();
					}
				}
				else if (gamemod == FOF)
				{
					new prefix = 0;
					if (strcmp(message_prefix, "") != 0)
					{
						prefix = 1;
						Format(display_message, 192, "%s: %s", message_prefix, client_message);
					}
					new Handle:hBf;
					hBf = StartMessageOne("SayText", player_index);
					if (hBf != INVALID_HANDLE)
					{
						BfWriteByte(hBf, player_index);						
						if (prefix == 0)
						{
							BfWriteString(hBf, client_message);
						}
						else
						{
							BfWriteString(hBf, display_message);
						}
						BfWriteByte(hBf, 10);
						BfWriteByte(hBf, 0);
						BfWriteByte(hBf, 1);
						EndMessage();
					}
				}
				else
				{
					if (strcmp(message_prefix, "") == 0)
					{
						Format(display_message, 192, "%s", client_message);
					}
					else
					{
						Format(display_message, 192, "%s %s", message_prefix, client_message);
					}
					PrintToChat(player_index, display_message);
				}	
			}	
		}
	}
	
	return Plugin_Handled;
}

public Action:hlx_sm_psay(args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_psay <userid><colored><message> - sends private message");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	decl String: colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new is_colored = 0;
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0)
	{
		is_colored = 1;
		ignore_param = 1;
	}
	if (strcmp(colored_param, "0") == 0)
	{
		ignore_param = 1;
	}

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = (1 + ignore_param); i < argument_count; i++)
	{
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);

		if (i > (1 + ignore_param))
		{
			if ((191 - strlen(client_message)) > strlen(temp_argument))
			{
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125))
				{
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				}
				else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44))
				{
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0))
					{
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
				else
				{
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		}
		else
		{
			if ((192 - strlen(client_message)) > strlen(temp_argument))
			{
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}
	
	new client = StringToInt(client_id);
	if (client > 0)
	{
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			new color_index = player_index;
			decl String: display_message[192];
			if ((gamemod == CSS) || (gamemod == TF) || (gamemod == ZPS) || (gamemod == GES) || (gamemod == EMPIRES))
			{
				if (is_colored > 0)
				{
					if (is_message_cached(client_message) > 0)
					{
						client_message = parsed_message_cache;
						color_index = cached_color_index;
					}
					else
					{
						decl String: client_message_backup[192];
						strcopy(client_message_backup, 192, client_message);
					
						new player_color_index = color_all_players(client_message);
						if (player_color_index > -1)
						{
							color_index = player_color_index;
						}
						else
						{
							validate_team_colors();
							color_index = color_team_entities(client_message);
						}
						color_entities(client_message);
						add_message_cache(client_message_backup, client_message, color_index);
					}
				}
				if (strcmp(message_prefix, "") == 0)
				{
					Format(display_message, 192, "\x01%s", client_message);
				}
				else
				{
					Format(display_message, 192, "\x04%s\x01 %s", message_prefix, client_message);
				}
				if ((gamemod == CSS) || (gamemod == TF))
				{
					new Handle:hBf;
					hBf = StartMessageOne("SayText2", player_index);
					if (hBf != INVALID_HANDLE)
					{
						BfWriteByte(hBf, color_index); 
						BfWriteByte(hBf, 0); 
						BfWriteString(hBf, display_message);
						EndMessage();
					}
				}
				else
				{
					PrintToChat(player_index, display_message);
				}
			}
			else if (gamemod == INSMOD)
			{
				new prefix = 0;
				if (strcmp(message_prefix, "") != 0)
				{
					prefix = 1;
					Format(display_message, 192, "%s: %s", message_prefix, client_message);
				}
				// thanks to Fyren and IceMatrix for help with this
				new Handle:hBf;
				hBf = StartMessageOne("SayText", player_index);
				if (hBf != INVALID_HANDLE)
				{
					BfWriteByte(hBf, 1);
					BfWriteBool(hBf, true);
					BfWriteByte(hBf, player_index); 
					
					if (prefix == 0)
					{
						BfWriteString(hBf, client_message);
					}
					else
					{
						BfWriteString(hBf, display_message);
					}
					EndMessage();
				}
			}
			else if (gamemod == FF)
			{
				// thanks to hlstriker for help with this
				
				decl String: client_message_backup[192];
				strcopy(client_message_backup, 192, client_message);
			
				new player_color_index = color_all_players(client_message);
				if (player_color_index > -1)
				{
					color_index = player_color_index;
				}
				else
				{
					validate_team_colors();
					color_index = color_team_entities(client_message);
				}
				color_entities(client_message);
				add_message_cache(client_message_backup, client_message, color_index);
				

				
				if (strcmp(message_prefix, "") == 0)
				{
					Format(display_message, 192, "\x02%s\x0D\x0A", client_message);
				}
				else
				{
					Format(display_message, 192, "\x02^4%s:^ %s\x0D\x0A", message_prefix, client_message);
				}
				
				new Handle:hBf;
				hBf = StartMessageOne("SayText", player_index);
				if (hBf != INVALID_HANDLE)
				{
					BfWriteString(hBf, display_message);
					BfWriteByte(hBf, 1);
					EndMessage();
				}
			}
			else if (gamemod == FOF)
			{
				new prefix = 0;
				if (strcmp(message_prefix, "") != 0)
				{
					prefix = 1;
					Format(display_message, 192, "%s: %s", message_prefix, client_message);
				}
				new Handle:hBf;
				hBf = StartMessageOne("SayText", player_index);
				if (hBf != INVALID_HANDLE)
				{
					BfWriteByte(hBf, player_index);						
					if (prefix == 0)
					{
						BfWriteString(hBf, client_message);
					}
					else
					{
						BfWriteString(hBf, display_message);
					}
					BfWriteByte(hBf, 10);
					BfWriteByte(hBf, 0);
					BfWriteByte(hBf, 1);
					EndMessage();
				}
			}
			else
			{
				if (strcmp(message_prefix, "") == 0)
				{
					Format(display_message, 192, "%s", client_message);
				}
				else
				{
					Format(display_message, 192, "%s %s", message_prefix, client_message);
				}
				PrintToChat(player_index, display_message);
			}
			
		}	
	}
	
	return Plugin_Handled;
}


public Action:hlx_sm_psay2(args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_psay2 <userid><colored><message> - sends green colored private message");
		return Plugin_Handled;
	}
	
	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	decl String: colored_param[32];
	GetCmdArg(2, colored_param, 32);
	new ignore_param = 0;
	if (strcmp(colored_param, "1") == 0)
	{
		ignore_param = 1;
	}
	if (strcmp(colored_param, "0") == 0)
	{
		ignore_param = 1;
	}

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = (1 + ignore_param); i < argument_count; i++)
	{
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (i > (1 + ignore_param))
		{
			if ((191 - strlen(client_message)) > strlen(temp_argument))
			{
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125))
				{
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				}
				else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44))
				{
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0))
					{
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
				else
				{
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		}
		else
		{
			if ((192 - strlen(client_message)) > strlen(temp_argument))
			{
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if (client > 0)
	{
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			decl String:display_message[192];
			if ((gamemod == CSS) || (gamemod == DODS) || (gamemod == TF) || (gamemod == EMPIRES))
			{
				remove_color_entities(client_message);
				
				if (strcmp(message_prefix, "") == 0)
				{
					Format(display_message, 192, "\x04%s", client_message);
				}
				else
				{
					Format(display_message, 192, "\x04%s %s", message_prefix, client_message);
				}
				PrintToChat(player_index, display_message);
			}
			else
			{
				if (strcmp(message_prefix, "") == 0)
				{
					Format(display_message, 192, "%s", client_message);
				}
				else
				{
					Format(display_message, 192, "%s %s", message_prefix, client_message);
				}
				PrintToChat(player_index, display_message);
			}
		}	
	}
	return Plugin_Handled;
}


public Action:hlx_sm_csay(args)
{
	if (args < 1)
	{
		PrintToServer("Usage: hlx_sm_csay <message> - display center message");
		return Plugin_Handled;
	}

	new String: display_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 1; i <= argument_count; i++)
	{
		decl String: temp_argument[192];
		GetCmdArg(i, temp_argument, 192);
		if (i > 1)
		{
			if ((191 - strlen(display_message)) > strlen(temp_argument))
			{
				display_message[strlen(display_message)] = 32;
				strcopy(display_message[strlen(display_message)], 192, temp_argument);
			}
		}
		else
		{
			if ((192 - strlen(display_message)) > strlen(temp_argument))
			{
				strcopy(display_message[strlen(display_message)], 192, temp_argument);
			}
		}
	}

	if (strcmp(display_message, "") != 0)
	{
		PrintCenterTextAll(display_message);
	}
		
	return Plugin_Handled;
}


public Action:hlx_sm_msay(args)
{
	if (args < 3)
	{
		PrintToServer("Usage: hlx_sm_msay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	if (gamemod == HL2MP)
	{
		return Plugin_Handled;
	}
	
	if (CheckVoteDelay() != 0)
	{
		return Plugin_Handled;
	}
	
	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);
	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);
	decl String: handler_param[32];
	GetCmdArg(3, handler_param, 32);
	new ignore_param = 0;
	new need_handler = 0;
	if (strcmp(handler_param, "1") == 0)
	{
		need_handler = 1;
		ignore_param = 1;
	}
	if (strcmp(handler_param, "0") == 0)
	{
		need_handler = 1;
		ignore_param = 1;
	}

	new String: client_message[1024];
	new argument_count = GetCmdArgs();
	for(new i = (3 + ignore_param); i <= argument_count; i++)
	{
		decl String: temp_argument[1024];
		GetCmdArg(i, temp_argument, 1024);
		if (i > (3 + ignore_param))
		{
			if ((1023 - strlen(client_message)) > strlen(temp_argument))
			{
				client_message[strlen(client_message)] = 32;		
				strcopy(client_message[strlen(client_message)], 1024, temp_argument);
			}
		}
		else
		{
			if ((1024 - strlen(client_message)) > strlen(temp_argument))
			{
				strcopy(client_message[strlen(client_message)], 1024, temp_argument);
			}
		}
	}

	new time = StringToInt(display_time);
	if (time <= 0)
	{
		time = 10;
	}

	new client = StringToInt(client_id);
	if (client > 0)
	{
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			decl String: display_message[1024];
			strcopy(display_message, 1024, client_message);
			if (strcmp(display_message, "") != 0)
			{
				display_menu(player_index, time, display_message, need_handler);			
			}
		}	
	}
	
	return Plugin_Handled;
}


public Action:hlx_sm_tsay(args)
{
	if (args < 3)
	{
		PrintToServer("Usage: hlx_sm_tsay <time><userid><message> - sends hud message");
		return Plugin_Handled;
	}

	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);
	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 2; i < argument_count; i++)
	{
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (i > 2)
		{
			if ((191 - strlen(client_message)) > strlen(temp_argument))
			{
				client_message[strlen(client_message)] = 32;		
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
		else
		{
			if ((192 - strlen(client_message)) > strlen(temp_argument))
			{
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(client_message, "") != 0))
	{
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			new Handle:values = CreateKeyValues("msg");
			KvSetString(values, "title", client_message);
			KvSetNum(values, "level", 1); 
			KvSetString(values, "time", display_time); 
			CreateDialog(player_index, values, DialogType_Msg);
			CloseHandle(values);
		}	
	}		
		
	return Plugin_Handled;
}


public Action:hlx_sm_hint(args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_hint <userid><message> - send hint message");
		return Plugin_Handled;
	}

	if (gamemod == HL2MP)
	{
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	new String: client_message[192];
	new argument_count = GetCmdArgs();
	for(new i = 1; i < argument_count; i++)
	{
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (i > 1)
		{
			if ((191 - strlen(client_message)) > strlen(temp_argument))
			{
				if ((temp_argument[0] == 41) || (temp_argument[0] == 125))
				{
					strcopy(client_message[strlen(client_message)], 191, temp_argument);
				}
				else if ((strlen(client_message) > 0) && (client_message[strlen(client_message)-1] != 40) && (client_message[strlen(client_message)-1] != 123) && (client_message[strlen(client_message)-1] != 58) && (client_message[strlen(client_message)-1] != 39) && (client_message[strlen(client_message)-1] != 44))
				{
					if ((strcmp(temp_argument, ":") != 0) && (strcmp(temp_argument, ",") != 0) && (strcmp(temp_argument, "'") != 0))
					{
						client_message[strlen(client_message)] = 32;
					}
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
				else
				{
					strcopy(client_message[strlen(client_message)], 192, temp_argument);
				}
			}
		}
		else
		{
			if ((192 - strlen(client_message)) > strlen(temp_argument))
			{
				strcopy(client_message[strlen(client_message)], 192, temp_argument);
			}
		}
	}

	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(client_message, "") != 0))
	{
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			PrintHintText(player_index, client_message);
		}	
	}		
			
	return Plugin_Handled;
}


public Action:hlx_sm_browse(args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_browse <userid><url> - open client ingame browser");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	new String: client_url[192];

	decl String: argument_string[512];
	GetCmdArgString(argument_string, 512);

	new find_pos = StrContains(argument_string, "http://", true);
	if (find_pos == -1)
	{
		new argument_count = GetCmdArgs();
		for(new i = 1; i < argument_count; i++)
		{
			decl String: temp_argument[192];
			GetCmdArg(i+1, temp_argument, 192);
			if ((192 - strlen(client_url)) > strlen(temp_argument))
			{
				strcopy(client_url[strlen(client_url)], 192, temp_argument);
			}
		}
	}
	else
	{
		strcopy(client_url, 192, argument_string[find_pos]);
		ReplaceString(client_url, 192, "\"", "");
	}

	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(client_url, "") != 0))
	{
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			ShowMOTDPanel(player_index, "HLstatsX", client_url, MOTDPANEL_TYPE_URL);
		}
	}
			
	return Plugin_Handled;
}


public Action:hlx_sm_swap(args)
{
	if (args < 1)
	{
		PrintToServer("Usage: hlx_sm_swap <userid> - swaps players to the opposite team (css only)");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	new client = StringToInt(client_id);
	if (client > 0)
	{
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			swap_player(player_index);
		}
	}
	return Plugin_Handled;
}


public Action:hlx_sm_redirect(args)
{
	if (args < 3)
	{
		PrintToServer("Usage: hlx_sm_redirect <time><userid><address><reason> - asks player to be redirected to specified gameserver");
		return Plugin_Handled;
	}

	decl String: display_time[16];
	GetCmdArg(1, display_time, 16);

	decl String: client_id[32];
	GetCmdArg(2, client_id, 32);

	new String: server_address[192];

	new argument_count = GetCmdArgs();
	new break_address = argument_count;

	for(new i = 2; i < argument_count; i++)
	{
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (strcmp(temp_argument, ":") == 0)
		{
			break_address = i + 1;
		}
		else if (i == 3)
		{
			break_address = i - 1;
		}
		if (i <= break_address)
		{
			if ((192 - strlen(server_address)) > strlen(temp_argument))
			{
				strcopy(server_address[strlen(server_address)], 192, temp_argument);
			}
		}
	}	

	new String: redirect_reason[192];
	for(new i = break_address + 1; i < argument_count; i++)
	{
		decl String: temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if ((192 - strlen(redirect_reason)) > strlen(temp_argument))
		{
			redirect_reason[strlen(redirect_reason)] = 32;		
			strcopy(redirect_reason[strlen(redirect_reason)], 192, temp_argument);
		}
	}	


	new client = StringToInt(client_id);
	if ((client > 0) && (strcmp(server_address, "") != 0))
	{
		new player_index = GetClientOfUserId(client);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index)) && (IsClientInGame(player_index)))
		{
			new Handle:top_values = CreateKeyValues("msg");
			KvSetString(top_values, "title", redirect_reason);
			KvSetNum(top_values, "level", 1); 
			KvSetString(top_values, "time", display_time); 
			CreateDialog(player_index, top_values, DialogType_Msg);
			CloseHandle(top_values);
			
			new Float: display_time_float;
			display_time_float = StringToFloat(display_time);
			DisplayAskConnectBox(player_index, display_time_float, server_address);
		}	
	}		
		
	return Plugin_Handled;
}


public Action:hlx_sm_player_action(args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_player_action <clientid><action> - trigger player action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	decl String: client_id[32];
	GetCmdArg(1, client_id, 32);

	decl String: player_action[192];
	GetCmdArg(2, player_action, 192);

	new client = StringToInt(client_id);
	if (client > 0)
	{
		log_player_event(client, "triggered", player_action);
	}

	return Plugin_Handled;
}


public Action:hlx_sm_team_action(args)
{
	if (args < 2)
	{
		PrintToServer("Usage: hlx_sm_team_action <team_name><action> - trigger team action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	decl String: team_name[64];
	GetCmdArg(1, team_name, 64);

	decl String: team_action[64];
	GetCmdArg(2, team_action, 64);

	LogToGame("Team \"%s\" triggered \"%s\"", team_name, team_action); 

	return Plugin_Handled;
}


public Action:hlx_sm_world_action(args)
{
	if (args < 1)
	{
		PrintToServer("Usage: hlx_sm_world_action <action> - trigger world action to be handled from HLstatsX");
		return Plugin_Handled;
	}

	decl String: world_action[64];
	GetCmdArg(1, world_action, 64);

	LogToGame("World triggered \"%s\"", world_action); 

	return Plugin_Handled;
}


is_command_blocked(String: command[])
{
	new command_blocked = 0;
	new command_index = 0;
	while ((command_blocked == 0) && (command_index < sizeof(blocked_commands)))
	{
		if (strcmp(command, blocked_commands[command_index]) == 0)
		{
			command_blocked++;
		}
		command_index++;
	}
	if (command_blocked > 0)
	{
		return 1;
	}
	return 0;
}


public Action:hlx_block_commands(client, args)
{
	if (client)
	{
		if (client == 0)
		{
			return Plugin_Continue;
		}
		new block_chat_commands = GetConVarInt(hlx_block_chat_commands);

		decl String: user_command[192];
		GetCmdArgString(user_command, 192);

		decl String: origin_command[192];
		new start_index = 0;
		new command_length = strlen(user_command);
		if (command_length > 0)
		{
			if (user_command[0] == 34)
			{
				start_index = 1;
				if (user_command[command_length - 1] == 34)
				{
					user_command[command_length - 1] = 0;
				}
			}
			strcopy(origin_command, 192, user_command[start_index]);
			
			if (user_command[start_index] == 47)
			{
				start_index++;
			}
		}

		new String: command_type[32] = "say";

		if (gamemod == INSMOD)
		{
			decl String: say_type[1];
			strcopy(say_type, 2, user_command[start_index]);
			if (strcmp(say_type, "1") == 0)
			{
				command_type = "say";
			}
			else if (strcmp(say_type, "2") == 0)
			{
				command_type = "say_team";
			}
			start_index += 4;
		}

		if (command_length > 0)
		{
			if (block_chat_commands > 0)
			{
				new command_blocked = is_command_blocked(user_command[start_index]);
				if (command_blocked > 0)
				{
					if ((IsClientConnected(client)) && (IsClientInGame(client)))
					{
						if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
							(strcmp("hlx", user_command[start_index]) == 0) ||
							(strcmp("hlstatsx", user_command[start_index]) == 0))
						{
							DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
						}

						if (gamemod == INSMOD)
						{
							log_player_event(client, command_type, user_command[start_index]);
						}
						else
						{
							log_player_event(client, command_type, origin_command);
						}
					}
					return Plugin_Handled;
				}
				else
				{

					if (gamemod == INSMOD)
					{
						log_player_event(client, command_type, user_command[start_index]);
					}
				}
			}
			else
			{
				if ((IsClientConnected(client)) && (IsClientInGame(client)))
				{
					if ((strcmp("hlx_menu", user_command[start_index]) == 0) ||
						(strcmp("hlx", user_command[start_index]) == 0) ||
						(strcmp("hlstatsx", user_command[start_index]) == 0))
					{
						DisplayMenu(HLstatsXMenuMain, client, MENU_TIME_FOREVER);
					}
				}

				if (gamemod == INSMOD)
				{
					log_player_event(client, command_type, user_command[start_index]);
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}


public Action:HLstatsX_Event_GameLog(const String: message[])
{
	if ((strcmp("", logmessage_ignore) != 0) && (StrContains(message, logmessage_ignore) != -1))
	{
		if (StrContains(message, "position") == -1)
		{
			logmessage_ignore = "";
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}


public Action:HLstatsX_Event_PlyDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((gamemod == CSS) || (gamemod == DODS) || (gamemod == AOC) || (gamemod == FOF) || (gamemod == EMPIRES))
	{		
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
		if ((attacker > 0) && (victim > 0))
		{
			decl String: weapon[64];
			//pscyhonic - using printweapon for AOC since that is what normally is logged
			if (gamemod == AOC)
			{
				GetEventString(event, "printweapon", weapon, 64);
			}
			else
			{
				GetEventString(event, "weapon", weapon, 64);
			}
			new suicide = 0;
			if (attacker == victim)
			{
				suicide = 1;
			}
			
			new player_team_index = GetClientTeam(attacker);
			decl String: player_team[64];
			player_team = team_list[player_team_index];

			decl String: player_name[32];
			if (!GetClientName(attacker, player_name, 32))
			{
				strcopy(player_name, 32, "UNKNOWN");
			}

			decl String: player_authid[32];
			if (!GetClientAuthString(attacker, player_authid, 32))
			{
				strcopy(player_authid, 32, "UNKNOWN");
			}

			new Float: player_origin[3];
			GetClientAbsOrigin(attacker, player_origin);

			new player_userid = GetClientUserId(attacker);

			if (suicide == 0)
			{

				new headshot = 0;
				new hitgroup = 0;
				new damagetype = 0;
				new String: headshot_logentry[12] = "";
				if (gamemod == CSS || gamemod == FOF)
				{
					headshot = GetEventBool(event, "headshot");
					if (headshot == 1)
					{
					 	headshot_logentry = "(headshot) ";
					}
				//psychonic - AOC headshots
				}
				else if (gamemod == AOC)
				{
					hitgroup = GetEventInt(event, "hitgroup");
					damagetype = GetEventInt(event, "damagetype");
					if ((hitgroup == 1 && (damagetype & 32 || damagetype & 16)) || (hitgroup == 8 && damagetype & 256))
					{
						headshot = 1;
					 	headshot_logentry = "(headshot) ";
					}
				}
				
				// recon - Empires headshots
				else if (gamemod == EMPIRES)
				{	
					// Do we have a headshot?
					if (StrContains(weapon, "hs_", false) != -1)
					{
						// Yes, fix the weapon string						
						ReplaceString(weapon, sizeof(weapon), "hs_", "", false);
						headshot_logentry = "(headshot) ";						
					}
				}

				new victim_team_index = GetClientTeam(victim);
				decl String: victim_team[64];
				victim_team = team_list[victim_team_index];

				decl String: victim_name[32];
				if (!GetClientName(victim, victim_name, 32))
				{
					strcopy(victim_name, 32, "UNKNOWN");
				}

				decl String: victim_authid[32];
				if (!GetClientAuthString(victim, victim_authid, 32))
				{
					strcopy(victim_authid, 32, "UNKNOWN");
				}
			
				new Float: victim_origin[3];
				GetClientAbsOrigin(victim, victim_origin);

				new victim_userid = GetClientUserId(victim);
			
				if (gamemod == EMPIRES)
				{
					Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" killed \"%s<%d><%s><%s>\"",
						   player_name, player_userid, player_authid, player_team, 
						   victim_name, victim_userid, victim_authid, victim_team);
				
				}
				else
				{
					Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" killed \"%s<%d><%s><%s>\" with \"%s\"",
						   player_name, player_userid, player_authid, player_team, 
						   victim_name, victim_userid, victim_authid, victim_team,
						   weapon);
				}
				

				LogToGame("\"%s<%d><%s><%s>\" killed \"%s<%d><%s><%s>\" with \"%s\" %s(attacker_position \"%d %d %d\") (victim_position \"%d %d %d\")",
					player_name, player_userid, player_authid, player_team, 
					victim_name, victim_userid, victim_authid, victim_team,
					weapon, headshot_logentry, 
					RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]), 
					RoundFloat(victim_origin[0]), RoundFloat(victim_origin[1]), RoundFloat(victim_origin[2]));

			}
			else
			{
				
				if (gamemod == AOC)
				{
				Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" committed suicide with \"",
					player_name, player_userid, player_authid, player_team);
				}
				else
				{
				Format(logmessage_ignore, 512, "\"%s<%d><%s><%s>\" committed suicide with \"%s\"",
					player_name, player_userid, player_authid, player_team, weapon);				
				}
				LogToGame("\"%s<%d><%s><%s>\" committed suicide with \"%s\" (attacker_position \"%d %d %d\")",
					player_name, player_userid, player_authid, player_team, weapon, 
					RoundFloat(player_origin[0]), RoundFloat(player_origin[1]), RoundFloat(player_origin[2]));
			}
		}

	}
	else if (gamemod == TF)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
		
		switch (GetEventInt(event, "customkill"))
		{
			case 0:
			{
				// octo & psychonic     log kills resulting from critical hits, train hits, and drownings
				new bits = GetEventInt(event,"damagebits");
				if (bits & 1048576 && attacker > 0 && attacker != victim)
				{
					log_player_event(attacker, "triggered", "crit_kill");
				}
				else if (bits == 16 && victim > 0)
				{
					log_player_event(victim, "triggered", "hit_by_train");
				}
				else if (bits == 16384 && victim > 0)
				{
					log_player_event(victim, "triggered", "drowned");
				}
			}
			case 2:
			{
				log_playerplayer_event(attacker, victim, "triggered", "backstab");
			}
			case 6:
			{
				if (attacker == victim)
				{
					// psychonic & octo     log forced suicides ("kill" & "explode")
					log_player_event(victim, "triggered", "force_suicide");
				}
			}
			case 17, 18:
				SetEventString(event, "weapon_logclassname", "tf_projectile_arrow_fire");
		}
		if (GetEventInt(event, "death_flags") & 16)
		{
			log_player_event(attacker, "triggered", "first_blood");
		}
	}
	
	return Plugin_Continue;
}

public Action: HLstatsX_Event_PlyTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((gamemod == CSS) || (gamemod == TF))
	{
		new userid = GetEventInt(event, "userid");
		if (userid > 0)
		{
			new player_team_index = GetEventInt(event, "team");
			decl String: player_team[64];
			player_team = team_list[player_team_index];
			new player_index = GetClientOfUserId(userid);
			if (player_index > 0)
			{
				if (IsClientInGame(player_index))
				{
					if (gamemod == CSS)
					{
						if (player_index == ct_player_color)
						{
							ct_player_color = -1;
						}
						if (player_index == ts_player_color)
						{
							ts_player_color = -1;
						}
					}
					else
					{
						if (player_index == blue_player_color)
						{
							blue_player_color = -1;
						}
						if (player_index == red_player_color)
						{
							red_player_color = -1;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
						
public HLstatsX_Event_RescueSurvivor(Handle:event, const String:name[], bool:dontBroadcast)
{
	log_player_event(GetClientOfUserId(GetEventInt(event, "rescuer")), "triggered", "rescued_survivor", 1);
}

public HLstatsX_Event_Heal(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if (player != GetClientOfUserId(GetEventInt(event, "subject")))
	{
		log_player_event(player, "triggered", "healed_teammate", 1);
	}
}

public HLstatsX_Event_Revive(Handle:event, const String:name[], bool:dontBroadcast)
{
	log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "revived_teammate", 1);
}

public HLstatsX_Event_StartleWitch(Handle:event, const String:name[], bool:dontBroadcast)
{
	log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "startled_witch", 1);
}

public HLstatsX_Event_Pounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (victim > 0)
	{
		log_playerplayer_event(GetClientOfUserId(GetEventInt(event, "userid")), victim, "triggered", "pounce", 1);
	}
	else
	{
		log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "pounce", 1);
	}
}

public HLstatsX_Event_Boomered(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim > 0)
	{
		log_playerplayer_event(GetClientOfUserId(GetEventInt(event, "attacker")), victim, "triggered", "vomit", 1);
	}
	else
	{
		log_player_event(GetClientOfUserId(GetEventInt(event, "attacker")), "triggered", "vomit", 1);
	}
}

public HLstatsX_Event_L4DFF(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (player == GetClientOfUserId(GetEventInt(event, "guilty")))
	{
		if (victim > 0)
		{
			log_playerplayer_event(player, victim, "triggered", "friendly_fire", 1);
		}
		else
		{
			log_player_event(player, "triggered", "friendly_fire", 1);
		}
	}
}

public HLstatsX_Event_L4DAward(Handle:event, const String:name[], bool:dontBroadcast)
{
	// thanks to msleeper for figuring out most of these
	// "userid"	"short"			// player who earned the award
	// "entityid"	"long"			// client likes ent id
	// "subjectentid"	"long"			// entity id of other party in the award, if any
	// "award"		"short"			// id of award earned
	
	switch(GetEventInt(event, "award"))
	{
		case 19:
			log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "cr0wned", 0);
		case 21:
			log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "hunter_punter", 0);
		case 27:
			log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "tounge_twister", 0);
		case 67:
			log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "protect_teammate", 0);
		case 80:
			log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "no_death_on_tank", 0);
		case 136:
			log_player_event(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "killed_all_survivors", 0);
	}
}

public HLstatsX_Event_StealSandvich(Handle:event, const String:name[], bool:dontBroadcast)
{
	log_playerplayer_event(GetClientOfUserId(GetEventInt(event, "target")), GetClientOfUserId(GetEventInt(event, "owner")), "triggered", "steal_sandvich", 1);
}

public HLstatsX_Event_Stunned(Handle:event, const String:name[], bool:dontBroadcast)
{
	log_playerplayer_event(GetClientOfUserId(GetEventInt(event, "stunner")), GetClientOfUserId(GetEventInt(event, "victim")), "triggered", "stun", 1);
}

public HLstatsX_Event_Extinguish(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "healer"));
	
	switch (GetEntProp(client, Prop_Send, "m_iClass"))
	{
		case 2:
			log_player_event(client, "triggered", "sniper_extinguish", 1);
		case 5:
			log_player_event(client, "triggered", "medic_extinguish", 1);
		case 7:
			log_player_event(client, "triggered", "pyro_extinguish", 1);
		case 9:
			log_player_event(client, "triggered", "engineer_extinguish", 1);
	}
}

public HLstatsX_Event_Teleport(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "builderid");
	
	if (userid != GetEventInt(event, "userid"))
	{
		log_player_event(GetClientOfUserId(userid), "triggered", "teleport", 1);
	}
	else
	{
		log_player_event(GetClientOfUserId(userid), "triggered", "teleport_self", 1);
	}
}

public HLstatsX_Event_Jarated(Handle:event, const String:name[], bool:dontBroadcast)
{
	log_playerplayer_event(GetEventInt(event, "thrower_entindex"), GetEventInt(event, "victim_entindex"), "triggered", "jarate", 1);
}

//psychonic - Round_Win team account for INSMOD and AOC
public HLstatsX_Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:winTeam[64];

	if (gamemod == INSMOD)
	{
		get_insmod_teamname(GetEventInt(event, "winner"), winTeam, sizeof(winTeam));
	}
	else
	{
		winTeam = team_list[GetEventInt(event, "winner")];
	}
	LogToGame("Team \"%s\" triggered \"Round_Win\"", winTeam); 
}

public HLstatsX_Event_GESRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winner = GetEventInt(event, "winnerid");
	if (winner > 0)
	{
		log_player_event(winner, "triggered", "Round_Win", 1);
	}
	else
	{
		winner = GetEventInt(event, "teamid");
		if (winner > 0)
		{
			decl String:winTeam[64];
			winTeam = team_list[winner];
			LogToGame("Team \"%s\" triggered \"Round_Win_Team\"", winTeam);
		}
	}
	new awards[6];
	awards[0] = GetEventInt(event, "award1_id");
	awards[1] = GetEventInt(event, "award2_id");
	awards[2] = GetEventInt(event, "award3_id");
	awards[3] = GetEventInt(event, "award4_id");
	awards[4] = GetEventInt(event, "award5_id");
	awards[5] = GetEventInt(event, "award6_id");

	new winners[6];
	winners[0] = GetEventInt(event, "award1_winner");
	winners[1] = GetEventInt(event, "award2_winner");
	winners[2] = GetEventInt(event, "award3_winner");
	winners[3] = GetEventInt(event, "award4_winner");
	winners[4] = GetEventInt(event, "award5_winner");
	winners[5] = GetEventInt(event, "award6_winner");

	for (new i = 0; i < 6; i++)
	{
		if (winners[i] > 0)
		{
			switch(awards[i])
			{
				case 0:
					log_player_event(winners[i], "triggered", "GE_AWARD_DEADLY", 1);
				case 1:
					log_player_event(winners[i], "triggered", "GE_AWARD_HONORABLE", 1);
				case 2:
					log_player_event(winners[i], "triggered", "GE_AWARD_PROFESSIONAL", 1);
				case 3:
					log_player_event(winners[i], "triggered", "GE_AWARD_MARKSMANSHIP", 1);
				case 4:
					log_player_event(winners[i], "triggered", "GE_AWARD_AC10", 1);
				case 5:
					log_player_event(winners[i], "triggered", "GE_AWARD_FRANTIC", 1);
				case 6:
					log_player_event(winners[i], "triggered", "GE_AWARD_WTA", 1);
				case 7:
					log_player_event(winners[i], "triggered", "GE_AWARD_LEMMING", 1);
				case 8:
					log_player_event(winners[i], "triggered", "GE_AWARD_LONGIN", 1);
				case 9:
					log_player_event(winners[i], "triggered", "GE_AWARD_SHORTIN", 1);
				case 10:
					log_player_event(winners[i], "triggered", "GE_AWARD_DISHONORABLE", 1);
				case 11:
					log_player_event(winners[i], "triggered", "GE_AWARD_NOTAC10", 1);
				case 12:
					log_player_event(winners[i], "triggered", "GE_AWARD_MOSTLYHARMLESS", 1);
			}
		}
	}
}

public HLstatsX_Event_GESRoleChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "playerid"	"short"
	// "ident"		"string"
	
	new clientid = GetEventInt(event, "playerid");

	if (clientid > 0)
	{
		decl String:ident[32];
		decl String:playername[64];
		decl String:teamname[64];
		decl String:auth[64];
		
		GetEventString(event, "ident", ident, sizeof(ident));
		GetClientName(clientid, playername, sizeof(playername));
		
		GetTeamName(GetClientTeam(clientid), teamname, sizeof(teamname));
		GetClientAuthString(clientid, auth, sizeof(auth));
		
		LogToGame("\"%s<%d><%s><%s>\" changed role to \"%s\"", playername, GetClientUserId(clientid), auth, teamname, ident);
	}	
}

swap_player(player_index)
{
	if (gamemod == CSS)
	{
		if (IsClientConnected(player_index))
		{
			new player_team_index = GetClientTeam(player_index);
			decl String: player_team[64];
			player_team = team_list[player_team_index];			

			if (strcmp(player_team, "CT") == 0)
			{
				if (IsPlayerAlive(player_index))
				{
					CS_SwitchTeam(player_index, CS_TEAM_T);
					CS_RespawnPlayer(player_index);
					new new_model = GetRandomInt(0, 3);
					SetEntityModel(player_index, ts_models[new_model]);
				}
				else
				{
					CS_SwitchTeam(player_index, CS_TEAM_T);
				}
			}
			else if (strcmp(player_team, "TERRORIST") == 0)
			{
				if (IsPlayerAlive(player_index))
				{
					CS_SwitchTeam(player_index, CS_TEAM_CT);
					CS_RespawnPlayer(player_index);
					new new_model = GetRandomInt(0, 3);
					SetEntityModel(player_index, ct_models[new_model]);
					new weapon_entity = GetPlayerWeaponSlot(player_index, 4);
					if (weapon_entity > 0)
					{
						decl String: class_name[64];
						GetEdictClassname(weapon_entity, class_name, 64);
						if (strcmp(class_name, "weapon_c4") == 0)
						{
							RemovePlayerItem(player_index, weapon_entity);
						}
					}
				}
				else
				{
					CS_SwitchTeam(player_index, CS_TEAM_CT);
				}
			}
		}
	}
}


public CreateHLstatsXMenuMain(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXMainCommandHandler, MenuAction_Select|MenuAction_Cancel);

	if (gamemod == INSMOD)
	{
		SetMenuTitle(MenuHandle, "HLstatsX - Main Menu");
		AddMenuItem(MenuHandle, "", "Display Rank");
		AddMenuItem(MenuHandle, "", "Next Players");
		AddMenuItem(MenuHandle, "", "Top10 Players");
		AddMenuItem(MenuHandle, "", "Auto Ranking");
		AddMenuItem(MenuHandle, "", "Console Events");
		AddMenuItem(MenuHandle, "", "Toggle Ranking Display");
	}
	else
	{
		SetMenuTitle(MenuHandle, "HLstatsX - Main Menu");
		AddMenuItem(MenuHandle, "", "Display Rank");
		AddMenuItem(MenuHandle, "", "Next Players");
		AddMenuItem(MenuHandle, "", "Top10 Players");
		AddMenuItem(MenuHandle, "", "Clans Ranking");
		AddMenuItem(MenuHandle, "", "Server Status");
		AddMenuItem(MenuHandle, "", "Statsme");
		AddMenuItem(MenuHandle, "", "Auto Ranking");
		AddMenuItem(MenuHandle, "", "Console Events");
		AddMenuItem(MenuHandle, "", "Weapon Usage");
		AddMenuItem(MenuHandle, "", "Weapons Accuracy");
		AddMenuItem(MenuHandle, "", "Weapons Targets");
		AddMenuItem(MenuHandle, "", "Player Kills");
		AddMenuItem(MenuHandle, "", "Toggle Ranking Display");
		AddMenuItem(MenuHandle, "", "Cheater List");
		AddMenuItem(MenuHandle, "", "Display Help");
	}

	SetMenuPagination(MenuHandle, 8);
}


public CreateHLstatsXMenuAuto(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXAutoCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Auto-Ranking");
	AddMenuItem(MenuHandle, "", "Enable on round-start");
	AddMenuItem(MenuHandle, "", "Enable on round-end");
	AddMenuItem(MenuHandle, "", "Enable on player death");
	AddMenuItem(MenuHandle, "", "Disable");

	SetMenuPagination(MenuHandle, 8);
}


public CreateHLstatsXMenuEvents(&Handle: MenuHandle)
{
	MenuHandle = CreateMenu(HLstatsXEventsCommandHandler, MenuAction_Select|MenuAction_Cancel);

	SetMenuTitle(MenuHandle, "HLstatsX - Console Events");
	AddMenuItem(MenuHandle, "", "Enable Events");
	AddMenuItem(MenuHandle, "", "Disable Events");
	AddMenuItem(MenuHandle, "", "Enable Global Chat");
	AddMenuItem(MenuHandle, "", "Disable Global Chat");

	SetMenuPagination(MenuHandle, 8);
}


make_player_command(client, String: player_command[192]) 
{
	if (client > 0)
	{
		log_player_event(client, "say", player_command);
	}
}


public HLstatsXMainCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientConnected(param1))
		{
			if (gamemod == INSMOD)
			{
				switch (param2)
				{
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						DisplayMenu(HLstatsXMenuAuto, param1, MENU_TIME_FOREVER);
					case 4 : 
						DisplayMenu(HLstatsXMenuEvents, param1, MENU_TIME_FOREVER);
					case 5 : 
						make_player_command(param1, "/hlx_hideranking");
				}
			}
			else
			{
				switch (param2)
				{
					case 0 : 
						make_player_command(param1, "/rank");
					case 1 : 
						make_player_command(param1, "/next");
					case 2 : 
						make_player_command(param1, "/top10");
					case 3 : 
						make_player_command(param1, "/clans");
					case 4 : 
						make_player_command(param1, "/status");
					case 5 : 
						make_player_command(param1, "/statsme");
					case 6 : 
						DisplayMenu(HLstatsXMenuAuto, param1, MENU_TIME_FOREVER);
					case 7 : 
						DisplayMenu(HLstatsXMenuEvents, param1, MENU_TIME_FOREVER);
					case 8 : 
						make_player_command(param1, "/weapons");
					case 9 : 
						make_player_command(param1, "/accuracy");
					case 10 : 
						make_player_command(param1, "/targets");
					case 11 : 
						make_player_command(param1, "/kills");
					case 12 : 
						make_player_command(param1, "/hlx_hideranking");
					case 13 : 
						make_player_command(param1, "/cheaters");
					case 14 : 
						make_player_command(param1, "/help");
				}
			}
		}
	}
}


public HLstatsXAutoCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientConnected(param1))
		{
			switch (param2)
			{
				case 0 : 
					make_player_command(param1, "/hlx_auto start rank");
				case 1 : 
					make_player_command(param1, "/hlx_auto end rank");
				case 2 : 
					make_player_command(param1, "/hlx_auto kill rank");
				case 3 : 
					make_player_command(param1, "/hlx_auto clear");
			}
		}
	}
}


public HLstatsXEventsCommandHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientConnected(param1))
		{
			switch (param2)
			{
				case 0 : 
					make_player_command(param1, "/hlx_display 1");
				case 1 : 
					make_player_command(param1, "/hlx_display 0");
				case 2 : 
					make_player_command(param1, "/hlx_chat 1");
				case 3 : 
					make_player_command(param1, "/hlx_chat 0");
			}
		}
	}
}
