stock void SendDicePanel(int number, int client, const char[] title, const char[] text)
{
	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%s - Option: %d", TITLE, number);
	Panel panel = new Panel();
	panel.SetTitle(sTitle);
	panel.DrawText(text);
	panel.Send(client, PanelHandler, 10);
	panel.Close();
}

void EnableFreeze(int client, bool turnOn, float time)
{	
	if (IsClientInGame(client))
	{
		if (turnOn)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			
			if (time > 0) 
				CreateTimer(time, Timer_DisableFreeze, client);
		}
		else
			SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

void EnableBurn(int client, int health)
{
	float time = float(health) / 5.0;
	
	if (health < 100) 
		IgniteEntity(client, time);
	else 
		IgniteEntity(client, 100.0);
}

void EnableRocket(int client)
{
	float Origin[3];
	
	GetClientAbsOrigin(client, Origin);
	
	Origin[2] = Origin[2] + 20;
	
	EnableGodMode(client, true);
	EnableShake(client, 10, 40, 25);
	
	EmitSoundToAll("weapons/rpg/rocketfire1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	CreateTimer(1.0, PlayRocketSound, client);
	CreateTimer(3.1, EndRocket, client);
}

void EnableGodMode(int client, bool turnOn)
{
	if (turnOn) 
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	else
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

void EnableShake(int client, int time, int distance, int value)
{
	Handle message = StartMessageOne("Shake", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(message, "command", 0);
		PbSetFloat(message, "local_amplitude", float(value));
		PbSetFloat(message, "frequency", float(distance));
		PbSetFloat(message, "duration", float(time));
	}
	else
	{
		BfWriteByte(message, 0);
		BfWriteFloat(message, float(value));
		BfWriteFloat(message, float(distance));
		BfWriteFloat(message, float(time));
	}
	
	EndMessage();	
}

bool IsClientValid(int client)
{
	if (client > 0 && client <= MaxClients)
		if (IsClientInGame(client))
			return true;
	return false;
}

void EnableDrug(int client)
{
	g_hDrugTimer[client] = CreateTimer(1.0, Timer_DrugL, client, TIMER_REPEAT);	
}

void SetGlow(int client, RenderFx fx = RENDERFX_NONE, int r = 255, int g = 255, int b = 255, RenderMode render = RENDER_NORMAL, int nAmount = 255)
{
	SetEntProp(client, Prop_Send, "m_nRenderFX", fx, 1);
	SetEntProp(client, Prop_Send, "m_nRenderMode", render, 1);

	int nOffsetClrRender = GetEntSendPropOffs(client, "m_clrRender");
	SetEntData(client, nOffsetClrRender, r, 1, true);
	SetEntData(client, nOffsetClrRender + 1, g, 1, true);
	SetEntData(client, nOffsetClrRender + 2, b, 1, true);
	SetEntData(client, nOffsetClrRender + 3, nAmount, 1, true);
}

void ClearTimer(Handle & rHandle, bool bKill)
{
	if(rHandle != null)
	{
		if(!bKill)
			CloseHandle(rHandle);
		else
			KillTimer(rHandle);
		rHandle = null;
	}
}

stock void Weapon_SetAmmo(int iWeapon, int iAmmo)
{
	SetEntProp(iWeapon, Prop_Data, "m_iClip1", iAmmo);
}

stock void Weapon_SetReserveAmmo(int iWeapon, int iReserveAmmo)
{
	SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iReserveAmmo);
}

void Client_ResetAmmo(int client)
{
	if(IsClientValid(client))
	{
		int zomg = GetEntDataEnt2(client, g_iActiveWeapon);
		if (g_iClip1 != -1)
			SetEntData(zomg, g_iClip1, 200, 4, true);
		if (g_iClip2 != -1)
			SetEntData(zomg, g_iClip2, 200, 4, true);
		if (g_iPrimaryAmmo != -1)
			SetEntData(zomg, g_iPrimaryAmmo, 200, 4, true);
		if (g_iSecondaryAmmo != -1)
			SetEntData(zomg, g_iSecondaryAmmo, 200, 4, true);
	}
}

void ResetClientDice(int client)
{
	g_bDice[client] = false;
	g_bLastT[client] = false;
	g_bHE[client] = false;
	g_bDoubleDamage[client] = false;
	g_bDoubleDamageE[client] = false;
	g_bNoHSDMG[client] = false;
	g_bHalfDMG[client] = false;
	g_bHalfSelfDMG[client] = false;
	g_bNoWeaponUse[client] = false;
	g_bZombie[client] = false;
	g_bNoDamage[client] = false;
	g_bNoSelfHS[client] = false;
	g_iCustomOption[client] = -1;
	g_bCustomModel[client] = false;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntityGravity(client, 1.0);
		SetGlow(client, RENDERFX_NONE, 255, 255, 255, RENDER_NORMAL, 255);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
	}
	g_iNoclipCounter[client] = 5;
	g_bRespawn[client] = false;
	g_bBusy[client] = false;
	ResetClientDice2(client);
	g_bNightvision[client] = false;
	g_bGodmode[client] = false;
	g_bAmmoInfi[client] = false;
	g_bAuto[client] = false;
	
	if (g_hDrugTimer[client] != null)
		ClearTimer(g_hDrugTimer[client], true);
	
	if (g_hBeaconTimer[client] != null)
		ClearTimer(g_hBeaconTimer[client], true);
	
	if (g_hDiscoColor[client] != null)
		ClearTimer(g_hDiscoColor[client], true);
	
	if (g_hBitchSlap[client] != null)
		ClearTimer(g_hBitchSlap[client], true);

	g_hDiceTimer[client] = null;

	if (g_hSlapDMG[client] != null)
		ClearTimer(g_hSlapDMG[client], true);
	
	if (g_hSlapTimer[client] != null)
		ClearTimer(g_hSlapTimer[client], true);
}

void ResetClientDice2(int client)
{
	if (!IsClientInGame(client)) 
		return;
	
	float pos[3];
	float angs[3];
	
	EnableFreeze(client, false, 0.0);
	EnableGodMode(client, false);

	ExtinguishEntity(client);
	ClientCommand(client, "r_screenoverlay 0");
	
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, angs);

	SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
	
	angs[2] = 0.0;
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);	
	
	Handle message = StartMessageOne("Fade", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
			
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(message, "duration", 1536);
		PbSetInt(message, "hold_time", 1536);
		PbSetInt(message, "flags", (0x0001 | 0x0010));
		PbSetColor(message, "clr", {0, 0, 0, 0});
	}
	else
	{
		BfWriteShort(message, 1536);
		BfWriteShort(message, 1536);
		BfWriteShort(message, (0x0001 | 0x0010));
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
	}

	EndMessage();
	
	message = StartMessageOne("Shake", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(message, "command", 1);
		PbSetFloat(message, "local_amplitude", 0.0);
		PbSetFloat(message, "frequency", 0.0);
		PbSetFloat(message, "duration", 1.0);
	}
	else
	{
		BfWriteByte(message, 1);
		BfWriteFloat(message, 0.0);
		BfWriteFloat(message, 0.0);
		BfWriteFloat(message, 1.0);
	}
	
	EndMessage();
	g_iCustomOption[client] = -1;
}
