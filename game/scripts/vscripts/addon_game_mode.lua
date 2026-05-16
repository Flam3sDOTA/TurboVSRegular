if TurboVSRegular == nil then
	_G.TurboVSRegular = class({})
end

require("precache")
require("events")
require("timers")

function Precache( context )
	for _,Item in pairs( g_ItemPrecache ) do
    	PrecacheItemByNameSync( Item, context )
    end

	for _,Model in pairs( g_ModelPrecache ) do
		PrecacheResource( "model", Model, context )
	end

	for _,Particle in pairs( g_ParticlePrecache ) do
		PrecacheResource( "particle", Particle, context )
	end

	for _,Sound in pairs( g_SoundPrecache ) do
		PrecacheResource( "soundfile", Sound, context )
	end

	for _,Unit in pairs( g_UnitPrecache ) do
    	PrecacheUnitByNameAsync( Unit, function( unit ) end )
  	end
	PrecacheResource("particle_folder", "particles/econ/items/pudge/pudge_arcana", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_antimage_female", context)
	PrecacheResource("model_folder", "models/heroes/antimage_female", context)
	PrecacheResource("model_folder", "models/items/pudge/arcana", context)
	PrecacheResource("particle_folder", "particles/econ/items/juggernaut/jugg_arcana", context)
	PrecacheResource("model_folder", "models/heroes/juggernaut", context)
	PrecacheResource("particle_folder", "particles/econ/items/earthshaker/earthshaker_arcana", context)
	PrecacheResource("model_folder", "models/items/earthshaker/earthshaker_arcana", context)
	PrecacheResource("particle_folder", "particles/econ/items/zeus/arcana_chariot", context)
	PrecacheResource("model_folder", "models/heroes/zeus", context)
	PrecacheResource("particle_folder", "particles/econ/items/wisp", context)
	PrecacheResource("model_folder", "models/items/io/io_ti7", context)
	PrecacheResource("particle_folder", "particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith", context)
	PrecacheResource("model_folder", "models/heroes/phantom_assassin", context)
	PrecacheResource("particle_folder", "particles/econ/items/lina/lina_head_headflame", context)
	PrecacheResource("model_folder", "models/heroes/invoker_kid", context)
	PrecacheResource("model_folder", "models/items/wraith_king/arcana", context)
	PrecacheResource("model_folder", "models/heroes/attachto_ghost", context)
	PrecacheResource("model_folder", "models/heroes/crystal_maiden_persona", context)
	PrecacheResource("model_folder", "models/heroes/dragon_knight_persona", context)
	PrecacheResource("model_folder", "models/heroes/invoker_kid", context)
	PrecacheResource("model_folder", "models/heroes/mirana_persona", context)
	PrecacheResource("model_folder", "models/heroes/phantom_assassin_persona", context)
	PrecacheResource("model_folder", "models/heroes/pudge_cute", context)
	PrecacheResource("model_folder", "models/heroes/shopkeeper", context)
	PrecacheResource("model_folder", "models/heroes/shopkeeper_dire", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_crystalmaiden_persona", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_invoker_kid", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_phantom_assassin_persona", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_pudge_cute", context)
	PrecacheResource("particle_folder", "particles/base_attacks", context)
	PrecacheResource("particle_folder", "particles/neutral_fx", context)
	PrecacheResource("particle_folder", "particles/generic_gameplay", context)
	PrecacheResource("particle_folder", "particles/generic_hero_status", context)
	PrecacheResource("particle_folder", "particles/items_fx", context)
	PrecacheResource("particle_folder", "particles/items2_fx", context)
	PrecacheResource("particle_folder", "particles/items3_fx", context)
	PrecacheResource("particle_folder", "particles/items4_fx", context)
	PrecacheResource("particle_folder", "particles/items5_fx", context)
	PrecacheResource("particle_folder", "particles/items6_fx", context)
	PrecacheResource("particle_folder", "particles/items7_fx", context)
	PrecacheResource("particle_folder", "particles/items8_fx", context)
	PrecacheResource("particle_folder", "particles/items_4fx", context)
end

function Activate()
	GameRules.TurboVSRegular = TurboVSRegular()
	GameRules.TurboVSRegular:InitGameMode()
	SendToServerConsole("tv_delay 0")
end

function TurboVSRegular:InitGameMode()
	MAX_TEAMS = 2   
	PLAYER_COUNT = {}        
	PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 5
	PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 5

	local count = 0
	for team,number in pairs(PLAYER_COUNT) do
		if count >= MAX_TEAMS then
			GameRules:SetCustomGameTeamMaxPlayers(team, 0)
		else
			GameRules:SetCustomGameTeamMaxPlayers(team, number)
		end
		count = count + 1
	end

	GameRules:SetSameHeroSelectionEnabled(false)
	GameRules:SetUseUniversalShopMode(true)
	GameRules:SetShowcaseTime(0)
	GameRules:SetGoldTickTime(0)
	GameRules:SetTimeOfDay(0.25)
	GameRules:SetFilterMoreGold(true)

	local GameMode = GameRules:GetGameModeEntity()
	GameMode:SetCanSellAnywhere(true)
	GameMode:DisableHudFlip(true)
	GameMode:SetUseDefaultDOTARuneSpawnLogic(true)
	GameMode:SetTowerBackdoorProtectionEnabled(true)
	GameMode:SetFreeCourierModeEnabled(true)
	GameMode:SetUseTurboCouriers(false)
	GameMode:SetExecuteOrderFilter(Dynamic_Wrap(TurboVSRegular, "OnExecuteOrder"), self)
	GameMode:SetModifyExperienceFilter(Dynamic_Wrap(TurboVSRegular, "OnModifyExperience"), self)
	GameMode:SetModifyGoldFilter(Dynamic_Wrap(TurboVSRegular, "OnModifyGold"), self)
	GameMode:SetBountyRunePickupFilter(Dynamic_Wrap(TurboVSRegular, "OnBountyRunePickup"), self)

	TurboVSRegular.turboCouriers = {}
	TurboVSRegular.playerCouriers = {}
	TurboVSRegular.secretShopItems = {}

	local itemKV = LoadKeyValues("scripts/npc/items.txt")
	if itemKV then
		for itemName, itemData in pairs(itemKV) do
			if type(itemData) == "table" and itemData["SecretShop"] == 1 then
				TurboVSRegular.secretShopItems[itemName] = true
			end
		end
	end

	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap( TurboVSRegular, 'OnGameRulesStateChange' ), self )
	ListenToGameEvent("npc_spawned", Dynamic_Wrap(TurboVSRegular, "OnNPCSpawned"), self)
	ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(TurboVSRegular, "OnTeamKillCredit" ), self )
	ListenToGameEvent('entity_killed', Dynamic_Wrap(TurboVSRegular, 'OnEntityKilled'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(TurboVSRegular, 'OnPlayerUsedAbility'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(TurboVSRegular, 'OnItemPickedUp'), self)
end