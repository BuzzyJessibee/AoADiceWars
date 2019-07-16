-- Create our frame and name it.
local frame = CreateFrame("Frame", "DiceWarsFrame", UIParent, "BasicFrameTemplate")
local attackButton = CreateFrame("Button", "AttackButton", frame, "UIPanelButtonTemplate")
local defendButton = CreateFrame("Button", "DefendButton", frame, "UIPanelButtonTemplate")
local rezButton = CreateFrame("Button", "RezButton", frame, "UIPanelButtonTemplate")
local healButton = CreateFrame("Button", "HealButton", frame, "UIPanelButtonTemplate")
frame.memberCount = frame:CreateFontString("memberCountString", "OVERLAY", "GameFontNormal")
local PC_Dropdown = LibStub("PhanxConfig-Dropdown");
local playerName = UnitName('player');
local DPSRoll = 0
local DPSRollAdd = 0
local TankRoll = 0
local TankRollADD = 0
local HealerRoll = 0
local RezRoll = 0

--Make a title for the window!
frame.TitleText:SetText("AoA Dice Wars")
frame.TitleText:SetPoint("TOP", frame, "TOP", 0, -6);
frame.TitleText:SetTextColor(0.8, 0, 0.8, 1);

--Make a table to store our data
	frame.data = { };

--Register when our addon is loaded so we can use SavedVariables, then if it doesn't exist, create it.
frame:RegisterEvent("ADDON_LOADED")

--Register group events so we can update the fontstring when people join and leave
frame:RegisterEvent("GROUP_JOINED")
frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AoADiceWars" then
		if not AoADiceWarsDB then AoADiceWarsDB = {} end;
		-- Delaying execution of setup until AoADiceWarsDB exists
		self:SetUpStuff();
	end
--Ask Blizz how many players are in the group. If we or a group member leave or join a group, update the text accordingly.
	if event == "GROUP_JOINED" or event == "GROUP_LEFT" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD"
	then 
		self.data.IsInGroup = IsInGroup()
		self.data.IsInRaid = IsInRaid()
		self.data.GroupMembers = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
		self.memberCount:SetText("There are " .. self.data.GroupMembers .. " players in your group!")	
		self.ISwearImInAGroup(); --change our text based on what kind of group we're in
	end
end)

--Make our frame draggable so that people can move it where they want it.
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop",function(self)
	self:StopMovingOrSizing()
end)
frame:SetClampedToScreen(true)

-- The code below makes the frame visible.
frame:SetPoint("CENTER")
frame:SetSize(320, 200)

--Make a dropdown using our new library we imported
local PlayerRole = PC_Dropdown:New(frame, 'Role', 'Choose your party role', 
{ { text = 'DPS', value = "DPS" }, 
  { text = 'Support', value = "SUPPORT" }, 
  { text = 'Tank', value = "TANK" } })
--Make it Show Up
PlayerRole:SetPoint("LEFT", frame, 10, 30)
--Tell a player when they change roles
PlayerRole.OnValueChanged = 
  function(self, value)
--Make these variables so that we can refer to them later
	frame.data.playerRole = value
	AoADiceWarsDB.playerRole = value
    print("Congrats! You are now a "  .. frame.data.playerRole or "nothing?! Dork" .. ".");
	frame.ShowTheHealers()
	frame.MakeTheHealButton();
  end;
PlayerRole:SetWidth(100);
  
--Make a dropdown for how many healers are in a group
local HealerCount = PC_Dropdown:New(frame, '# of Healers', 'Please choose how many healers there are.', 
{ { text = '1', value = 1 }, 
  { text = '2+', value = 2 } })
--Make it Show Up
HealerCount:SetPoint("RIGHT", frame, -10, 30)
--Tell a player when they change roles
HealerCount.OnValueChanged = 
  function(self, value)
--Make these variables so that we can refer to them later
	frame.data.healerCount = value
	AoADiceWarsDB.healerCount = value
    print("Number of healers set to "  .. frame.data.healerCount or "nothing?! Dork" .. ".");
  end;
HealerCount:SetWidth(100); 

--Show the HealerCount dropdown if we're a healer, else hide it because we don't need it.
function frame.ShowTheHealers()
	if frame.data.playerRole == "SUPPORT" or AoADiceWarsDB.playerRole == "SUPPORT"
	then HealerCount:Show()
	else HealerCount:Hide()
	end
end

--Use the fontstring to show the player how many players are in the current group
	frame.memberCount:SetWidth(200);

	frame.memberCount:SetPoint("TOP", frame, "TOP", 0, -30);
	
--Make The Attack Button
attackButton:SetSize(150, 22)
attackButton:SetPoint("BOTTOMLEFT", 10,10)
attackButton:SetText("Attack")

--Make The Defend Button
defendButton:SetSize(150, 22)
defendButton:SetPoint("BOTTOMRIGHT", -10,10)
defendButton:SetText("Defend")

--Make The Rez Button
rezButton:SetSize(300, 22)
rezButton:SetPoint("BOTTOMRIGHT", -10,35)
rezButton:SetText("Revive")

--Make the Heal Button
healButton:SetSize(100,22)
healButton:SetText("Heal")
healButton:SetPoint("BOTTOM", 0, 10)

--If we're a healer, add a heal button
function frame.MakeTheHealButton()
	if frame.data.playerRole == "SUPPORT" or AoADiceWarsDB.playerRole == "SUPPORT"
	then 
		attackButton:SetSize(100, 22)
		defendButton:SetSize(100, 22)
		healButton:Show()
	else
		healButton:Hide()
		defendButton:SetSize(150, 22)
		attackButton:SetSize(150, 22)
	end
end

--If the player is using TRP3 stylize their name
if TRP3_API then
    local function UpdatePlayerName()
        local currentUser = AddOn_TotalRP3.Player.GetCurrentUser();
        playerName = currentUser:GetRoleplayingName() or UnitName("player");
    end

    TRP3_API.events.registerCallback(TRP3_API.events.WORKFLOW_ON_FINISH, UpdatePlayerName);
    TRP3_API.events.registerCallback(TRP3_API.events.REGISTER_DATA_UPDATED, function(id)
        if id == TRP3_API.globals.player_id then
            UpdatePlayerName();
        end
    end);
end

--If the player is using MRP, stylize their name (ily Oraibi & Katorie)
if msp and not TRP3_API then table.insert(msp.callback.received,
	function(u) 
		if msp.my.NA ~= playerName
		then playerName = msp.my.NA
	  end;
	end);
end;
	

--When we click the button, adjust the rolls based on our role
attackButton:SetScript("OnClick", function(self)
	if frame.data.playerRole == "DPS" or AoADiceWarsDB.playerRole == "DPS"
		then 
			DPSRoll = math.random(20)
			DPSRollAdd = DPSRoll + 2
		if DPSRoll == 19 or DPSRoll == 20
			then  
				SendChatMessage(playerName.. " attacks by rolling " .. DPSRoll .. " + 2 to get " ..DPSRollAdd .. "! CRITICAL HIT!", frame.data.PartyType);
		else 
			SendChatMessage(playerName.." attacks by rolling " .. DPSRoll .. " + 2 to get " ..DPSRollAdd .. "!", frame.data.PartyType);
		end
	elseif  frame.data.playerRole == "TANK" or AoADiceWarsDB.playerRole == "TANK"
		then 
			TankRoll = math.random(20)
		if TankRoll == 20
			then SendChatMessage(playerName.." attacks by rolling " .. TankRoll .. "! CRITICAL HIT!", frame.data.PartyType);
		else
			SendChatMessage(playerName.." attacks by rolling " .. TankRoll .. "!", frame.data.PartyType);
		end
	elseif frame.data.playerRole == "SUPPORT" or AoADiceWarsDB.playerRole == "SUPPORT"
		then 
			HealerRoll = math.random(20)
		if HealerRoll == 20
			then SendChatMessage(playerName.." attacks by rolling " .. HealerRoll .. "! CRITICAL HIT!", frame.data.PartyType);
		else
			SendChatMessage(playerName.." attacks by rolling " .. HealerRoll .. "!", frame.data.PartyType);
		end			
	else print("Set a role!");
	end
end)

--When we click the button, adjust the rolls based on our role
defendButton:SetScript("OnClick", function(self)
	if frame.data.playerRole == "DPS" or AoADiceWarsDB.playerRole == "DPS"
		then 
			DPSRoll = math.random(20)
		if DPSRoll == 20
			then SendChatMessage(playerName.." defends by rolling " .. DPSRoll .. "! CRITICAL COUNTER!", frame.data.PartyType);
		else
			SendChatMessage(playerName.." defends by rolling " .. DPSRoll .. "!", frame.data.PartyType);
		end				
	elseif  frame.data.playerRole == "TANK" or AoADiceWarsDB.playerRole == "TANK"
		then 
			TankRoll = math.random(20)
			TankRollADD = TankRoll + 2
		if TankRoll == 19 or TankRoll == 20
			then 
			SendChatMessage(playerName.." defends by rolling " .. TankRoll .. " + 2 to get " ..TankRollADD .. "! CRITICAL COUNTER!", frame.data.PartyType);
		else 
			SendChatMessage(playerName.." defends by rolling " .. TankRoll .. " + 2 to get " ..TankRollADD .. "!", frame.data.PartyType);
		end
	elseif frame.data.playerRole == "SUPPORT" or AoADiceWarsDB.playerRole == "SUPPORT"
		then 
			HealerRoll = math.random(20)
		if HealerRoll == 20
			then SendChatMessage(playerName.." defends by rolling " .. HealerRoll .. "! CRITICAL COUNTER!", frame.data.PartyType);
		else
			SendChatMessage(playerName.." defends by rolling " .. HealerRoll .. "!", frame.data.PartyType);
		end	
	else print("Set a role!");
	end
end)

rezButton:SetScript("OnClick", function(self)
	RezRoll = math.random(100)
	SendChatMessage(playerName.." attempts to rez by rolling " .. RezRoll .. "!", frame.data.PartyType);
end)

--When we click the button, run the function HealerDiceRoll() to get our roll.
healButton:SetScript("OnClick", function(self)
	if frame.data.playerRole == "SUPPORT" or AoADiceWarsDB.playerRole == "SUPPORT"
	then 
		frame.HealerDiceRoll();
	else
		print("No one should see this");
	end
end)

--Make a Slash Command so that we can open the frame again without reloading
SLASH_AOA1 = '/aoa';
function SlashCmdList.AOA(msg, editBox)
	if not frame:IsVisible()
		then frame:Show()
		else frame:Hide()
	end
end
--Make a Slash Command so that we can print what version the user currently has in the chat
SLASH_VER1 = '/aoaver'
function SlashCmdList.VER(msg, editBox)
	print("You're running |cFF9370DBversion 1.1 - Initial TRP Support!|r")
end

-- Delaying execution of setup until AoADiceWarsDB exists
function frame:SetUpStuff()
  PlayerRole:SetValue(AoADiceWarsDB.playerRole);
  HealerCount:SetValue(AoADiceWarsDB.healerCount);
  frame.ShowTheHealers();
  frame.MakeTheHealButton();
  print("[|cFF9370DBAoA|r] Thanks for using AoA DiceWars! You're on |cFF9370DBversion 1.2!|r");
  print("[|cFF9370DBAoA|r] If you close the window, type |cFF9370DB/aoa|r to reopen it")
end;

function frame.HealerDiceRoll()
	if AoADiceWarsDB.healerCount == 1 or frame.data.healerCount == 1 
		then
			if frame.data.GroupMembers <= 5 
				then HealerRoll = math.random(1,4)
					SendChatMessage(playerName.." rolled " .. HealerRoll .. " points for healing!", frame.data.PartyType);
			elseif frame.data.GroupMembers > 5 and frame.data.GroupMembers <= 8
				then HealerRoll = math.random(2,5)
					 SendChatMessage(playerName.." rolled " .. HealerRoll .. " points for healing!", frame.data.PartyType);
			elseif frame.data.GroupMembers > 8 and frame.data.GroupMembers <= 10
				then HealerRoll = math.random(3,6)
					SendChatMessage(playerName.." rolled " .. HealerRoll .. " points for healing!", frame.data.PartyType);
			elseif frame.data.GroupMembers > 10
				then 
					print("You can't heal this many people by yourself!");	
			end
	elseif AoADiceWarsDB.healerCount == 2 or frame.data.healerCount == 2
		then HealerRoll = math.random(1,4)
			SendChatMessage(playerName.." rolled " .. HealerRoll .. " points for healing!", frame.data.PartyType);
					
	else print("Please enter a number of healers!")
	end
end

function frame.ISwearImInAGroup()
	if frame.data.IsInGroup == true and frame.data.IsInRaid == false
	then frame.data.PartyType = "PARTY"
	elseif frame.data.IsInRaid == true
	then frame.data.PartyType = "RAID"
	elseif frame.data.IsInGroup == false and frame.data.IsInRaid == false
	then frame.data.PartyType = "SAY"
	end
end