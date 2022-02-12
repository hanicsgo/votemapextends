#include <sourcemod>
#include <colors>

#pragma newdecls required
#pragma semicolon 1

ConVar g_hVoteExtendTime; 										
ConVar g_hMaxVoteExtends; 										

int g_VoteExtends = 0; 											
char g_szSteamID[MAXPLAYERS + 1][32];							
char g_szUsedVoteExtend[MAXPLAYERS+1][32]; 						

public Plugin myinfo = 
{
	name = "Extend Vote Time Map",
	author = "Edited by Hai Tran",
	description = "Add new time for map",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_ve", Command_VoteExtend, "Vote to extend the map");
	RegConsoleCmd("sm_extend", Command_VoteExtend, "Vote to extend the map");
	g_hMaxVoteExtends = CreateConVar("add_max_vote_extends", "1", "The max numbers vote extends", FCVAR_NOTIFY, true, 0.0);
	g_hVoteExtendTime = CreateConVar("add_vote_extend_time", "10.0", "The time in minutes that is added to the remaining map time if a vote extend is successful.", FCVAR_NOTIFY, true, 0.0);
}

public void OnMapStart()
{
	g_VoteExtends = 0;
	
	for (int i = 0; i < MAXPLAYERS+1; i++)
		g_szUsedVoteExtend[i][0] = '\0';
}

public void OnClientPostAdminCheck(int client)
{
	GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], MAX_NAME_LENGTH, true);
}

public Action Command_VoteExtend(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[AEYB] Please wait until the current vote has finished.");
		return Plugin_Handled;
	}

	if (g_VoteExtends >= GetConVarInt(g_hMaxVoteExtends))
	{
		ReplyToCommand(client, "[AEYB] There have been too many extends this map.");
		return Plugin_Handled;
	}

	for (int i = 0; i < g_VoteExtends; i++)
	{
		if (StrEqual(g_szUsedVoteExtend[i], g_szSteamID[client], false))
		{
			ReplyToCommand(client, "[AEYB] You have already used your vote to extend this map.");
			return Plugin_Handled;
		}
	}
	StartVoteExtend(client);
	return Plugin_Handled;
}


public void StartVoteExtend(int client)
{
	char szPlayerName[MAX_NAME_LENGTH];	
	GetClientName(client, szPlayerName, MAX_NAME_LENGTH);
	CPrintToChatAll("[{olive}AEYB{default}] Vote to Extend started by {green}%s{default}", szPlayerName);

	g_szUsedVoteExtend[g_VoteExtends] = g_szSteamID[client];	
	g_VoteExtends++;	

	Menu voteExtend = CreateMenu(H_VoteExtend);
	SetVoteResultCallback(voteExtend, H_VoteExtendCallback);
	char szMenuTitle[128];

	char buffer[8];
	IntToString(RoundToFloor(GetConVarFloat(g_hVoteExtendTime)), buffer, sizeof(buffer));

	Format(szMenuTitle, sizeof(szMenuTitle), "Extend map for %s minutes?", buffer);
	SetMenuTitle(voteExtend, szMenuTitle);
	
	AddMenuItem(voteExtend, "", "Yes");
	AddMenuItem(voteExtend, "", "No");
	SetMenuExitButton(voteExtend, false);
	VoteMenuToAll(voteExtend, 20);
}

public void H_VoteExtendCallback(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	int votesYes = 0;
	int votesNo = 0;

	if (item_info[0][VOTEINFO_ITEM_INDEX] == 0) {	
		votesYes = item_info[0][VOTEINFO_ITEM_VOTES];
		if (num_items > 1) {
			votesNo = item_info[1][VOTEINFO_ITEM_VOTES];
		}
	}
	else {	// If the winner is No
		votesNo = item_info[0][VOTEINFO_ITEM_VOTES];
		if (num_items > 1) {
			votesYes = item_info[1][VOTEINFO_ITEM_VOTES];
		}
	}

	if (votesYes > votesNo) 
	{
		CPrintToChatAll("[{olive}AEYB{default}] Vote to Extend succeeded - Votes Yes: %i | Votes No: %i", votesYes, votesNo);
		ExtendMapTimeLimit(RoundToFloor(GetConVarFloat(g_hVoteExtendTime)*60));
	} 
	else
	{
		CPrintToChatAll("[{olive}AEYB{default}] Vote to Extend failed - Votes Yes: %i | Votes No: %i", votesYes, votesNo);
	}
}

public int H_VoteExtend(Menu tMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		CloseHandle(tMenu);
	}
}

stock bool IsValidClient(int client) 
{ 
    if (client <= 0) 
        return false; 
	
    if (client > MaxClients) 
        return false; 
	
    if ( !IsClientConnected(client) ) 
        return false; 
	
    return IsClientInGame(client); 
} 
