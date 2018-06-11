Broadcaster = {}
Broadcaster.__index = Broadcaster

function Broadcaster:new(app, db)
    local self = {}
    setmetatable(self, Broadcaster)
    self.app = app
    self.db = db
    return self
end

function Broadcaster:UpdateDB(db)
    self.db = db
end

function Broadcaster:StartSession(name, players)
    self:SendBufferedMessage(format("Attendance check started (%s)", name))

    local message = "People on time: "
    for k, v in pairs(players) do
        message = message .. v.name .. " "
    end
    
    self:SendBufferedMessage(message)
    self:SendBufferedMessage("Whisper to be added to the list")
end

function Broadcaster:PeriodicCheck(players)
    self:SendBufferedMessage(format("Checking attendance"))

    local message = "People here: "
    for k, v in pairs(players) do
        message = message .. v.name .. " "
    end
    
    self:SendBufferedMessage(message)
    self:SendBufferedMessage("Whisper to be added to the list")
end

function Broadcaster:StopSession(players)
    self:SendBufferedMessage(format("Stopped attendance check"))

    local message = "People here: "
    for k, v in pairs(players) do
        message = message .. v.name .. " "
    end
    
    self:SendBufferedMessage(message)
    self:SendBufferedMessage("Thanks for coming!")
end

function Broadcaster:SendBufferedMessage(message)
    local switch = {
        ["GUILD"] = function(message) self:SendBufferedMessageGuild(message) end,
        ["DEBUG"] = function(message) self:SendBufferedMessagePrint(message) end,
    }
    if switch[self.db.type] then switch[self.db.type](message) end
end

function Broadcaster:SendBufferedMessagePrint(message)
    self.app:Print(message)
end

function Broadcaster:SendBufferedMessageGuild(message)
    SendChatMessage(message, "GUILD")
end