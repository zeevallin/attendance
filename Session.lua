Session = {}
Session.__index = Session

function Session:new(db, interval)
    local self = {}
    setmetatable(self, Session)

    self.db = db
    self.db.lastCheckTime = nil
    self.db.interval = interval
    self.db.checkID = nil
    self.db.checks = {}

    return self
end

function Session:load(db)
    local self = {}
    setmetatable(self, Session)

    self.db = db

    return self
end

function Session:CheckHasEnded(time)
    return time > self:GetNextCheckTime()
end

function Session:GetNextCheckTime()
    local nextCheckTime
    local interval = self.db.interval * 60
    if self.db.lastCheckTime then
        nextCheckTime = self.db.lastCheckTime + interval
    else
        nextCheckTime = self.db.startTime + interval
    end
    return nextCheckTime
end

function Session:NewCheckDB(time)
    local id = timeToID(time)
    self.db.checks[id] = {
        time = time,
        players = {},
    }
    return id, db
end

function Session:GetCheckDB(id)
    return self.db.checks[id]
end

function Session:GetCurrentCheckDB()
    if self.db.checkID then return self:GetCheckDB(self.db.checkID) end
end

function Session:AddPlayerToCurrentCheck(time, id, name, note)
    local db = self:GetCurrentCheckDB()
    if db then
        db.players[id] = {
            time = time,
            name = name,
            note = note,
        }
    end
end

function Session:PlayersForCurrentCheck()
    local db = self:GetCurrentCheckDB()
    if db then return db.players else return {} end
end

function Session:NewCheck(time, players, type)
    local id, db = self:NewCheckDB(time)
    self.db.checkID = id

    for idx, player in ipairs(players) do
        self:AddPlayerToCurrentCheck(time, player.id, player.name)
    end

    self.db.lastCheckTime = time
end

function Session:PeriodicCheck(time, players)
    self:NewCheck(time, players, "PERIODIC")
end

function Session:InitialCheck(players)
    self:NewCheck(self.db.startTime, players, "INITIAL")
end

function Session:End(time)
    self.db.checkID = nil
    self.db.endTime = time
end