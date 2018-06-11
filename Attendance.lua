local AceDB = LibStub("AceDB-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceTimer = LibStub("AceTimer-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local Icon = LibStub("LibDBIcon-1.0")

local ATTENDANCE_DB_NAME = "AttendanceDB"

local App = LibStub("AceAddon-3.0"):NewAddon("Attendance", "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0")

local AppLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Attendance", {
	type = "data source",
    text = "Attendance",
	icon = "Interface/Icons/INV_Misc_ScrollRolled01b",
    OnClick = function(event, button)
        local options = {
            ["LeftButton"] = function()
                App:ToggleSessionsFrame()
            end,
            ["RightButton"] = function()
                App:OpenOptions()
            end,
        }

        if options[button] then options[button]() end
    end,
    OnTooltipShow = function(tooltip)
        if App.session then
            tooltip:SetText("Attendance (Session Active)")
        else
            tooltip:SetText("Attendance")
        end

        tooltip:AddLine("Light weight attendance tracker", 1, 1, 1)

        tooltip:AddDoubleLine("Left click", "Manage session")
        tooltip:AddDoubleLine("Right click", "Configure")
        
        tooltip:Show()
    end,
})

function AppLDB:SetActive()
    self.icon = "Interface/Icons/INV_Misc_ScrollRolled03d"
end

function AppLDB:SetInactive()
    self.icon = "Interface/Icons/INV_Misc_ScrollRolled01b"
end

App.defaults = {
    profile = {
        enabled = true,
        interval = 30,
        countOfflineRaidMembers = true,
        broadcast = {
            type = "GUILD",
            channel = nil,
        },
        minimap = {
            hide = false,
        },
    },
    char = {
        session = nil,
    },
    global = {
        sessions = {}
    }
}

App.options = {
    type = "group",
    name = "Attendance",
    args = {
        enable = {
            name = "Enable",
            desc = "Toggles the addon on and off",
            descStyle = "inline",
            width = "full",
            type = "toggle",
            order = 1,
            set = function(info, val)
                App.db.profile.enabled = val
                if val then App:Enable() else App:Disable() end
            end,
            get = function(info)
                return App.db.profile.enabled
            end
        },
        minimapIcon = {
            name = "Hide Minimap Icon",
            desc = "Toggles the visibility of the minimap icon",
            descStyle = "inline",
            width = "full",
            order = 2,
            type = "toggle",
            set = function(info, val)
                App.db.profile.minimap.hide = val
                if val then Icon:Hide("Attendance") else Icon:Show("Attendance") end
            end,
            get = function(info)
                return App.db.profile.minimap.hide
            end
        },
        start = {
            name = "Start",
            desc = "Starts a new session",
            guiHidden = true,
            type = "execute",
            func = function()
                App:StartSession("Raid")
            end,
        },
        stop = {
            name = "Stop",
            desc = "Stops the current session",
            guiHidden = true,
            type = "execute",
            func = function()
                App:StopSession()
            end,
        },
        config = {
            name = "Config",
            desc = "Opens the configuration screen",
            guiHidden = true,
            type = "execute",
            func = function()
                App:OpenOptions()
            end,
        },
        configuration = {
            name = "Configuration",
            desc = "General configuratio",
            type = "group",
            order = 3,
            args = {
                ignoreOnline = {
                    name = "Count offline raid members",
                    desc = "Use to restrict who gets counted when performing attendance checkups.",
                    descStyle = "inline",
                    width = "full",
                    order = 1,
                    type = "toggle",
                    set = function(info, val)
                        App.db.profile.countOfflineRaidMembers = val
                    end,
                    get = function(info)
                        return App.db.profile.countOfflineRaidMembers
                    end
                },
                intervalHeader = {
                    name = "Interval",
                    type = "header",
                    width = "full",
                    order = 2,
                },
                intervalDesc = {
                    name = "Time in minutes between attendance checks",
                    fontSize = "medium",
                    type = "description",
                    width = "full",
                    order = 3,
                },
                interval = {
                    name = "",
                    type = "range",
                    width = "full",
                    order = 4,
                    min = 1,
                    softMin = 5,
                    max = 120,
                    softMax = 60,
                    step = 5,
                    set = function(info, val)
                        App.db.profile.interval = val
                    end,
                    get = function(info)
                        return App.db.profile.interval
                    end
                },
            },
        },
        broadcast = {
            name = "Broadcast",
            desc = "Broadcast options",
            type = "group",
            order = 4,
            args = {
                channel = {
                    name = "Channel",
                    type = "select",
                    width = "full",
                    order = 2,
                    values = {
                        ["GUILD"] = "Guild chat",
                        ["DEBUG"] = "Print to chat (Debug)",
                    },
                    set = function(info, val)
                        App.opt.broadcast.type = val
                        App.broadcast:UpdateDB(App.opt.broadcast)
                    end,
                    get = function(info)
                        return App.opt.broadcast.type
                    end
                },
            },
        }
    }
}

function App:CHAT_MSG_WHISPER(name, msg, author)
    if self.session then

        local id = author
        local time = GetTime()

        m = split(author, "-")
        local name = m[1]

        self.session:AddPlayerToCurrentCheck(time, id, name, msg)

        self:Print("Added player", name, "to attendance check")
    end
end

function App:GetSessionsFrame()
    if self.sessionsFrame then return self.sessionsFrame end
    self.sessionsFrame = SessionsFrame:new(self)
    return self.sessionsFrame
end

function App:ToggleSessionsFrame()
    local frame = App:GetSessionsFrame()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function App:NewSessionDB()
    local time = GetTime()
    local id = time * 1000
    local db = {
        startTime = time,
        endTime = nil,
    }
    self.db.global.sessions[id] = db
    return id, db
end

function App:GetSessionDB(id)
    return self.db.global.sessions[id]
end

function App:GetCurrentSessionDB()
    local id = self.db.char.sessionID
    if id then return self:GetSessionDB(id) end
end

function App:ToggleSession(name)
    if self.session then self:StopSession()
    else self:StartSession(name)
    end
end

function App:GetPlayers()
    local players = {}
    local max = 1

    if UnitInRaid("player") then max = MAX_RAID_MEMBERS
    elseif UnitInParty("player") then max = MAX_PARTY_MEMBERS + 1
    else
        name, _ = UnitFullName("player")
        local id = formatNameID(name)
        table.insert(players, {
            id = id,
            name = name,
        })
        return players
    end

    for i = 1, max do
        local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        if name then
            if not (not self.opt.countOfflineRaidMembers and not online) then
                local id = formatNameID(name)
                table.insert(players, {
                    id = id,
                    name = name,
                })
            end
        end
    end

    return players
end

function App:StartSession(name)
    if not self.session then
        
        local id, db = self:NewSessionDB()

        self.session = Session:new(db, self.opt.interval)
        self.db.char.sessionID = id

        self.session:InitialCheck(self:GetPlayers())

        self:RegisterEvent("CHAT_MSG_WHISPER")
        AppLDB:SetActive()

        local players = self.session:PlayersForCurrentCheck()
        self.broadcast:StartSession(name, players)

        self:Print("A new session has been started")
    else
        self:Print("A session is already in progress")
    end
end

function App:StopSession()
    if self.session then

        local time = GetTime()
        local players = self.session:PlayersForCurrentCheck()
        self.session:End(time)
        self.broadcast:StopSession(players)
        self:ClearSessionData()
        self:UnregisterEvent("CHAT_MSG_WHISPER")
        AppLDB:SetInactive()

        self:Print("The session has ended")
    else
        self:Print("No session available to stop")
    end
end

function App:ResumeSession()
    local db = self:GetCurrentSessionDB()
    if not self.session and db then
        self.session = Session:load(db)
        self:RegisterEvent("CHAT_MSG_WHISPER")
        AppLDB:SetActive()
        self:Print("The session has been resumed")
    else
        self:ClearSessionData()
        self:Print("No session to resume")
    end
end

function App:ClearSessionData()
    self.session = nil
    self.db.char.sessionID = nil
end

function App:StartTicker()
    if not self.ticker then
        self.ticker = self:ScheduleRepeatingTimer("TickerHandler", 1)
    end
    return self.ticker
end

function App:StopTicker()
    if self.ticker then
        self:CancelTimer(self.ticker)
    end
    self.ticker = nil
end

function App:TickerHandler()
    local time = GetTime()
    if self.session then
        if self.session:CheckHasEnded(time) then
            self.session:PeriodicCheck(time, self:GetPlayers())
            local players = self.session:PlayersForCurrentCheck()
            self.broadcast:PeriodicCheck(players)
        end
    end
end

function App:OnEnable()
    if not self.opt.enabled then
		self:Disable()
		return
    end

    self:ResumeSession()
    self:StartTicker()
end

function App:OnDisable()
    self:StopTicker()
    self:StopSession()
end

function App:OnProfileEnable(event, database, newProfileKey)
    self.opt = database.profile
    self.broadcast:UpdateDB(self.opt.broadcast)
    if not self.opt.enabled then
		self:Disable()
    end
end

function App:OpenOptions()
    -- Need to call twice in a row because of a synchronicity bug in blizzard config UI
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function App:SlashCommandHandler(input)
    if not input or input:trim() == "" then
        App:ToggleSessionsFrame()
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(App, "att", "AttendanceOptions", input)
    end
end

function App:OnInitialize()
    -- Register and setup saved variables
    self.db = AceDB:New(ATTENDANCE_DB_NAME, self.defaults, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileEnable")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileEnable")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileEnable")
    self.opt = self.db.profile
    self.options.args.profiles = AceDBOptions:GetOptionsTable(self.db)
    self.options.args.profiles.order = -1

    -- Initialize message broadcaster
    self.broadcast = Broadcaster:new(self, self.db.profile.broadcast)

    -- Register AddOn configuration window
    AceConfigRegistry:RegisterOptionsTable("AttendanceOptions", self.options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AttendanceOptions", "Attendance")

    -- Register minimap icon
    Icon:Register("Attendance", AppLDB, self.db.profile.minimap)
end

App:RegisterChatCommand("att", "SlashCommandHandler")
App:RegisterChatCommand("attendance", "SlashCommandHandler")
