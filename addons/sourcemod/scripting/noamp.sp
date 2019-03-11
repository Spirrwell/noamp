/************************************************************************
*	This file is part of NOAMP.
*
*	NOAMP is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	NOAMP is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with NOAMP.  If not, see <http://www.gnu.org/licenses/>.
************************************************************************/

// NIGHT OF A MILLION PARROTS
// Main script 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <steamtools>
#include <morecolors>

#include "noamp\noamp_defs.sp"
#include "noamp\noamp_funcs.sp"
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
	
	AddNormalSoundHook(NormalSoundHook);
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
	cvar_difficulty = CreateConVar("noamp_difficulty", "normal", "Game difficulty, loads a script named {mapname}_{difficulty}.txt eg. noamp_forest_normal.txt. If you want to choose a scheme to load, use noamp_scheme.");
	cvar_scheme = CreateConVar("noamp_scheme", "null", "If not \"null\", loads a chosen script from ../sourcemod/data/noamp. Difficulty settings will be used otherwise.");
	cvar_ignoreprefix = CreateConVar("noamp_ignoreprefix", "0", "Ignores the noamp_ map prefix check in map start. Allows NOAMP in every other map.");
	cvar_timelimit = FindConVar("mp_timelimit");
	
	
	HookConVarChange(cvar_enabled, cvHookEnabled);
	HookConVarChange(cvar_difficulty, cvHookDifficulty);
	HookConVarChange(cvar_scheme, cvHookScheme);
	
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
	AddFileToDownloadsTable("sound/noamp/music/corruptor2.mp3");
	AddFileToDownloadsTable("sound/noamp/corruptor/corruption.mp3");
	AddFileToDownloadsTable("noamp/corruptor/glitch.mp3");
	AddFileToDownloadsTable("noamp/corruptor/secret.mp3");
	AddFileToDownloadsTable("noamp/corruptor/something.mp3");
	AddFileToDownloadsTable("sound/noamp/kaching.mp3");
	AddFileToDownloadsTable("sound/noamp/playerdeath.mp3");
	AddFileToDownloadsTable("sound/noamp/playerdisconnect.mp3");
	AddFileToDownloadsTable("sound/noamp/mystic.mp3");
	AddFileToDownloadsTable("sound/noamp/timertick.wav");
	
	for (new i = 0; i < 9; i++)
	{
		decl String:sample[64];
		Format(sample, sizeof(sample), "%s", SpookySounds[i]);
		AddFileToDownloadsTable(sample);
	}
	
	for (new i = 0; i < 4; i++)
	{
		decl String:sample[64];
		Format(sample, sizeof(sample), "%s", CorruptorSpeech[i]);
		AddFileToDownloadsTable(sample);
	}
}

public Precache()
{
	PrecacheSound("music/deadparrotachieved.mp3");
	PrecacheSound("noamp/gameover.mp3");
	PrecacheSound("noamp/music/corruptor.mp3");
	PrecacheSound("noamp/music/corruptor2.mp3");
	PrecacheSound("noamp/corruptor/corruption.mp3");
	PrecacheSound("noamp/corruptor/glitch.mp3");
	PrecacheSound("noamp/corruptor/secret.mp3");
	PrecacheSound("noamp/corruptor/something.mp3");
	PrecacheSound("noamp/kaching.mp3");
	PrecacheSound("noamp/playerdeath.mp3");
	PrecacheSound("noamp/playerdisconnect.mp3");
	PrecacheSound("noamp/mystic.mp3");
	PrecacheSound("noamp/timertick.wav");
	
	for (new i = 0; i < 9; i++)
	{
		decl String:sample[64];
		Format(sample, sizeof(sample), "%s", SpookySounds[i]);
		PrecacheSound(sample);
	}
	
	for (new i = 0; i < 4; i++)
	{
		decl String:sample[64];
		Format(sample, sizeof(sample), "%s", CorruptorSpeech[i]);
		PrecacheSound(sample);
	}
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
		BuildPath(Path_SM, ScriptPath, sizeof(ScriptPath), "data/noamp/default.txt");
	}
	BuildPath(Path_SM, ScriptPath, sizeof(ScriptPath), "data/noamp/%s_%s.txt", currentMap, difficulty);
	PrintToServer("Loaded NOAMP scheme %s.", ScriptPath);
	
	ResetGame(false, true);
	UpdateGameDesc();
}

public cvHookScheme(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	decl String:scheme[128] = "null";
	GetConVarString(cvar_scheme, scheme, 128);
	
	if (StrEqual(scheme, "null", false) || StrEqual(scheme, "", false))
	{
		LogError("\"null\" scheme, loading default scheme.");
		BuildPath(Path_SM, ScriptPath, sizeof(ScriptPath), "data/noamp/default.txt");
	}
	BuildPath(Path_SM, ScriptPath, sizeof(ScriptPath), "data/noamp/%s", scheme);
	PrintToServer("Loaded NOAMP scheme %s.", ScriptPath);
	
	ResetGame(false, true);
	UpdateGameDesc();
}

public Action:NormalSoundHook(iClients[64], &iNumClients, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags)
{
	new bool:bValid = false;
	new bool:bValidTimer = false;
	
	bValid = StrContains(strSample, "weapons/parrot", false) == 0;
	bValidTimer = StrContains(strSample, "noamp/timertick.wav", false) == 0;
	
	if (bValid)
	{
		iPitch = parrotSoundPitch;
		iFlags |= SND_CHANGEPITCH;
		return Plugin_Changed;
	}
	if (bValidTimer)
	{
		iPitch = timerSoundPitch;
		iFlags |= SND_CHANGEPITCH;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnClientConnected(client)
{
	decl String:name[128];
	GetClientName(client, name, sizeof(name));
	if (HasWaveStarted)
	{
		CPrintToChat(client, "Welcome to NOAMP %s! A wave is currently in progress and you can join in after it ends.", name);
	}
}

public OnClientDisconnect(client)
{
	ResetClient(client, false);
	EmitSoundToAll("noamp/playerdisconnect.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS);
}

public OnConfigsExecuted()
{
	UpdateGameDesc();
}

public OnMapStart()
{
	IsEnabled = GetConVarBool(cvar_enabled);
	
	// just in case, slaughter the timers if something is left ticking from last game
	//KillTimers();
	
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
	
	decl String:scheme[128] = "null";
	GetConVarString(cvar_scheme, scheme, 128);
	
	if (StrEqual(scheme, "null", false) || StrEqual(scheme, "", false))
	{
		IsCustomScheme = false;
	}
	else
	{
		IsCustomScheme = true;
	}
	
	if (IsCustomScheme)
	{
		BuildPath(Path_SM, ScriptPath, sizeof(ScriptPath), "data/noamp/%s", scheme);
		PrintToServer("Loaded NOAMP scheme %s.", ScriptPath);
	}
	else
	{
		decl String:difficulty[128] = "null";
		GetConVarString(cvar_difficulty, difficulty, 128);
		
		if (StrEqual(difficulty, "null", false) || StrEqual(difficulty, "", false))
		{
			LogError("\"null\" difficulty, loading default scheme.");
			BuildPath(Path_SM, ScriptPath, sizeof(ScriptPath), "data/noamp/default.txt");
		}
		
		BuildPath(Path_SM, ScriptPath, sizeof(ScriptPath), "data/noamp/%s_%s.txt", currentMap, difficulty);
		PrintToServer("Loaded NOAMP scheme %s.", ScriptPath);
	}
	
	Precache();
	ResetGame(false, false);
	FindSpawns();
	
	h_TimerHUD = CreateTimer(0.1, HUD, _, TIMER_REPEAT);
	h_TimerWaitingForPlayers = CreateTimer(0.1, WaitingForPlayers, _, TIMER_REPEAT);
	
	HasGameStarted = false;
	IsMapLoaded = true;
	
	if (playerLives == 0)
		IsLivesDisabled = true;
	else
	IsLivesDisabled = false;
	
	// time limit will end the game in progress, attemping to disable
	// save the old value so we can restore
	// TODO: replace this with a custom time limit thing in the future
	timelimitSavedValue = GetConVarInt(cvar_timelimit);
	SetConVarInt(cvar_timelimit, 0);
}

public OnMapEnd()
{
	IsMapLoaded = false;
	ResetGame(false, false);
}

public UpdateGameDesc()
{
	decl String:gamedesc[256];
	if (StrEqual(schemeName, "null", false))
	{
		Format(gamedesc, 256, "NOAMP %s", PL_VERSION);
	}
	else
	{
		Format(gamedesc, 256, "NOAMP %s: %s", PL_VERSION, schemeName);
	}
	Steam_SetGameDescription(gamedesc);
}

public ReadNOAMPScript()
{
	new Handle:kv = CreateKeyValues("NOAMP_Scheme");
	FileToKeyValues(kv, ScriptPath);
	
	if (!KvGotoFirstSubKey(kv))
	{
		if (StrEqual(ScriptPath, "data/noamp/default.txt", false))
		{
			LogError("Error reading default KeyValues, default.txt might be missing. NOAMP will not be loaded.");
			IsEnabled = false;
			return;
		}
		LogError("Error reading KeyValues, file might be missing. Loading default scheme.");
		BuildPath(Path_SM, ScriptPath, sizeof(ScriptPath), "data/noamp/default.txt");
		ReadNOAMPScript();
		return;
	}
	
	decl String:buffer[12];
	KvGetSectionName(kv, buffer, sizeof(buffer));
	
	if (StrEqual(buffer, "general"))
	{
		decl String:strschemename[256];
		decl String:strbossparrothp[32];
		decl String:strbossparrotsize[32];
		decl String:strchestaward[32];
		decl String:strsmallparrotsize[32];
		decl String:strgiantparrotsize[32];
		decl String:strplayerlives[32];
		decl String:strpreparationsecs[32];
		decl String:strmaxhpprice[32];
		decl String:strmaxarmorprice[32];
		decl String:strmaxspeedprice[32];
		decl String:strkegprice[32];
		decl String:strfillspecialprice[32];
		decl String:strvulturesprice[32];
		decl String:strbaseupgrade1price[32];
		
		KvGetString(kv, "name", strschemename, 256);
		KvGetString(kv, "bossparrothp", strbossparrothp, 32);
		KvGetString(kv, "bossparrotsize", strbossparrotsize, 32);
		KvGetString(kv, "chestaward", strchestaward, 32);
		KvGetString(kv, "smallparrotsize", strsmallparrotsize, 32);
		KvGetString(kv, "giantparrotsize", strgiantparrotsize, 32);
		KvGetString(kv, "playerlives", strplayerlives, 32);
		KvGetString(kv, "preparationsecs", strpreparationsecs, 32);
		KvGetString(kv, "maxhpprice", strmaxhpprice, 32);
		KvGetString(kv, "maxarmorprice", strmaxarmorprice, 32);
		KvGetString(kv, "maxspeedprice", strmaxspeedprice, 32);
		KvGetString(kv, "kegprice", strkegprice, 32);
		KvGetString(kv, "fillspecialprice", strfillspecialprice, 32);
		KvGetString(kv, "vulturesprice", strvulturesprice, 32);
		KvGetString(kv, "baseupgrade1price", strbaseupgrade1price, 32);
		
		schemeName = strschemename;
		parrotBossHP = StringToInt(strbossparrothp);
		bossParrotSize = StringToFloat(strbossparrotsize);
		chestAward = StringToInt(strchestaward, 10);
		smallParrotSize = StringToFloat(strsmallparrotsize);
		giantParrotSize = StringToFloat(strgiantparrotsize);
		playerLives = StringToInt(strplayerlives, 10);
		preparationSecs = StringToInt(strpreparationsecs, 10);
		maxHPPrice = StringToInt(strmaxhpprice, 10);
		maxArmorPrice = StringToInt(strmaxarmorprice, 10);
		maxSpeedPrice = StringToInt(strmaxspeedprice, 10);
		kegPrice = StringToInt(strkegprice, 10);
		powerupFillSpecialPrice = StringToInt(strfillspecialprice, 10);
		powerupVulturesPrice = StringToInt(strvulturesprice, 10);
		baseUpgradePrices[1] = StringToInt(strbaseupgrade1price, 10);
		
		KvGotoNextKey(kv);
	}
	
	new ibuffer;
	decl String:stri[32];
	waveCount = 0;
	
	for (new i = 1; i < NOAMP_MAXWAVES; i++)
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		ibuffer = StringToInt(buffer, 10);
		IntToString(i, stri, 32);
		
		if (StrEqual(buffer, stri))
		{
			decl String:strparrotcount[32];
			decl String:strgiantparrotcount[32];
			decl String:strmaxparrots[32];
			decl String:strisfoggy[2];
			decl String:strisboss[2];
			decl String:striscorrupt[2];
			
			KvGetString(kv, "parrotcount", strparrotcount, 32);
			KvGetString(kv, "giantparrotcount", strgiantparrotcount, 32);
			KvGetString(kv, "maxparrots", strmaxparrots, 32);
			KvGetString(kv, "foggy", strisfoggy, 2);
			KvGetString(kv, "boss", strisboss, 2);
			KvGetString(kv, "corruptor", striscorrupt, 2);
			
			waveParrotCount[ibuffer] = StringToInt(strparrotcount, 10);
			waveGiantParrotCount[ibuffer] = StringToInt(strgiantparrotcount, 10);
			waveMaxParrots[ibuffer] = StringToInt(strmaxparrots, 10);
			
			new fogint;
			fogint = StringToInt(strisfoggy, 10);
			if (fogint == 0)
				waveIsFoggy[ibuffer] = false;
			else if (fogint == 1)
				waveIsFoggy[ibuffer] = true;
			else
			{
				waveIsFoggy[ibuffer] = false;
				LogError("KeyValue \"foggy\" can only be 0 or 1.");
			}
			
			new bossint;
			bossint = StringToInt(strisboss, 10);
			if (bossint == 0)
				waveIsBossWave[ibuffer] = false;
			else if (bossint == 1)
				waveIsBossWave[ibuffer] = true;
			else
			{
				waveIsBossWave[ibuffer] = false;
				LogError("KeyValue \"boss\" can only be 0 or 1.");
			}
			
			new corruptint;
			corruptint = StringToInt(striscorrupt, 10);
			if (corruptint == 0)
				waveIsCorruptorWave[ibuffer] = false;
			else if (corruptint == 1)
				waveIsCorruptorWave[ibuffer] = true;
			else
			{
				waveIsCorruptorWave[ibuffer] = false;
				LogError("KeyValue \"corruptor\" can only be 0 or 1.");
			}
			
			waveCount++;
		}
		KvGotoNextKey(kv);
	}
	
	if (IsDebug())
	{
		PrintToServer("Wave count: %d", waveCount);
	}
	
	CloseHandle(kv);
}

// WTF: temp very stupid way of reading parrotcreator script
public ReadParrotCreatorScript(mode)
{
	decl Handle:file;
	BuildPath(Path_SM, ParrotCreatorScriptPath, sizeof(ParrotCreatorScriptPath), "data/noamp/default_parrotcreator.txt");
	file = OpenFile(ParrotCreatorScriptPath, "r");
	
	new bool:foundcreatorline = false;
	new bool:foundwavesline = false;
	new bool:foundwavestartline = false;
	new bool:foundcreatorlistline = false;
	new linescount = 0;
	new currentwave = 0;

	decl String:fileline[128];
	FileSeek(file, 0, SEEK_SET);
	
	while (!IsEndOfFile(file) && ReadFileLine(file, fileline, 128))
	{
		TrimString(fileline);

		if (!foundcreatorline && !StrEqual(fileline, "ParrotCreator", false))
		{
			ThrowError("ParrotCreator script reading failed! Didn't find \"ParrotCreator\"");
			break;
		}
		
		if (StrContains(fileline, "//", false) == 0)
		{
			continue;
		}
		
		if (StrEqual(fileline, "ParrotCreator", false))
		{
			PrintToServer("Found ParrotCreator");
			foundcreatorline = true;
			continue;
		}
		
		if (mode == 1 && foundcreatorline && StrContains(fileline, "beginwave", false) == 0)
		{
			PrintToServer("Found beginwave");
			new value = ExplodeTrimAndConvertStringToInt( fileline, "_" );
			currentwave = value;
			PrintToServer("currentwave = %d", currentwave);
			foundwavestartline = true;
			continue;
		}
		
		if (mode == 1 && foundcreatorline && StrContains(fileline, "endwave", false) == 0)
		{
			PrintToServer("Found endwave");
			foundwavestartline = false;
			continue;
		}
		
		if (mode == 1 && foundcreatorline && foundwavestartline && StrContains(fileline, "creatorscheme", false) == 0)
		{
			PrintToServer("Found creatorscheme");
			foundcreatorlistline = true;
			continue;
		}
		
		if (mode == 1 && !foundcreatorline || !foundwavestartline)
			break;
		
		if (StrContains(fileline, "end", false) == 0)
		{
			PrintToServer("StrContains end");
			if (foundcreatorlistline)
				foundcreatorlistline = false;
			continue;
		}
		else if (mode == 1 && foundcreatorlistline && StrContains(fileline, "normal", false) == 0)
		{
			PrintToServer("StrContains normal");
			for (new i = 1; i < NOAMP_MAXPARROTCREATOR_WAVES; i++)
			{
				if (parrotCreatorScheme[currentwave][i] == 0)
				{
					PrintToServer("StrContains normal");
					parrotCreatorScheme[currentwave][i] = PARROTCREATOR_NORMAL;
					break;
				}
			}
		}
		else if (mode == 1 && foundcreatorlistline && StrContains(fileline, "small", false) == 0)
		{
			PrintToServer("StrContains small");
			for (new i = 1; i < NOAMP_MAXPARROTCREATOR_WAVES; i++)
			{
				if (parrotCreatorScheme[currentwave][i] == 0)
				{
					parrotCreatorScheme[currentwave][i] = PARROTCREATOR_SMALL;
					break;
				}
			}
		}
		else if (mode == 1 && foundcreatorlistline && StrContains(fileline, "giant", false) == 0)
		{
			PrintToServer("StrContains giant");
			for (new i = 1; i < NOAMP_MAXPARROTCREATOR_WAVES; i++)
			{
				if (parrotCreatorScheme[currentwave][i] == 0)
				{
					parrotCreatorScheme[currentwave][i] = PARROTCREATOR_GIANTS;
					break;
				}
			}
		}
		else if (mode == 1 && foundcreatorlistline && StrContains(fileline, "boss", false) == 0)
		{
			PrintToServer("StrContains boss");
			for (new i = 1; i < NOAMP_MAXPARROTCREATOR_WAVES; i++)
			{
				if (parrotCreatorScheme[currentwave][i] == 0)
				{
					parrotCreatorScheme[currentwave][i] = PARROTCREATOR_BOSS;
					break;
				}
			}
		}
		else if (mode == 2 && StrContains(fileline, "onchange", false) == 0)
		{
			PrintToServer("Found onchange");
			int value = ExplodeTrimAndConvertStringToInt( fileline, "_" );
			if ( value == creatorwave )
			{
				ScriptCommands(fileline);
			}
		}
		else if (mode == 3 && StrContains(fileline, "oncorruption", false) == 0)
		{
			PrintToServer("Found oncorruption");
			ScriptCommands(fileline);
		}
		continue;
	}
	CloseHandle(file);
}

public ScriptCommands(const String:fileline[])
{
	if ( StrContains( fileline, "spawnparrots", false ) == 0 )
	{
		if ( StrContains( fileline, "normal", false ) == 0 )
		{
			int value = ExplodeTrimAndConvertStringToInt( fileline, "=" );
			SpawnParrotAmount( value, PARROT_NORMAL );
		}
		else if ( StrContains( fileline, "giant", false ) == 0 )
		{
			int value = ExplodeTrimAndConvertStringToInt( fileline, "=" );
			SpawnParrotAmount( value, PARROT_GIANT );
		}
		else if ( StrContains( fileline, "small", false ) == 0 )
		{
			int value = ExplodeTrimAndConvertStringToInt( fileline, "=" );
			SpawnParrotAmount( value, PARROT_SMALL );
		}
		else if ( StrContains( fileline, "boss", false ) == 0 )
		{
			int value = ExplodeTrimAndConvertStringToInt( fileline, "=" );
			SpawnParrotAmount( value, PARROT_BOSS );
		}
	}
	else if ( StrContains( fileline, "setpitch", false ) == 0 )
	{
		int value = ExplodeTrimAndConvertStringToInt( fileline, "=" );
		parrotDesiredSoundPitch = value;
	}
	else if ( StrContains( fileline, "setsize", false ) == 0 )
	{
		float value = ExplodeTrimAndConvertStringToFloat( fileline, "=" );
		giantParrotSize = value;
		bossParrotSize = value;
		smallParrotSize = value;
	}
}