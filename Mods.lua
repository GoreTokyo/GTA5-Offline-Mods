util.require_natives(1663599433)
native_invoker.accept_bools_as_ints(true)

local Animations = require("Animations")
local joaat, toast, yield, current_time_millis, create_thread, create_tick_handler, handle_to_pointer, delete_by_handle, get_all_peds, get_all_vehicles, get_all_objects, write_int, read_int, read_long, script_global, alloc_int = util.joaat, util.toast, util.yield, util.current_time_millis, util.create_thread, util.create_tick_handler, entities.handle_to_pointer, entities.delete_by_handle, entities.get_all_peds_as_handles, entities.get_all_vehicles_as_handles, entities.get_all_objects_as_handles, memory.write_int, memory.read_int, memory.read_long, memory.script_global, memory.alloc_int
local my_root, player_root, ref_by_path, ref_by_rel_path, trigger_command = menu.my_root, menu.player_root, menu.ref_by_path, menu.ref_by_rel_path, menu.trigger_command

menu.divider(my_root(), "Animation Lua")
local animations = menu.list(my_root(), "Animations")

local function request_model(model)
    if not STREAMING.IS_MODEL_VALID(model) then return false end
    STREAMING.REQUEST_MODEL(model)
    local timeout = current_time_millis() + 3500
    while not STREAMING.HAS_MODEL_LOADED(model) do
        if current_time_millis() > timeout then return false end
        yield(10)
    end
    return true
end

local function request_anim_dict(dict)
    STREAMING.REQUEST_ANIM_DICT(dict)
    local timeout = current_time_millis() + 3500
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        if current_time_millis() > timeout then return false end
        yield(10)
    end
    return true
end

local function set_network_attributes(entity, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
    local net_id = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
    NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, exists_all_machines)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(net_id, can_migrate)
    NETWORK.SET_NETWORK_ID_CAN_BE_REASSIGNED(net_id, can_be_reassigned)
    if disable_proximity_migration then
        NETWORK.NETWORK_DISABLE_PROXIMITY_MIGRATION(net_id)
    end
end

local function create_entity(create_func, modelhash, pos, additional_args, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
    local pos = pos or v3()
    local status = request_model(modelhash)
    if status then
        local entity = create_func(modelhash, pos, table.unpack(additional_args))
        if entity ~= 0 then
            set_network_attributes(entity, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(modelhash)
            return entity
        end
    end
    return 0
end

local function create_ambient_pickup(pickuphash, pos, flags, value, modelhash, p7, p8, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration) -- 6
    local create_func = function(modelhash, pos, pickuphash, flags, value, modelhash, p7, p8)
        return OBJECT.CREATE_AMBIENT_PICKUP(pickuphash, pos.x, pos.y, pos.z, flags, value, modelhash, p7, p8)
    end
    return create_entity(create_func, modelhash, pos, { pickuphash, flags, value, modelhash, p7, p8 }, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
end

local function create_object_no_offset(modelhash, pos, isnetworked, scripthostobj, dynamic, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
    local create_func = function(modelhash, pos, isnetworked, scripthostobj, dynamic)
        return OBJECT.CREATE_OBJECT_NO_OFFSET(modelhash, pos.x, pos.y, pos.z, isnetworked, scripthostobj, dynamic)
    end
    return create_entity(create_func, modelhash, pos, { isnetworked, scripthostobj, dynamic }, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
end

local function create_ped_inside_vehicle(vehicle, pedtype, modelhash, seat, isnetworked, scripthostped, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration) -- 6
    local create_func = function(modelhash, pos, vehicle, pedtype, seat, isnetworked, scripthostped)
        return PED.CREATE_PED_INSIDE_VEHICLE(vehicle, pedtype, modelhash, seat, isnetworked, scripthostped)
    end
    return create_entity(create_func, modelhash, v3(), { vehicle, pedtype, seat, isnetworked, scripthostped }, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
end

local function create_ped(pedtype, modelhash, pos, heading, isnetworked, scripthostped, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration) -- 6
    local create_func = function(modelhash, pos, pedtype, heading, isnetworked, scripthostped)
        return PED.CREATE_PED(pedtype, modelhash, pos.x, pos.y, pos.z, heading, isnetworked, scripthostped)
    end
    return create_entity(create_func, modelhash, pos, { pedtype, heading, isnetworked, scripthostped }, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
end

local function create_object(modelhash, pos, isnetworked, scripthostobj, dynamic, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration) -- 7
    local create_func = function(modelhash, pos, isnetworked, scripthostobj, dynamic)
        return OBJECT.CREATE_OBJECT(modelhash, pos.x, pos.y, pos.z, isnetworked, scripthostobj, dynamic)
    end
    return create_entity(create_func, modelhash, pos, { isnetworked, scripthostobj, dynamic }, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
end

local function create_vehicle(modelhash, pos, heading, isnetworked, scripthostveh, p7, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration) -- 7
    local create_func = function(modelhash, pos, heading, isnetworked, scripthostveh, p7)
        return VEHICLE.CREATE_VEHICLE(modelhash, pos.x, pos.y, pos.z, heading, isnetworked, scripthostveh, p7)
    end
    return create_entity(create_func, modelhash, pos, { heading, isnetworked, scripthostveh, p7 }, exists_all_machines, can_migrate, can_be_reassigned, disable_proximity_migration)
end

local function set_entity_as_networked(Entity, timeout)
    local end_time = current_time_millis() + (timeout or 1500)
    while current_time_millis() < end_time and not NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(Entity) do
        NETWORK.NETWORK_REGISTER_ENTITY_AS_NETWORKED(Entity)
        yield(0)
    end
    return NETWORK.NETWORK_GET_ENTITY_IS_NETWORKED(Entity)
end

local function constantize_network_id(Entity)
    if set_entity_as_networked(Entity, 25) then
        local net_id = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(Entity)
        NETWORK.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, true)
        NETWORK.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(net_id, PLAYER.PLAYER_ID(), true)
        return net_id
    end
end

local function request_control_of_id(net_id, time_to_wait)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(net_id) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(net_id)
        local start_time = current_time_millis()
        local timeout = start_time + (time_to_wait or 3000)
        while not NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(net_id) and current_time_millis() < timeout do
            yield(0)
        end
        return NETWORK.NETWORK_HAS_CONTROL_OF_NETWORK_ID(net_id)
    end
    return true
end

local function request_control_of_entity(entity, time_to_wait)
    if not ENTITY.IS_AN_ENTITY(entity) then
        return false
    end
    if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_A_PLAYER(entity) then
        return false
    end
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    local start_time = current_time_millis()
    local timeout = start_time + (time_to_wait or 3000)
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and current_time_millis() < timeout do
        yield(0)
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

local Animation = {}
local Emote_Props = {}
local AnimationProp = {}

local function Animation.play(ped, EmoteName)
    if not ENTITY.DOES_ENTITY_EXIST(ped) then
        return
            false
    end
    local InVehicle = PED.IS_PED_IN_ANY_VEHICLE(ped, true)
    local ChosenDict, ChosenAnimation, ename = table.unpack(EmoteName)
    local AnimationDuration = -1

    if #Emote_Props > 0 then
        AnimationProp.destroy_all(ped)
    end
    if ChosenDict == "MaleScenario" or ChosenDict == "Scenario" then
        if InVehicle then return end
        TASK.CLEAR_PED_TASKS(ped)
        if ChosenDict == "MaleScenario" then
            TASK.TASK_START_SCENARIO_IN_PLACE(ped, ChosenAnimation, 0, true)
        elseif ChosenDict == "ScenarioObject" then
            TASK.TASK_START_SCENARIO_AT_POSITION(ped, ChosenAnimation, ENTITY.GET_ENTITY_COORDS(ped) - vector3(0.0, 0.0, 0.5), ENTITY.GET_ENTITY_HEADING(ped), 0, true, false)
        else
            TASK.TASK_START_SCENARIO_IN_PLACE(ped, ChosenAnimation, 0, true)
        end
        -- toast("Playing scenario = (" .. ChosenAnimation .. ")")
        return true
    end

    request_anim_dict(ChosenDict)

    local MovementType = 0
    if EmoteName.AnimationOptions then
        local options = EmoteName.AnimationOptions
        if options.EmoteLoop then
            MovementType = options.EmoteMoving and 51 or 1
        elseif options.EmoteMoving then
            MovementType = 51
        elseif options.EmoteStuck then
            MovementType = 50
        end
        AnimationDuration = options.EmoteDuration or -1
    end
    if InVehicle == 1 then MovementType = 51 end
    TASK.TASK_PLAY_ANIM(ped, ChosenDict, ChosenAnimation, 2.0, 2.0, AnimationDuration, MovementType, 0.0, false, false, false)
    STREAMING.REMOVE_ANIM_DICT(ChosenDict)

    if EmoteName.AnimationOptions and EmoteName.AnimationOptions.Prop then
        local options = EmoteName.AnimationOptions
        AnimationProp.add(ped, options.Prop, options.PropBone, table.unpack(options.PropPlacement))
        if options.SecondProp then
            AnimationProp.add(ped, options.SecondProp, options.SecondPropBone, table.unpack(options.SecondPropPlacement))
        end
    end

    return true
end

local function Animation.cancel(ped)
    TASK.CLEAR_PED_TASKS(ped)
    AnimationProp.destroy_all(ped)
end

local function AnimationProp.add(ped, propmodel, bone, off1, off2, off3, rot1, rot2, rot3)
    local prop = create_object(joaat(propmodel), ENTITY.GET_ENTITY_COORDS(ped), true, false, false, true, false, false, true)
    ENTITY.SET_ENTITY_INVINCIBLE(prop, true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(prop, ped, PED.GET_PED_BONE_INDEX(ped, bone), off1 or 0.0, off2 or 0.0, off3 or 0.0, rot1 or 0.0, rot2 or 0.0, rot3 or 0.0, false, false, false, false, 1, true)
    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(prop, false, true)
    table.insert(Emote_Props, prop)
end

local function AnimationProp.destroy_all(ped)
    for _, entity in ipairs(Emote_Props) do
        if ENTITY.DOES_ENTITY_EXIST(entity) and ped == ENTITY.GET_ENTITY_ATTACHED_TO(entity) and WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped, false) ~= entity then
            ENTITY.DETACH_ENTITY(entity, true, false)
            delete_by_handle(entity)
        end
    end
    Emote_Props = {}
end

menu.toggle_loop(animations, "X Key To Stop Animation", {}, "", function()
    if PAD.IS_CONTROL_PRESSED(0, 73) then
        Animation.cancel(PLAYER.PLAYER_PED_ID())
        yield(200)
    end
end)

local emote_categories = {
    { name = "Animations", id = "Emotes1", emotes = Animations.emotes },
    { name = "Animation With Props", id = "Emotes2", emotes = Animations.emotes2 },
    { name = "Dance", id = "Dance", emotes = Animations.dances },
    { name = "DJ", id = "DJ", emotes = Animations.dj },
}

for _, category in ipairs(emote_categories) do
    local cat_menu = menu.list(animations, category.name)
    for key, emote in pairs(category.emotes) do
        menu.action(cat_menu, key, {}, "", function()
            Animation.play(PLAYER.PLAYER_PED_ID(), emote)
        end)
    end
end
