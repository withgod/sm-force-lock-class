#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.0.1"
#define DB_IDENTIFER "force-class-interval"

String:currentMap[PLATFORM_MAX_PATH];
Database:db;
ConVar force_interval; // min
ConVar fciDebug;

public Plugin:myinfo = 
{
	name = "Force Suck Class Interval",
	author = "withgod",
	description = "force spy/sniper interval plugin.",
	version = PLUGIN_VERSION,
	url = "http://github.com/withgod/sm-force-class-interval"
};


public void UpdateHistory(int result_id)
{
	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] Fn UpdateHistory");
	new String:sql[PLATFORM_MAX_PATH];
	Format(sql, sizeof(sql), "update history set updated_at = CURRENT_TIMESTAMP, map = '%s' where id = %d", currentMap, result_id);
	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] update updated_at [%s]", sql);
	if (!SQL_FastQuery(db, sql)) 
	{
		new String:error[PLATFORM_MAX_PATH];
		SQL_GetError(db, error, sizeof(error));
		LogError("[FCI] Failed to query (error: %s)", error);
	}
}public void UpdateHistoryByUserId(int userid)
{
	new String:steamid[PLATFORM_MAX_PATH];

	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] Fn UpdateHistoryByUserId");

	new TFClassType:current_class = TF2_GetPlayerClass(userid);
	if (!GetClientAuthId(userid, AuthId_Steam2, steamid, PLATFORM_MAX_PATH)) {
		LogError("[FCI] Failed to get clientid");
	}

	new String:sql[PLATFORM_MAX_PATH];
	Format(sql, sizeof(sql), "update history set updated_at = CURRENT_TIMESTAMP, map = '%s' where user_id = %d and class_id = %d", currentMap, steamid, current_class);
	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] update updated_at [%s]", sql);
	if (!SQL_FastQuery(db, sql)) 
	{
		new String:error[PLATFORM_MAX_PATH];
		SQL_GetError(db, error, sizeof(error));
		LogError("[FCI] Failed to query (error: %s)", error);
	}
}

public void OnPluginStart()
{
	// https://wiki.alliedmods.net/Translations_(SourceMod_Scripting)
	LoadTranslations("force-class-interval.phrases");

	// https://wiki.alliedmods.net/ConVars_(SourceMod_Scripting)
	force_interval  = CreateConVar("fci_force_interval", "15", "force interval time(min)");
	fciDebug = CreateConVar("fci_debug", "0", "foce interval plugin debug cvar");

	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] force class interval plugin loaded!");

	// https://wiki.alliedmods.net/Team_Fortress_2_Events
	// https://wiki.alliedmods.net/Events_(SourceMod_Scripting)
	HookEvent("player_spawn", Event_PlayerSpawn);

	// https://wiki.alliedmods.net/SQL_(SourceMod_Scripting)
	new String:error[PLATFORM_MAX_PATH];
	db = SQL_Connect(DB_IDENTIFER, true, error, sizeof(error));
	
	if (db == null)
	{
		LogError("[FCI] Could not connect database: %s", error);
	}
}

public Action Command_Leftime(int client, int args)
{
	if (GetConVarBool(fciDebug))
		PrintToServer("user %d called leftime", client);
	return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	new String:steamid[PLATFORM_MAX_PATH];

	// in game userindex
	int userid = GetClientOfUserId(GetEventInt (event, "userid", 0));
	// 0=Unassigned 2=red 3=blue
	int teamid = GetClientTeam(userid);

	if (teamid == 0) { // not joined on changelevel
		return;
	}

	// TFClass_Sniper, TFClass_Spy https://sm.alliedmods.net/new-api/tf2/TFClassType
	new TFClassType:current_class = TF2_GetPlayerClass(userid);

	// steam id = ex. STEAM_0:0:18507580 
	if (!GetClientAuthId(userid, AuthId_Steam2, steamid, PLATFORM_MAX_PATH)) {
		LogError("[FCI] Failed to get clientid");
	}

	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] client[%d][%s] spawn for team[%d]class[%d]", userid, steamid, teamid, current_class);

	new String:sql1[PLATFORM_MAX_PATH];
	Format(sql1, sizeof(sql1), "select id, user_id, class_id, map, updated_at, strftime('%%s', updated_at) from history where user_id = '%s' and class_id = %d limit 1", steamid, current_class);
	//PrintToServer("[FCI] query[%s]", sql1);

	DBResultSet hQuery = SQL_Query(db, sql1);
	if (hQuery == null)
	{
			new String:error[PLATFORM_MAX_PATH];
			SQL_GetError(db, error, sizeof(error));
			LogError("[FCI]Failed to query (error: %s)", error);
			delete hQuery;
			return;
	}

	if (SQL_GetRowCount(hQuery) == 0) // 1st time.
    {
		new String:sql2[PLATFORM_MAX_PATH];
		Format(sql2, sizeof(sql2), "insert into history(user_id, class_id, map) values('%s', %d, '%s')", steamid, current_class, currentMap);
		if (!SQL_FastQuery(db, sql2)) 
		{
			new String:error[PLATFORM_MAX_PATH];
			SQL_GetError(db, error, sizeof(error));
			LogError("[FCI]Failed to query (error: %s)", error);
		}
		if (GetConVarBool(fciDebug))
			PrintToServer("[FCI] inserted");
		delete hQuery;
		return;
    } 

	new String:result_uid[PLATFORM_MAX_PATH], String:result_map[PLATFORM_MAX_PATH], String:result_updated[PLATFORM_MAX_PATH], String:result_updated_tmp[PLATFORM_MAX_PATH];
	int result_id, result_class, result_updatedInt;

	SQL_FetchRow(hQuery); // limit 1

	result_id = SQL_FetchInt(hQuery, 0);
	SQL_FetchString(hQuery, 1, result_uid, sizeof(result_uid));
	result_class = SQL_FetchInt(hQuery, 2);
	SQL_FetchString(hQuery, 3, result_map, sizeof(result_map));
	SQL_FetchString(hQuery, 4, result_updated, sizeof(result_updated));
	SQL_FetchString(hQuery, 5, result_updated_tmp, sizeof(result_updated_tmp));
	result_updatedInt = StringToInt(result_updated_tmp);
	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] result uid[%s]class[%d]map[%s]date[%s/%d] / current map[%s] current class[%d]", result_uid, result_class, result_map, result_updated, result_updatedInt, currentMap, current_class);

	// same map on preview spawn or not suck class.
	if (
		StrEqual(result_map, currentMap) ||
		 (current_class != TFClass_Sniper && current_class != TFClass_Spy)
		)
	{
		if (GetConVarBool(fciDebug))
			PrintToServer("same map or not suck class.");
		UpdateHistory(result_id);
	} 
	else
	{
		if (GetConVarBool(fciDebug))
			PrintToServer("[FCI] different map and suck class");
		new String:current_timestampStr[PLATFORM_MAX_PATH];
		int current_timestamp = GetTime();
		FormatTime(current_timestampStr, sizeof(current_timestampStr), "%Y-%m-%d %H:%M:%S");
		if (GetConVarBool(fciDebug))
			PrintToServer("[FCI] current timestamp %s/%d", current_timestampStr, current_timestamp);

		int _force_interval = GetConVarInt(force_interval);
		int interval_period = result_updatedInt + (_force_interval * 60);
		if (GetConVarBool(fciDebug))
			PrintToServer("[FCI] force interval[%d]period[%d]", _force_interval, interval_period);

		if (interval_period < current_timestamp) {
			if (GetConVarBool(fciDebug))
				PrintToServer("[FCI] class choice ok");
			UpdateHistory(result_id);
		} else {
			new String:timeleft_msg[PLATFORM_MAX_PATH], String:msg[PLATFORM_MAX_PATH], String:class_name[PLATFORM_MAX_PATH];

			int timeleft = interval_period - current_timestamp;
			int timeleft_min = timeleft / 60;
			int timeleft_sec = timeleft % 60;
			Format(timeleft_msg, sizeof(timeleft_msg), "%02d:%02d", timeleft_min, timeleft_sec);

			if (current_class == TFClass_Sniper) {
				Format(class_name, sizeof(class_name), "%s", "Sniper");
			} else {
				Format(class_name, sizeof(class_name), "%s", "Spy");
			}
			
			Format(msg, sizeof(msg), "[FCI] %T", "msg1", userid, class_name, timeleft_msg);
			PrintCenterText(userid, msg);
			PrintToChat(userid, msg);
			if (GetConVarBool(fciDebug))
				PrintToChat(userid, "[FCI] more %d sec", timeleft);
			ShowVGUIPanel(userid, teamid == 2 ? "class_red" : "class_blue");
			TF2_SetPlayerClass(userid, TFClass_Scout);
			TF2_RespawnPlayer(userid);
		}
	}

	delete hQuery;
}

public OnMapStart() 
{
	GetCurrentMap(currentMap, sizeof(currentMap));
	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] map starting current map is %s", currentMap);
}

public OnMapEnd()
{
	if (GetConVarBool(fciDebug))
		PrintToServer("[FCI] map ending current map is %s", currentMap);
	for (int i = 1; i < MaxClients + 1; i++) {
		//PrintToServer("[FCI]end %d/%d/%d", i, IsClientInGame(i), IsFakeClient(i));
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			PrintToServer("[FCI] map ending update userid[%d]", i);
			UpdateHistoryByUserId(i);
		}
	}
}
