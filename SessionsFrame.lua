local AceDB = LibStub("AceDB-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local AceTimer = LibStub("AceTimer-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local Icon = LibStub("LibDBIcon-1.0")

SessionsFrame = {}
SessionsFrame.__index = SessionsFrame
function SessionsFrame:new(app)

    local container = AceGUI:Create("Frame")
    container.app = app
    container:SetTitle("Attendance")

    local header = AceGUI:Create("InlineGroup")
    container:AddChild(header)
    
    header:SetAutoAdjustHeight(false)
    header:SetHeight(100)
    header:SetRelativeWidth(1.0)
    
    local button = AceGUI:Create("Button")
    button:SetText("Start new session")
    button:SetCallback("OnClick", function()
        container.app:StartSession("Clickity")
    end)
    header:AddChild(button)

    local button = AceGUI:Create("Button")
    button:SetText("Stop session")
    button:SetCallback("OnClick", function()
        container.app:StopSession()
    end)
    header:AddChild(button)
    
    local list = AceGUI:Create("InlineGroup")
    list:SetLayout("Fill")
    list:SetAutoAdjustHeight(false)
    list:SetRelativeWidth(1.0)
    list:SetHeight(320)
    container:AddChild(list)
    
    local listScroll = AceGUI:Create("ScrollFrame")
    listScroll:SetLayout("List")
    list:AddChild(listScroll)

    local i = 1
    repeat
        local item = AceGUI:Create("InlineGroup")
        item:SetFullWidth(true)
        item:SetFullHeight(true)
        listScroll:AddChild(item)

        local title = AceGUI:Create("Label")
        title:SetText("Testing")
        item:AddChild(title)

        i = i + 1
    until(i >= 20)

    container:Hide()
    return container
end

