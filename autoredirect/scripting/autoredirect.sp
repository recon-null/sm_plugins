/**
* Auto Name Changer by MoggieX
*
* Description:
* 	If a player connects with the name "unnamed" we chnage to a helpful name
*	Remember you were a n00b once too!
*
* Usage:
* 	Install and go!
*	Alter the convar sm_autoname_name if needed
*	
* Thanks to:
* 	Tsunami =D
*  	 bl4nk for the layout of the this plugin
*
* Version 3.0
*  - Added checks for any player with "unnamed" in thier name or what ever has been set in sm_autoname_ntc
* 
* Version 3.5
*  - Recon added multi check name support 
* 
* Fork to autoredirect
* 
* Version 1.0
*  - Private release
*
* Version 1.1
* - Fixed client crash bug
* - Added sm_redirect admin command
* - Added admin immunity
*/

/**
* 
* sourcemod/configs/autoredirect/names.cfg format
* 
* "Names"
* {
* 		"0"
* 		{
* 			"name"		"emp_recruit"
* 		}
* 
* 		"1"
* 		{
* 			"name"		"Nacho's Newbie"
* 		} 
* } 
* 
*/

#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.5"

// Handles
new Handle:cvarRedirectIPPort;

// Holds the names KVs
new Handle:kvNames = INVALID_HANDLE;

// Holds the connect string
new String:connectStr[128];

public Plugin:myinfo = 
{
	name = "Auto Redirect",
	author = "Forked from MoggieX's Auto Name Changer by Recon.",
	description = "Connects players with names in the config file to the server in the sm_redirect_ipport cvar.",
	version = PLUGIN_VERSION,
	url = "No website yet."
};

public OnPluginStart()
{
	// For ProcessTargetString
	LoadTranslations("common.phrases");
	
	// Create version cvar
	CreateConVar("sm_autoredirect_version", PLUGIN_VERSION, "Auto Redirect Version",
				 FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Create ip / port cvar
	cvarRedirectIPPort = CreateConVar("sm_redirect_ipport", "0.0.0.0:0000",
									  "Server to connect clients to.",FCVAR_PRINTABLEONLY);	
	
	// Hook the cvar change
	HookConVarChange(cvarRedirectIPPort, OnRedirectIPPortChanged);
	
	RegAdminCmd("sm_redirect", Command_Redirect, ADMFLAG_ROOT, "Redirects a client to the server in sm_redirect_ipport.");
	
	// Load the names KVs
	LoadNames();
}

public OnPluginEnd()
{
	// Close the names KVs
	CloseHandle(kvNames);
}


/**
 * Loads names into kvQuestions
 *
 * @noreturn
 */
LoadNames()
{	
	// Holds the path to the KV file
	decl String:locNames[256];
	
	// Locate the KV file
	BuildPath(Path_SM, locNames, sizeof(locNames), "configs/autoredirect/names.cfg");
	
	// Make sure the question file exists
	if(FileExists(locNames))
	{	
		// Create the KV handle
		kvNames = CreateKeyValues("Names");
		
		// Load the KV file
		FileToKeyValues(kvNames, locNames);		
	}
	else
	
		// No names file, set fail state
		SetFailState("Unable to find configs/autoredirect/names.cfg");	
}

public OnRedirectIPPortChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	// Create the connect string
	Format(connectStr, sizeof(connectStr), "steam://connect/%s", newVal);
}

public Action:Command_Redirect(client, args)
{
	// Did the user enter any args?
	if (args < 1)
	{
		// Tell them how to use the command
		PrintToConsole(client, "Usage: sm_redirect <name | userid | group>");
		return Plugin_Handled;
	}
		
	// Get the target string
	decl String:targetStr[100];
	decl String:targetName[32];
	decl bool:mlPhrase;
	GetCmdArg(1, targetStr, sizeof(targetStr));
	
	// Holds the targets
	new targets[MAXPLAYERS];
	
	// Get the target string
	ProcessTargetString(targetStr, client, targets, sizeof(targets),
						COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), mlPhrase);
	
	// No targets
	if (targets[0] == 0)
	{
		// Notify the admin
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
		return Plugin_Handled;		
	}
	
	// Redirect each target
	for(new i = 0; i < sizeof(targets); i++)	
		RedirectClient(client, targets[i]);	
 
	// Command completed
	return Plugin_Handled;	
}

//////////////////////////////////////////////////////////////////
// Player checking on connection (post admin check)
//////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
{
	// If this is a bot, return
	if(IsFakeClient(client))
		return;
	
	// If this is an admin, return
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
		return;

	// Player's current name
 	decl String:player_name[65];
	
	// Get Client Name
 	GetClientName(client, player_name, sizeof(player_name));

	// Look for each name
	for(new i = 0; ; i++)
	{
		// Holds the name to check
		new String:nameToCheck[65];	
		
		// Get a string version of i
		new String:strI[5];
		IntToString(i, strI, sizeof(strI));
	
		// Jump to the section for the name
		// to check
		//
		// If the section can't be found, we have
		// probably checked all the names in the file,
		// so break
		if (!KvJumpToKey(kvNames, strI))
			break;
		
		// Get the name to check and rewind the KVs
		KvGetString(kvNames, "name", nameToCheck, sizeof(nameToCheck));
		KvRewind(kvNames);
	
		// Check for a match
		if (StrContains(player_name, nameToCheck, false) != -1)  	
		{			
			// Redirect the client
			RedirectClient(0, client);
			break;
		}
	}
}
 
/**
 * Redirects a client
 * 
 * @param client The client to redirect
 * 
 * @noreturn
 */ 
RedirectClient(client, target)
{ 		
	// Log the action
	LogAction(client, target, "redirect URL executed ", connectStr);
	
	// Send the user to google (to avoid a crash)
 	ShowMOTDPanel(target, " ", "http://www.google.com", MOTDPANEL_TYPE_URL);
	
	// Create the timer to redirect the player
	CreateTimer(5.0, RedirectPlayer, target, TIMER_HNDL_CLOSE);
}
 
public Action:RedirectPlayer(Handle:timer, any:target)
{
	// Make sure the target is in game
	if (IsClientInGame(target))
	{
		// Redirect the target
		ShowMOTDPanel(target, " ", connectStr, MOTDPANEL_TYPE_URL);
	}
} 