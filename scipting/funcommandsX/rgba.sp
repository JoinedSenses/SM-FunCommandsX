// -------------------------------------------------------------------------------
// Set any of these to 0 and recompile to completely disable those commands
// -------------------------------------------------------------------------------
#define COLORIZE		1
#define INVISIBLE		1
#define DISCO			1


/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
// Basic color arrays for temp entities
int g_iTColors[26][4]         = {{255, 255, 255, 255}, {0, 0, 0, 192}, {255, 0, 0, 192},    {0, 255, 0, 192}, {0, 0, 255, 192}, {255, 255, 0, 192}, {255, 0, 255, 192}, {0, 255, 255, 192}, {255, 128, 0, 192}, {255, 0, 128, 192}, {128, 255, 0, 192}, {0, 255, 128, 192}, {128, 0, 255, 192}, {0, 128, 255, 192}, {192, 192, 192}, {210, 105, 30}, {139, 69, 19}, {75, 0, 130}, {248, 248, 255}, {216, 191, 216}, {240, 248, 255}, {70, 130, 180}, {0, 128, 128},	{255, 215, 0}, {210, 180, 140}, {255, 99, 71}};
char g_sTColors[26][32];

//remembers players color/alpha settings
int g_PlayerColor[MAXPLAYERS+1][4];
//tells recurring rgba functions to skip weapon setting if true
int g_AffectWeapon[MAXPLAYERS+1];

/*****************************************************************


			L I B R A R Y   I N C L U D E S


*****************************************************************/
#if COLORIZE
#include "funcommandsX/rgba/colorize.sp"
#endif
#if INVISIBLE
#include "funcommandsX/rgba/invisible.sp"
#endif
#if DISCO
#include "funcommandsX/rgba/disco.sp"
#endif

/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public void SetupRGBA() {
	Format(g_sTColors[0], sizeof(g_sTColors[]), "%t", "color_normal");
	Format(g_sTColors[1], sizeof(g_sTColors[]), "%t", "color_black");
	Format(g_sTColors[2], sizeof(g_sTColors[]), "%t", "color_red");
	Format(g_sTColors[3], sizeof(g_sTColors[]), "%t", "color_green");
	Format(g_sTColors[4], sizeof(g_sTColors[]), "%t", "color_blue");
	Format(g_sTColors[5], sizeof(g_sTColors[]), "%t", "color_yellow");
	Format(g_sTColors[6], sizeof(g_sTColors[]), "%t", "color_purple");
	Format(g_sTColors[7], sizeof(g_sTColors[]), "%t", "color_cyan");
	Format(g_sTColors[8], sizeof(g_sTColors[]), "%t", "color_orange");
	Format(g_sTColors[9], sizeof(g_sTColors[]), "%t", "color_pink");
	Format(g_sTColors[10], sizeof(g_sTColors[]), "%t", "color_olive");
	Format(g_sTColors[11], sizeof(g_sTColors[]), "%t", "color_lime");
	Format(g_sTColors[12], sizeof(g_sTColors[]), "%t", "color_violet");
	Format(g_sTColors[13], sizeof(g_sTColors[]), "%t", "color_lightblue");
	Format(g_sTColors[14], sizeof(g_sTColors[]), "%t", "color_silver");
	Format(g_sTColors[15], sizeof(g_sTColors[]), "%t", "color_chocolate");
	Format(g_sTColors[16], sizeof(g_sTColors[]), "%t", "color_saddlebrown");
	Format(g_sTColors[17], sizeof(g_sTColors[]), "%t", "color_indigo");
	Format(g_sTColors[18], sizeof(g_sTColors[]), "%t", "color_ghostwhite");
	Format(g_sTColors[19], sizeof(g_sTColors[]), "%t", "color_thistle");
	Format(g_sTColors[20], sizeof(g_sTColors[]), "%t", "color_aliceblue");
	Format(g_sTColors[21], sizeof(g_sTColors[]), "%t", "color_steelblue");
	Format(g_sTColors[22], sizeof(g_sTColors[]), "%t", "color_teal");
	Format(g_sTColors[23], sizeof(g_sTColors[]), "%t", "color_gold");
	Format(g_sTColors[24], sizeof(g_sTColors[]), "%t", "color_tan");
	Format(g_sTColors[25], sizeof(g_sTColors[]), "%t", "color_tomato");

	//set all player colors to normal
	for (int i = 0; i < sizeof(g_PlayerColor); i++) {
		ResetClientColor(i);
	}

	//hook change loadout for TF2
	if (g_GameType == GAME_TF2) {
		HookEvent("post_inventory_application", hook_InventoryApplication, EventHookMode_Post);
	}
	//HookEvent("player_spawn", hook, EventHookMode_Post);

	#if COLORIZE
	// sm_colorize, sm_colorize_colors
	SetupColorize();
	#endif
	#if INVISIBLE
	// sm_invis, sm_alpha
	SetupInvisible();
	#endif
	#if DISCO
	// sm_disco
	SetupDisco();
	#endif
}

public void OnPluginEnd_RGBA() {
	//reset all invis/colorize if applicable
	for (int i = 1 ; i < GetMaxClients(); i++) {
		if (IsClientConnected(i) && IsClientInGame(i)) {
			#if COLORIZE
			DoRGBA(i, RENDER_NORMAL);
			#endif
			#if INVISIBLE
			DoRGBA(i, RENDER_TRANSCOLOR);
			#endif
		}

		ResetClientColor(i);

		#if DISCO
		KillDisco();
		#endif
	}
}

public void OnMapStart_RGBA() {
	#if DISCO
	OnMapStart_Disco();
	#endif
}

public void OnMapEnd_RGBA() {
	#if DISCO
	OnMapEnd_Disco();
	#endif

	//reset all players color/alpha
	for (int i = 0; i < sizeof(g_PlayerColor); i++) {
		ResetClientColor(i);
	}
}

public bool OnClientConnect_RGBA(int client, char[] rejectmsg, int maxlen) {
	//reset players default color/alpha
	ResetClientColor(client);

	#if INVISIBLE
	OnClientConnect_Invisible(client, rejectmsg, maxlen);
	#endif

	return true;
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
public Action hook_InventoryApplication(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	SetWearablesRGBA(client, RENDER_NORMAL);
	SetWeaponsRGBA(client, RENDER_NORMAL);

	#if INVISIBLE
	SetWearablesRGBA(client, RENDER_TRANSCOLOR);
	SetWeaponsRGBA(client, RENDER_TRANSCOLOR);
	#endif

	return Plugin_Continue;
}



/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
void ResetClientColor(int client) {
	g_PlayerColor[client][0] = 255;
	g_PlayerColor[client][1] = 255;
	g_PlayerColor[client][2] = 255;
	g_PlayerColor[client][3] = 255;

	g_AffectWeapon[client] = true;
}

void SetColor(int target, int c) {
	g_PlayerColor[target] = g_iTColors[c];
}

void DoRGBA(int client, RenderMode mode, bool weapon = true) {
	if (weapon) {
		SetWeaponsRGBA(client, mode);
	}
	SetWearablesRGBA(client, mode);
	SetEntityRenderMode(client, mode);
	SetEntityRenderColor(client, g_PlayerColor[client][0], g_PlayerColor[client][1], g_PlayerColor[client][2], g_PlayerColor[client][3]);

	#if INVISIBLE
	if (mode == RENDER_NORMAL) {
		DoRGBA(client, RENDER_TRANSCOLOR);
	}
	#endif
}


void SetWeaponsRGBA(int client, RenderMode mode) {
	if (!g_AffectWeapon[client]) {
		return;
	}

	int m_hMyWeapons = FindSendPropInfo(g_PlayerProperty, "m_hMyWeapons");

	//GetEntDataEnt2 will error if m_hMyWeapons is -1
	if (m_hMyWeapons == -1) {
		return;
	}

	for (int i = 0, weapon; i < 47; i += 4) {
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);

		if (weapon > 0 && IsValidEdict(weapon)) {
			char classname[64];
			if (GetEdictClassname(weapon, classname, sizeof(classname)) && StrContains(classname, "weapon") != -1) {
				SetEntityRenderMode(weapon, mode);
				SetEntityRenderColor(weapon, g_PlayerColor[client][0], g_PlayerColor[client][1], g_PlayerColor[client][2], g_PlayerColor[client][3]);
			}
		}
	}
}

void SetWearablesRGBA(int client, RenderMode mode) {
	//only set wearable items for Team Fortress 2
	if (g_GameType == GAME_TF2) {
		SetWearablesRGBA_Impl(client, mode, "tf_wearable", "CTFWearable");
		SetWearablesRGBA_Impl(client, mode, "tf_wearable_demoshield", "CTFWearableDemoShield");
	}
}

void SetWearablesRGBA_Impl(int client, RenderMode mode, const char[] entClass, const char[] serverClass) {
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, entClass)) != -1) {
		if (IsValidEntity(ent)) {
			if (GetEntDataEnt2(ent, FindSendPropInfo(serverClass, "m_hOwnerEntity")) == client) {
				SetEntityRenderMode(ent, mode);
				SetEntityRenderColor(ent, g_PlayerColor[client][0], g_PlayerColor[client][1], g_PlayerColor[client][2], g_PlayerColor[client][3]);
			}
		}
	}
}

/*****************************************************************


			A D M I N   M E N U   F U N C T I O N S


*****************************************************************/
void Setup_AdminMenu_RGBA_Player(TopMenuObject parentmenu) {
	#if COLORIZE
	Setup_AdminMenu_Colorize_Player(parentmenu);
	#endif
	#if INVISIBLE
	Setup_AdminMenu_Invis_Player(parentmenu);
	#endif
}

void Setup_AdminMenu_RGBA_Server(TopMenuObject parentmenu) {
	#if DISCO
	Setup_AdminMenu_Disco_Server(parentmenu);
	#endif
}