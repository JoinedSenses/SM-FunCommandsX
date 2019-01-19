//Teleport: by Spazman0

/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
float ZeroVector[3];

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public void SetupTeleport() {
	RegAdminCmd("sm_sendaim", cmdSendAim, ADMFLAG_SLAY, "sm_sendaim <#userid|name> - Teleports player to where admin is looking");
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action cmdSendAim(int client, int args) {
	if (!args) {
		return Plugin_Handled;
	}

	char target[32];
	GetCmdArg(1, target, sizeof(target));

	
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	float vOrigin[3];
	if (!SetTeleportEndPoint(client, vOrigin)) {
		PrintToChat(client, "Unable to teleport client to location");
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++) {
		TeleportEntity(target_list[i], vOrigin, NULL_VECTOR, ZeroVector);
	}

	return Plugin_Handled;
}

bool SetTeleportEndPoint(int client, float vOrigin[3]) {
	float vStart[3];
	float vAngles[3];
	float vPos[3];

	GetClientEyePosition(client, vStart);
	GetClientEyeAngles(client, vAngles);
	GetClientAbsOrigin(client, vPos);
	vPos[2] += 5.0;

	TR_TraceRayFilter(vStart, vAngles, MASK_ALL, RayType_Infinite, TeleportTraceFilter, client);

	bool result;
	if (TR_DidHit()) {
		TR_GetEndPosition(vOrigin);

		float vForward[3];
		float vUp[3];

		MakeVectorFromPoints(vStart, vOrigin, vPos);
		GetVectorAngles(vPos, vAngles);

		GetAngleVectors(vAngles, vForward, NULL_VECTOR, vUp);
		NegateVector(vForward);
		NegateVector(vUp);
		ScaleVector(vForward, 40.0);
		ScaleVector(vUp, 15.0);

		int count;
		while (!(result = FindValidTeleportDestination(client, vOrigin, vOrigin)) && count++ < 15) {
			AddVectors(vOrigin, vForward, vOrigin);
			AddVectors(vOrigin, vUp, vOrigin);
			ScaleVector(vForward, 0.8);
			ScaleVector(vUp, 0.7);
		}
	}

	return result;
}

public Action DeleteParticles(Handle timer, any particle) {
    if (IsValidEntity(particle)) {
        char classname[32];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false)) {
            RemoveEdict(particle);
        }
    }
}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
// Thanks to nosoop for this function
bool FindValidTeleportDestination(int client, const float vecPosition[3], float vecDestination[3]) {
	float vecMins[3], vecMaxs[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", vecMaxs);

	if (GetClientButtons(client) & IN_DUCK) {
		vecMaxs[2] += 20;
	}
	
	TR_TraceHullFilter(vecPosition, vecPosition, vecMins, vecMaxs, MASK_PLAYERSOLID, TeleportTraceFilter, client);
	
	bool valid = !TR_DidHit();
	
	if (valid) {
		vecDestination = vecPosition;
		return true;
	}
	
	// Basic unstuck handling.
	/** 
	 * Basically we treat the corners and center edges of the player's bounding box as potential
	 * teleport destination candidates.
	 */
	float vecTestPosition[3];
	for (int z = 0; z < 2; z++) {
		float zpos;
		switch (z) {
			case 0: {
				zpos = 10.0;
			}
			case 1: {
				// less likely to hit the ceiling so do that second
				zpos = -vecMaxs[2];
			}
		}
		
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				float vecOffset[3];
				vecOffset[2] = zpos;
				
				switch (x) {
					case -1: {
						vecOffset[0] = vecMins[0];
					}
					case 1: {
						vecOffset[0] = vecMaxs[0];
					}
				}
				switch (y) {
					case -1: {
						vecOffset[1] = vecMins[1];
					}
					case 1: {
						vecOffset[1] = vecMaxs[1];
					}
				}
				
				AddVectors(vecPosition, vecOffset, vecTestPosition);
				
				TR_TraceHullFilter(vecTestPosition, vecTestPosition, vecMins, vecMaxs, MASK_PLAYERSOLID, TeleportTraceFilter, client);
				
				valid = !TR_DidHit();
				
				if (valid) {
					vecDestination = vecTestPosition;
					return true;
				}
			}
		}
	}
	return false;
}

public bool TeleportTraceFilter(int entity, int contentsMask, int client) {
	return entity != client;
}

void TeleportEffects(float pos[3]) {
	if (g_GameType == GAME_TF2) {
		ShowParticle(pos, "pyro_blast", 1.0);
		ShowParticle(pos, "pyro_blast_lines", 1.0);
		ShowParticle(pos, "pyro_blast_warp", 1.0);
		ShowParticle(pos, "pyro_blast_flash", 1.0);
		ShowParticle(pos, "burninggibs", 0.5);
	}
}

void ShowParticle(float possie[3], char[] particlename, float time) {
    int particle = CreateEntityByName("info_particle_system");
    if (IsValidEdict(particle)) {
        TeleportEntity(particle, possie, NULL_VECTOR, NULL_VECTOR);
        DispatchKeyValue(particle, "effect_name", particlename);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "start");
        CreateTimer(time, DeleteParticles, particle);
    }
    else {
        LogError("ShowParticle: could not create info_particle_system");
    }
}

void PerformTeleport(int client, int target, float pos[3]) {
	float partpos[3];

	GetClientEyePosition(target, partpos);
	partpos[2]-=20.0;

	TeleportEffects(partpos);

	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
	pos[2]+=40.0;

	TeleportEffects(pos);

	LogAction(client, target, "\"%L\" teleported \"%L\"" , client, target);
}

/*****************************************************************


			A D M I N   M E N U   F U N C T I O N S


*****************************************************************/
void Setup_AdminMenu_Teleport_Player(TopMenuObject parentmenu) {
	AddToTopMenu(hTopMenu, "sm_tele", TopMenuObject_Item, AdminMenu_Tele, parentmenu, "sm_tele", ADMFLAG_SLAY);
}


public int AdminMenu_Tele(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "%T", "Teleport player", param);
	}
	else if (action == TopMenuAction_SelectOption) {
		DisplayTeleMenu(param);
	}
}

void DisplayTeleMenu(int client) {
	Menu menu = new Menu(MenuHandler_Tele);

	char title[100];
	Format(title, sizeof(title), "%T:", "Teleport player", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	AddTargetsToMenu(menu, client, true, false);

	menu.Display(client, MENU_TIME_FOREVER);
}


public int MenuHandler_Tele(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_End) {
		delete menu;
	}
	else if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack && hTopMenu != null) {
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select) {
		char info[32];
		int userid;
		int target;


		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0) {
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target)) {
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else {
			char name[32];
			GetClientName(target, name, sizeof(name));
			float vOrigin[3];
			if (SetTeleportEndPoint(param1, vOrigin) && IsClientInGame(target) && IsPlayerAlive(target)) {
				PerformTeleport(param1, target, vOrigin);
				ShowActivity2(param1, "[SM] ", "%t", "was Teleported",  name);
			}
			else {
				PrintToChat(param1, "Unable to perform teleport");
			}
		}

		/* Re-draw the menu if they're still valid */
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1)) {
			DisplayTeleMenu(param1);
		}
	}
}