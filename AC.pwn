/////////////////////////////////////////////////////////////
//AntyCheat stworzony przez Dawidoskyy                     //
//Kontakt Discord - Dawidoskyy#0329                        //
//Podziekowania dla Deduction, Luk_Ass, Kuddy, Gnik        //
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
//            Co posiada antycheat?                        //
//            -Anty Weapon hack                            //
//            -Anty Armour Hack                            //
//            -Anty High Ping                              //
//            -Anty FakeKill                               //
//            -Anty Jetpack                                //
//            -Anty Bot/Raksamp                            //
//            -Anty GodMode                                //
//            -Anty AirBreak                               //
//            -Anty Sobeit                                 //
//            -Anty FakeBullet                             //
//            -Anty RapidFire                              //
//            -Anty NoReload                               //
//            -Limit ip                                    //
//            -Anty MoneyHack                              //
//            -Anty CarSpamer                              //
//            -Anty Anty Proxy/VPN                         //
//            -Anty SpeedHack                              //
//            -Anty Spam                                   //
//            -Anty CarWarp                                //
//            -Anty CarTuning                              //
//            -Console informer                            //
//            -Admin Warning + informer                    //
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////
//                       Konfiguracja                         //
// Najlepiej jest przepisa� wszystko do gamemode, a nawet   //
// jest to wymagane. Teraz napisze jak dodawac graczowi       //
// kase oraz bron aby nie wyrzucilo go za ac                  //
// - Ka�de GivePlayerWeapon zamie� na ServerWeapon        //
// - Ka�de GivePlayerMoney zamie� na GivePlayerCash       //
// - Ka�de SetPlayerMoney zamie� na SetPlayerCash         //
// - Ka�de SetPlayerArmour ustaw na max 99                  //
////////////////////////////////////////////////////////////////


#include <a_samp>
#include <zcmd>
#include <sscanf2>
#include <a_http>
#include <foreach>

#define ORANGE2     0xFF990080
#define RED 0xFF0000FF
#define COLOR_AC     0xFF990080
#define COLOR_WARNING 0xFF4500AA


#define ResetMoneyBar ResetPlayerMoney
#define UpdateMoneyBar GivePlayerMoney

#define MAX_IP 3 


enum weapons
{
    Melee,
    Thrown,
    Pistols,
    Shotguns,
    SubMachine,
    Assault,
    Rifles,
    Heavy,
    Handheld,

}
new Weapons[MAX_PLAYERS][weapons];
new DamageTaken[MAX_PLAYERS];
new Float:xo[MAX_PLAYERS],Float:yo[MAX_PLAYERS],Float:zo[MAX_PLAYERS];
new timerantiairbrk[MAX_PLAYERS];

new isAc[MAX_PLAYER_NAME] = 0;

new String[512];

new playerEnteringVehicle[MAX_PLAYERS];

new spamming[MAX_PLAYERS][2];
new tick;
new kickplayer[MAX_PLAYERS];

new Cash[MAX_PLAYERS];

new NoReloading[MAX_PLAYERS];
new CurrentWeapon[MAX_PLAYERS];
new CurrentAmmo[MAX_PLAYERS];

new FloodControl[MAX_PLAYERS],
    gb_as@con[MAX_PLAYERS] = {true, ...},
    gi_as@non[MAX_PLAYERS],
    gi_as@car[MAX_PLAYERS];


stock Name(playerid)
{
    new nname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, nname, sizeof(nname));
    return nname;
}

stock PutPlayerInVehicleEx(playerid, vehicleid, seatid)
{
    if(vehicleid != INVALID_VEHICLE_ID && seatid != 128)
    {
        playerEnteringVehicle[playerid] = vehicleid;
    }
    
    PutPlayerInVehicle(playerid, vehicleid, seatid);
    
    return 1;
}

stock GetVehicleSpeed(vehicleid)
{
    new Float:xPos[3];
    GetVehicleVelocity(vehicleid, xPos[0], xPos[1], xPos[2]);
    return floatround(floatsqroot(xPos[0] * xPos[0] + xPos[1] * xPos[1] + xPos[2] * xPos[2]) * 170.00);
}

stock GivePlayerCash(playerid, money)
{
    Cash[playerid] += money;
    ResetMoneyBar(playerid);
    UpdateMoneyBar(playerid,Cash[playerid]);
    return Cash[playerid];
}
stock SetPlayerCash(playerid, money)
{
    Cash[playerid] = money;
    ResetMoneyBar(playerid);
    UpdateMoneyBar(playerid,Cash[playerid]);
    return Cash[playerid];
}
stock ResetPlayerCash(playerid)
{
    Cash[playerid] = 0;
    ResetMoneyBar(playerid);
    UpdateMoneyBar(playerid,Cash[playerid]);
    return Cash[playerid];
}
stock GetPlayerCash(playerid)
{
    return Cash[playerid];
}

stock IsWeaponWithAmmo(weaponid)
{
    switch(weaponid)
    {
        case 16..18, 22..39, 41..42: return 1;
        default: return 0;
    }
    return 0;

}

stock GetPlayerWeaponAmmo(playerid,weaponid)
{
    new wd[2][13];
    for(new i; i<13; i++) GetPlayerWeaponData(playerid,i,wd[0][i],wd[1][i]);
    for(new i; i<13; i++)
    {
        if(weaponid == wd[0][i]) return wd[1][i];
    }
    return 0;
}

stock IsPlayerSurfingOnVehicle(playerid)
{
	if(GetPlayerSurfingVehicleID(playerid) != INVALID_VEHICLE_ID)
	return true;
	return false;
}

stock IsPlayerInAirPlane(playerid)
{
	new playerveh = GetPlayerVehicleID(playerid);
	switch(GetVehicleModel(playerveh))
	{
		case
			460,464,476,511,512,513,519,520,553,577,592,593,//flying vehicle models
			417,425,447,465,469,487,488,497,501,548,563:
			return true;
	}
	return false;
}

stock Float:GetPlayerMoveCount(Float:oldd,Float:neww)
{
	new Float:ret;
	if(oldd < neww)
	{
		ret = neww - oldd;
	}
	else if(neww > oldd)
	{
	    ret = oldd - neww;
	}
	else if(neww == oldd)
	{
	    ret = 0;
	}
	return ret;
}

forward ban(playerid);
public ban(playerid)
{
    Ban(playerid);
	return 1;
}

forward MyHttpResponse(playerid, response_code, data[]);
forward OnPlayerSpeedHack(playerid);

forward IsAc(playerid);
public IsAc(playerid)
{
	isAc[playerid] = false;
	return 1;
}


public OnVehicleMod(playerid,vehicleid,componentid)
{
    if(GetPlayerInterior(playerid) == 0)
    {
        SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu tuning hacka");
	    GameTextForPlayer(playerid, "~g~ban", 8000, 4);
        kickplayer[playerid] = SetTimerEx("ban", 50, 0, "dd", playerid, 1);
        printf("[AC] %s Zostal zbanowany za tuning hacka.", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
        {
            if (IsPlayerConnected(i))
            {
                if(IsPlayerAdmin(playerid))
                {
			        format(String, sizeof(String),"[AC]: %s zostal zbanowany za tuning hacka",PlayerName(playerid));
                    SendClientMessage(i, COLOR_AC, String);
                }
            }
        }
    }
    return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
    isAc[playerid] = true;
	SetTimerEx("IsAc", 3000, false, "i", playerid);
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 1;
}
 
public OnPlayerLeaveCheckpoint(playerid)
{
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 1;
}
 
public OnPlayerEnterRaceCheckpoint(playerid)
{
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 1;
}
 
public OnPlayerLeaveRaceCheckpoint(playerid)
{
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 0;
}

forward antiairbrk(playerid);
public antiairbrk(playerid)
{
    new Float:xt,Float:yt,Float:zt;
    GetPlayerPos(playerid,xt,yt,zt);
	GetPlayerPos(playerid,xo[playerid],yo[playerid],zo[playerid]);
	if(IsPlayerInAnyVehicle(playerid)) return 0;
	if(isAc[playerid] == 1) return 0;
    if(!IsPlayerInAirPlane(playerid))
    {
        if(!IsPlayerSurfingOnVehicle(playerid))
        {
        if(xo[playerid] != 0.0 || yo[playerid] != 0.0 || zo[playerid] != 0.0)
        {
            new Float:xs,Float:ys,Float:zs;
            xs = GetPlayerMoveCount(xo[playerid],xt);
            ys = GetPlayerMoveCount(yo[playerid],yt);
            zs = GetPlayerMoveCount(zo[playerid],zt);
            if(xs >= 16.5 || ys >= 16.5 || zs >= 16.5)
            {
                if(xs <= 50.0)
                {
                    SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony z podejrzeniem AirBreak");
			        GameTextForPlayer(playerid, "~g~kick", 8000, 4);
                    kickplayer[playerid] = SetTimerEx("ban", 50, 0, "dd", playerid, 1);
                    printf("[AC] %s Zostal wyrzucony z podejrzeniem AirBreak.", PlayerName(playerid));
                }
            }
        }
        }
    }
    return 1;
}

public OnPlayerText(playerid, text[])
{
    new count = GetTickCount2();
    if (count-spamming[playerid][1] < 1000) {
        spamming[playerid][0] ++;
        if (spamming[playerid][0] == 3) {
            SendClientMessage(playerid, -1, "[AC]: Zostales ostrzezony za spam!!!.");
        }
        if (spamming[playerid][0] == 5) {
            spamming[playerid][0] = 0;
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony z powodu spamu");
			GameTextForPlayer(playerid, "~g~kick", 8000, 4);
            kickplayer[playerid] = SetTimerEx("kick", 50, 0, "dd", playerid, 1);
            printf("[AC] %s Zostal wyrzucony za spam.", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
        {
            if (IsPlayerConnected(i))
            {
                if(IsPlayerAdmin(playerid))
                {
			        format(String, sizeof(String),"[AC]: %s zostal wyrzucony za spam",PlayerName(playerid));
                    SendClientMessage(i, COLOR_AC, String);
                }
            }
        }
            return 0;
        }
    }
    else
    {
        spamming[playerid][0] = 1;
    }
    spamming[playerid][1] = count;
    return 1;
}

forward DamageTimer(playerid);
public DamageTimer(playerid)
{
    DamageTaken[playerid] = 0;
    return 1;
}


forward kick(playerid);
public kick(playerid)
{
    Kick(playerid);
	return 1;
}

forward pingchecktimer(playerid);
public pingchecktimer(playerid)
{
    if(GetPlayerPing(playerid) > 500)
	{
	    SetTimerEx("kick", 500, false, "i", playerid);
		SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony z powodu wysokiego pingu");
		GameTextForPlayer(playerid, "~g~kick", 8000, 4);
		printf("[AC] %s Zostal wyrzucony z powodu wysokiego pingu.", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
        {
            if (IsPlayerConnected(i))
            {
                if(IsPlayerAdmin(playerid))
                {
			        format(String, sizeof(String),"[AC]: %s zostal wyrzucony z powodu wysokiego pingu",PlayerName(playerid));
                    SendClientMessage(i, COLOR_AC, String);
                }
            }
        }
	}
    return 1;
}

forward MoneyTimer();
public MoneyTimer()
{
    new username[MAX_PLAYER_NAME];
    for(new i=0; i<MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            if(GetPlayerCash(i) != GetPlayerMoney(i))
            {
                ResetMoneyBar(i);
                UpdateMoneyBar(i,GetPlayerCash(i));
                new hack = GetPlayerMoney(i) - GetPlayerCash(i);
                GetPlayerName(i,username,sizeof(username));
                printf("%s has picked up/attempted to spawn $%d.", username,hack);
            }
        }
    }
}

public OnFilterScriptInit()
{
	print("[AC]: //////////////////////////////.");
    print("[AC]: //  Poprawnie zaladowano AC //.");
    print("[AC]: //     Autor Dawidoskyy     //.");
	print("[AC]: //     AC version: 0.4      //.");
    print("[AC]: //////////////////////////////.");
	SetTimer("MoneyTimer", 1000, 1);
	
	for(new i; i < MAX_PLAYERS; i ++)
    {
        if(!IsPlayerConnected(i)) continue;
        else SetTimerEx("decon", 3000, false, "d", i);
    }
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    if(IsWeaponWithAmmo(weaponid) && weaponid != 38)
    {
        
        new count = 0;
        if(weaponid != CurrentWeapon[playerid]) CurrentWeapon[playerid] = weaponid, CurrentAmmo[playerid] = GetPlayerWeaponAmmo(playerid,weaponid), count++;
        if(GetPlayerWeaponAmmo(playerid,weaponid) > CurrentAmmo[playerid] || GetPlayerWeaponAmmo(playerid,weaponid) < CurrentAmmo[playerid])
        {
            
            CurrentAmmo[playerid] = GetPlayerWeaponAmmo(playerid,weaponid);
            NoReloading[playerid] = 0;
            count++;
        }
        if(GetPlayerWeaponAmmo(playerid,weaponid) != 0 && GetPlayerWeaponAmmo(playerid,weaponid) == CurrentAmmo[playerid] && count == 0)
        {
            
            NoReloading[playerid]++;
            if(NoReloading[playerid] >= 5)
            {
                
                NoReloading[playerid] = 0;
                CurrentWeapon[playerid] = 0;
                CurrentAmmo[playerid] = 0;
                SetTimerEx("kick", 500, false, "i", playerid);
		        SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony z podejrzeniem RapidFire/NoReload");
				GameTextForPlayer(playerid, "~g~kick", 8000, 4);
		        printf("[AC] %s Zostal wyrzucony z podejrzeniem RapidFire/NoReload.", PlayerName(playerid));
				for (new i=0;i<MAX_PLAYERS;i++)
                {
                    if (IsPlayerConnected(i))
                    {
                        if(IsPlayerAdmin(playerid))
                        {
			                format(String, sizeof(String),"[AC]: %s zostal wyrzucony z podejrzeniem RapidFire/NoReload",PlayerName(playerid));
                            SendClientMessage(i, COLOR_AC, String);
                        }
                    }
                }
                return 0;
            }
        }
    }
	if( hittype != BULLET_HIT_TYPE_NONE )
    {
        if( !( -1000.0 <= fX <= 1000.0 ) || !( -1000.0 <= fY <= 1000.0 ) || !( -1000.0 <= fZ <= 1000.0 ) )
        {
            SetTimerEx("kick", 500, false, "i", playerid);
		    SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony za FakeBullet");
	        GameTextForPlayer(playerid, "~g~kick", 8000, 4);
			printf("[AC] %s Zostal wyrzucony za FakeBullet.", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal wyrzucony za FakeBullet",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
            return 0; 
        }
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	DeletePVar(playerid, "LastHP");
    DeletePVar(playerid, "LastHP1");
    DeletePVar(playerid, "last_anim");
	playerEnteringVehicle[playerid] = INVALID_PLAYER_ID;
	KillTimer(timerantiairbrk[playerid]);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	AntiDeAMX();
	gb_as@con=true;
    SetTimerEx("decon", 3000, false, "d", playerid);
	timerantiairbrk[playerid] = SetTimerEx("antiairbrk", 300, true, "i", playerid);
	xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
    SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);
    return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
    xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(gb_as@con[playerid]) return 1;
    if(newstate == PLAYER_STATE_DRIVER)
    {
        if(GetTickCount() - 600 < FloodControl[playerid]) PunirSpam(playerid);
        FloodControl[playerid] = GetTickCount();
        gi_as@non[playerid] = 1;
        gi_as@car[playerid] = GetPlayerVehicleID(playerid);
    }
    else
    {
        if(GetTickCount() - 600 < FloodControl[playerid]) PunirSpam(playerid);
        FloodControl[playerid] = GetTickCount();
        gi_as@non[playerid] = 0;
    }
	return 1;
}

forward AntiBot(playerid);
public AntiBot(playerid)
{
    for(new i = 0; i<MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && IsPlayerNPC(i))
        {
            new name[MAX_PLAYER_NAME];
            GetPlayerName(i, name, sizeof(name));
            SetTimerEx("ban", 500, false, "i", playerid);
		    SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z podejrzeniem bota");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
			printf("[AC] %s Zostal zbanowany z podejrzeniem bota", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z podejrzeniem bota",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
        }
    }
}

forward decon(playerid);
public decon(playerid) return gb_as@con[playerid] = false, 0x1;

forward AntiBotPing(playerid);
public AntiBotPing(playerid)
{
    for(new i = 0; i<MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            if(GetPlayerPing(i) < 0)
            {
                new name[MAX_PLAYER_NAME];
                GetPlayerName(i, name, sizeof(name));
                SetTimerEx("ban", 500, false, "i", playerid);
		        SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z podejrzeniem bota");
				GameTextForPlayer(playerid, "~g~ban", 8000, 4);
				printf("[AC] %s Zostal zbanowany z podejrzeniem bota.", PlayerName(playerid));
				for (new i=0;i<MAX_PLAYERS;i++)
                {
                    if (IsPlayerConnected(i))
                    {
                        if(IsPlayerAdmin(playerid))
                        {
			                format(String, sizeof(String),"[AC]: %s zostal zbanowany z podejrzeniem bota",PlayerName(playerid));
                            SendClientMessage(i, COLOR_AC, String);
                        }
                    }
                }
            }
        }
    }
}

forward AntiJetPack( playerid );
public AntiJetPack( playerid )
{
    if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK)
    {
		SetTimerEx("ban", 500, false, "i", playerid);
		SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany za Jetpack Cheat");
		GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		printf("[AC] %s Zostal zbanowany za Anty Jetpack", PlayerName(playerid));
    }
}

public OnPlayerConnect(playerid)
{
    new ip[16], string[59];
	GetPlayerIp(playerid, ip, sizeof ip);
	format(string, sizeof string, "www.shroomery.org/ythan/proxycheck.php?ip=%s", ip);
	HTTP(playerid, HTTP_GET, string, "", "MyHttpResponse");
	
	SetPVarInt(playerid, "LastHP", 0);
    SetPVarInt(playerid, "LastHP1", 0);
    SetPVarInt(playerid, "last_anim", 0); 
	
	xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
	
	new pIP[16], oIP[16], 
    max_ip;
    GetPlayerIp(playerid, pIP, sizeof(pIP)); 
    foreach (new i : Player) 
    {
        if(IsPlayerConnected(i)) 
        {
            GetPlayerIp(i, oIP, sizeof(oIP)); 
            if(strcmp(pIP, oIP, true) == 0) 
            {
                max_ip++; 
                if(max_ip >= MAX_IP) return Kick(playerid); 
            }
        }
    }

    DamageTaken[playerid] = 0;
	gb_as@con[playerid] = true;
    gi_as@non[playerid] = 0;
    gi_as@car[playerid] = 0;
	
	return 1;
}

public MyHttpResponse(playerid, response_code, data[])
{
	new name[MAX_PLAYERS];
	new ip[16];
	GetPlayerName(playerid, name, sizeof(name));
	GetPlayerIp(playerid, ip, sizeof ip);
	if(strcmp(ip, "127.0.0.1", true) == 0)
	{

	}
	if(response_code == 200)
	{	
		if(data[0] == 'Y')
		{
			SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony za korzystanie z proxy/vpn");
			GameTextForPlayer(playerid, "~g~kick", 8000, 4);
	        SetTimerEx("kick", 300, false, "i", playerid);
		    printf("[AC] %s Zostal wyrzucony za Proxy/VPN.", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal wyrzucony za korzystanie z proxy/vpn",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
		}
		if(data[0] == 'N')
		{

		}
		if(data[0] == 'X')
		{
			printf("WRONG IP FORMAT");
		}
		else
		{
			printf("The request failed! The response code was: %d", response_code);
		}
	}
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart)
{
   DamageTaken[playerid] = 1;
   return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{   if(killerid != INVALID_PLAYER_ID)
	{
    if(DamageTaken[playerid] == 0)
    {
	    SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony z powodu FakeKilla");
		GameTextForPlayer(playerid, "~g~kick", 8000, 4);
		SetTimerEx("kick", 300, false, "i", playerid);
		printf("[AC] %s Zostal wyrzucony za FakeKilla.", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal wyrzucony za FakeKilla",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
    }
    if(killerid == playerid)
    {
        SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony z powodu FakeKilla");
		GameTextForPlayer(playerid, "~g~kick", 8000, 4);
	    SetTimerEx("kick", 300, false, "i", playerid);
		printf("[AC] %s Zostal wyrzucony za FakeKilla.", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal wyrzucony za FakeKilla",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
    }
    if(DamageTaken[playerid] == 1)
    {
        SetTimerEx("DamageTimer", 10, false, "i", playerid);
    }
    }
	for (new i=0;i<MAX_PLAYERS;i++)
    {
        if (IsPlayerConnected(i))
        {
            if(IsPlayerAdmin(playerid))
            {
			    format(String, sizeof(String),"[ACwarning]: %s zostal zabity przez %s",PlayerName(playerid), PlayerName(killerid));
                SendClientMessage(i, COLOR_AC, String);
            }
        }
    }
	xo[playerid] = 0.0;
    yo[playerid] = 0.0;
    zo[playerid] = 0.0;
    KillTimer(timerantiairbrk[playerid]);
    return 1;
}

public OnPlayerSpeedHack(playerid){

	if(GetVehicleSpeed(GetPlayerVehicleID(playerid)) > 500)
	{
	    new pName[24];
	    GetPlayerName(playerid, pName, 24);
	    SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony z powodu SpeedHacka");
		GameTextForPlayer(playerid, "~g~kick", 8000, 4);
		SetTimerEx("kick", 500, false, "i", playerid);
		printf("[AC] %s Zostal wyrzucony za SpeedHacka.", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal wyrzucony za SpeedHacka",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
	}
	if(GetVehicleSpeed(GetPlayerVehicleID(playerid)) > 300)
	{
		printf("[ACwarning] %s osiagnal predkosc wieksza niz 300!.", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[ACwarning]: %s osiagnal predkosc wieksza niz 300! prawdopodobny SpeedHack",PlayerName(playerid));
                        SendClientMessage(i, COLOR_WARNING, String);
                    }
                }
            }
	}
	return true;
}

public OnPlayerUpdate(playerid)
{
    new Float: health, Float: armour;
    GetPlayerHealth(playerid, health);
    GetPlayerArmour(playerid, armour);
 
    GetPlayerArmour(playerid, armour);
	SprawdzBron(playerid);
	
	SetTimerEx("OnPlayerSpeedHack", 100, true, "i", playerid);
	
    if(GetPlayerWeapon(playerid) == WEAPON_MINIGUN)
	{
		SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(minigun)");
		GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		SetTimerEx("ban", 500, false, "i", playerid);
		printf("[AC] %s Zostal zbanowany za Weapon Hacka(minigun).", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(minigun)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
	}
	if(GetPlayerWeapon(playerid) == WEAPON_ROCKETLAUNCHER)
	{
		SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(RPG)");
		GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		SetTimerEx("ban", 300, false, "i", playerid);
		printf("[AC] %s Zostal zbanowany za Weapon Hacka(RPG).", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(RPG)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
	}
	if(GetPlayerWeapon(playerid) == WEAPON_HEATSEEKER)
	{
		SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu  Weapon Hack(RPG)");
		GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		SetTimerEx("ban", 300, false, "i", playerid);
		printf("[AC] %s Zostal zbanowany za Weapon Hacka(RPG).", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(RPG)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
	}
	if(GetPlayerWeapon(playerid) == WEAPON_SATCHEL)
	{
		SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu  Weapon Hacka(C4)");
		GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		SetTimerEx("ban", 300, false, "i", playerid);
		printf("[AC] %s Zostal zbanowany za Weapon Hacka(C4).", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(C4)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
	}
	if(GetPlayerWeapon(playerid) == WEAPON_BOMB)
	{
		SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu  Weapon Hacka(Detonator)");
		GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		SetTimerEx("ban", 300, false, "i", playerid);
		printf("[AC] %s Zostal zbanowany za Weapon Hacka(Detonator).", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Detonator)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
	}
	if(GetPlayerWeapon(playerid) == WEAPON_FLAMETHROWER)
	{
		SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Flamethrower)");
		GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		SetTimerEx("ban", 300, false, "i", playerid);
		printf("[AC] %s Zostal zbanowany za Weapon Hacka(Flamethrower).", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Flamethrower)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
	}
	if(armour == 100)
    {
	    SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany za Armour Hacka");
		GameTextForPlayer(playerid, "~g~ban", 8000, 4);
	    SetTimerEx("ban", 300, false, "i", playerid);
		printf("[AC] %s Zostal zbanowany za Armour Hacka.", PlayerName(playerid));
		for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu Armour Hacka)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
	}
	if(!IsPlayerInAnyVehicle(playerid)) return 1;
    if(gi_as@non[playerid] != 0)
    {
        if(gi_as@car[playerid] != GetPlayerVehicleID(playerid)) PunirSpam(playerid);
    }
    GetPlayerHealth(playerid, health);
    GetPlayerArmour(playerid, armour);
    new HP = floatround(health +armour, floatround_floor);
    if (GetPlayerTeam(playerid) == 255)
    {
        new anim_id = GetPlayerAnimationIndex(playerid);
        if (anim_id != GetPVarInt(playerid, "last_anim"))
        {
            if (1071 <= anim_id <= 1086 || 1170 <= anim_id <= 1179 || 1240 <= anim_id <= 1243)
            {
                if (HP == GetPVarInt(playerid, "LastHP1") && HP == GetPVarInt(playerid, "LastHP"))
                {
                    new animlib[32], animname[32];
                    GetAnimationName(anim_id, animlib, sizeof(animlib), animname, sizeof(animname));
                    new name[MAX_PLAYER_NAME];
                    GetPlayerName(playerid, name, sizeof(name));
                    SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu  Anty GodMode");
		            GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		            SetTimerEx("ban", 300, false, "i", playerid);
		            printf("[AC] %s Zostal zbanowany za GodMode.", PlayerName(playerid));
					for (new i=0;i<MAX_PLAYERS;i++)
                    {
                        if (IsPlayerConnected(i))
                        {
                            if(IsPlayerAdmin(playerid))
                            {
			                    format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu GodMode",PlayerName(playerid));
                                SendClientMessage(i, COLOR_AC, String);
                            }
                        }
                    }
                    }else{
                        SetPVarInt(playerid, "LastHP1", HP);
                    }
                }
            SetPVarInt(playerid, "last_anim", anim_id);
            }
        }
    if (HP != GetPVarInt(playerid, "LastHP"))
    {
        SetPVarInt(playerid, "LastHP", HP);
    }
	return 1;
}

SprawdzBron(playerid)
{
    new weaponid = GetPlayerWeapon(playerid);

    if(weaponid >= 1 && weaponid <= 15)
    {
        if(weaponid == Weapons[playerid][Melee])
        {
        return 1;
        }
            else
            {
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Mele)");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		    SetTimerEx("ban", 300, false, "i", playerid);
			printf("[AC] %s Zostal zbanowany za Weapon Hacka(Mele).", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Mele)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
            }
    }

    if( weaponid >= 16 && weaponid <= 18 || weaponid == 39 ) 
    {
        if(weaponid == Weapons[playerid][Thrown])
        {
        return 1;
        }
            else
            {
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Granades)");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		    SetTimerEx("ban", 300, false, "i", playerid);
			printf("[AC] %s Zostal zbanowany za Weapon Hacka(Granades).", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Granades)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
            }
    }
    if( weaponid >= 22 && weaponid <= 24 ) 
    {
        if(weaponid == Weapons[playerid][Pistols])
        {
        return 1;
        }
        else
        {
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Pistols)");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		    SetTimerEx("ban", 300, false, "i", playerid);
			printf("[AC] %s Zostal zbanowany za Weapon Hacka(Pistols).", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Pistols)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
        }
    }

    if( weaponid >= 25 && weaponid <= 27 ) 
    {
        if(weaponid == Weapons[playerid][Shotguns])
        {
        return 1;
        }
            else
            {
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Shotguns)");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		    SetTimerEx("ban", 300, false, "i", playerid);
			printf("[AC] %s Zostal zbanowany za Weapon Hacka(Shotguns).", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Shotguns)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
            }
    }
    if( weaponid == 28 || weaponid == 29 || weaponid == 32 ) 
    {
        if(weaponid == Weapons[playerid][SubMachine])
        {
        return 1;
        }
            else
            {
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Machine Guns)");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		    SetTimerEx("ban", 300, false, "i", playerid);
			printf("[AC] %s Zostal zbanowany za Weapon Hacka(Machine Guns).", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Machine Guns)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
            }
    }

    if( weaponid == 30 || weaponid == 31 )
    {
        if(weaponid == Weapons[playerid][Assault])
        {
        return 1;
        }
            else
            {
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Assasult Guns)");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		    SetTimerEx("ban", 300, false, "i", playerid);
			printf("[AC] %s Zostal zbanowany za Weapon Hacka(assasult Guns).", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Assasult Guns)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
            }
    }

    if( weaponid == 33 || weaponid == 34 )
    {
        if(weaponid == Weapons[playerid][Rifles])
        {
        return 1;
        }
            else
            {
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Snipers)");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		    SetTimerEx("ban", 300, false, "i", playerid);
			printf("[AC] %s Zostal zbanowany za Weapon Hacka(Snipers).", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Snipers)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
            }
    }
    if( weaponid >= 35 && weaponid <= 38 ) 
    {
        if(weaponid == Weapons[playerid][Heavy])
        {
        return 1;
        }
            else
            {
            SendClientMessage(playerid,ORANGE2,"[AC]: Zostales zbanowany z powodu Weapon Hacka(Heavy)");
			GameTextForPlayer(playerid, "~g~ban", 8000, 4);
		    SetTimerEx("ban", 300, false, "i", playerid);
			printf("[AC] %s Zostal zbanowany za Weapon Hacka(Heavy).", PlayerName(playerid));
			for (new i=0;i<MAX_PLAYERS;i++)
            {
                if (IsPlayerConnected(i))
                {
                    if(IsPlayerAdmin(playerid))
                    {
			            format(String, sizeof(String),"[AC]: %s zostal zbanowany z powodu WeaponHacka(Heavy)",PlayerName(playerid));
                        SendClientMessage(i, COLOR_AC, String);
                    }
                }
            }
            }
    }
    else { return 1; }
    
    return 1;
}

ServerWeapon(playerid, weaponid, ammo)
{
    if(weaponid >= 1 && weaponid <= 15)
    {
    Weapons[playerid][Melee] = weaponid;
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
    }
    if( weaponid >= 16 && weaponid <= 18 || weaponid == 39 ) 
    {
    Weapons[playerid][Thrown] = weaponid;
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
    }
    if( weaponid >= 22 && weaponid <= 24 ) 
    {
    Weapons[playerid][Pistols] = weaponid;
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
    }

    if( weaponid >= 25 && weaponid <= 27 ) 
    {
    Weapons[playerid][Shotguns] = weaponid;
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
    }
    if( weaponid == 28 || weaponid == 29 || weaponid == 32 ) 
    {
    Weapons[playerid][SubMachine] = weaponid;
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
    }

    if( weaponid == 30 || weaponid == 31 )
    {
    Weapons[playerid][Assault] = weaponid;
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
    }

    if( weaponid == 33 || weaponid == 34 ) 
    {
    Weapons[playerid][Rifles] = weaponid;
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
    }
    if( weaponid >= 35 && weaponid <= 38 ) 
    {
    Weapons[playerid][Heavy] = weaponid;
    GivePlayerWeapon(playerid, weaponid, ammo);
    return 1;
    }
    return 1;
}

AntiDeAMX()
{
    new a[][] =
    {
        "Unarmed (Fist)",
        "Brass K"
    };
    #pragma unused a
}

PunirSpam(playerid)
{
    SendClientMessage(playerid,ORANGE2,"[AC]: Zostales wyrzucony z powodu CarSpamer");
	GameTextForPlayer(playerid, "~g~kick", 8000, 4);
	SetTimerEx("kick", 300, false, "i", playerid);
	printf("[AC] %s wyrzucony za CarSpamer.", PlayerName(playerid));
	for (new i=0;i<MAX_PLAYERS;i++)
    {
        if (IsPlayerConnected(i))
        {
            if(IsPlayerAdmin(playerid))
            {
			    format(String, sizeof(String),"[AC]: %s zostal wyrzucony z powodu CarSpamer",PlayerName(playerid));
                SendClientMessage(i, COLOR_AC, String);
            }
        }
    }
    return 1;
}

GetTickCount2()
{
    new count = GetTickCount();
    return count < 0 ? count +- tick : count - tick;
}

PlayerName(playerid)
{
 new name[25];
 GetPlayerName(playerid, name, sizeof(name));
 return name;
}

CMD:actest(playerid)
{
if(IsPlayerAdmin(playerid))
{
    ServerWeapon(playerid, 24, 500);
}
return 1;
}
CMD:kasa(playerid)
{
if(IsPlayerAdmin(playerid))
{
    SetPlayerCash(playerid, 500);
}
return 1;
}

#if defined _ALS_PutPlayerInVehicle
  #undef PutPlayerInVehicle
#else
#define _ALS_PutPlayerInVehicle
#endif
#define PutPlayerInVehicle PutPlayerInVehicleEx
