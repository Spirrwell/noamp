// NIGHT OF A MILLION PARROTS
// Main script

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <morecolors>

#include "noamp\noamp_defs.sp"
#include "noamp\noamp_cmds.sp"
#include "noamp\noamp_menus.sp"
#include "noamp\noamp_logic.sp"
#include "noamp\noamp_events.sp"
#include "noamp\noamp_spawns.sp"

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "NIGHT OF A MILLION PARROTS",
	author = "Felis",
	description = "Coop survival gamemode against waves of PARROTS!",
	version = PL_VERSION,
	url = "http://loli.dance/"
}

public OnPluginStart()
{
	RegisterCvars();
	RegisterCmds();
	SDKStuff();
	HookEvents();
	FindPropInfo();
	CommandListeners();
	AddFilesToDownloadTable();
	
	CreateDirectory("addons/sourcemod/data/noamp", 3);

	LoadTranslations("noamp.phrases");
	AddServerTag(SERVER_TAG);
	
	AddNormalSoundHook( NormalSoundHook );
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
    MarkNativeAsOptional("GetUserMessageType");
    return APLRes_Success;
}

RegisterCvars()
{
	cvar_enabled = CreateConVar("noamp_enabled", "1", "Enable NIGHT OF A MILLION PARROTS gamemode.");
	cvar_debug = CreateConVar("noamp_debug", "0", "Enable debug mode for testing.");
	cvar_difficulty = CreateConVar("noamp_difficulty", "normal", "Game difficulty, loads a script named [mapname]_[difficulty].txt eg. noamp_forest_normal.txt");
	cvar_ignoreprefix = CreateConVar("noamp_ignoreprefix", "0", "Ignores the noamp_ map prefix check in map start. Allows NOAMP in every other map.");
	
	HookConVarChange(cvar_enabled, cvHookEnabled);
	HookConVarChange(cvar_difficulty, cvHookDifficulty);
	
	/* replaced by keyvalues
	cvar_lives = CreateConVar("noamp_playerlives", "10", "How many lives players have. 0 for infinite.");
	cvar_maxhpprice = CreateConVar("noamp_upgrades_maxhp_price", "500", "How much max HP upgrade costs?");
	cvar_maxarmorprice = CreateConVar("noamp_upgrades_maxarmor_price", "300", "How much max armor upgrade costs?");
	cvar_maxspeedprice = CreateConVar("noamp_upgrades_maxspeed_price", "450", "How much max speed upgrade costs?");
	cvar_kegprice = CreateConVar("noamp_weapons_keg_price", "100", "How much one powder keg costs?");
	cvar_chestaward = CreateConVar("noamp_chestaward", "300", "How much money each team member gets from chest capture?");
	cvar_preparationsecs = CreateConVar("noamp_preparationsecs", "30", "Preparation phase time.");
	cvar_giantparrotsize = CreateConVar("noamp_giantparrotsize", "4.0", "Size of giant parrots.");
	cvar_bossparrotsize = CreateConVar("noamp_bossparrotsize", "12.0", "Size of giant parrots.");
	*/
	
	AutoExecConfig(true, "noamp");
}

RegisterCmds()
{
	RegConsoleCmd("noamp_menu", CMD_NOAMP_Menu);
	RegConsoleCmd("noamp_givemoney", GiveMoneyToTarget);
	RegAdminCmd("noamp_startgame", CmdStartGame, ADMFLAG_KICK, "Start the game.");
	RegAdminCmd("noamp_resetgame", CmdResetGame, ADMFLAG_KICK, "Reset the game.");
	RegConsoleCmd("debug_noamp_testparrotspawns", CmdTestSpawns);
	RegConsoleCmd("debug_noamp_testgiantparrotspawns", CmdTestGiantSpawns);
	RegConsoleCmd("debug_noamp_gibemonipls", CmdGiveMoney);
	RegConsoleCmd("debug_noamp_giballupgraeds", CmdGiveAllUpgrades);
	RegConsoleCmd("debug_noamp_reloadscript", CmdReloadKeyValues);
	RegConsoleCmd("debug_noamp_jumptowave", CmdJumpToWave);
}

SDKStuff()
{
	/*
	* hello, theres nothing here yet
	*/
}

HookEvents()
{
	HookEvent("gamemode_firstround_wait_end", Event_WaitEnd);
	HookEvent("npc_death", OnParrotDeath);
	HookEvent("chest_capture", OnChestCapture);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_hurt", OnPlayerHurt);
}

FindPropInfo()
{
	h_iSpecial = FindSendPropOffs("CPVK2Player", "m_iSpecial");
	h_iHealth = FindSendPropInfo("CPVK2Player", "m_iHealth");
	h_ArmorValue = FindSendPropInfo("CPVK2Player", "m_ArmorValue");
	h_iMaxHealth = FindSendPropInfo("CPVK2Player", "m_iMaxHealth");
	h_iMaxArmor = FindSendPropInfo("CPVK2Player", "m_iMaxArmor");
	h_flMaxspeed = FindSendPropInfo("CPVK2Player", "m_flMaxspeed");
	h_flDefaultSpeed = FindSendPropInfo("CPVK2Player", "m_flDefaultSpeed");
	h_iPlayerClass = FindSendPropInfo("CPVK2Player", "m_iPlayerClass");
	h_flModelScale = FindSendPropOffs("CBasePlayer", "m_flModelScale");
}

CommandListeners()
{
	AddCommandListener(ChatListener, "say");
	AddCommandListener(ChatListener, "say2");
	AddCommandListener(ChatListener, "say_team");
	
	AddCommandListener(ChangeTeamListener, "changeteam");
	AddCommandListener(DropItemListener, "dropitem");
}

AddFilesToDownloadTable()
{
	AddFileToDownloadsTable("sound/noamp/gameover.mp3");
	AddFileToDownloadsTable("sound/noamp/music/corruptor.mp3");
	AddFileToDownloadsTable("sound/noamp/kaching.mp3");
	AddFileToDownloadsTable("sound/noamp/playerdeath.mp3");
	AddFileToDownloadsTable("sound/noamp/playerdisconnect.mp3");
	AddFileToDownloadsTable("sound/noamp/mystic.mp3");
}

public Precache()
{
	PrecacheSound("music/deadparrotachieved.mp3");
	PrecacheSound("noamp/noamp_gameover.mp3");
	PrecacheSound("noamp/music/corruptor.mp3");
	PrecacheSound("noamp/kaching.mp3");
	PrecacheSound("noamp/playerdeath.mp3");
	PrecacheSound("noamp/playerdisconnect.mp3");
	PrecacheSound("noamp/mystic.mp3");
}

public ReadNOAMPScript()
{
	new Handle:kv = CreateKeyValues("NOAMP_Scheme");
	FileToKeyValues(kv, KVPath);
	
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	
	decl String:buffer[12];
	KvGetSectionName(kv, buffer, sizeof(buffer));
	
	if (StrEqual(buffer, "general"))
	{
		new String:strschemename[256];
		new String:strbossparrothp[32];
		new String:strbossparrotsize[32];
		new String:strchestaward[32];
		new String:strgiantparrotsize[32];
		new String:strplayerlives[32];
		new String:strpreparationsecs[32];
		new String:strmaxhpprice[32];
		new String:strmaxarmorprice[32];
		new String:strmaxspeedprice[32];
		new String:strkegprice[32];
		new String:strfillspecialprice[32];
		
		KvGetString(kv, "name", strschemename, 256);
		KvGetString(kv, "bossparrothp", strbossparrothp, 32);
		KvGetString(kv, "bossparrotsize", strbossparrotsize, 32);
		KvGetString(kv, "chestaward", strchestaward, 32);
		KvGetString(kv, "giantparrotsize", strgiantparrotsize, 32);
		KvGetString(kv, "playerlives", strplayerlives, 32);
		KvGetString(kv, "preparationsecs", strpreparationsecs, 32);
		KvGetString(kv, "maxhpprice", strmaxhpprice, 32);
		KvGetString(kv, "maxarmorprice", strmaxarmorprice, 32);
		KvGetString(kv, "maxspeedprice", strmaxspeedprice, 32);
		KvGetString(kv, "kegprice", strkegprice, 32);
		KvGetString(kv, "fillspecialprice", strfillspecialprice, 32);
		
		schemeName = strschemename;
		parrotBossHP = StringToInt(strbossparrothp);
		bossParrotSize = StringToFloat(strbossparrotsize);
		chestAward = StringToInt(strchestaward, 10);
		giantParrotSize = StringToFloat(strgiantparrotsize);
		playerLives = StringToInt(strplayerlives, 10);
		preparationSecs = StringToInt(strpreparationsecs, 10);
		maxHPPrice = StringToInt(strmaxhpprice, 10);
		maxArmorPrice = StringToInt(strmaxarmorprice, 10);
		maxSpeedPrice = StringToInt(strmaxspeedprice, 10);
		kegPrice = StringToInt(strkegprice, 10);
		powerupFillSpecialPrice = StringToInt(strfillspecialprice, 10);
		
		KvGotoNextKey(kv);
	}
	
	new ibuffer;
	new String:stri[32];
	waveCount = 0;
	
	for (new i = 1; i < NOAMP_MAXWAVES; i++)
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		ibuffer = StringToInt(buffer, 10);
		IntToString(i, stri, 32);
		
		if (StrEqual(buffer, stri))
		{
			new String:strparrotcount[32];
			new String:strgiantparrotcount[32];
			new String:strmaxparrots[32];
			new String:strisboss[2];
			
			KvGetString(kv, "parrotcount", strparrotcount, 32);
			KvGetString(kv, "giantparrotcount", strgiantparrotcount, 32);
			KvGetString(kv, "maxparrots", strmaxparrots, 32);
			KvGetString(kv, "boss", strisboss, 2);
			
			waveParrotCount[ibuffer] = StringToInt(strparrotcount, 10);
			waveGiantParrotCount[ibuffer] = StringToInt(strgiantparrotcount, 10);
			waveMaxParrots[ibuffer] = StringToInt(strmaxparrots, 10);
			
			new bossint;
			bossint = StringToInt(strisboss, 10);
			if (bossint == 0)
				waveIsBossWave[ibuffer] = false;
			else if (bossint == 1)
				waveIsBossWave[ibuffer] = true;
			else if (bossint != 0 || bossint != 1)
			{
				waveIsBossWave[ibuffer] = false;
				LogError("KeyValue \"boss\" can only be 0 or 1.");
			}
			
			waveCount++;
		}
		KvGotoNextKey(kv);
	}
	
	if (GetConVarBool(cvar_debug))
	{
		PrintToServer("Wave count: %d", waveCount);
	}
	
	CloseHandle(kv);
	return;
}

public cvHookEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	IsEnabled = GetConVarBool(cvar);
}

public cvHookDifficulty(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:difficulty[128] = "null";
	GetConVarString(cvar_difficulty, difficulty, 128);
	
	decl String:currentMap[128];
	GetCurrentMap(currentMap, 128);
	
	if (StrEqual(difficulty, "null", false) || StrEqual(difficulty, "", false))
	{
		LogError("\"null\" difficulty, loading default scheme.");
		BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/noamp/default.txt", currentMap, difficulty);
	}
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/noamp/%s_%s.txt", currentMap, difficulty);
	PrintToServer("Loaded NOAMP scheme %s.", KVPath);
	
	ResetGame(false, true);
}

public Action:NormalSoundHook(iClients[64], &iNumClients, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags)
{
	new bool:bValid = false;
	
	bValid = StrContains(strSample, "weapons/parrot", false) == 0;
	
	if (bValid)
	{
		iPitch = parrotSoundPitch;
		iFlags |= SND_CHANGEPITCH;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnClientConnected(client)
{
	
}

public OnClientDisconnect(client)
{
	ResetClient(client, false);
	EmitSoundToAll("noamp/playerdisconnect.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS);
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (!IsEnabled)
		return Plugin_Continue;
	
	if (IsMapLoaded)
	{	
		new String:newInfo[64];
		Format(newInfo, 64, "Night of a Million Parrots %s", PL_VERSION);
		strcopy(gameDesc, sizeof(gameDesc), newInfo);
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnMapStart()
{
	IsEnabled = GetConVarBool(cvar_enabled);
	
	if (!IsEnabled)
	{
		PrintToServer("NOAMP is disabled, not loading stuff.");
		return;
	}
	
	decl String:currentMap[128];
	GetCurrentMap(currentMap, 128);
	
	if (!GetConVarBool(cvar_ignoreprefix))
	{
		if (StrContains(currentMap, "noamp_", false) == -1)
		{
			PrintToServer("NOAMP is disabled, maps prefix is not \"noamp_\". You can disable this check by changing cvar noamp_ignoreprefix to 1.");
			IsEnabled = false;
			return;
		}
	}
	
	decl String:difficulty[128] = "null";
	GetConVarString(cvar_difficulty, difficulty, 128);
	
	if (StrEqual(difficulty, "null", false) || StrEqual(difficulty, "", false))
	{
		LogError("\"null\" difficulty, loading default scheme.");
		BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/noamp/default.txt", currentMap, difficulty);
	}
	
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/noamp/%s_%s.txt", currentMap, difficulty);
	PrintToServer("Loaded NOAMP scheme %s.", KVPath);
	
	Precache();
	ResetGame(false, false);
	FindSpawns();
	
	CreateTimer(0.1, HUD, _, TIMER_REPEAT);
	
	IsGameStarted = false;
	IsMapLoaded = true;
	IsWaitingForPlayers = true;
	
	if (playerLives == 0)
		IsLivesDisabled = true;
	else
	IsLivesDisabled = false;
	
	for (new i = 0; i < MaxClients; i++)
	{
		clientLives[i] = 0;
	}
}

public OnMapEnd()
{
	IsMapLoaded = false;
	ResetGame(false, false);
}