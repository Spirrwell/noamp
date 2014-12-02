// NOAMP Spawns

/* FIXME: rewrite the whole spawn code in future, some of the stuff is taken from almcaeobtac's Dynamic NPC Spawner!! for temp use testing game logic
* and special thanks to him ofc
* https://forums.alliedmods.net/showthread.php?t=133910
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <morecolors>

public FindSpawns()
{
	decl String:targetname[128];
	decl Float:entorg[3];
	new count;
	new giantcount;
	new bosscount;
	
	for (new i = 0; i < 3000; i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
			if (StrEqual(targetname, "noamp_parrotspawn"))
			{
				count++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", entorg);
				Format(ParrotSpawns[count], 128, "%f %f %f", entorg[0], entorg[1], entorg[2]);
				
				if (GetConVarBool(cvar_debug))
				{
					PrintToServer("caught a spawn target");
					PrintToServer("m_vecOrigin = %s", ParrotSpawns[count]);
				}
			}
			
			if (StrEqual(targetname, "noamp_giantparrot_spawn"))
			{
				giantcount++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", entorg);
				Format(GiantParrotSpawns[giantcount], 128, "%f %f %f", entorg[0], entorg[1], entorg[2]);
				
				if (GetConVarBool(cvar_debug))
				{
					PrintToServer("caught a giant parrot spawn target");
					PrintToServer("m_vecOrigin = %s", GiantParrotSpawns[giantcount]);
				}
			}
			
			if (StrEqual(targetname, "noamp_boss_spawn"))
			{
				bosscount++;
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", entorg);
				Format(BossParrotSpawns[bosscount], 128, "%f %f %f", entorg[0], entorg[1], entorg[2]);
				
				if (GetConVarBool(cvar_debug))
				{
					PrintToServer("caught a boss spawn target");
					PrintToServer("m_vecOrigin = %s", BossParrotSpawns[bosscount]);
				}
			}
		}
	}
}

public ResetSpawns()
{
	for (new i = 0; i < 1000; i++)
	{
		ParrotSpawns[i] = "null";
	}
	for (new i = 0; i < 1000; i++)
	{
		GiantParrotSpawns[i] = "null";
	}
	for (new i = 0; i < 1000; i++)
	{
		BossParrotSpawns[i] = "null";
	}
	
	FindSpawns();
}

public GetSpawnCount()
{
	new spawns = 0;
	for (new i = 0; i <= 1000; i++)
	{
		if (!StrEqual(ParrotSpawns[i], "null", false))
		{
			spawns++;
		}
	}
	new String:tempstring[4];
	IntToString(spawns, tempstring, 4);
	return spawns;
}

public GetRandomSpawnPoint()
{
	new nodecount = 0;
	new currentnode = 1;
	
	while (currentnode <= GetSpawnCount())
	{
		nodecount++;
		currentnode++;
	}
	
	if (nodecount == 0)
	{
		PrintToServer("NO NODES!!!!");
		return 0;
	}
	
	decl choosenode[nodecount+1];
	
	nodecount = 0;
	currentnode = 1;
	
	while (currentnode <= GetSpawnCount())
	{
		nodecount++;
		choosenode[nodecount] = currentnode;
		currentnode++;
	}
	
	new randomnode = choosenode[GetRandomInt(1, nodecount)];
	
	return randomnode;
}

public SpawnParrot()
{
	new randomnode = GetRandomSpawnPoint();
	
	if (randomnode == 0)
	{
		LogError("No nodes, not spawning parrot.");
		return;
	}
	
	new parrot = CreateEntityByName("npc_parrot");
	
	decl String:nodepoints[3][128];
	ExplodeString(ParrotSpawns[randomnode], " ", nodepoints, 3, 128);
	
	decl Float:nodeorg[3];
	nodeorg[0] = StringToFloat(nodepoints[0]);
	nodeorg[1] = StringToFloat(nodepoints[1]);
	nodeorg[2] = StringToFloat(nodepoints[2]);
	
	decl String:orgstring[128];
	Format(orgstring, 128, "%f %f %f", nodeorg[0], nodeorg[1], nodeorg[2]);
	
	DispatchKeyValue(parrot, "origin", orgstring);
	DispatchSpawn(parrot);
	
	DispatchKeyValue(parrot, "targetname", "noamp_parrot");
	
	if (GetConVarBool(cvar_debug))
	{
		PrintToServer("Parrot spawned at %s", orgstring);
	}
}

public SpawnGiantParrot()
{	
	new randomnode = GetRandomSpawnPoint();
	
	if (randomnode == 0)
	{
		LogError("No nodes, not spawning parrot.");
		return;
	}
	
	new parrot = CreateEntityByName("npc_parrot");
	
	decl String:nodepoints[3][128];
	ExplodeString(GiantParrotSpawns[randomnode], " ", nodepoints, 3, 128);
	
	decl Float:nodeorg[3];
	nodeorg[0] = StringToFloat(nodepoints[0]);
	nodeorg[1] = StringToFloat(nodepoints[1]);
	nodeorg[2] = StringToFloat(nodepoints[2]);
	
	decl String:orgstring[128];
	Format(orgstring, 128, "%f %f %f", nodeorg[0], nodeorg[1], nodeorg[2]);
	
	DispatchKeyValue(parrot, "origin", orgstring);
	DispatchSpawn(parrot);
	
	decl Float:vecParrotMins[3];
	decl Float:vecParrotMaxs[3];
	GetEntPropVector(parrot, Prop_Send, "m_vecMins", vecParrotMins);
	GetEntPropVector(parrot, Prop_Send, "m_vecMaxs", vecParrotMaxs);
	
	ScaleVector(vecParrotMins, giantParrotSize);
	ScaleVector(vecParrotMaxs, giantParrotSize);
	
	SetEntPropVector(parrot, Prop_Send, "m_vecSpecifiedSurroundingMins", vecParrotMins);
	SetEntPropVector(parrot, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecParrotMaxs);
	
	new Float:scalevalue = giantParrotSize;
	SetEntPropFloat(parrot, Prop_Send, "m_flModelScale", scalevalue);
	
	SetEntProp(parrot, Prop_Data, "m_iHealth", 100);
	DispatchKeyValue(parrot, "targetname", "noamp_giant");
	
	if (GetConVarBool(cvar_debug))
	{
		PrintToServer("Giant parrot spawned at %s", orgstring);
	}
}

public SpawnBossParrot()
{	
	new randomnode = GetRandomSpawnPoint();
	
	if (randomnode == 0)
	{
		LogError("No nodes, not spawning parrot.");
		return;
	}
	
	new parrot = CreateEntityByName("npc_parrot");
	
	decl String:nodepoints[3][128];
	ExplodeString(GiantParrotSpawns[randomnode], " ", nodepoints, 3, 128);
	
	decl Float:nodeorg[3];
	nodeorg[0] = StringToFloat(nodepoints[0]);
	nodeorg[1] = StringToFloat(nodepoints[1]);
	nodeorg[2] = StringToFloat(nodepoints[2]);
	
	decl String:orgstring[128];
	Format(orgstring, 128, "%f %f %f", nodeorg[0], nodeorg[1], nodeorg[2]);
	
	DispatchKeyValue(parrot, "origin", orgstring);
	DispatchSpawn(parrot);
	
	decl Float:vecParrotMins[3];
	decl Float:vecParrotMaxs[3];
	GetEntPropVector(parrot, Prop_Send, "m_vecMins", vecParrotMins);
	GetEntPropVector(parrot, Prop_Send, "m_vecMaxs", vecParrotMaxs);
	
	ScaleVector(vecParrotMins, bossParrotSize);
	ScaleVector(vecParrotMaxs, bossParrotSize);
	
	SetEntPropVector(parrot, Prop_Send, "m_vecSpecifiedSurroundingMins", vecParrotMins);
	SetEntPropVector(parrot, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecParrotMaxs);
	
	new Float:scalevalue = bossParrotSize;
	SetEntPropFloat(parrot, Prop_Send, "m_flModelScale", scalevalue);
	
	SetEntProp(parrot, Prop_Data, "m_iHealth", parrotBossHP);
	DispatchKeyValue(parrot, "targetname", "noamp_boss");
	
	if (GetConVarBool(cvar_debug))
	{
		PrintToServer("Boss parrot spawned at %s", orgstring);
	}
}