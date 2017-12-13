CantSim = LibStub("AceAddon-3.0"):NewAddon("CantSim", "AceConsole-3.0")

local addonName = "Can't Sim"
local debug = false
local defaults = {
    profile = {
        DB = {
            stats = {},
            atonementHealing = 72,
            leechPawn = 2.17,
            avoidancePawn = 1.5,
            scalingLeechBool = false
        }
    }
}
DB = {
        stats = {},
        atonementHealing = 72,
        leechPawn = 2.17,
        avoidancePawn = 1.5,
        scalingLeechBool = false
}
function CantSim:GetCharacterStats()
    DB.stats["critRating"] = GetCombatRating(9) 
    DB.stats["critPercent"] = GetCritChance()
    DB.stats["hasteRating"] = GetCombatRating(18)
    DB.stats["hastePercent"] = GetHaste()
    DB.stats["masteryRating"] = GetCombatRating(26)
    DB.stats["masteryPercent"] = DB.stats.masteryRating / 250
    DB.stats["versatilityRating"] = GetCombatRating(29)
    DB.stats.versatilityPercent = DB.stats.versatilityRating / 475
    DB.stats.effectiveILvl = select(1, GetDetailedItemLevelInfo(GetInventoryItemLink("player", 16)))
    DB.stats.classInfo = UnitClass("player")
    DB.stats.currentSpec = GetSpecialization()
    DB.stats.currentSpecName = DB.stats.currentSpec and select(2, GetSpecializationInfo(DB.stats.currentSpec)) or "None"
    DB.stats.leechRating = GetCombatRating(17)
    DB.stats.leechPercent = DB.stats.leechRating / 230
    isDisciplinePriest = false
end

function CantSim:GetPriestPawn()
    if DB.stats.currentSpecName == "Discipline" then
        isDisciplinePriest = true
        leechModifier = 1
        DB.stats.intRating = UnitStat("player", 4)
        DB.stats.intPawn = 1000/((DB.stats.intRating/100)/1.05)
        DB.stats.critPawn = 1000*leechModifier/400/((DB.stats.critPercent/100 * leechModifier) + 1)
        DB.stats.masteryPawn = 1000*(1/250/(1+(DB.stats.masteryPercent + 12.8)/100)* DB.atonementHealing/100)
        DB.stats.versatilityPawn = 1000 * (1/475/(1+DB.stats.versatilityPercent/100))
        DB.stats.maxResult = math.max(DB.stats.critPawn, DB.stats.masteryPawn, DB.stats.versatilityPawn)
        DB.stats.hastePawn = DB.stats.maxResult * 1.25 / (1 + (DB.stats.hastePercent/100))
        if DB.scalingLeechBool then
            DB.stats.leechPawn = (1 / math.sqrt(DB.stats.leechPercent/100)) * .3
            if(DB.stats.leechPawn > 2.17) then
                DB.stats.leechPawn = 2.17
            end
        else
            DB.stats.leechPawn = DB.leechPawn
        end
        DB.stats.avoidancePawn = DB.avoidancePawn
        DB.pawnString = "( Pawn: v1: \""..DB.stats.currentSpecName.." (Can't Sim)\": Intellect="..DB.stats.intPawn..", Versatility="..DB.stats.versatilityPawn..", HasteRating="..DB.stats.hastePawn..", MasteryRating="..DB.stats.masteryPawn..", CritRating="..DB.stats.critPawn..", Leech="..DB.stats.leechPawn..", Avoidance="..DB.stats.avoidancePawn..")"
    end
end

--GET PAWN STRINGS
function CantSim:GetPawnStringDialog()
    CantSim:GetCharacterStats()
    if DB.stats.classInfo == "Priest" then
        CantSim:GetPriestPawn()
    else 
        DB.pawnString = "Your class/spec is not supported yet. Feel free to PM me @Drizz#2038 on Discord to get your spec started."
    end
    if debug then 
        for k,v in pairs(DB.stats) do print(k,v) end
        print(DB.pawnString)
    end
    LibStub("AceConfigDialog-3.0"):SelectGroup(addonName, DB.pawnString)
end

function CantSim:GetPawnStringConsole()
    CantSim:GetCharacterStats()
    if DB.stats.classInfo == "Priest" then
        CantSim:GetPriestPawn()
    else 
        DB.pawnString = "Your class/spec is not supported yet. Feel free to PM me @Drizz#2038 on Discord to get your spec started."
    end
    if debug then 
        for k,v in pairs(DB.stats) do print(k,v) end
        print(DB.pawnString)
        for k,v in pairs(self.db.profile) do print(k,v) end
    end
    LibStub("AceConfigDialog-3.0"):Open(addonName)
    LibStub("AceConfigDialog-3.0"):SelectGroup(addonName, DB.pawnString)
end

function CantSim:Reset()
	DB = self.db.profile["DB"]
end

function CantSim:UpdateAtonementHealing(number)
    DB.atonementHealing = number
end

function CantSim:UpdateLeechWeight(number)
    DB.leechPawn = number
end

function CantSim:UpdateAvoidanceWeight(number)
    DB.avoidancePawn = number
end

local options = {
    name = addonName,
    handler = CantSim,
    type = 'group',
    args = {
        get = {
            type = "execute",
            guiHidden = true,
            name = "Get Pawn",
            desc = "Gets your pawn string for your spec",
            func = "GetPawnStringConsole",
            order = 1,
            width = "half"
        },
        getDialog = {
            type = "execute",
            cmdHidden = true,
            name = "Get Pawn",
            desc = "Gets your pawn string for your spec",
            func = "GetPawnStringDialog",
            order = 1,
            width = "half"
        },
        pawnString = {
            type = "group",
            order = 3,
            name = "Pawn String",
            guiInline = false,
            cmdHidden = true,
            args = {
                pawn = {
                    type = "input",
                    name = "Pawn String",
                    desc = "Displays your pawn string",
                    multiline = 5,
                    width = "full",
                    get = function() return DB.pawnString end,
                    cmdHidden = true
                },
            }
        },
        advOptions = {
            type = "group",
            order = 4,
            name = "Advanced Options",
            guiInline = false,
            cmdHidden = true,
            args = {
                    atonementPercent = {
                    order = 1,
                    cmdHidden = true,
                    type = "range",
                    name = "Atonement Healing Percentage",
                    desc = "Percent of healing that comes from Atonement",
                    hidden = function() return (not isDisciplinePriest) end,
                    min = 1, max = 100, step = 1,
                    width = "full",
                    get = function() return DB.atonementHealing end,
                    set = function(info, value) CantSim:UpdateAtonementHealing(value) end
                },
                scalingLeech = {
                    order = 2,
                    cmdHidden = true,
                    type = "toggle",
                    name = "Use Scaling Leech",
                    desc = "Checking this uses a scaling leech formula based on current leech rating",
                    get = function() return (DB.scalingLeechBool) end,
                    set = function(_, newValue) DB.scalingLeechBool = newValue; end,
                },
                leech = {
                    order = 3,
                    cmdHidden = true,
                    type = "range",
                    name = "Leech Weight",
                    desc = "Weighted amount for leech",
                    width = "double",
                    min = 0, max = 3, step = .01,
                    hidden = function() return (DB.scalingLeechBool) end,
                    get = function() return DB.leechPawn end,
                    set = function(info, value) CantSim:UpdateLeechWeight(value) end,
                    width = "full"
                },
                avoidance = {
                    order = 5,
                    cmdHidden = true,
                    type = "range",
                    name = "Avoidance Weight",
                    desc = "Weighted amount for avoidance",
                    min = 0, max = 3, step = .01,
                    get = function() return DB.avoidancePawn end,
                    set = function(info, value) CantSim:UpdateAvoidanceWeight(value) end,
                    width = "full"
                },
            }
        }    
    },
}

function CantSim:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(addonName, defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options, "cs", "cantsim")

    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
    self.db.RegisterCallback(self, "OnProfileChanged", "Reset")
	self.db.RegisterCallback(self, "OnProfileCopied", "Reset")
	self.db.RegisterCallback(self, "OnProfileReset", "Reset")
    self.db.RegisterCallback(self, "OnDatabaseReset", "Reset")
    

    DB = self.db.profile.DB
end