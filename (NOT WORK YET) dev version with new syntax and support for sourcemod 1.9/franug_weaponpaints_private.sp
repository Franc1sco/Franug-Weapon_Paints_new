/*
	Weapon Paints

	Copyright (C) 2017 Francisco 'Franc1sco' García

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>
#include <givenameditem>

#define IDAYS 26

#undef REQUIRE_PLUGIN
#include <lastrequest>
#include <sm_franugknife>

#pragma newdecls required;

Database db;

int clientlang[MAXPLAYERS+1];

//bool checked[MAXPLAYERS + 1];

#define MAX_PAINTS 800
#define MAX_LANGUAGES 40
#define MAX_TYPES 80

enum Listados
{
	String:Nombre[64],
	index,
	Float:wear,
	stattrak,
	quality,
	pattern,
	String:flag[8],
	String:type[64]
}

Handle g_hTypesArray[MAX_LANGUAGES] = null;
Menu g_hTypesMenu[MAX_LANGUAGES][MAX_TYPES];

Menu menuw[MAX_LANGUAGES] = null;
int g_paints[MAX_LANGUAGES][MAX_PAINTS][Listados];
int g_paintCount[MAX_LANGUAGES];
char path_paints[PLATFORM_MAX_PATH];

bool g_hosties = false;

bool g_c4;
Handle cvar_c4;

Handle arbol[MAXPLAYERS+1] = null;
Menu menu1[MAXPLAYERS+1] = null;

Handle saytimer;
Handle cvar_saytimer;
int g_saytimer;

Handle rtimer;
Handle cvar_rtimer;
int g_rtimer;

Handle cvar_rmenu;
bool g_rmenu;

Handle cvar_onlyadmin;
bool onlyadmin;

char s_arma[MAXPLAYERS+1][64];
int s_sele[MAXPLAYERS+1];

int ismysql;

Handle array_paints[MAX_LANGUAGES];
Handle array_armas;

#define DATA "6.5 private version"

//new String:base[64] = "weaponpaints";

bool uselocal = false;

bool comprobado41[MAXPLAYERS+1];

bool chooset[MAXPLAYERS + 1];


public Plugin myinfo =
{
	name = "SM CS:GO Weapon Paints",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

char g_sCmdLogPath[256];

public void OnPluginStart()
{
 	for(int i=0;;i++)
	{
		BuildPath(Path_SM, g_sCmdLogPath, sizeof(g_sCmdLogPath), "logs/weaponpaints_%d.log", i);
		if ( !FileExists(g_sCmdLogPath) )
			break;
	}
	
	LoadTranslations ("franug_weaponpaints.phrases");
	
	CreateConVar("sm_wpaints_version", DATA, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	HookEvent("round_start", roundStart);
	//HookEvent("player_team", EventPlayerTeam);
	//HookEvent("player_spawn", Event_Player_Spawn, EventHookMode_Pre);
	AddCommandListener(OnJoinTeam, "joingame");
	AddCommandListener(OnJoinTeam, "jointeam");
	
	//RegConsoleCmd("buyammo1", GetSkins);
	RegConsoleCmd("sm_ws", GetSkins);
	RegConsoleCmd("sm_wskins", GetSkins);
	RegConsoleCmd("sm_paints", GetSkins);
	
	RegAdminCmd("sm_reloadwskins", ReloadSkins, ADMFLAG_ROOT);
	RegAdminCmd("sm_wsremove", RemoveSkins, ADMFLAG_ROOT);
	
	cvar_c4 = CreateConVar("sm_weaponpaints_c4", "1", "Enable or disable that people can apply paints to the C4. 1 = enabled, 0 = disabled");
	cvar_saytimer = CreateConVar("sm_weaponpaints_saytimer", "10", "Time in seconds for block that show the plugin commands in chat when someone type a command. -1.0 = never show the commands in chat");
	cvar_rtimer = CreateConVar("sm_weaponpaints_roundtimer", "-1.0", "Time in seconds roundstart for can use the commands for change the paints. -1.0 = always can use the command");
	cvar_rmenu = CreateConVar("sm_weaponpaints_rmenu", "1", "Re-open the menu when you select a option. 1 = enabled, 0 = disabled.");
	cvar_onlyadmin = CreateConVar("sm_weaponpaints_onlyadmin", "0", "This feature is only for admins. 1 = enabled, 0 = disabled.");
	
	g_c4 = GetConVarBool(cvar_c4);
	g_saytimer = GetConVarInt(cvar_saytimer);
	g_rtimer = GetConVarInt(cvar_rtimer);
	g_rmenu = GetConVarBool(cvar_rmenu);
	onlyadmin = GetConVarBool(cvar_onlyadmin);
	
	HookConVarChange(cvar_c4, OnConVarChanged);
	HookConVarChange(cvar_saytimer, OnConVarChanged);
	HookConVarChange(cvar_rtimer, OnConVarChanged);
	HookConVarChange(cvar_rmenu, OnConVarChanged);
	HookConVarChange(cvar_onlyadmin, OnConVarChanged);
	
	int count = GetLanguageCount();
	for (int i=0; i<count; i++)
		ReadPaints(i);
	
	char Items[64];
	
	if(array_armas != null) delete array_armas;
	
	array_armas = CreateArray(128);
	
	Format(Items, 64, "negev");
	//Format(Items[desc], 64, "Negev");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "m249");
	//Format(Items[desc], 64, "M249");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "bizon");
	//Format(Items[desc], 64, "PP-Bizon");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "p90");
	//Format(Items[desc], 64, "P90");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "scar20");
	//Format(Items[desc], 64, "SCAR-20");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "g3sg1");
	//Format(Items[desc], 64, "G3SG1");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "m4a1");
	//Format(Items[desc], 64, "M4A1");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "m4a1_silencer");
	//Format(Items[desc], 64, "M4A1-S");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "ak47");
	//Format(Items[desc], 64, "AK-47");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "aug");
	//Format(Items[desc], 64, "AUG");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "galilar");
	//Format(Items[desc], 64, "Galil AR");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "awp");
	//Format(Items[desc], 64, "AWP");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "sg556");
	//Format(Items[desc], 64, "SG 553");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "ump45");
	//Format(Items[desc], 64, "UMP-45");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "mp7");
	//Format(Items[desc], 64, "MP7");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "famas");
	//Format(Items[desc], 64, "FAMAS");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "mp9");
	//Format(Items[desc], 64, "MP9");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "mac10");
	//Format(Items[desc], 64, "MAC-10");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "ssg08");
	//Format(Items[desc], 64, "SSG 08");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "nova");
	//Format(Items[desc], 64, "Nova");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "xm1014");
	//Format(Items[desc], 64, "XM1014");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "sawedoff");
	//Format(Items[desc], 64, "Sawed-Off");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "mag7");
	//Format(Items[desc], 64, "MAG-7");
	PushArrayString(array_armas, Items);
	

	
	// Secondary weapons
	Format(Items, 64, "elite");
	//Format(Items[desc], 64, "Dual Berettas");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "deagle");
	//Format(Items[desc], 64, "Desert Eagle");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "tec9"); // 26
	//Format(Items[desc], 64, "Tec-9");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "fiveseven");
	//Format(Items[desc], 64, "Five-SeveN");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "cz75a");
	//Format(Items[desc], 64, "CZ75-Auto");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "glock");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "usp_silencer");
	//Format(Items[desc], 64, "USP-S");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "p250");
	//Format(Items[desc], 64, "P250");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "hkp2000");
	//Format(Items[desc], 64, "P2000");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "bayonet");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_gut");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_flip");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_m9_bayonet");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_karambit");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_tactical");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_butterfly");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "c4");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_falchion");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_push");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "revolver");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_survival_bowie");
	PushArrayString(array_armas, Items);
	
	ComprobarDB(true, "weaponpaints");
}

public void OnPluginEnd()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
			
		OnClientDisconnect(client);
	}
}

/*
public OnClientPostAdminCheck(client)
{
	QueryClientConVar(client, "cl_language", ConVarQueryFinished:CallBack);
}

public CallBack(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	langindex = GetLanguageByName(cvarValue);
    if(langindex == -1)
    {
		CreateTimer(0.1, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
    }
    
    clientlang[client] = langindex ;
	CheckSteamID(client);
	
	chooset[client] = true;
}
*/

/*
public Action EventPlayerTeam(Handle event, const String:name[], bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0 && client <= MaxClients)
	{
		if(IsFakeClient(client))
		{
			return Plugin_Continue;
		}
	}
		
	// refresh client channel after a delay to fix invalid memory access bug
	CreateTimer(0.1, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}*/

public Action Timer_ClientLanguage(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	
	if (client)
	{
		//if(!checked[client])
		//{
			clientlang[client] = GetClientLanguage(client);
			CheckSteamID(client);
			//checked[client] = true;
		//}
	}

	return Plugin_Stop;
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	if (chooset[client])return;
	
	clientlang[client] = GetClientLanguage(client);
	CheckSteamID(client);
	
	chooset[client] = true;
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == cvar_c4)
	{
		g_c4 = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == cvar_saytimer)
	{
		g_saytimer = StringToInt(newValue);
	}
	else if (convar == cvar_rtimer)
	{
		g_rtimer = StringToInt(newValue);
	}
	else if (convar == cvar_rmenu)
	{
		g_rmenu = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == cvar_onlyadmin)
	{
		onlyadmin = view_as<bool>(StringToInt(newValue));
	}
}

public void OnMapStart() {
	
	CreateTimer(3.0, valveserver, _, TIMER_FLAG_NO_MAPCHANGE);
} 

public Action valveserver(Handle timer)
{
	GameRules_SetProp("m_bIsValveDS", 1);
	GameRules_SetProp("m_bIsQuestEligible", 1);
}

void ComprobarDB(bool reconnect = false, char[] basedatos = "weaponpaints")
{
	
	if (uselocal)Format(basedatos, 64, "clientprefs");
	if(reconnect)
	{
		if (db != null)
		{
			//LogMessage("Reconnecting DB connection");
			CloseHandle(db);
			db = null;
		}
	}
	else if (db != null)
	{
		return;
	}

	if (!SQL_CheckConfig( basedatos ))
	{
		if(StrEqual(basedatos, "clientprefs")) SetFailState("Databases not found");
		else 
		{
			//base = "clientprefs";
			ComprobarDB(true,"clientprefs");
			uselocal = true;
		}
		
		return;
	}
	Database.Connect(OnSqlConnect, basedatos);
}

public void OnSqlConnect(Database hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogToFileEx(g_sCmdLogPath, "Database failure: %s", error);
		
		SetFailState("Databases dont work");
	}
	else
	{
		db = hndl;
		char buffer[3096];
		
		SQL_GetDriverIdent(SQL_ReadDriver(db), buffer, sizeof(buffer));
		ismysql = StrEqual(buffer,"mysql", false) ? 1 : 0;
	
		char temp[64][44];
		for(int i=0;i<GetArraySize(array_armas);++i)
		{
			GetArrayString(array_armas, i, temp[i], 64);
		}
		if (ismysql == 1)
		{
			Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `weaponpaints` (`playername` varchar(128) NOT NULL, `steamid` varchar(32) NOT NULL, `last_accountuse` int(64) NOT NULL,");
			
			for(int i=0;i<GetArraySize(array_armas);++i)
			{
				Format(buffer, sizeof(buffer), "%s `%s` varchar(64) NOT NULL DEFAULT 'none',", buffer, temp[i]);
			}
			Format(buffer, sizeof(buffer), "%s PRIMARY KEY  (`steamid`))", buffer);
			
			LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
			SQL_TQuery(db, tbasicoC, buffer);

		}
		else
		{
			Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS weaponpaints (playername varchar(128) NOT NULL, steamid varchar(32) NOT NULL, last_accountuse int(64) NOT NULL,");
		
			for(int i=0;i<GetArraySize(array_armas);++i)
			{
				Format(buffer, sizeof(buffer), "%s %s varchar(64) NOT NULL DEFAULT 'none',", buffer, temp[i]);
			}
			Format(buffer, sizeof(buffer), "%s PRIMARY KEY  (steamid))", buffer);
			
			LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
			SQL_TQuery(db, tbasicoC, buffer);
		}
	}
}

public void OnClientDisconnect(int client)
{	
	//checked[client] = false;
	chooset[client] = false;
	if(comprobado41[client] && !IsFakeClient(client)) SaveCookies(client);
	comprobado41[client] = false;
	if(arbol[client] != null)
	{
		ClearTrie(arbol[client]);
		CloseHandle(arbol[client]);
		arbol[client] = null;
	}
	if(menu1[client] != null)
	{
		delete menu1[client];
		menu1[client] = null;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("IsClientInLastRequest");
	MarkNativeAsOptional("Franug_GetKnife");

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "hosties"))
	{
		g_hosties = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "hosties"))
	{
		g_hosties = false;
	}
	
	
}

public Action RemoveSkins(int client,int args)
{	
	char buffer[1024];
	char steamid[64];
	GetCmdArg(1, steamid, 64);
	if (ismysql == 1)
		Format(buffer, sizeof(buffer), "DELETE FROM `weaponpaints` WHERE `steamid` = '%s';", steamid);
	else
		Format(buffer, sizeof(buffer), "DELETE FROM weaponpaints WHERE steamid = '%s';", steamid);

	LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	SQL_TQuery(db, tbasicoPRemoved, buffer, GetClientUserId(client));
	
	
	return Plugin_Handled;
}


public Action ReloadSkins(int client, int args)
{	
	int count = GetLanguageCount();
	for (int i=0; i<count; i++)
		ReadPaints(i);
		
	
	ReplyToCommand(client, " \x04[WP]\x01 %T","Weapon paints reloaded", client);
	
	return Plugin_Handled;
}

void ShowMenu(int client,int item)
{
	if (item == 0 && GetArraySize(g_hTypesArray[clientlang[client]]) > 0)
	{
		Menu hMenu = new Menu(SkinCategoryHandler);
		
		SetMenuTitle(hMenu, "%T", "Paints category menu title", client);
		
		char display[32];
		Format(display, sizeof(display), "%T", "All category", client);
		AddMenuItem(hMenu, "", display);
		
		for (int i; i < GetArraySize(g_hTypesArray[clientlang[client]]); i++)
		{
			char szType[32];
			GetArrayString(g_hTypesArray[clientlang[client]], i, szType, sizeof(szType));
			AddMenuItem(hMenu, "", szType);
		}
		
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		if (item == -3) // Hack to fix skipping first item
			item = 0;

		SetMenuTitle(menuw[clientlang[client]], "%T","Menu title 1", client);
		
		//RemoveMenuItem(menuw, 2);
		RemoveMenuItem(menuw[clientlang[client]], 1);
		RemoveMenuItem(menuw[clientlang[client]], 0);
		char tdisplay[64];
		//Format(tdisplay, sizeof(tdisplay), "%T", "Choose from your favorite paints", client);
		//InsertMenuItem(menuw, 0, "-2", tdisplay);
		Format(tdisplay, sizeof(tdisplay), "%T", "Random paint", client);
		InsertMenuItem(menuw[clientlang[client]], 0, "0", tdisplay);
		Format(tdisplay, sizeof(tdisplay), "%T", "Default paint", client);
		InsertMenuItem(menuw[clientlang[client]], 1, "-1", tdisplay);
		
		DisplayMenuAtItem(menuw[clientlang[client]], client, item, 0);
	}
}

void ShowMenuM(int client)
{
	if(onlyadmin && GetUserAdmin(client) == INVALID_ADMIN_ID) return;
	
	Menu menu2 = new Menu(DIDMenuHandler_2);
	SetMenuTitle(menu2, "%T by Franc1sco franug","Menu title 2", client, DATA);
	
	char tdisplay[64];
	Format(tdisplay, sizeof(tdisplay), "%T", "Select paint for the current weapon", client);
	AddMenuItem(menu2, "1", tdisplay);
	Format(tdisplay, sizeof(tdisplay), "%T", "Select paint for each weapon", client);
	AddMenuItem(menu2, "2", tdisplay);
	//Format(tdisplay, sizeof(tdisplay), "%T", "Favorite paints", client);
	//AddMenuItem(menu2, "3", tdisplay);
	
	DisplayMenu(menu2, client, 0);
}

public Action GetSkins(int client,int args)
{	
	Format(s_arma[client], 64, "none");
	ShowMenuM(client);
	
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(StrEqual(sArgs, "ws", false))
	{
		ShowMenuM(client);
		if(saytimer != null || g_saytimer == -1) return Plugin_Handled;
		saytimer = CreateTimer(1.0*g_saytimer, Tsaytimer);
		return Plugin_Continue;
		
		
	}
	if(StrEqual(sArgs, "!wskins", false) || StrEqual(sArgs, "!ws", false) || StrEqual(sArgs, "!paints", false))
	{
		Format(s_arma[client], 64, "none");
		//ShowMenuM(client);
		
		if(saytimer != null || g_saytimer == -1) return Plugin_Handled;
		saytimer = CreateTimer(1.0*g_saytimer, Tsaytimer);
		return Plugin_Continue;
		
	}
	else if(StrEqual(sArgs, "!ss", false) || StrEqual(sArgs, "!showskin", false))
	{
		ShowSkin(client);
		
		if(saytimer != null || g_saytimer == -1) return Plugin_Handled;
		saytimer = CreateTimer(1.0*g_saytimer, Tsaytimer);
		return Plugin_Continue;
	}
    
	return Plugin_Continue;
}

void ShowSkin(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon < 1 || !IsValidEdict(weapon) || !IsValidEntity(weapon))
	{
		CPrintToChat(client, " {green}[WP]{default} %T", "Paint not found", client);
		return;
	}
	
	int buscar = GetEntProp(weapon,Prop_Send,"m_nFallbackPaintKit");
	for(int i=1; i<g_paintCount[clientlang[client]];i++)
	{
		if(buscar == g_paints[clientlang[client]][i][index])
		{
			CPrintToChat(client, " {green}[WP]{default} %T", "Paint found", client, g_paints[clientlang[client]][i][Nombre]);
			return;
		}
	}
	
	CPrintToChat(client, " {green}[WP]{default} %T", "Paint not found", client);
}

public Action Tsaytimer(Handle timer)
{
	saytimer = null;
}

public Action roundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	if(g_rtimer == -1) return;
	
	if(rtimer != null)
	{
		KillTimer(rtimer);
		rtimer = null;
	}
	
	rtimer = CreateTimer(1.0*g_rtimer, Rtimer);
}

public Action Rtimer(Handle timer)
{
	rtimer = null;
}

public int DIDMenuHandler_2(Menu menu, MenuAction action, int client, int itemNum) 
{
	if ( action == MenuAction_Select ) 
	{

		
		char info[4];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		int theindex = StringToInt(info);
		if(theindex == 1) ShowMenu(client, 0);
		else if(theindex == 2 && comprobado41[client]) ShowMenuArmas(client, 0);
		//else if(theindex == 3) ShowMenuFav(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int SkinCategoryHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		if (itemNum == 0)
		{
			ShowMenu(client, -3);
			return;
		}
		
		char szType[32];
		GetArrayString(g_hTypesArray[clientlang[client]], itemNum-1, szType, sizeof(szType));		
		SetMenuTitle(g_hTypesMenu[clientlang[client]][itemNum-1], "%T", "Choose a paint from a category menu title", client, szType);
		DisplayMenu(g_hTypesMenu[clientlang[client]][itemNum-1], client, 0);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ShowMenuArmas(int client, int item)
{	
	if(menu1[client] == null) CrearMenu1(client);
	DisplayMenuAtItem(menu1[client], client, item, 0);
}

public int DIDMenuHandler(Menu menu, MenuAction action,int client, int itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		if(!comprobado41[client])
		{
			if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
			return;
		}
		
		char Classname[64];
		char info[4];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		int theindex = StringToInt(info);
		
		if(StrEqual(s_arma[client], "none"))
		{
			if(GetUserAdmin(client) == INVALID_ADMIN_ID && rtimer == null && g_rtimer != -1)
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You can use this command only the first seconds", client, g_rtimer);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
			if(!IsPlayerAlive(client))
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use this when you are dead", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
			if(g_hosties && IsClientInLastRequest(client))
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use this when you are in a lastrequest", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}

			if(theindex != -1 && !StrEqual(g_paints[clientlang[client]][theindex][flag], "0"))
			{
				if(!CheckCommandAccess(client, "weaponpaints_override", ReadFlagString(g_paints[clientlang[client]][theindex][flag]), true))
				{
					CPrintToChat(client, " {green}[WP]{default} %T", "You dont have access to this paint", client);
					if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
					return;
				}
			}
			
		
			int windex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(windex < 1)
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
		
		
			if(!GetEdictClassname(windex, Classname, 64) || StrEqual(Classname, "weapon_taser") || (!g_c4 && StrEqual(Classname, "weapon_c4")))
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
			ReplaceString(Classname, 64, "weapon_", "");
			int weaponindex = GetEntProp(windex, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponindex == 42 || weaponindex == 59)
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == windex || GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == windex || GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == windex || (g_c4 && GetPlayerWeaponSlot(client, CS_SLOT_C4) == windex))
			{
				switch (weaponindex)
				{
					case 60: strcopy(Classname, 64, "m4a1_silencer");
					case 61: strcopy(Classname, 64, "usp_silencer");
					case 63: strcopy(Classname, 64, "cz75a");
					case 500: strcopy(Classname, 64, "bayonet");
					case 506: strcopy(Classname, 64, "knife_gut");
					case 505: strcopy(Classname, 64, "knife_flip");
					case 508: strcopy(Classname, 64, "knife_m9_bayonet");
					case 507: strcopy(Classname, 64, "knife_karambit");
					case 509: strcopy(Classname, 64, "knife_tactical");
					case 515: strcopy(Classname, 64, "knife_butterfly");
					case 512: strcopy(Classname, 64, "knife_falchion");
					case 516: strcopy(Classname, 64, "knife_push");
					case 64: strcopy(Classname, 64, "revolver");
					case 514: strcopy(Classname, 64, "knife_survival_bowie");
				}
				
				if(arbol[client] == null)
				{
					//checked[client] = false;
					CreateTimer(0.0, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
					return;
				}
				else 
				{
					int valor = 0;
					if(!GetTrieValue(arbol[client], Classname, valor))
					{
						CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon", client);
						if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
						return;
					}
					
					char buffer[1024], nombres[64];
					if(theindex == -1) Format(nombres, sizeof(nombres), "default");
					else Format(nombres, sizeof(nombres), g_paints[clientlang[client]][theindex][Nombre]);
					char steamid[32];
					GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
					Format(buffer, sizeof(buffer), "UPDATE weaponpaints SET %s = '%s' WHERE steamid = '%s';", Classname,nombres,steamid);
					LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
					SQL_TQuery(db, tbasico, buffer, GetClientUserId(client));
					SetTrieValue(arbol[client], Classname, theindex);
				}
				
				//ChangePaint(client, windex, Classname, weaponindex, true);
				char Classname2[64];
				Format(Classname2, 64, "weapon_%s", Classname);
				Restore(client, windex, Classname2);
				FakeClientCommand(client, "use %s", Classname2);
				if(theindex == -1) CPrintToChat(client, " {green}[WP]{default} %T","You have choose your default paint for your",client, Classname);
				else if(theindex == 0) CPrintToChat(client, " {green}[WP]{default} %T","You have choose a random paint for your",client, Classname);
				else CPrintToChat(client, " {green}[WP]{default} %T", "You have choose a weapon",client, g_paints[clientlang[client]][theindex][Nombre], Classname);
				
				char temp[128], temp1[64];
				if(theindex == -1) Format(temp, 128, "%s", Classname);
				else if (theindex == 0)
				{
				
					Format(temp1, sizeof(temp1), "%T", "Random paint", client);
					Format(temp, 128, "%s - %s", Classname, temp1);
				}
				else Format(temp, 128, "%s - %s", Classname, g_paints[clientlang[client]][theindex][Nombre]);
				if(menu1[client] == null) CrearMenu1(client);
				int imenu = FindStringInArray(array_armas, Classname);
				InsertMenuItem(menu1[client], imenu, Classname, temp);
				FindStringInArray(array_armas, Classname);
				RemoveMenuItem(menu1[client], imenu+1);
			}
			else CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon",client);
			
			
		}
		else
		{
			Format(Classname, 64, s_arma[client]);
			
			if(arbol[client] == null)
			{
				//checked[client] = false;
				CreateTimer(0.0, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
				return;
			}
			else 
			{
				char buffer[1024], nombres[64];
				if(theindex == -1) Format(nombres, sizeof(nombres), "default");
				else Format(nombres, sizeof(nombres), g_paints[clientlang[client]][theindex][Nombre]);
				char steamid[32];
				GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
				Format(buffer, sizeof(buffer), "UPDATE weaponpaints SET %s = '%s' WHERE steamid = '%s';", Classname,nombres,steamid);
				LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
				SQL_TQuery(db, tbasico, buffer, GetClientUserId(client));
				SetTrieValue(arbol[client], Classname, theindex);
			}
			
			if(theindex == -1) CPrintToChat(client, " {green}[WP]{default} %T","You have choose your default paint for your",client, Classname);
			else if(theindex == 0) CPrintToChat(client, " {green}[WP]{default} %T","You have choose a random paint for your",client, Classname);
			else CPrintToChat(client, " {green}[WP]{default} %T", "You have choose a weapon",client, g_paints[clientlang[client]][theindex][Nombre], Classname);
			
			char temp[128], temp1[64];
			if(theindex == -1) Format(temp, 128, "%s", Classname);
			else if (theindex == 0)
			{
				
				Format(temp1, sizeof(temp1), "%T", "Random paint", client);
				Format(temp, 128, "%s - %s", Classname, temp1);
			}
			else Format(temp, 128, "%s - %s", Classname, g_paints[clientlang[client]][theindex][Nombre]);
			int imenu = FindStringInArray(array_armas, Classname);
			InsertMenuItem(menu1[client], imenu, Classname, temp);
			FindStringInArray(array_armas, Classname);
			RemoveMenuItem(menu1[client], imenu+1);
			Format(s_arma[client], 64, "none");
			ShowMenuArmas(client, s_sele[client]);
			return;
		}

		if(g_rmenu) 
		{
			bool found = false;
			
			for (int i; i < GetMenuItemCount(menu); i++)
			{
				GetMenuItem(menu, i, info, sizeof(info));
				
				if (StrEqual(info, "cat"))
					found = true;
			}

			if (found)
				DisplayMenu(menu, client, 0);
			else
				ShowMenu(client, GetMenuSelectionPosition());
		}
	}
}

/* public Action RestoreItemID(Handle timer, Handle pack)
{
    new entity;
    new m_iItemIDHigh;
    new m_iItemIDLow;
    
    ResetPack(pack);
    entity = EntRefToEntIndex(ReadPackCell(pack));
    m_iItemIDHigh = ReadPackCell(pack);
    m_iItemIDLow = ReadPackCell(pack);
    
    if(entity != INVALID_ENT_REFERENCE)
	{
		SetEntProp(entity,Prop_Send,"m_iItemIDHigh",m_iItemIDHigh);
		SetEntProp(entity,Prop_Send,"m_iItemIDLow",m_iItemIDLow);
	}
} */

void ReadPaints(int index_new)
{
	g_hTypesArray[index_new] = CreateArray(32);
	array_paints[index_new] = CreateArray(128);
	char code[64], language[128];
	GetLanguageInfo(index_new, code, 64, language, 128);
	
	BuildPath(Path_SM, path_paints, sizeof(path_paints), "configs/franug_weaponpaints/csgo_wpaints_%s.cfg", language);
	
	if(!FileExists(path_paints)) BuildPath(Path_SM, path_paints, sizeof(path_paints), "configs/franug_weaponpaints/csgo_wpaints_english.cfg");
	
	KeyValues kv;
	g_paintCount[index_new] = 1;
	ClearArray(array_paints[index_new]);
	PushArrayString(array_paints[index_new], "random");
	Format(g_paints[index_new][0][Nombre], 64, "random")

	kv = new KeyValues("Paints");
	FileToKeyValues(kv, path_paints);

	if (!KvGotoFirstSubKey(kv)) {

		SetFailState("CFG File not found: %s", path_paints);
		delete kv;
	}
	do {

		KvGetSectionName(kv, g_paints[index_new][g_paintCount[index_new]][Nombre], 64);
		g_paints[index_new][g_paintCount[index_new]][index] = KvGetNum(kv, "paint", 0);
		g_paints[index_new][g_paintCount[index_new]][wear] = KvGetFloat(kv, "wear", 0.01);
		g_paints[index_new][g_paintCount[index_new]][stattrak] = KvGetNum(kv, "stattrak", -2);
		g_paints[index_new][g_paintCount[index_new]][quality] = KvGetNum(kv, "quality", 3);
		g_paints[index_new][g_paintCount[index_new]][pattern] = KvGetNum(kv, "pattern", 0);
		KvGetString(kv, "flag", g_paints[index_new][g_paintCount[index_new]][flag], 8, "0");
		KvGetString(kv, "type", g_paints[index_new][g_paintCount[index_new]][type], 11, "None");
		
		if (FindStringInArray(g_hTypesArray[index_new], g_paints[index_new][g_paintCount[index_new]][type]) == -1)
			PushArrayString(g_hTypesArray[index_new], g_paints[index_new][g_paintCount[index_new]][type]);

		PushArrayString(array_paints[index_new], g_paints[index_new][g_paintCount[index_new]][Nombre]);
		g_paintCount[index_new]++;
	} while (KvGotoNextKey(kv));
	delete kv;
	
	SortADTArray(g_hTypesArray[index_new], Sort_Ascending, Sort_String);
	
	if (menuw[index_new] != null) delete menuw[index_new];
	menuw[index_new] = null;
	
	menuw[index_new] = new Menu(DIDMenuHandler);
	
	// TROLLING
	SetMenuTitle(menuw[index_new], "( ͡° ͜ʖ ͡°)");
	char item[4];
	AddMenuItem(menuw[index_new], "0", "Random paint");
	AddMenuItem(menuw[index_new], "-1", "Default paint"); 
	// FORGET THIS
	
	for (int i=g_paintCount[index_new]; i<MAX_PAINTS; ++i) {
	
		g_paints[index_new][i][index] = 0;
	}
	//char menuitem[192];
	for (int i=1; i<g_paintCount[index_new]; ++i) {
		Format(item, 4, "%i", i);
		AddMenuItem(menuw[index_new], item, g_paints[index_new][i][Nombre]);
		
/* 		if(StrEqual(g_paints[g_paintCount][flag], "public", false))
		{
			AddMenuItem(menuw, item, g_paints[i][Nombre]);
		}
		else 
		{
			Format(menuitem, 192, "%s (flag %s)", g_paints[i][Nombre],g_paints[i][flag]);
			AddMenuItem(menuw, item, menuitem);
		} */
	}
	
	SetMenuExitButton(menuw[index_new], true);
	
	for (int i; i < GetArraySize(g_hTypesArray[index_new]); i++)
	{
		char szType[32];
		GetArrayString(g_hTypesArray[index_new], i, szType, sizeof(szType));
		
		g_hTypesMenu[index_new][i] = null;
		g_hTypesMenu[index_new][i] = new Menu(DIDMenuHandler);
		SetMenuExitButton(g_hTypesMenu[index_new][i], true);
		
		AddMenuItem(g_hTypesMenu[index_new][i], "cat", "", ITEMDRAW_IGNORE);
		
		for (int j = 1; j < g_paintCount[index_new]; ++j)
		{
			Format(item, 4, "%i", j);
			if (StrEqual(g_paints[index_new][j][type], szType))
				AddMenuItem(g_hTypesMenu[index_new][i], item, g_paints[index_new][j][Nombre]);
		}
	}	
}

/* stock GetReserveAmmo(client, weapon)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return -1;
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

stock SetReserveAmmo(client, weapon, ammo)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return;
    
    SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}  */

stock int GetReserveAmmo(int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
	if(ammotype == -1) return -1;
    
	return ammotype;
}

stock int SetReserveAmmo(int weapon,int ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
	//PrintToChatAll("fijar es %i", ammo);
} 

void Restore(int client, int windex, char[] Classname)
{
	bool knife = false;
	if(StrContains(Classname, "weapon_knife", false) == 0 || StrContains(Classname, "weapon_bayonet", false) == 0) 
	{
		knife = true;
	}
	
	if(knife)
	{
		if(GetFeatureStatus(FeatureType_Native, "Franug_GetKnife") == FeatureStatus_Available) 
			GiveNamedItem_GiveKnife(client, Franug_GetKnife(client));
		else
		{
			RemovePlayerItem(client, windex);
			AcceptEntityInput(windex, "Kill");
	
			GivePlayerItem(client, "weapon_knife");
		}
		return;
	}
	
	//PrintToChat(client, "weapon %s", Classname);
	int ammo, clip;
	ammo = GetReserveAmmo(windex);
	clip = GetEntProp(windex, Prop_Send, "m_iClip1");
	
	RemovePlayerItem(client, windex);
	AcceptEntityInput(windex, "Kill");
	
	int entity = GivePlayerItem(client, Classname);

	SetReserveAmmo(entity, ammo);
	SetEntProp(entity, Prop_Send, "m_iClip1", clip);
}

public void OnGiveNamedItemEx(int client, const char[] Classname)
{
	if (StrContains(Classname, "weapon_") != 0)
		return;

	if (IsFakeClient(client))
		return;
		
	int itemdefinition = GiveNamedItemEx.GetItemDefinitionByClassname(Classname);
	
	if (itemdefinition == -1)
		return;
		
	if(onlyadmin && GetUserAdmin(client) == INVALID_ADMIN_ID) return;
		
	
	if(StrEqual(Classname, "weapon_taser") || (!g_c4 && StrEqual(Classname, "weapon_c4")))
	{
		return;
	}
	if(GiveNamedItemEx.IsClassnameKnife(Classname))
	{
		if(GetFeatureStatus(FeatureType_Native, "Franug_GetKnife") == FeatureStatus_Available) 
		{
			itemdefinition = Franug_GetKnife(client);
			if(itemdefinition < 2)
				return;
		}
	
		if(itemdefinition == 42 || itemdefinition == 59)
		{
			return;
		}
	}
	
	char classnamet[64];
	//Format(classnamet, 64, Classname);
	GiveNamedItemEx.GetClassnameByItemDefinition(itemdefinition, classnamet, 64);
	ReplaceString(classnamet, 64, "weapon_", "");

	if(arbol[client] == null) return;
	int valor = 0;
	if(!GetTrieValue(arbol[client], classnamet, valor)) return;
	if(valor == -1 || (valor != 0 && g_paints[clientlang[client]][valor][index] == 0)) return;
	
	if(valor == 0)
	{
		valor = GetRandomInt(1, g_paintCount[clientlang[client]]-1);
	}
	else if(valor == -1) return;
	
/* 	new m_iItemIDHigh = GetEntProp(entity, Prop_Send, "m_iItemIDHigh");
	new m_iItemIDLow = GetEntProp(entity, Prop_Send, "m_iItemIDLow"); */
	GiveNamedItemEx.Paintkit = g_paints[clientlang[client]][valor][index];
	
	if(g_paints[clientlang[client]][valor][wear] >= 0.0) GiveNamedItemEx.Wear = g_paints[clientlang[client]][valor][wear];
	if(g_paints[clientlang[client]][valor][pattern] >= 0) GiveNamedItemEx.Seed = g_paints[clientlang[client]][valor][pattern];
	if(g_paints[clientlang[client]][valor][stattrak] != -2) GiveNamedItemEx.Kills = g_paints[clientlang[client]][valor][stattrak];
	if(g_paints[clientlang[client]][valor][quality] != -2) GiveNamedItemEx.EntityQuality = g_paints[clientlang[client]][valor][quality];
}

void SaveCookies(int client)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if (!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
	}	

	char buffer[3096];
	Format(buffer, sizeof(buffer), "UPDATE weaponpaints SET last_accountuse = %d, playername = '%s' WHERE steamid = '%s';",GetTime(), SafeName,steamid);
	LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	SQL_TQuery(db, tbasico2, buffer);
}

void CrearMenu1(int client)
{
	
	menu1[client] = new Menu(DIDMenuHandler_armas);
	SetMenuTitle(menu1[client], "%T","Menu title 1", client);
	
	char Items[64];
	
	char temp[128], temp1[64];
	int valor;
	for(int i=0;i<GetArraySize(array_armas);++i)
	{
		GetArrayString(array_armas, i, Items, 64);
		if(GetTrieValue(arbol[client], Items, valor))
		{
			if(valor == -1) Format(temp, 128, "%s", Items);
			else if (valor == 0)
			{
				Format(temp1, sizeof(temp1), "%T", "Random paint", client);
				Format(temp, 128, "%s - %s", Items, temp1);
			}
			else Format(temp, 128, "%s - %s", Items, g_paints[clientlang[client]][valor][Nombre]);
		}
		else Format(temp, 128, "%s", Items);
		AddMenuItem(menu1[client], Items, temp);
	}
}

public int DIDMenuHandler_armas(Menu menu, MenuAction action,int client,int itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		char info[64];
		
		menu.GetItem(itemNum, info, sizeof(info));

		Format(s_arma[client], 64, info);
		s_sele[client] = GetMenuSelectionPosition();
		ShowMenu(client, 0);
	}
}

void CheckSteamID(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	
	Format(query, sizeof(query), "SELECT * FROM weaponpaints WHERE steamid = '%s'", steamid);
	LogToFileEx(g_sCmdLogPath, "Query %s", query);
	SQL_TQuery(db, T_CheckSteamID, query, GetClientUserId(client));
}
 
public void T_CheckSteamID(Handle owner, Handle hndl, const char[] error, any data)
{
	int client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	if (hndl == null)
	{
		ComprobarDB();
		return;
	}
	//PrintToChatAll("comprobado41");
	if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		Nuevo(client);
		return;
	}
	
	arbol[client] = CreateTrie();

	char Items[64];
	
	char temp[64];
	int contar = 3;
	//PrintToChat(client, "pasado");
	for(int i=0;i<GetArraySize(array_armas);++i)
	{
		GetArrayString(array_armas, i, Items, 64);
		SQL_FetchString(hndl, contar, temp, 64);
		SetTrieValue(arbol[client], Items, FindStringInArray(array_paints[clientlang[client]], temp));
		
		//PrintToChat(client, "Sacado %i del arma %s", FindStringInArray(array_paints[clientlang[client]], temp),Items);
		
		contar++;
	}

/*   	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite1", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite2", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite3", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite4", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite5", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite6", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite7", FindStringInArray(array_paints, temp));
	contar++; */
	
	
	comprobado41[client] = true;
/* 	new String:equipo[64];
	SQL_FetchString( hndl, 0, equipo, 64);
	PrintToChatAll(equipo);
	
	SQL_FetchString( hndl, 1, equipo, 64);
	PrintToChatAll(equipo);
	
	SQL_FetchString( hndl, 2, equipo, 64);
	PrintToChatAll(equipo);
	
	SQL_FetchString( hndl, 3, equipo, 64); // este
	PrintToChatAll(equipo); */
	
	//PrintToChatAll("pasado");
	
/* 	char equipo[4];
	SQL_FetchString( hndl, 0, equipo, 4);
	
	if(StrEqual(equipo, "CT", false))
	{
		ft[client] = CS_TEAM_CT;
	}
	else if(StrEqual(equipo, "T", false))
	{
		ft[client] = CS_TEAM_T;
	} */
	Renovar(client);

}

public void tbasicoPRemoved(Handle owner, Handle hndl, const char[] error, any data)
{
	int client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	if (hndl == null)
	{
		ComprobarDB();
		return;
	}
	
	PrintToChat(client, "Client deleted");
}

void Renovar(int client)
{
	if(IsPlayerAlive(client))
	{
		char classname[64];
		int weaponIndex;
		for (int i = 0; i <= 3; i++)
		{
			if(i == CS_SLOT_GRENADE) continue;
			
			if ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
			{
				GetEdictClassname(weaponIndex, classname, 64);
				
				Restore(client, weaponIndex, classname);
			}
		}
	}
}

void Nuevo(int client)
{
	//PrintToChatAll("metido");
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	int userid = GetClientUserId(client);
	
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if (!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
	}
		
	Format(query, sizeof(query), "INSERT INTO weaponpaints(playername, steamid, last_accountuse) VALUES('%s', '%s', '%d');", SafeName, steamid, GetTime());
	LogToFileEx(g_sCmdLogPath, "Query %s", query);
	SQL_TQuery(db, tbasico3, query, userid);
}


public void PruneDatabase()
{
	if (db == null)
	{
		LogToFileEx(g_sCmdLogPath, "Prune Database: No connection");
		ComprobarDB();
		return;
	}

	int maxlastaccuse;
	maxlastaccuse = GetTime() - (IDAYS * 86400);

	char buffer[1024];

	if (ismysql == 1)
		Format(buffer, sizeof(buffer), "DELETE FROM `weaponpaints` WHERE `last_accountuse`<'%d' AND `last_accountuse`>'0';", maxlastaccuse);
	else
		Format(buffer, sizeof(buffer), "DELETE FROM weaponpaints WHERE last_accountuse<'%d' AND last_accountuse>'0';", maxlastaccuse);

	LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	SQL_TQuery(db, tbasicoP, buffer);
}

public void tbasico(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
	}
	int client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	comprobado41[client] = true;
	
}

public void tbasico2(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
		ComprobarDB();
	}
}

public void tbasico3(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
		ComprobarDB();
	}
	int client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	arbol[client] = CreateTrie();

	char Items[64];
	
	for(int i=0;i<GetArraySize(array_armas);++i)
	{
		GetArrayString(array_armas, i, Items, 64);
		SetTrieValue(arbol[client], Items, -1);
	}
	
	SetTrieValue(arbol[client], "favorite1", -1);
	SetTrieValue(arbol[client], "favorite2", -1);
	SetTrieValue(arbol[client], "favorite3", -1);
	SetTrieValue(arbol[client], "favorite4", -1);
	SetTrieValue(arbol[client], "favorite5", -1);
	SetTrieValue(arbol[client], "favorite6", -1);
	SetTrieValue(arbol[client], "favorite7", -1);
	
	comprobado41[client] = true;
}

public void tbasicoC(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
	}
	//LogMessage("Database connection successful");
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			//checked[client] = false;
			CreateTimer(0.0, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void tbasicoP(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
		ComprobarDB();
	}
	//LogMessage("Prune Database successful");
}