public Action Timer_DisableFreeze(Handle timer, any client)
{
	EnableFreeze(client, false, 0.0);
	
	return Plugin_Handled;
}

public Action PlayRocketSound(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) 
		return;
	
	float Origin[3];
	
	GetClientAbsOrigin(client, Origin);
	
	Origin[2] = Origin[2] + 50;
	
	EmitSoundToAll("weapons/rpg/rocket1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	for (int x=1; x <= 15; x++) 
		CreateTimer(0.2*x, Timer_RocketL, client);
	
	TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
}

public Action EndRocket(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	float Origin[3];
	
	GetClientAbsOrigin(client, Origin);
	
	Origin[2] = Origin[2] + 50;
	
	LoopClients(i)
	{
		StopSound(i, SNDCHAN_AUTO, "weapons/rpg/rocket1.wav");
	}
	
	EmitSoundToAll("weapons/hegrenade/explode3.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	int expl = CreateEntityByName("env_explosion");
	
	TeleportEntity(expl, Origin, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(expl, "fireballsprite", "sprites/zerogxplode.spr");
	DispatchKeyValue(expl, "spawnflags", "0");
	DispatchKeyValue(expl, "iMagnitude", "1000");
	DispatchKeyValue(expl, "iRadiusOverride", "100");
	DispatchKeyValue(expl, "rendermode", "0");
	
	DispatchSpawn(expl);
	ActivateEntity(expl);
	
	AcceptEntityInput(expl, "Explode");
	AcceptEntityInput(expl, "Kill");
	
	EnableGodMode(client, false);
	ForcePlayerSuicide(client);

	return Plugin_Handled;
}

public Action Timer_RocketL(Handle timer, int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
		
	float velocity[3];
	
	velocity[2] = 300.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	
	return Plugin_Handled;
}

public Action Timer_DrugL(Handle timer, any client)
{
	if (!IsClientInGame(client)) 
		return Plugin_Stop;
	
	float DrugAngles[20] = {0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0};

	if (!IsPlayerAlive(client))
	{
		float pos[3];
		float angs[3];
		
		GetClientAbsOrigin(client, pos);
		GetClientEyeAngles(client, angs);
		
		angs[2] = 0.0;
		
		TeleportEntity(client, pos, angs, NULL_VECTOR);	
		
		Handle message = StartMessageOne("Fade", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
		
		if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
		{
			PbSetInt(message, "duration", 1536);
			PbSetInt(message, "hold_time", 1536);
			PbSetInt(message, "flags", (0x0001 | 0x0010));
			PbSetColor(message, "clr", {0, 0, 0, 255});
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
		
		return Plugin_Stop;
	}
	
	float pos[3];
	float angs[3];
	int coloring[4];

	coloring[0] = GetRandomInt(0,255);
	coloring[1] = GetRandomInt(0,255);
	coloring[2] = GetRandomInt(0,255);
	coloring[3] = 128;
	
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, angs);
	
	angs[2] = DrugAngles[GetRandomInt(0,100) % 20];
	
	TeleportEntity(client, pos, angs, NULL_VECTOR);

	Handle message = StartMessageOne("Fade", client);

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) 
	{
		PbSetInt(message, "duration", 255);
		PbSetInt(message, "hold_time", 255);
		PbSetInt(message, "flags", (0x0002));
		PbSetColor(message, "clr", coloring);
	}
	else
	{
		BfWriteShort(message, 255);
		BfWriteShort(message, 255);
		BfWriteShort(message, (0x0002));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, GetRandomInt(0,255));
		BfWriteByte(message, 128);
	}
	
	EndMessage();	
		
	return Plugin_Handled;
}

public Action Timer_CheckKnife(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T && !g_bNoWeaponUse[client])
		{
			int iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			if (iWeapon == INVALID_ENT_REFERENCE)
			{
				int weapon = GivePlayerItem(client, "weapon_knife");
				EquipPlayerWeapon(client, weapon);
			}
		}
	}
}

public Action TimerBeacon(Handle timer, any nClient)
{
	if(IsClientConnected(nClient) && IsClientInGame(nClient) && IsPlayerAlive(nClient))
	{
		// beacon effect...
		float pfEyePosition[3];
		GetClientEyePosition(nClient, pfEyePosition);

#if defined(SOUND_BEACON)
		EmitAmbientSound(SOUND_BEACON, pfEyePosition, SOUND_FROM_WORLD, SNDLEVEL_ROCKET);
#endif

		float pfAbsOrigin[3];
		GetClientAbsOrigin(nClient, pfAbsOrigin);
		pfAbsOrigin[2] += 5.0;

		TE_Start("BeamRingPoint");
		TE_WriteVector("m_vecCenter", pfAbsOrigin);
		TE_WriteFloat("m_flStartRadius", 20.0);
		TE_WriteFloat("m_flEndRadius", 400.0);
		TE_WriteNum("m_nModelIndex", g_iBeamSprite);
		TE_WriteNum("m_nHaloIndex", g_iHaloSprite);
		TE_WriteNum("m_nStartFrame", 0);
		TE_WriteNum("m_nFrameRate", 0);
		TE_WriteFloat("m_fLife", 1.0);
		TE_WriteFloat("m_fWidth", 3.0);
		TE_WriteFloat("m_fEndWidth", 3.0);
		TE_WriteFloat("m_fAmplitude", 0.0);
		TE_WriteNum("r", 128);
		TE_WriteNum("g", 255);
		TE_WriteNum("b", 128);
		TE_WriteNum("a", 192);
		TE_WriteNum("m_nSpeed", 100);
		TE_WriteNum("m_nFlags", 0);
		TE_WriteNum("m_nFadeLength", 0);
		TE_SendToAll();
	}
	else
	{
		KillTimer(timer);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action SlapTimerPlayer(Handle timer, int client)
{
	if (IsClientValid(client))
	{
		if (g_hSlapTimer[client] != null)
		{
			if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
			{
				SlapPlayer(client, 0, true);
				return Plugin_Continue;
			}
		}
	}
	g_hSlapTimer[client] = null;
	return Plugin_Stop;
}

public Action TimerBitchSlap(Handle timer, int client)
{
	if (IsClientValid(client))
	{
		if (g_hBitchSlap[client] != null)
		{
			if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
			{
				SlapPlayer(client, 0, true);
				return Plugin_Continue;
			}
		}
	}
	g_hBitchSlap[client] = null;
	return Plugin_Stop;
}

public Action DMGSlapTimerPlayer(Handle timer, int client)
{
	if (IsClientValid(client))
	{
		if (g_hSlapDMG[client] != null)
		{
			if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
			{
				SlapPlayer(client, 5, true);
				return Plugin_Continue;
			}
		}
	}
	g_hSlapDMG[client] = null;
	return Plugin_Stop;
}

public Action Timer_ChangePlayerColor(Handle timer, int client)
{
	if (IsClientValid(client))
	{
		if (g_hDiscoColor[client] != null)
		{
			int Red = GetRandomInt(0, 255);
			int Green = GetRandomInt(0, 255);
			int Blue = GetRandomInt(0, 255);
			SetEntityRenderMode(client, RENDER_NORMAL);
			SetEntityRenderColor(client, Red, Green, Blue, 255);
			
			return Plugin_Continue;
		}
	}
	
	return Plugin_Stop;
}

public Action RespawnPlayer(Handle timer, int client)
{
	CS_RespawnPlayer(client);
}

public Action Timer_ResetAmmo(Handle timer)
{
	LoopClients(i)
	{
		if (IsPlayerAlive(i) && g_bAmmoInfi[i])
		{
			Client_ResetAmmo(i);
		}
	}
}
