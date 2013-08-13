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
*/

/**
* 
* sourcemod/configs/autonamechanger/names.cfg format
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
#define PLUGIN_VERSION "3.5"

//Handles
new Handle:cvarNewName;

// Holds the names KVs
new Handle:kvNames = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Auto Name Changer",
	author = "MoggieX, Multi check name support added by Recon",
	description = "Auto changes players named unnamed",
	version = PLUGIN_VERSION,
	url = "http://www.UKManDown.co.uk"
};

public OnPluginStart()
{	
	// Create version cvar
	CreateConVar("sm_autoname_version", PLUGIN_VERSION, "Name Changer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Create the name to change to cvar
	cvarNewName = CreateConVar("sm_autoname_name", "Press ESC > Options > Set Name", "Default name to change to.",FCVAR_PRINTABLEONLY);	
	
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
	BuildPath(Path_SM, locNames, sizeof(locNames), "configs/autonamechanger/names.cfg");
	
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
		SetFailState("Unable to find configs/autonamechanger/names.cfg");	
}

//////////////////////////////////////////////////////////////////
// Player checking on connection (post admin check)
//////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
{
	// If this is a bot, return
	if(IsFakeClient(client))
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
			// The name to change to
			new String:newName[65];	
			GetConVarString(cvarNewName, newName, sizeof(newName));
			
			// Change the client's name and break
			ClientCommand(client, "name \"%s\"", newName);
			break;
		}
	}
 }