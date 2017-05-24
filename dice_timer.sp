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
