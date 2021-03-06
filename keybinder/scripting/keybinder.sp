/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

// Holds the binds KVs
new Handle:kvBinds = INVALID_HANDLE;

// Total number of binds
new totalBinds = 0;

public Plugin:myinfo = 
{
	name = "Key Binder",
	author = "Recon",
	description = "Binds client keys to commands.",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{	
	// Load binds KVs
	LoadBinds();	
}

/**
 * Loads questions into kvQuestions
 *
 * @noreturn
 */
LoadBinds()
{	
	// Holds the path to the KV file
	decl String:locBinds[256];
	
	// Locate the KV file
	BuildPath(Path_SM, locBinds, sizeof(locBinds), "configs/binds.cfg");
	
	// Make sure the question file exists
	if(FileExists(locBinds))
	{	
		// Create the KV handle
		kvBinds = CreateKeyValues("Binds");
		
		// Load the KV file
		FileToKeyValues(kvBinds, locBinds);		
	}
	else
	
		// No question file, set fail state
		SetFailState("Unable to find configs/binds.cfg");
	
	// Get the total number of binds
	totalBinds = KvGetNum(kvBinds, "totalBinds");
}

public OnClientPostAdminCheck(client)
{
	// Bind keys
	for (new i = 0; i < totalBinds - 1; i++)
	{
		// Strings to hold values from the KV file		
		decl String:key[25];
		decl String:command[256];
		
		// Holds a string version of i
		decl String:jumpTo[5];
		
		// Get a string version of i
		IntToString(i, jumpTo, sizeof(jumpTo));		
		KvJumpToKey(kvBinds, jumpTo);
		
		// Get the key to bind to and the command to bind
		KvGetString(kvBinds, "key", key, sizeof(key));
		KvGetString(kvBinds, "command", command, sizeof(command));
		
		// Set the KVs back to the beginning
		KvRewind(kvBinds);
		
		// Run the command
		ClientCommand(client, "bind %s \"%s\"", key, command);
	}	
}