#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <sdkhooks>
#include <emitsoundany>

#pragma newdecls required

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientInGame(%1))

#define TAG_COLOR "{darkred}"
#define HIGH_COLOR "{orchid}"
#define TEXT_COLOR "{green}"
#define DICE_SOUND     "ngx/dice/dice.mp3"
#define NEGATIVE_SOUND "ngx/dice/negative.mp3"
#define POSITIVE_SOUND "ngx/dice/positive.mp3"
#define TITLE    "Dice"

bool g_bDice[MAXPLAYERS+1] = {false, ...};
bool g_bLastT[MAXPLAYERS+1] = {false, ...};
bool g_bHE[MAXPLAYERS+1] = {false, ...};
bool g_bDoubleDamage[MAXPLAYERS+1] = {false, ...};
bool g_bDoubleDamageE[MAXPLAYERS+1] = {false, ...};
bool g_bNoHSDMG[MAXPLAYERS+1] = {false, ...};
bool g_bNoDamage[MAXPLAYERS+1] = {false, ...};
bool g_bNoSelfHS[MAXPLAYERS+1] = {false, ...};
bool g_bHalfSelfDMG[MAXPLAYERS+1] = {false, ...};
bool g_bHalfDMG[MAXPLAYERS+1] = {false, ...};
bool g_bNoWeaponUse[MAXPLAYERS+1] = {false, ...};
bool g_bZombie[MAXPLAYERS+1] = {false, ...};
bool g_bRespawn[MAXPLAYERS+1] = {false, ...};
bool g_bNightvision[MAXPLAYERS+1] = {false, ...};
bool g_bGodmode[MAXPLAYERS+1] = {false, ...};
bool g_bAmmoInfi[MAXPLAYERS+1] = {false, ...};
bool g_bBusy[MAXPLAYERS+1] = {false, ...};
bool g_bCustomModel[MAXPLAYERS + 1] =  { false, ... };
bool g_bAuto[MAXPLAYERS+1] = {false, ...};

bool g_bDebug = false;

Handle g_hBeaconTimer[MAXPLAYERS+1] = {null, ...};
Handle g_hDiscoColor[MAXPLAYERS+1] = {null, ...};
Handle g_hRespawnTimer[MAXPLAYERS+1] = {null, ...};
Handle g_hSlapTimer[MAXPLAYERS+1] = {null, ...};
Handle g_hDrugTimer[MAXPLAYERS+1] = {null, ...};
Handle g_hBitchSlap[MAXPLAYERS+1] = {null, ...};
Handle g_hSlapDMG[MAXPLAYERS+1] = {null, ...};
Handle g_hDiceTimer[MAXPLAYERS + 1] =  { null, ... };

Handle g_hAmmo = null;

int g_iNoclipCounter[MAXPLAYERS + 1] =  { 0, ... };
int g_iCustomOption[MAXPLAYERS + 1] =  { -1, ... };

int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iActiveWeapon = -1;
int g_iClip1 = -1;
int g_iClip2 = -1;
int g_iSecondaryAmmo = -1;
int g_iPrimaryAmmo = -1;

#include "dice_stocks.sp"
#include "dice_timer.sp"

public Plugin myinfo =
{
	name = "Dice",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "github.com/Bara20/Dice"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Dice_ResetClient", Native_ResetClient);
	
	RegPluginLibrary("dice");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_rtd", Command_Dice);
	RegConsoleCmd("sm_w", Command_Dice);
	RegConsoleCmd("sm_dice", Command_Dice);
	
	RegConsoleCmd("sm_wdebug", Command_Debug);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("hegrenade_detonate", Event_HEGrenade, EventHookMode_Pre);
	
	g_iActiveWeapon = FindSendPropInfo("CAI_BaseNPC", "m_hActiveWeapon");
	g_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iClip2 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip2");
	g_iPrimaryAmmo = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
	g_iSecondaryAmmo = FindSendPropInfo("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
}

public void OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo.vmt");

	PrecacheModel("models/props/de_train/barrel.mdl");
	PrecacheModel("models/chicken/chicken_zombie.mdl");
	PrecacheModel("models/props/cs_office/vending_machine.mdl");
	PrecacheModel("models/props/cs_office/sofa.mdl");
	PrecacheModel("models/props/cs_office/bookshelf1.mdl");
	PrecacheModel("models/props/cs_office/chair_office.mdl");
	PrecacheModel("models/props/cs_office/computer_monitor.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb.mdl");
	PrecacheModel("models/props/cs_office/ladder1.mdl");
	PrecacheModel("models/props/de_dust/dust_rusty_barrel.mdl");
	PrecacheModel("models/props/cs_office/tv_plasma.mdl");
    
	PrecacheSoundAny("weapons/rpg/rocketfire1.wav");
	PrecacheSoundAny("weapons/rpg/rocket1.wav");
	PrecacheSoundAny("weapons/hegrenade/explode3.wav");
	
	PrecacheSoundAny("ambient/tones/floor1.wav");
	PrecacheSoundAny("sound/weapons/rpg/rocket1.wav");
	PrecacheSoundAny("sound/weapons/hegrenade/explode3.wav");
	PrecacheSoundAny("sound/ambient/tones/floor1.wav");
	
	PrecacheSoundAny(DICE_SOUND);
	AddFileToDownloadsTable("sound/" ... DICE_SOUND);
	
	PrecacheSoundAny(NEGATIVE_SOUND);
	AddFileToDownloadsTable("sound/" ... NEGATIVE_SOUND);
	
	PrecacheSoundAny(POSITIVE_SOUND);
	AddFileToDownloadsTable("sound/" ... POSITIVE_SOUND);
	

	if (g_hAmmo)
	{
		KillTimer(g_hAmmo, false);
		g_hAmmo = null;
	}
	
	g_hAmmo = CreateTimer(1.0, Timer_ResetAmmo, _, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
	ResetClientDice(client);
}

public Action Command_Debug(int client, int args)
{
	if(g_bDebug && !CheckCommandAccess(client, "sm_admin", ADMFLAG_ROOT, true))
		return Plugin_Handled;
	
	PrintToChat(client, "You suck hard!");
	
	char option[12];
	GetCmdArg(1, option, sizeof(option));
	
	g_iCustomOption[client] = StringToInt(option);
	
	g_bBusy[client] = true;
	
	g_hDiceTimer[client] = CreateTimer(1.0, tWuerfel, client);
	
	return Plugin_Continue;
}

public Action Command_Dice(int client, int args)
{
	if (IsClientValid(client))
	{
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			if (IsPlayerAlive(client))
			{
				if (!g_bDice[client])
				{
					if(!g_bBusy[client] || g_hDiceTimer[client] != null)
					{
						
						EmitSoundToClientAny(client, DICE_SOUND);
						
						Handle hPanel = CreatePanel();
						SetPanelTitle(hPanel, "Bitte warten...");
						DrawPanelText(hPanel, "(Glücksspiel kann süchtig machen!)");
						SendPanelToClient(hPanel, client, PanelHandler, 10);
						
						CloseHandle(hPanel);
						
						g_bBusy[client] = true;
						g_hDiceTimer[client] = CreateTimer(2.0, tWuerfel, client);
					}
					else
						CPrintToChat(client, "%s[%s] %sDer Würfel rollt gerade...", TAG_COLOR, TITLE, TEXT_COLOR);
				}
				else
					CPrintToChat(client, "%s[%s] %sSie haben bereits gewürfelt!", TAG_COLOR, TITLE, TEXT_COLOR);
			}
			else
				CPrintToChat(client, "%s[%s] %sSie sind nicht am leben!", TAG_COLOR, TITLE, TEXT_COLOR);
		}
		else
			CPrintToChat(client, "%s[%s] %sSie müssen ein T sein um zu würfeln!!", TAG_COLOR, TITLE, TEXT_COLOR);
	}
	return Plugin_Continue;
}

public Action Event_HEGrenade(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_bHE[client])
	{
		GivePlayerItem(client, "weapon_hegrenade");
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bDebug)
		for (int count = 0; count <= 10; count++)
			PrintToChatAll("Dice Debug enabled!");
	
	LoopClients(client)
			ResetClientDice(client);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientValid(client))
	{
		ResetClientDice(client);
	}
	
	CreateTimer(1.0, Timer_CheckKnife, GetClientUserId(client));
}

public Action Event_PlayerDeathPre(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(client))
	{
		if(!g_bCustomModel[client])
			return Plugin_Continue;
		
		int iEntity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		
		if(iEntity > 0 && IsValidEdict(iEntity))
			AcceptEntityInput(iEntity, "Kill");
	}
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", 0);
	
	if (g_bRespawn[client])
	{
		g_hRespawnTimer[client] = CreateTimer(0.3, RespawnPlayer, client);
	}
	
	if (GetTeamClientCount(2) == 1)
	{
		LoopClients(i)
		{
			if (IsPlayerAlive(i))
			{
				if (g_bLastT[i])
				{
					ForcePlayerSuicide(i);
				}
			}
		}
	}
	
	if (IsClientValid(client))
	{
		ResetClientDice(client);
	}
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
		return Plugin_Continue;
	RemoveEdict(ragdoll);
	
	return Plugin_Continue;
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientValid(client))
	{
		ResetClientDice(client);
	}
}

public int PanelHandlerSpawn(Menu hPanel, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			ClientCommand(param1, "say /w");
		}
		if (param2 == 2)
		{
			CloseHandle(hPanel);
		}
	}
	if (action == MenuAction_Cancel)
	{
		CloseHandle(hPanel);
	}
	return 0;
}

public int PanelHandler(Menu hPanel, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Cancel)
	{
		CloseHandle(hPanel);
	}
	return 0;
}

public Action tWuerfel(Handle timer, int client)
{
	if (IsClientValid(client) && g_hDiceTimer[client] != null)
	{
		SetRandomSeed(GetTime());
		int rand = 1;
		rand = GetRandomInt(1, 89);
		rand = GetRandomInt(1, 89);
		g_bBusy[client] = false;
		
		if(g_bDebug)
			PrintToChat(client, "Rand: %d - Custom: %d", rand, g_iCustomOption[client]);
			
		if(g_iCustomOption[client] >= 0)
			rand = g_iCustomOption[client];
		
		if(g_bDebug)
		{
			PrintToChat(client, "Rand: %d - Custom: %d", rand, g_iCustomOption[client]);
			PrintToChat(client, "Würfel Option: %d", rand);
			LogMessage("[Dice] Player: \"%L\" Option: %d 1/2", client, rand);
		}
		
		if (rand == 1)
		{
			g_bDice[client] = true;
			EmitSoundToClientAny(client, NEGATIVE_SOUND);

			SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
		}
		else
		{
			if (rand == 2)
			{
				int rHP = GetRandomInt(1, 50);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie haben %d HP bekommen!", rHP);
				g_bDice[client] = true;
				SetEntityHealth(client, GetClientHealth(client) + rHP);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 3)
			{
				int rHP = GetRandomInt(1, 50);
				float rSpeed = GetRandomFloat(0.01, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie bekommen %d HP und sind %.0f Prozent schneller!", rHP, rSpeed * 100);
				g_bDice[client] = true;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", rSpeed + 1, 0);
				SetEntityHealth(client, GetClientHealth(client) + rHP);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 4)
			{
				float rSpeed = GetRandomFloat(0.01, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent schneller!", rSpeed * 100);
				g_bDice[client] = true;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", rSpeed + 1, 0);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 5)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 6)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);

				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 7)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 8)
			{
				float rSpeed = GetRandomFloat(0.1, 0.3);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent langsamer!", rSpeed * 100);
				g_bDice[client] = true;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1 - rSpeed, 0);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 9)
			{
				int rHP = GetRandomInt(1, 50);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie bekommen %d HP!", rHP);
				g_bDice[client] = true;
				SetEntityHealth(client, GetClientHealth(client) + rHP);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 10)
			{
				int rHP = GetRandomInt(1, 50);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie haben nun %d HP!", rHP);
				g_bDice[client] = true;
				SetEntityHealth(client, rHP);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 11)
			{
				float rSpeed = GetRandomFloat(0.1, 0.3);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent langsamer!", rSpeed * 100);
				g_bDice[client] = true;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1 - rSpeed, 0);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 12)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 13)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 14)
			{
				g_bDice[client] = true;
				
				int ent = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);

				if (ent == -1)
					ent = client;
				
				TE_SetupBeamFollow(ent, g_iBeamSprite, g_iHaloSprite, 10.0, 4.0, 4.0, 3, {0, 255, 0, 255});
				TE_SendToAll();
				EmitSoundToClientAny(client, NEGATIVE_SOUND);

				SendDicePanel(rand, client, TITLE, "Ein grüner Laser verfolgt Sie nun!");
			}
			if (rand == 15)
			{
				g_bDice[client] = true;
				
				int ent = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);

				if (ent == -1)
					ent = client;
				
				TE_SetupBeamFollow(ent, g_iBeamSprite, g_iHaloSprite, 10.0, 4.0, 4.0, 3, {255, 0, 0, 255});
				TE_SendToAll();
				EmitSoundToClientAny(client, NEGATIVE_SOUND);

				SendDicePanel(rand, client, TITLE, "Ein roter Laser verfolgt Sie nun!");
			}
			if (rand == 16)
			{
				g_bDice[client] = true;
				
				int ent = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);

				if (ent == -1)
					ent = client;
				
				TE_SetupBeamFollow(ent, g_iBeamSprite, g_iHaloSprite, 10.0, 4.0, 4.0, 3, {0, 0, 255, 255});
				TE_SendToAll();
				EmitSoundToClientAny(client, NEGATIVE_SOUND);

				SendDicePanel(rand, client, TITLE, "Ein blauer Laser verfolgt Sie nun!");
			}
			if (rand == 17)
			{
				int rHP = GetRandomInt(30, 70);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie haben %d HP verloren!", rHP);
				g_bDice[client] = true;
				if((GetClientHealth(client) - rHP) > 0)
					SetEntityHealth(client, GetClientHealth(client) - rHP);
				else
					ForcePlayerSuicide(client);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 18)
			{
				int rHP = GetRandomInt(30, 70);
				float rSpeed = GetRandomFloat(0.1, 0.3);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie haben %d HP verloren und sind %.0f Prozent langsamer!", rHP, rSpeed * 100);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				g_bDice[client] = true;
				if((GetClientHealth(client) - rHP) > 0)
					SetEntityHealth(client, GetClientHealth(client) - rHP);
				else
					ForcePlayerSuicide(client);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1 - rSpeed, 0);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 19)
			{
				int rHP = GetRandomInt(10, 50);
				float rSpeed = GetRandomFloat(0.1, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie haben %d HP bekommen und sind %.0f Prozent schneller!", rHP, rSpeed * 100);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				g_bDice[client] = true;
				SetEntityHealth(client, GetClientHealth(client) + rHP);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", rSpeed + 1, 0);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 20)
			{
				float rSpeed = GetRandomFloat(0.1, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent schneller und werden von ein grünen Laser verfolgt!", rSpeed * 100);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				g_bDice[client] = true;
				
				int ent = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);

				if (ent == -1)
					ent = client;
				
				TE_SetupBeamFollow(ent, g_iBeamSprite, g_iHaloSprite, 10.0, 4.0, 4.0, 3, {0, 255, 0, 255});
				TE_SendToAll();
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", rSpeed + 1, 0);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 21)
			{
				float rGrav = GetRandomFloat(0.05, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent leichter!", rGrav * 100);
				g_bDice[client] = true;
				SetEntityGravity(client, 1 - rGrav);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 22)
			{
				float rGrav = GetRandomFloat(0.1, 0.5);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent schwerer!", rGrav * 100);
				g_bDice[client] = true;
				SetEntityGravity(client, rGrav + 1);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 23)
			{
				g_bDice[client] = true;
				ClientCommand(client, "r_screenoverlay effects/redflare.vmt");
				EmitSoundToClientAny(client, NEGATIVE_SOUND);

				SendDicePanel(rand, client, TITLE, "Sie haben ein rot/grünen Punkt vor Augen!?");
			}
			if (rand == 24)
			{
				g_bDice[client] = true;
				ForcePlayerSuicide(client);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);

				SendDicePanel(rand, client, TITLE, "Da sind Sie vor Schreck umgefallen!");
			}
			if (rand == 25)
			{
				g_bDice[client] = true;
				
				int iItem = GivePlayerItem(client, "weapon_deagle");
				EquipPlayerWeapon(client, iItem);
				
				Weapon_SetAmmo(iItem, 0);
				Weapon_SetReserveAmmo(iItem, 0);
				
				EmitSoundToClientAny(client, NEGATIVE_SOUND);

				SendDicePanel(rand, client, TITLE, "Sie haben eine Deagle bekommen! Viel Glück ;)");
			}
			if (rand == 26)
			{
				g_bDice[client] = true;
				
				if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != INVALID_ENT_REFERENCE)
				{
					EmitSoundToClientAny(client, NEGATIVE_SOUND);
					SendDicePanel(rand, client, TITLE, "Sie haben eine Niete gezogen!");
				}
				else
				{
					int iItem = GivePlayerItem(client, "weapon_deagle");
					EquipPlayerWeapon(client, iItem);
					EmitSoundToClientAny(client, POSITIVE_SOUND);
					SendDicePanel(rand, client, TITLE, "Sie haben eine Deagle bekommen!");
				}
			}
			if (rand == 27)
			{
				int rTime = GetRandomInt(20, 60);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie werden %d Sekunden geschüttelt!", rTime);
				g_bDice[client] = true;
				EnableShake(client, rTime, 20, 160);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 28)
			{
				float rTime = GetRandomFloat(10.0, 60.0);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %0.f Sekunden eingefroren!", rTime);
				g_bDice[client] = true;
				EnableFreeze(client, true, rTime);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 29)
			{
				g_bDice[client] = true;
				EnableRocket(client);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Viel Spass im Weltall!");
			}
			if (rand == 30)
			{
				g_bDice[client] = true;
				EnableBurn(client, 70);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie stehen unter Feuer!");
			}
			if (rand == 31)
			{
				g_bDice[client] = true;
				EnableDrug(client);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie stehen unter Drogen!");
			}
			if (rand == 32)
			{
				g_bDice[client] = true;
				SetGlow(client, RENDERFX_NONE, 0, 255, 0, RENDER_GLOW, 255);
				SetEntityRenderFx(client, RENDERFX_GLOWSHELL);
				SetEntityRenderMode(client, RENDER_GLOW);
				g_hBeaconTimer[client] = CreateTimer(2.0, TimerBeacon, client, TIMER_REPEAT);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie blinken!");
			}
			if (rand == 33)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/de_train/barrel.mdl");
				g_bCustomModel[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Fass!");
			}
			if (rand == 34)
			{
				g_bDice[client] = true;
				SetEntityHealth(client, 1);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben 1HP!");
			}
			if (rand == 35)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/vending_machine.mdl");
				g_bCustomModel[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Automat!");
			}
			if (rand == 36)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/sofa.mdl");
				g_bCustomModel[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Sofa!");
			}
			if (rand == 37)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/bookshelf1.mdl");
				g_bCustomModel[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Bücherregal!");
			}
			if (rand == 38)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/vending_machine.mdl");
				g_bCustomModel[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Getränkeautomat!");
			}
			if (rand == 39)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				SendDicePanel(rand, client, TITLE, "Sie haben eine Niete gewürfelt... :-(");
			}
			if (rand == 40)
			{
				g_bDice[client] = true;
				g_hDiscoColor[client] = CreateTimer(0.1, Timer_ChangePlayerColor, client, TIMER_REPEAT);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Ihr Körper ändert dauerthaft ihre Farbe!");
			}
			if (rand == 41)
			{
				g_bDice[client] = true;
				g_bRespawn[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Wiedergeburt!");
			}
			if (rand == 42)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Niete...!");
			}
			if (rand == 43)
			{
				g_bDice[client] = true;
				g_bNightvision[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben ein Nachtsichtgerät!");
			}
			if (rand == 44)
			{
				g_bDice[client] = true;
				SetEntProp(client, Prop_Send, "m_iDefaultFOV", 35, 4, 0);
				SetEntProp(client, Prop_Send, "m_iFOV", 35, 4, 0);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben Zoom Sicht!");
			}
			if (rand == 45)
			{
				g_bDice[client] = true;
				SetEntProp(client, Prop_Send, "m_iDefaultFOV", 200, 4, 0);
				SetEntProp(client, Prop_Send, "m_iFOV", 200, 4, 0);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben eine andere Sicht!");
			}
			if (rand == 46)
			{
				int rHP = GetRandomInt(110, 150);
				float rSpeed = GetRandomFloat(0.1, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie haben %d HP, sind %.0f Prozent schneller aber Sie brennen!", rHP, rSpeed * 100);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				g_bDice[client] = true;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", rSpeed + 1, 0);
				SetEntityHealth(client, rHP);
				EnableBurn(client, rHP + -1);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 47)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 48)
			{
				float rTime = GetRandomFloat(5.0, 10.0);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind für %0.f Sekunden unsterblich!", rTime);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				g_bDice[client] = true;
				g_bGodmode[client] = true;
				SetEntityRenderColor(client, 0, 255, 255, 255);
				CreateTimer(rTime, Timer_DisableGodMode, client);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 49)
			{
				g_bDice[client] = true;
				g_bAmmoInfi[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben unendlich Munition!");
			}
			if (rand == 50)
			{
				int rHP = GetRandomInt(110, 150);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie haben nun %d HP!", rHP);
				g_bDice[client] = true;
				SetEntityHealth(client, rHP);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 51)
			{
				g_bDice[client] = true;
				GivePlayerItem(client, "weapon_flashbang");
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben nun eine Blendgranate!");
			}
			if (rand == 52)
			{
				g_bDice[client] = true;
				GivePlayerItem(client, "weapon_flashbang");
				GivePlayerItem(client, "weapon_flashbang");
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben nun zwei Blendgranate!");
			}
			if (rand == 53)
			{
				g_bDice[client] = true;
				GivePlayerItem(client, "weapon_smokegrenade");
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben nun eine Rauchgranate!");
			}
			if (rand == 54)
			{
				g_bDice[client] = true;
				GivePlayerItem(client, "weapon_hegrenade");
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben nun eine g_bHE!");
			}
			if (rand == 55)
			{
				g_bDice[client] = true;
				GivePlayerItem(client, "weapon_flashbang");
				GivePlayerItem(client, "weapon_flashbang");
				GivePlayerItem(client, "weapon_smokegrenade");
				GivePlayerItem(client, "weapon_hegrenade");
				EmitSoundToClientAny(client, POSITIVE_SOUND);

				SendDicePanel(rand, client, TITLE, "Sie haben nun:\n+ 2 Blendgranaten\n+ 1 Rauchgranaten\n+ 1 g_bHE");
			}
			if (rand == 56)
			{
				g_bDice[client] = true;
				if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != INVALID_ENT_REFERENCE)
				{
					EmitSoundToClientAny(client, NEGATIVE_SOUND);
					SendDicePanel(rand, client, TITLE, "... Niete ...");
				}
				else
				{
					int iItem = GivePlayerItem(client, "weapon_deagle");
					EquipPlayerWeapon(client, iItem);
					EmitSoundToClientAny(client, POSITIVE_SOUND);
					SendDicePanel(rand, client, TITLE, "Sie haben eine Deagle bekommen!");
				}
			}
			if (rand == 57)
			{
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie dürfen noch einmal würfeln!");
			}
			if (rand == 58)
			{
				g_bDice[client] = true;
				g_bAuto[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie können nun die 'jump'-Taste gedrückt halten!");
			}
			if (rand == 59)
			{
				float rSpeed = GetRandomFloat(1.0, 5.0);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie werden nun alle %0.f Sekunden geohrfeigt!", rSpeed);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				g_bDice[client] = true;
				g_hSlapTimer[client] = CreateTimer(rSpeed, SlapTimerPlayer, client, TIMER_REPEAT);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 60)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 61)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 62)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 63)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				int ts = 0;
				
				LoopClients(i)
				{
					if(GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
					{
						ts++;
					}
				}
				
				if(ts > 1)
				{
					g_bLastT[client] = true;
					SendDicePanel(rand, client, TITLE, "Sie sterben, wenn Sie letzter T sind!");
				}
				else
				{
					ForcePlayerSuicide(client);
					SendDicePanel(rand, client, TITLE, "Sie sterben, weil Sie letzter T waren!");
				}
					
			}
			if (rand == 64)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Mirror Slay... aber es wurde nur eine Niete. :)");
			}
			if (rand == 65)
			{
				g_bDice[client] = true;
				g_bDoubleDamage[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie bekommen doppelten Schaden!");
			}
			if (rand == 66)
			{
				g_bDice[client] = true;
				g_bNoHSDMG[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie machen kein Headshot Schaden mehr!");
			}
			if (rand == 67)
			{
				g_bDice[client] = true;
				g_bDoubleDamageE[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie machen doppelten Schaden!");
			}
			if (rand == 68)
			{
				g_bDice[client] = true;
				g_bNoDamage[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie machen kein Schaden mehr!");
			}
			if (rand == 69)
			{
				g_bDice[client] = true;
				g_bNoSelfHS[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie bekommen kein Headshot Schaden mehr!");
			}
			if (rand == 70)
			{
				int rHP = GetRandomInt(10, 70);
				float rSpeed = GetRandomFloat(0.1, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie verlieren %d HP aber Sie sind %.0f Prozent schneller!", rHP, rSpeed * 100);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				g_bDice[client] = true;
				if((GetClientHealth(client) - rHP) > 0)
					SetEntityHealth(client, GetClientHealth(client) - rHP);
				else
					ForcePlayerSuicide(client);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", rSpeed + 1, 0);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 71)
			{
				g_bDice[client] = true;
				g_bHE[client] = true;
				GivePlayerItem(client, "weapon_hegrenade");
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben unendlich HEs!");
			}
			if (rand == 72)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Niete - Versuchen Sie es später noch einmal!");
			}
			if (rand == 73)
			{
				float rSpeed = GetRandomFloat(0.1, 0.3);
				float rGrav = GetRandomFloat(0.1, 0.3);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent langsamer und %.0f Prozent schwerer!", rSpeed * 100, rGrav * 100);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				g_bDice[client] = true;
				SetEntityGravity(client, rGrav + 1);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1 - rSpeed, 0);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 74)
			{
				float rSpeed = GetRandomFloat(0.1, 0.2);
				float rGrav = GetRandomFloat(0.1, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent schneller und %.0f Prozent leichter!", rSpeed * 100, rGrav * 100);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				g_bDice[client] = true;
				SetEntityGravity(client, 1 - rGrav);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", rSpeed + 1, 0);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 75)
			{
				float rSpeed = GetRandomFloat(0.1, 0.2);
				float rGrav = GetRandomFloat(0.1, 0.3);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent schneller und %.0f Prozent schwerer!", rSpeed * 100, rGrav * 100);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				g_bDice[client] = true;
				SetEntityGravity(client, rGrav + 1);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", rSpeed + 1, 0);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 76)
			{
				float rSpeed = GetRandomFloat(0.1, 0.3);
				float rGrav = GetRandomFloat(0.1, 0.2);
				char buffer[64];
				Format(buffer, sizeof(buffer), "Sie sind %.0f Prozent langsamer und %.0f Prozent leichter!", rSpeed * 100, rGrav * 100);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				g_bDice[client] = true;
				SetEntityGravity(client, 1 - rSpeed);
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1 - rGrav, 0);
				
				SendDicePanel(rand, client, TITLE, buffer);
			}
			if (rand == 77)
			{
				g_bDice[client] = true;
				g_bHalfDMG[client] = true;
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie bekommen halben Schaden!");
			}
			if (rand == 78)
			{
				g_bDice[client] = true;
				g_bHalfSelfDMG[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie machen nur noch halben Schaden!");
			}
			if (rand == 79)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben eine Niete gewürfelt!");
			}
			if (rand == 80)
			{
				g_bDice[client] = true;
				g_bNoWeaponUse[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie können keine Waffen mehr aufheben!");
			}
			if (rand == 81)
			{
				g_bDice[client] = true;
				g_bHalfSelfDMG[client] = true;
				
				if(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) != INVALID_ENT_REFERENCE)
				{
					EmitSoundToClientAny(client, NEGATIVE_SOUND);
					SendDicePanel(rand, client, TITLE, "Sie haben eine Niete gezogen!");
				}
				else
				{
					int iItem = GivePlayerItem(client, "weapon_deagle");
					EquipPlayerWeapon(client, iItem);
					EmitSoundToClientAny(client, POSITIVE_SOUND);
					SendDicePanel(rand, client, TITLE, "Sie haben eine Deagle bekommen!");
				}
			}
			if (rand == 82)
			{
				g_bDice[client] = true;
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				int iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
				if(iWeapon != INVALID_ENT_REFERENCE)
				{
					RemovePlayerItem(client, iWeapon); 
					AcceptEntityInput(iWeapon, "Kill");
				}
				
				SendDicePanel(rand, client, TITLE, "Sie verlieren ihr Messer");
			}
			if (rand == 83)
			{
				g_bDice[client] = true;
				SetEntityGravity(client, 1600.0);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sollten weniger essen...");
			}
			if (rand == 84)
			{
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie können noch einmal Wuerfeln!");
			}
			if (rand == 85)
			{
				g_bDice[client] = true;
				g_bNoWeaponUse[client] = true;
				g_bZombie[client] = true;
				SetEntityHealth(client, 500);
				SetEntityModel(client, "models/chicken/chicken_zombie.mdl");
				g_bCustomModel[client] = true;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.6, 0);
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Zombie Huhn,\n Sie können keine Waffen aufheben,\n Sie machen kein Waffen/Granat Schaden,\n aber Sie bekommen 500HP,\n aber Sie 40% langsamer.");
			}
			if (rand == 86)
			{
				g_bDice[client] = true;
				int iItem = GivePlayerItem(client, "weapon_deagle");
				EquipPlayerWeapon(client, iItem);
				Weapon_SetAmmo(iItem, 0);
				Weapon_SetReserveAmmo(iItem, 0);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie haben eine Deagle bekommen! Viel Glück");
			}
			if (rand == 87)
			{
				g_bDice[client] = true;
				g_hBitchSlap[client] = CreateTimer(0.5, TimerBitchSlap, client, TIMER_REPEAT);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie leiden unter Bitchslap!");
			}
			if (rand == 88)
			{
				g_bDice[client] = true;
				g_hSlapDMG[client] = CreateTimer(2.0, DMGSlapTimerPlayer, client, TIMER_REPEAT);
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie leiden unter Slap!");
			}
			if (rand == 89)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/chair_office.mdl");
				g_bCustomModel[client] = true;

				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Chef-Sessel!");
			}
			if (rand == 90)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/computer_monitor.mdl");
				g_bCustomModel[client] = true;

				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Monitor!");
			}
			if (rand == 91)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/computer_caseb.mdl");
				g_bCustomModel[client] = true;

				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Computer!");
			}
			if (rand == 92)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/ladder1.mdl");
				g_bCustomModel[client] = true;

				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind eine Leiter!");
			}
			if (rand == 93)
			{
				g_bDice[client] = true;
				SetEntityModel(client, "models/props/cs_office/tv_plasma.mdl");
				g_bCustomModel[client] = true;

				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind ein Fernseher!");
			}
			if (rand == 94)
			{
				g_bDice[client] = true;
				g_bNoDamage[client] = true;
				SetEntityModel(client, "models/props/de_dust/dust_rusty_barrel.mdl");
				g_bCustomModel[client] = true;
				
				EmitSoundToClientAny(client, POSITIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie sind eine rostige Tonne,\n und Sie machen kein Schaden.");
			}
			if (rand == 95)
			{
				g_bDice[client] = true;
				g_bNoDamage[client] = true;
				
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie machen kein Schaden mehr!");
			}
			if (rand == 96)
			{
				g_bDice[client] = true;
				g_bNoDamage[client] = true;
				
				EmitSoundToClientAny(client, NEGATIVE_SOUND);
				
				SendDicePanel(rand, client, TITLE, "Sie machen kein Schaden mehr!");
			}
		}
		
		if(g_bDebug)
			LogMessage("[Dice] Player: \"%L\" Option: %d 2/2", client, rand);
	}
	g_hDiceTimer[client] = null;
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsClientValid(client))
	{
		if(IsPlayerAlive(client))
			if (g_bAuto[client])
				if (!(GetEntityFlags(client) & FL_ONGROUND))
					if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
					{
						int iType = GetEntProp(client, Prop_Data, "m_nWaterLevel");
						if (iType <= 1)
							buttons &= ~IN_JUMP;
					}
	}
	return Plugin_Continue;
}

public void OnGameFrame()
{
	LoopClients(i)
	{
		if (IsPlayerAlive(i) && g_bNightvision[i])
			SetEntProp(i, Prop_Send, "m_bNightVisionOn", 1);
	}
}

public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (victim> 0 && attacker > 0 && IsClientValid(victim) && IsClientValid(attacker))
	{
		char sWeapon[64];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
		
		if(g_bZombie[attacker] && !StrEqual(sWeapon, "weapon_knife", false))
			return Plugin_Handled;
		if (g_bNoDamage[attacker])
			return Plugin_Handled;
		if (g_bGodmode[victim])
			return Plugin_Handled;
		if (GetClientTeam(attacker) == CS_TEAM_T)
		{
			if (g_bDoubleDamageE[attacker])
			{
				damage = damage * 2.0;
				return Plugin_Changed;
			}
			if (g_bHalfSelfDMG[attacker])
			{
				damage = damage * 0.5;
				return Plugin_Changed;
			}
			if(damagetype & CS_DMG_HEADSHOT)
			{
				if (g_bNoHSDMG[attacker])
					return Plugin_Handled;
			}
		}
		if (GetClientTeam(victim) == CS_TEAM_T)
		{
			if (g_bDoubleDamage[victim])
			{
				damage = damage * 2.0;
				return Plugin_Changed;
			}
			if (g_bHalfDMG[victim])
			{
				damage = damage * 0.5;
				return Plugin_Changed;
			}
			if(damagetype & CS_DMG_HEADSHOT)
			{
				if (g_bNoSelfHS[victim])
					return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action WeaponCanUse(int client, int weapon)
{
	if (IsClientValid(client) && g_bNoWeaponUse[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, TraceAttack);
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public void OnClientPostAdminCheck(int client)
{
	g_bGodmode[client] = false;
	g_bAuto[client] = false;
}

public Action Timer_DisableGodMode(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		g_bGodmode[client] = false;
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

public int Native_ResetClient(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(IsClientValid(client))
		ResetClientDice(client);
}

public void OnStartLR(int PrisonerIndex, int GuardIndex, int LR_Type)
{
	ResetClientDice(PrisonerIndex);
}
