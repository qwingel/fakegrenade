#include <amxmodx>
#include <reapi>

#define PLUGIN "fakegrenade"
#define VERSION "1.2"
#define AUTHOR "Antarktida"

/*
    Замена модели HE гранаты на модель flash гранаты
    закомментировать если не нужно
*/
#define W_MODEL "models/w_flashbang.mdl"

// Сила отталкивания (в юнитах)
const Float:powerRation = 600.0;

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHookChain(RG_ThrowHeGrenade, "OnThrowHeGrenade_Post", 1);
    #if defined W_MODEL
    RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "fw_PlayerWeapon_DefaultDeploy");
    #endif
}

public OnThrowHeGrenade_Post(const index, Float:vecStart[3], Float:vecVelocity[3], Float:time, const team, const usEvent) {
    // Индекс нашей гранаты
    new grenade = GetHookChainReturn(ATYPE_INTEGER);
    
    if (!is_nullent(grenade)) {
        set_entvar(grenade, var_nextthink, 0.0);
        SetTouch(grenade, "Grenade_Touch");
    }
    return HC_CONTINUE;
}

public Grenade_Touch(const grenade, const other) {
    if (is_nullent(grenade)) return;

    new Float:grenade_origin[3];
    get_entvar(grenade, var_origin, grenade_origin);

    // Удаляем гранату
    set_entvar(grenade, var_flags, FL_KILLME);

    // Отталкиваем игроков
    PushPlayersAway(grenade_origin);
}

public fw_PlayerWeapon_DefaultDeploy(iEnt, szViewModel[], szWeaponModel[]) {
    if (is_nullent(iEnt)) return;

    // HE onwer and entity id
    new id; id = get_member(iEnt, m_pPlayer);
    new weapon; weapon = rg_get_iteminfo(iEnt, ItemInfo_iId);

    if (!is_user_alive(id)) return;

    if (weapon == CSW_HEGRENADE){
        SetHookChainArg(2, ATYPE_STRING, W_MODEL); 
    }
}

stock PushPlayersAway(const Float:origin[3], Float:radius = 300.0) {
    new Float:playerOrigin[3], Float:direction[3], Float:distance;
    
    for (new id = 1; id <= MaxClients; id++) {
        if (!is_user_alive(id)) continue;

        get_entvar(id, var_origin, playerOrigin);

        // Направление от гранаты к игроку
        direction[0] = playerOrigin[0] - origin[0];
        direction[1] = playerOrigin[1] - origin[1];
        direction[2] = playerOrigin[2] - origin[2];

        distance = floatsqroot(
            direction[0]*direction[0] +
            direction[1]*direction[1] +
            direction[2]*direction[2]
        );

        if (distance > 0.0 && distance <= radius) {
            // Нормализация
            direction[0] /= distance;
            direction[1] /= distance;
            direction[2] /= distance;

            // Вычисляем коэффициент отталкивания относительно расстояния от игрока до гранаты
            new Float:force = powerRation * (1.0 - distance / radius);

            new Float:newVelocity[3];
            newVelocity[0] = direction[0] * force;
            newVelocity[1] = direction[1] * force;
            newVelocity[2] = direction[2] * force + 50.0;

            set_entvar(id, var_velocity, newVelocity);
        }
    }
}
