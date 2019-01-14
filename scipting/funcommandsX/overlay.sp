//Overlay: by Arg!

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public void SetupOverlay() {
	RegAdminCmd("sm_overlay", Command_Overlay, ADMFLAG_SLAY, "sm_overlay <#userid|name> [material] - Toggles or forces a material to be displayed on targets screen overlay");
}


/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action Command_Overlay(int client, int args) {
	char target[32];
	char material[129];
	char target_name[MAX_NAME_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	bool disable = false;

	//validate args
	if (args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_overlay <#userid|name> [material]");
		return Plugin_Handled;
	}

	//get arguments
	GetCmdArg(1, target, sizeof(target));

	if (args > 1) {
		GetCmdArg(2, material, sizeof(material));
		if (strlen(material) == 0) {
			disable = true;
		}
	}

	//get target(s)
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	SetOverlaySet(true);

	for (int i = 0; i < target_count; i++) {
		PerformOverlay(client, target_list[i], material, disable);
	}

	SetOverlaySet(false);

	ShowActivity2(client, "[SM] ", "%t", "was overlayed",  target_name, material);

	return Plugin_Handled;

}



/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
void SetOverlaySet(bool enable) {
	if (enable) {
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	}
	else {
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
	}
}

void PerformOverlay(int client, int target, char material[129], bool disable) {
	if (disable) {
		ClientCommand(target, "r_screenoverlay \"\"");
		LogAction(client, target, "\"%L\" removed \"%L\"'s overlay", client, target);
	}
	else {
		ClientCommand(target, "r_screenoverlay \"%s\"", material);
		LogAction(client, target, "\"%L\" set \"%L\"'s overlay to material \"%s\"", client, target, material);
	}
}