/*
* Empires API
* 
* Created By Theowningone
* Version: 1.1
* http://www.theowningone.info/
* http://www.borgamers.com/
*/

/******************
* --> Defines <-- *
******************/

#if defined _empires_included
#endinput
#endif
#define _empires_included

#include <sourcemod>
#include <sdktools>





/********************
* --> Is Stocks <-- *
********************/

/**
* Is Player Squad Leader
*
* @param client			Client Index
* @return				1 if leader, 0 if other
*/
stock IsSquadLeader(client)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CPlayerResource")){
                ent = i;
                break;
            }
        }
    }
	new offset = FindSendPropOffs("CPlayerResource", "m_bSquadLeader");
	new out = GetEntData(ent, offset + (client*4), 4);
	return out;
}

/**
* Is Player Commander
*
* @param client			Client Index
* @return				1 if comm, 0 if other
*/
stock IsComm(client)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CPlayerResource")){
                ent = i;
                break;
            }
        }
    }
	new offset = FindSendPropOffs("CPlayerResource", "m_bCommander");
	new out = GetEntData(ent, offset + (client*4), 4);
	return out;
}

/**
* Is Player In Vehicle
*
* @param client			Client Index
* @return				1 if in vehicle, 0 if not
*/
stock IsInVehicle(client)
{
	new team = GetClientTeam(client);
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	new out = 0;
	if(team == 2){
		for(new i = 0; i <= maxents; i++){
			if(IsValidEntity(i)){
				GetEntityNetClass(i, classname, sizeof(classname));
				if(StrEqual(classname, "CPlayerResource_NF")){
					ent = i;
					break;
				}
			}
		}
		new offset = FindSendPropOffs("CPlayerResource_NF", "m_iVehicle_NF");
		out = GetEntData(ent, offset + (client*4), 4);
	}else if(team == 3){
		for(new i = 0; i <= maxents; i++){
			if(IsValidEntity(i)){
				GetEntityNetClass(i, classname, sizeof(classname));
				if(StrEqual(classname, "CPlayerResource_IMP")){
					ent = i;
					break;
				}
			}
		}
		new offset = FindSendPropOffs("CPlayerResource_IMP", "m_iVehicle_IMP");
		out = GetEntData(ent, offset + (client*4), 4);
	}
	if(IsComm(client)){
		out = 1;
	}
	new newout = 0;
	if(out >= 1){
		newout = 1;
	}
	return newout;
}









/**********************
* --> Team Stocks <-- *
**********************/

/**
* Retrieves NF Resources.
*
* @return				NF Resources
*/
stock GetNFResources()
{
	new ent = FindEntityByClassname(-1, "emp_info_params");
	new offset = FindDataMapOffs(ent, "m_iNFResources");
	new out = GetEntData(ent, offset, 4);
	return out;
}

/**
* Sets NF Resources.
*
* @noreturn
*/
stock SetNFResources(amount)
{
	new ent = FindEntityByClassname(-1, "emp_info_params");
	new offset = FindDataMapOffs(ent, "m_iNFResources");
	SetEntData(ent, offset, amount, 4, true);
}

/**
* Retrieves BE Resources.
*
* @return				BE Resources
*/
stock GetBEResources()
{
	new ent = FindEntityByClassname(-1, "emp_info_params");
	new offset = FindDataMapOffs(ent, "m_iImpResources");
	new out = GetEntData(ent, offset, 4);
	return out;
}

/**
* Sets BE Resources.
*
* @noreturn
*/
stock SetBEResources(amount)
{
	new ent = FindEntityByClassname(-1, "emp_info_params");
	new offset = FindDataMapOffs(ent, "m_iImpResources");
	SetEntData(ent, offset, amount, 4, true);
}

/**
* Retrieves NF Reinforcements
*
* @return				NF Reinforcements
*/
stock GetNFReinforcements()
{
	new ent = FindEntityByClassname(-1, "emp_info_params");
	new offset = FindDataMapOffs(ent, "m_iNFReinforcements");
	new out = GetEntData(ent, offset, 4);
	out--;
	return out;
}

/**
* Sets NF Reinforcements
*
* @noreturn
*/
stock SetNFReinforcements(amount)
{
	new ent = FindEntityByClassname(-1, "emp_info_params");
	new offset = FindDataMapOffs(ent, "m_iNFReinforcements");
	amount++;
	SetEntData(ent, offset, amount, 4, true);
}

/**
* Retrieves BE Reinforcements
*
* @return				BE Reinforcements
*/
stock GetBEReinforcements()
{
	new ent = FindEntityByClassname(-1, "emp_info_params");
	new offset = FindDataMapOffs(ent, "m_iImpReinforcements");
	new out = GetEntData(ent, offset, 4);
	out--;
	return out;
}

/**
* Sets BE Reinforcements
*
* @noreturn
*/
stock SetBEReinforcements(amount)
{
	new ent = FindEntityByClassname(-1, "emp_info_params");
	new offset = FindDataMapOffs(ent, "m_iImpReinforcements");
	amount++;
	SetEntData(ent, offset, amount, 4, true);
}

/**
* Is Researched
*
* @param team			Team Index
* @param index			Research Index
* @return				1 if researched, 0 if not
*/
stock IsResearched(team, index)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent, out = 0;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CResearchResource")){
                ent = i;
                break;
            }
        }
    }
	new bebool = FindSendPropOffs("CResearchResource", "m_bResearched_IMP");
	new nfbool = FindSendPropOffs("CResearchResource", "m_bResearched_NF");
	if(team == 2){
		out = GetEntData(ent, nfbool + index, 4);
	}else if(team == 3){
		out = GetEntData(ent, bebool + index, 4);
	}
	return out;
}

/**
* Current Research
*
* @param team			Team Index
* @return				Research Index
*/
stock CurrentResearch(team)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent, out = 0;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CResearchResource")){
                ent = i;
                break;
            }
        }
    }
	new beitem = FindSendPropOffs("CResearchResource", "m_iResearchItem_IMP");
	new nfitem = FindSendPropOffs("CResearchResource", "m_iResearchItem_NF");
	if(team == 2){
		out = GetEntData(ent, nfitem, 4);
	}else if(team == 3){
		out = GetEntData(ent, beitem, 4);
	}
	return out;
}

/**
* Current Research Name
*
* @param team			Team Index
* @param buffer			Buffer to hold the research name
* @param size			Len of the buffer
* @return				Research Index
*/
stock CurrentResearchName(team, String:buffer[], size)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent, out = 0;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CResearchResource")){
                ent = i;
                break;
            }
        }
    }
	new beitem = FindSendPropOffs("CResearchResource", "m_iResearchItem_IMP");
	new nfitem = FindSendPropOffs("CResearchResource", "m_iResearchItem_NF");
	if(team == 2){
		out = GetEntData(ent, nfitem, 4);
	}else if(team == 3){
		out = GetEntData(ent, beitem, 4);
	}
	new Handle:ResearchNames = CreateTrie();
	SetTrieString(ResearchNames, "0", "None", true);
	SetTrieString(ResearchNames, "1", "Physics", true);
	SetTrieString(ResearchNames, "2", "Superheated Material Physics", true);
	SetTrieString(ResearchNames, "3", "Plasma Cannon Projectile", true);
	SetTrieString(ResearchNames, "4", "Plasma Bullet Projectile", true);
	SetTrieString(ResearchNames, "5", "Projectile Physics", true);
	SetTrieString(ResearchNames, "6", "Reflective Armor", true);
	SetTrieString(ResearchNames, "7", "Extended Range Cannon", true);
	SetTrieString(ResearchNames, "8", "Heavy Caliber Machine Gun", true);
	SetTrieString(ResearchNames, "9", "Nuclear Fission", true);
	SetTrieString(ResearchNames, "10", "Fission Reactor", true);
	SetTrieString(ResearchNames, "11", "Nuclear Warhead", true);
	SetTrieString(ResearchNames, "12", "Chemistry", true);
	SetTrieString(ResearchNames, "13", "Improved Flagration Compounds", true);
	SetTrieString(ResearchNames, "14", "Explosive Tipped Bullets", true);
	SetTrieString(ResearchNames, "15", "Improved Detonation Compounds", true);
	SetTrieString(ResearchNames, "16", "Upgraded Grenades", true);
	SetTrieString(ResearchNames, "17", "Explosive Shells", true);
	SetTrieString(ResearchNames, "18", "Improved Warhead Compounds", true);
	SetTrieString(ResearchNames, "19", "Upgraded Missile Warhead", true);
	SetTrieString(ResearchNames, "20", "Upgraded Grenadier RPG", true);
	SetTrieString(ResearchNames, "21", "Advanced Grenadier RPG", true);
	SetTrieString(ResearchNames, "22", "Improved Heat Transfer Fluids", true);
	SetTrieString(ResearchNames, "23", "Advanced Coolant Engine", true);
	SetTrieString(ResearchNames, "24", "Absorbant Materials", true);
	SetTrieString(ResearchNames, "25", "Absorbant Armor", true);
	SetTrieString(ResearchNames, "26", "Mechanical Engineering", true);
	SetTrieString(ResearchNames, "27", "Upgraded Chassis", true);
	SetTrieString(ResearchNames, "28", "Medium Tank Chassis", true);
	SetTrieString(ResearchNames, "29", "Advanced Chassis", true);
	SetTrieString(ResearchNames, "30", "Heavy Tank Chassis", true);
	SetTrieString(ResearchNames, "31", "Artillery Tank Chassis", true);
	SetTrieString(ResearchNames, "32", "Advanced Machining", true);
	SetTrieString(ResearchNames, "33", "Composite Armor", true);
	SetTrieString(ResearchNames, "34", "Gas Turbine Engine", true);
	SetTrieString(ResearchNames, "35", "Electrical Engineering", true);
	SetTrieString(ResearchNames, "36", "Advanced Magnet Research", true);
	SetTrieString(ResearchNames, "37", "Rail Gun", true);
	SetTrieString(ResearchNames, "38", "3 Phase Electric Motor", true);
	SetTrieString(ResearchNames, "39", "Reactive Armor", true);
	SetTrieString(ResearchNames, "40", "Tracking Systems", true);
	SetTrieString(ResearchNames, "41", "Homing Missiles", true);
	SetTrieString(ResearchNames, "42", "Guided Missiles", true);
	SetTrieString(ResearchNames, "43", "Upgraded Turrets Lvl 2", true);
	SetTrieString(ResearchNames, "44", "Upgraded Turrets Lvl 3", true);
	SetTrieString(ResearchNames, "45", "Improved Detonators", true);
	SetTrieString(ResearchNames, "46", "Biology", true);
	SetTrieString(ResearchNames, "47", "Regenerative Armor", true);
	SetTrieString(ResearchNames, "48", "Bio Diesel Engine", true);
	SetTrieString(ResearchNames, "49", "Biological Weaponry", true);
	SetTrieString(ResearchNames, "50", "Biological Warhead", true);
	SetTrieString(ResearchNames, "51", "Biological Projectile", true);
	decl String:research[64], String:researchname[64];
	IntToString(out, research ,sizeof(research));
	GetTrieString(ResearchNames, research, researchname, sizeof(researchname));
	strcopy(buffer, size, researchname);
	return out;
}

/**
* Set Research
*
* @param team			Team Index
* @param index			Research Index
* @param status			weather to research or not
* @noreturn
*/
stock SetResearch(team, index, bool:status)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CResearchResource")){
                ent = i;
                break;
            }
        }
    }
	new bebool = FindSendPropOffs("CResearchResource", "m_bResearched_IMP");
	new nfbool = FindSendPropOffs("CResearchResource", "m_bResearched_NF");
	if(team == 2){
		SetEntData(ent, nfbool + index, status, 4, true);
	}else if(team == 3){
		SetEntData(ent, bebool + index, status, 4, true);
	}
}






/*************************
* --> Vehicle Stocks <-- *
*************************/

/**
* Get Vehicle Occupants
*
* @param ent			Vehicle Entity Index
* @return   			Amount of clients in vehicle
*/
stock GetVehicleOccupants(ent)
{
	if(!IsValidEntity(ent)) return -1;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1;
	new dat, out = 0;
	new Player1 = FindSendPropOffs("CEmpTank", "m_hPlayer");
	new Player2 = FindSendPropOffs("CEmpTank", "m_hPlayer2");
	new Player3 = FindSendPropOffs("CEmpTank", "m_hPlayer3");
	new Player4 = FindSendPropOffs("CEmpTank", "m_hPlayer4");
	new Player5 = FindSendPropOffs("CEmpTank", "m_hPlayer5");
	new Player6 = FindSendPropOffs("CEmpTank", "m_hPlayer6");
	new Player7 = FindSendPropOffs("CEmpTank", "m_hPlayer7");
	new Player8 = FindSendPropOffs("CEmpTank", "m_hPlayer8");
	dat = GetEntDataEnt(ent, Player1);
	if(dat) out++;
	dat = GetEntDataEnt(ent, Player2);
	if(dat) out++;
	dat = GetEntDataEnt(ent, Player3);
	if(dat) out++;
	dat = GetEntDataEnt(ent, Player4);
	if(dat) out++;
	dat = GetEntDataEnt(ent, Player5);
	if(dat) out++;
	dat = GetEntDataEnt(ent, Player6);
	if(dat) out++;
	dat = GetEntDataEnt(ent, Player7);
	if(dat) out++;
	dat = GetEntDataEnt(ent, Player8);
	if(dat) out++;
	return out;
}

/**
* Get Vehicle Driver
*
* @param ent			Vehicle Entity Index
* @return 				Client Index of Driver (0 if none, -1 if invalid entity)
*/
stock GetVehicleDriver(ent)
{
	if(!IsValidEntity(ent)) return -1;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1;
	new Player1 = FindSendPropOffs("CEmpTank", "m_hPlayer");
	new out = GetEntDataEnt(ent, Player1);
	return out;
}

/**
* Set Vehicle Armor
*
* @param ent			Vehicle Entity Index
* @param side			side of armor (1 is front, 2 is back, 3 is left, 4 is right)
* @param front			Health to set armor to
* @return				-1 on error, 0 on success
*/
stock SetVehicleArmor(ent, side, Float:health)
{
	if(!IsValidEntity(ent)) return -1;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1;
	new off = FindSendPropOffs("CEmpTank", "m_flVehicleArmor");
	if(side == 1){
		SetEntDataFloat(ent, off, health, true);
	}else if(side == 2){
		SetEntDataFloat(ent, off+4, health, true);
	}else if(side == 3){
		SetEntDataFloat(ent, off+8, health, true);
	}else if(side == 4){
		SetEntDataFloat(ent, off+12, health, true);
	}
	return 0;
}

/**
* Get Vehicle Armor
*
* @param ent			Vehicle Entity Index
* @param side			side of armor (1 is front, 2 is back, 3 is left, 4 is right)
* @return				Armor Health (-1.0 on error)
*/
stock Float:GetVehicleArmor(ent, side)
{
	if(!IsValidEntity(ent)) return -1.0;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1.0;
	new off = FindSendPropOffs("CEmpTank", "m_flVehicleArmor");
	new Float:dat = -1.0;
	if(side == 1){
		dat = GetEntDataFloat(ent, off);
	}else if(side == 2){
		dat = GetEntDataFloat(ent, off+4);
	}else if(side == 3){
		dat = GetEntDataFloat(ent, off+8);
	}else if(side == 4){
		dat = GetEntDataFloat(ent, off+12);
	}
	return dat;
}

/**
* Set Vehicle Hull
*
* @param ent			Vehicle Entity Index
* @param health			Health to set hull to
* @return				-1 on error, 0 on success
*/
stock SetVehicleHull(ent, Float:health)
{
	if(!IsValidEntity(ent)) return -1;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1;
	new off = FindSendPropOffs("CEmpTank", "m_flTotalHealth");
	SetEntDataFloat(ent, off, health, true);
	return 0;
}

/**
* Get Vehicle Hull
*
* @param ent			Vehicle Entity Index
* @return				Hull Health (-1.0 on error)
*/
stock Float:GetVehicleHull(ent)
{
	if(!IsValidEntity(ent)) return -1.0;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1.0;
	new off = FindSendPropOffs("CEmpTank", "m_flTotalHealth");
	new Float:dat = GetEntDataFloat(ent, off);
	return dat;
}

/**
* Set Vehicle Heat
*
* @param ent			Vehicle Entity Index
* @param heat			Heat to set for vehicle
* @return				-1 on error, 0 on success
*/
stock SetVehicleHeat(ent, Float:heat)
{
	if(!IsValidEntity(ent)) return -1;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1;
	new off = FindSendPropOffs("CEmpTank", "m_flVehicleHeat");
	SetEntDataFloat(ent, off, het, true);
	return 0;
}

/**
* Get Vehicle Heat
*
* @param ent			Vehicle Entity Index
* @return				Vehicle Heat (-1.0 on error)
*/
stock Float:GetVehicleHeat(ent)
{
	if(!IsValidEntity(ent)) return -1.0;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1.0;
	new off = FindSendPropOffs("CEmpTank", "m_flVehicleHeat");
	new Float:dat = GetEntDataFloat(ent, off);
	return dat;
}

/**
* Get Vehicle Class
*
* @param ent			Vehicle Entity Index
* @return				Vehicle Class (-1 on error)
*/
stock GetVehicleClass(ent)
{
	if(!IsValidEntity(ent)) return -1.0;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1.0;
	new off = FindSendPropOffs("CEmpTank", "m_iChassis");
	new dat = GetEntData(ent, off, 4);
	return dat;
}

/**
* Get Vehicle Class Name
*
* @param ent			Vehicle Entity Index
* @param buffer			Buffer to hold the vehicle class name
* @param size			Len of the buffer
* @return				Vehicle Class (-1 on error)
*/
stock GetVehicleClassName(ent, String:buffer[], size)
{
	if(!IsValidEntity(ent)) return -1.0;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1.0;
	new off = FindSendPropOffs("CEmpTank", "m_iChassis");
	new out = GetEntData(ent, off, 4);
	new Handle:VehicleNames = CreateTrie();
	SetTrieString(VehicleNames, "0", "NF Jeep", true);
	SetTrieString(VehicleNames, "1", "NF APC", true);
	SetTrieString(VehicleNames, "2", "NF Light Tank", true);
	SetTrieString(VehicleNames, "3", "NF Med Tank", true);
	SetTrieString(VehicleNames, "4", "NF Heavy Tank", true);
	SetTrieString(VehicleNames, "5", "NF Arty Tank", true);
	SetTrieString(VehicleNames, "6", "Imperial Jeep", true);
	SetTrieString(VehicleNames, "7", "Imperial APC", true);
	SetTrieString(VehicleNames, "8", "Imperial AFV", true);
	SetTrieString(VehicleNames, "9", "Imperial Med Tank", true);
	SetTrieString(VehicleNames, "10", "Imperial Heavy Tank", true);
	SetTrieString(VehicleNames, "11", "Imperial Arty Tank", true);
	SetTrieString(VehicleNames, "12", "Imperial Commander", true);
	SetTrieString(VehicleNames, "13", "NF Commander", true);
	decl String:vehicle[64], String:vehiclename[64];
	IntToString(out, research ,sizeof(research));
	GetTrieString(VehicleNames, vehicle, vehiclename, sizeof(vehiclename));
	strcopy(buffer, size, vehiclename);
	return out;
}

/**
* Get Client Vehicle
*
* @param client			Client Index
* @return				Client Vehicle Entity Index (-1 is error, 0 is none)
*/
stock GetPlayerVehicle(client)
{
	new team = GetClientTeam(client);
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent, out = -1;
	if(team == 2){
		for(new i = 0; i <= maxents; i++){
			if(IsValidEntity(i)){
				GetEntityNetClass(i, classname, sizeof(classname));
				if(StrEqual(classname, "CPlayerResource_NF")){
					ent = i;
					break;
				}
			}
		}
		new offset = FindSendPropOffs("CPlayerResource_NF", "m_iVehicle_NF");
		out = GetEntData(ent, offset + (client*4), 4);
	}else if(team == 3){
		for(new i = 0; i <= maxents; i++){
			if(IsValidEntity(i)){
				GetEntityNetClass(i, classname, sizeof(classname));
				if(StrEqual(classname, "CPlayerResource_IMP")){
					ent = i;
					break;
				}
			}
		}
		new offset = FindSendPropOffs("CPlayerResource_IMP", "m_iVehicle_IMP");
		out = GetEntData(ent, offset + (client*4), 4);
	}
	if(IsComm(client)){
		if(Team == 2){
			for(new i = 0; i <= maxents; i++){
				if(IsValidEntity(i)){
					GetEdictClassname(i, classname, sizeof(classname));
					if(StrEqual(classname, "emp_nf_commander")){
						out = i;
						break;
					}
				}
			}
		}else if(Team == 3){
			for(new i = 0; i <= maxents; i++){
				if(IsValidEntity(i)){
					GetEdictClassname(i, classname, sizeof(classname));
					if(StrEqual(classname, "emp_imp_commander")){
						out = i;
						break;
					}
				}
			}
		}
	}
	return out;
}

/**
* Get Cannon Entity
*
* @param ent			Vehicle Entity Index
* @return				Cannon Entity Index
*/
stock GetCannonEnt(ent)
{
	if(!IsValidEntity(ent)) return -1;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1;
	new off = FindSendPropOffs("CEmpTank", "m_hCannon");
	new out = GetEntDataEnt(ent, off);
	return out;
}

/**
* Get Turret Entity
*
* @param ent			Vehicle Entity Index
* @return				Turret Entity Index
*/
stock GetTurretEnt(ent)
{
	if(!IsValidEntity(ent)) return -1;
	new String:class[256];
	GetEntityNetClass(ent, class, sizeof(class));
	if(!StrEqual(class, "CEmpTank", false)) return -1;
	new off = FindSendPropOffs("CEmpTank", "m_hTurret");
	new out = GetEntDataEnt(ent, off);
	return out;
}















/**********************
* --> Misc Stocks <-- *
**********************/

/**
* Retrieves a player's squad number
*
* @param client			Client Index
* @return				Player squad index (0 is none)
*/
stock GetPlayerSquadNum(client)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CPlayerResource")){
                ent = i;
                break;
            }
        }
    }
	new offset = FindSendPropOffs("CPlayerResource", "m_iSquad");
	new out = GetEntData(ent, offset + (client*4), 4);
	return out;
}


/**
* Retrieves a player's squad name
*
* @param client			Client Index
* @param buffer			Buffer to hold the squad name
* @param size			Len of the buffer
* @return				Player squad index
*/
stock GetPlayerSquadName(client, String:buffer[], size)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CPlayerResource")){
                ent = i;
                break;
            }
        }
    }
	new offset = FindSendPropOffs("CPlayerResource", "m_iSquad");
	new out = GetEntData(ent, offset + (client*4), 4);
	new Handle:	SquadNames = CreateTrie();
	SetTrieString(SquadNames, "0", "None", true);
	SetTrieString(SquadNames, "1", "Alpha", true);
	SetTrieString(SquadNames, "2", "Bravo", true);
	SetTrieString(SquadNames, "3", "Charlie", true);
	SetTrieString(SquadNames, "4", "Delta", true);
	SetTrieString(SquadNames, "5", "Echo", true);
	SetTrieString(SquadNames, "6", "Foxtrot", true);
	SetTrieString(SquadNames, "7", "Golf", true);
	SetTrieString(SquadNames, "8", "Hotel", true);
	SetTrieString(SquadNames, "9", "India", true);
	SetTrieString(SquadNames, "10", "Juliet", true);
	SetTrieString(SquadNames, "11", "Kilo", true);
	SetTrieString(SquadNames, "12", "Lima", true);
	SetTrieString(SquadNames, "13", "Mike", true);
	SetTrieString(SquadNames, "14", "November", true);
	SetTrieString(SquadNames, "15", "Oscar", true);
	SetTrieString(SquadNames, "16", "Papa", true);
	SetTrieString(SquadNames, "17", "Quebec", true);
	SetTrieString(SquadNames, "18", "Romeo", true);
	SetTrieString(SquadNames, "19", "Sierra", true);
	SetTrieString(SquadNames, "20", "Tango", true);
	SetTrieString(SquadNames, "21", "Uniform", true);
	SetTrieString(SquadNames, "22", "Victor", true);
	SetTrieString(SquadNames, "23", "Whiskey", true);
	SetTrieString(SquadNames, "24", "X-Ray", true);
	SetTrieString(SquadNames, "25", "Yankee", true);
	SetTrieString(SquadNames, "26", "Zulu", true);
	decl String:squad[64], String:squadname[64];
	IntToString(out, squad ,sizeof(squad));
	GetTrieString(SquadNames, squad, squadname, sizeof(squadname));
	strcopy(buffer, size, squadname);
	return out;
}

/**
* Retrieves a player's score
*
* @param client			Client Index
* @return				Player score
*/
stock GetPlayerScore(client)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CPlayerResource")){
                ent = i;
                break;
            }
        }
    }
	new offset = FindSendPropOffs("CPlayerResource", "m_iScore");
	new out = GetEntData(ent, offset + (client*4), 4);
	return out;
}


/**
* Retrieves a player's class
*
* @param client			Client Index
* @return				Player class (0 is scout, 1 is rifleman, 2 is gren, 3 is engy, 5 is spec)
*/
stock GetPlayerClassNum(client)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CPlayerResource")){
                ent = i;
                break;
            }
        }
    }
	new offset = FindSendPropOffs("CPlayerResource", "m_iClass");
	new out = GetEntData(ent, offset + (client*4), 4);
	return out;
}

/**
* Retrieves a player's class
*
* @param client			Client Index
* @param buffer			Buffer to hold the class name
* @param size			Len of the buffer
* @return				Player class index
*/
stock GetPlayerClassName(client, String:buffer[], size)
{
	new maxents = GetMaxEntities();
	decl String:classname[64];
	new ent;
	for(new i = 0; i <= maxents; i++){
        if(IsValidEntity(i)){
            GetEntityNetClass(i, classname, sizeof(classname));
            if(StrEqual(classname, "CPlayerResource")){
                ent = i;
                break;
            }
        }
    }
	new offset = FindSendPropOffs("CPlayerResource", "m_iClass");
	new out = GetEntData(ent, offset + (client*4), 4);
	new Handle:ClassNames = CreateTrie();
	SetTrieString(ClassNames, "0", "Scout", true);
	SetTrieString(ClassNames, "1", "Rifleman", true);
	SetTrieString(ClassNames, "2", "Grenadier", true);
	SetTrieString(ClassNames, "3", "Engineer", true);
	SetTrieString(ClassNames, "4", "Unknown", true);
	SetTrieString(ClassNames, "5", "None", true);
	decl String:class[64], String:classname2[64];
	IntToString(out, class ,sizeof(class));
	GetTrieString(ClassNames, class, classname2, sizeof(classname2));
	strcopy(buffer, size, classname2);
	return out;
}