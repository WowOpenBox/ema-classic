-- ================================================================================ --
--				EMA - ( Ebony's MultiBoxing Assistant )    							--
--				Current Author: Jennifer Cally (Ebony)								--
--																					--
--				License: All Rights Reserved 2018-2020 Jennifer Cally					--
--																					--
--				Some Code Used from "Jamba" that is 								--
--				Released under the MIT License 										--
--				"Jamba" Copyright 2008-2015  Michael "Jafula" Miller				--
--																					--
-- ================================================================================ --

-- Create the addon using AceAddon-3.0 and embed some libraries.
local EMA = LibStub( "AceAddon-3.0" ):NewAddon( 
	"DisplayTeam",
	"Module-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

-- Load libraries.
local EMAUtilities = LibStub:GetLibrary( "EbonyUtilities-1.0" )
local EMAHelperSettings = LibStub:GetLibrary( "EMAHelperSettings-1.0" )
local LibBagUtils = LibStub:GetLibrary( "LibBagUtils-1.0" )
local LibButtonGlow = LibStub:GetLibrary( "LibButtonGlow-1.0")
EMA.SharedMedia = LibStub( "LibSharedMedia-3.0" )

-- Constants required by EMAModule and Locale for this module.
EMA.moduleName = "JmbDspTm"
EMA.settingsDatabaseName = "DisplayTeamProfileDB"
EMA.chatCommand = "ema-display-team"
local L = LibStub( "AceLocale-3.0" ):GetLocale( "Core" )
EMA.parentDisplayName = L["DISPLAY"]
EMA.moduleDisplayName = L["DISPLAY"]
-- Icon 
EMA.moduleIcon = "Interface\\Addons\\EMA-Classic\\Media\\TeamCore.tga"
-- order
EMA.moduleOrder = 50

-- Settings - the values to store and their defaults for the settings database.
EMA.settings = {
	profile = {
		showTeamList = true,
		showTeamListOnMasterOnly = false,
		hideTeamListInCombat = false,
		enableClique = false,
		statusBarTexture = L["BLIZZARD"],
		borderStyle = L["BLIZZARD_TOOLTIP"],
		backgroundStyle = L["BLIZZARD_DIALOG_BACKGROUND"],
		fontStyle = L["ARIAL_NARROW"],
		fontSize = 12,
		teamListScale = 1,
		teamListTitleHeight = 15,
		teamListVerticalSpacing = 3,
		teamListHorizontalSpacing = 6,
		barVerticalSpacing = 2,
		barHorizontalSpacing = 2,
		charactersPerRow = 1,
		--Old code kept for Legacy Purpose
		barsAreStackedVertically = false,
		teamListHorizontal = true,
		showListTitle = true,
		olnyShowInParty = false,
		healthManaOutOfParty = false,
		showCharacterPortrait = false,
		characterPortraitWidth = 80,
		showFollowStatus = true,
		followStatusWidth = 100,
		followStatusHeight = 15,
		followStatusShowName = true,
		showExperienceStatus = true,
		showXpStatus = true,
		showHonorStatus = false,
		showRepStatus = false,
		experienceStatusWidth = 100,
		experienceStatusHeight = 15,
		experienceStatusShowValues = false,
		experienceStatusShowPercentage = true,		
		showHealthStatus = false,
		showClassColors = false,
		healthStatusWidth = 100,
		healthStatusHeight = 25,
		healthStatusShowValues = true,
		healthStatusShowPercentage = true,		
		showPowerStatus = false,
		powerStatusWidth = 100,
		powerStatusHeight = 15,
		powerStatusShowValues = true,
		powerStatusShowPercentage = true,
		showComboStatus = false,
		comboStatusWidth = 100,
		comboStatusHeight = 10,
		comboStatusShowValues = true,
		comboStatusShowPercentage = true,		
		showToolTipInfo = false,
--		ShowEquippedOnly = false,
		framePoint = "LEFT",
		frameRelativePoint = "LEFT",
		frameXOffset = 0,
		frameYOffset = 30,
		frameAlpha = 1.0,
		frameBackgroundColourR = 1.0,
		frameBackgroundColourG = 1.0,
		frameBackgroundColourB = 1.0,
		frameBackgroundColourA = 1.0,
		frameBorderColourR = 1.0,
		frameBorderColourG = 1.0,
		frameBorderColourB = 1.0,
		frameBorderColourA = 1.0,
		timerCount = 1,
		currGold = true
	},
}

-- Debug message.
function EMA:DebugMessage( ... )
	--EMA:Print( ... )
end

-- Configuration.
function EMA:GetConfiguration()
	local configuration = {
		name = EMA.moduleDisplayName,
		handler = EMA,
		type = "group",
		get = "EMAConfigurationGetSetting",
		set = "EMAConfigurationSetSetting",
		args = {	
			config = {
				type = "input",
				name = L["OPEN_CONFIG"],
				desc = L["OPEN_CONFIG_HELP"],
				usage = "/ema-display config",
				get = false,
				set = "",				
			},
			push = {
				type = "input",
				name = L["PUSH_SETTINGS"],
				desc = L["PUSH_SETTINGS_INFO"],
				usage = "/ema-display-team push",
				get = false,
				set = "EMASendSettings",
			},	
			hide = {
				type = "input",
				name = L["HIDE_TEAM_DISPLAY"],
				desc = L["HIDE_TEAM_DISPLAY_HELP"],
				usage = "/ema-display-team hide",
				get = false,
				set = "HideTeamListCommand",
			},	
			show = {
				type = "input",
				name = L["SHOW_TEAM_DISPLAY"],
				desc = L["SHOW_TEAM_DISPLAY_HELP"],
				usage = "/ema-display-team show",
				get = false,
				set = "ShowTeamListCommand",
			},				
		},
	}
	return configuration
end

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------

EMA.COMMAND_FOLLOW_STATUS_UPDATE = "FlwStsUpd"
EMA.COMMAND_EXPERIENCE_STATUS_UPDATE = "ExpStsUpd"
EMA.COMMAND_REPUTATION_STATUS_UPDATE = "RepStsUpd"
EMA.COMMAND_COMBO_STATUS_UPDATE = "CboStsUpd"
EMA.COMMAND_REQUEST_INFO = "SendInfo"
EMA.COMMAND_COMBAT_STATUS_UPDATE = "InComStsUpd"
EMA.COMMAND_POWER_STATUS_UPDATE = "PowStsUpd"
EMA.COMMAND_HEALTH_STATUS_UPDATE = "heaStsUpd"											  

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Constants used by module.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Variables used by module.
-------------------------------------------------------------------------------------------------------------

-- Team display variables.
EMA.globalFramePrefix = "EMADisplayTeam"
EMA.characterStatusBar = {}
EMA.totalMembersDisplayed = 0
EMA.teamListCreated = false	
EMA.refreshHideTeamListControlsPending = false
EMA.refreshShowTeamListControlsPending = false
EMA.updateSettingsAfterCombat = false

-------------------------------------------------------------------------------------------------------------
-- Team Frame.
-------------------------------------------------------------------------------------------------------------

local function GetCharacterHeight()
	local height = 0
	local heightPortrait = 0
	local heightFollowStatus = 0
	local heightExperienceStatus = 0
	local heightHealthStatus = 0
	local heightPowerStatus = 0
	local heightComboStatus = 0		
	local heightAllBars = 0
	if EMA.db.showCharacterPortrait == true then
		heightPortrait = EMA.db.characterPortraitWidth + EMA.db.teamListVerticalSpacing
	end
	if EMA.db.showFollowStatus == true then
		heightFollowStatus = EMA.db.followStatusHeight + EMA.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightFollowStatus
	end
	if EMA.db.showExperienceStatus == true then
		heightExperienceStatus = EMA.db.experienceStatusHeight + EMA.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightExperienceStatus
	end	
	if EMA.db.showHealthStatus == true then
		heightHealthStatus = EMA.db.healthStatusHeight + EMA.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightHealthStatus
	end
	if EMA.db.showPowerStatus == true then
		heightPowerStatus = EMA.db.powerStatusHeight + EMA.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightPowerStatus
	end
	if EMA.db.showComboStatus == true then
		heightComboStatus = EMA.db.comboStatusHeight + EMA.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightComboStatus
	end	
	if EMA.db.barsAreStackedVertically == true then
		height = max( heightPortrait, heightAllBars )
	
	else
		height = max( heightPortrait, heightFollowStatus, heightExperienceStatus, heightHealthStatus, heightPowerStatus, heightComboStatus )
		--height = max( heightPortrait, heightBagInformation, heightFollowStatus, heightExperienceStatus, heightReputationStatus, heightHealthStatus, heightPowerStatus, heightComboStatus )
	end
	return height
end

local function GetCharacterWidth()
	local width = 0
	local widthPortrait = 0
	local widthFollowStatus = 0
	local widthExperienceStatus = 0
	local widthHealthStatus = 0
	local widthPowerStatus = 0
	local widthComboStatus = 0	
	local widthAllBars = 0
	if EMA.db.showCharacterPortrait == true then
		widthPortrait = EMA.db.characterPortraitWidth + EMA.db.teamListHorizontalSpacing
	end
	if EMA.db.showFollowStatus == true then
		widthFollowStatus = EMA.db.followStatusWidth + EMA.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthFollowStatus
	end
	if EMA.db.showExperienceStatus == true then
		widthExperienceStatus = EMA.db.experienceStatusWidth + EMA.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthExperienceStatus		
	end
	if EMA.db.showHealthStatus == true then
		widthHealthStatus = EMA.db.healthStatusWidth + EMA.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthHealthStatus		
	end	
	if EMA.db.showPowerStatus == true then
		widthPowerStatus = EMA.db.powerStatusWidth + EMA.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthPowerStatus		
	end
	if EMA.db.showComboStatus == true then
		widthComboStatus = EMA.db.comboStatusWidth + EMA.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthComboStatus		
	end
	if EMA.db.barsAreStackedVertically == true then
		width = widthPortrait + max( widthFollowStatus, widthExperienceStatus, widthHealthStatus, widthPowerStatus, widthComboStatus )
		--width = widthPortrait + max( widthBagInformation, widthFollowStatus, widthExperienceStatus, widthReputationStatus, widthHealthStatus, widthPowerStatus, widthComboStatus )
	else
		width = widthPortrait + widthAllBars
	end
	return width
end

local function UpdateEMATeamListDimensions()
	local frame = EMADisplayTeamListFrame
	if EMA.db.showListTitle == true then
		EMA.db.teamListTitleHeight = 15
		EMADisplayTeamListFrame.titleName:SetText( L["EMA_TEAM"] )
	else
		EMA.db.teamListTitleHeight = 0
		EMADisplayTeamListFrame.titleName:SetText( "" )
	end
	if EMA.db.teamListHorizontal == true then
		--Old code kept for Legacy Purpose
		--	frame:SetWidth( (EMA.db.teamListVerticalSpacing * 3) + (GetCharacterWidth() * EMA.totalMembersDisplayed) )
		--	frame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() )
	else
		frame:SetWidth( (EMA.db.teamListHorizontalSpacing * 3) + GetCharacterWidth() )
		frame:SetHeight( EMA.db.teamListTitleHeight + (GetCharacterHeight() * EMA.totalMembersDisplayed) + (EMA.db.teamListVerticalSpacing * 3) )
	end
	frame:SetScale( EMA.db.teamListScale )
end

local function CreateEMATeamListFrame()
	-- The frame.
	local frame = CreateFrame( "Frame", "EMADisplayTeamListWindowFrame", UIParent )
	frame.obj = EMA
	frame:SetFrameStrata( "LOW" )
	frame:SetToplevel( true )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( true )
	frame:SetMovable( true )	
	frame:RegisterForDrag( "LeftButton" )
	frame:SetScript( "OnDragStart", 
		function( this ) 
			if IsAltKeyDown() then
				if not UnitAffectingCombat("player") then		
					-- TODO: SO ARROW ICON ON MOUDE
					this:StartMoving()
				end	
			end
		end )
	frame:SetScript( "OnDragStop", 
		function( this ) 
			this:StopMovingOrSizing() 
			local point, relativeTo, relativePoint, xOffset, yOffset = this:GetPoint()
			EMA.db.framePoint = point
			EMA.db.frameRelativePoint = relativePoint
			EMA.db.frameXOffset = xOffset
			EMA.db.frameYOffset = yOffset
		end	)	
	frame:ClearAllPoints()
	frame:SetPoint( EMA.db.framePoint, UIParent, EMA.db.frameRelativePoint, EMA.db.frameXOffset, EMA.db.frameYOffset )
	frame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = true, tileSize = 10, edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	-- Create the title for the team list frame.
	local titleName = frame:CreateFontString( "EMADisplayTeamListWindowFrameTitleText", "OVERLAY", "GameFontNormal" )
	titleName:SetPoint( "TOP", frame, "TOP", 0, -5 )
	titleName:SetTextColor( 1.00, 1.00, 1.00 )
	titleName:SetText( L["EMA_TEAM"] )
	frame.titleName = titleName
	-- Set transparency of the the frame (and all its children).
	frame:SetAlpha(EMA.db.frameAlpha)
	
	-- Set the global frame reference for this frame.
	EMADisplayTeamListFrame = frame
	
	EMA:SettingsUpdateBorderStyle()	
	EMA.teamListCreated = true

end

local function CanDisplayTeamList()
	local canShow = false
	if EMA.db.showTeamList == true then
		if EMA.db.showTeamListOnMasterOnly == true then
			if EMAApi.IsCharacterTheMaster( EMA.characterName ) == true then
				canShow = true
			end
		else
			canShow = true
		end
	end
	return canShow
end

function EMA:ShowTeamListCommand()
	EMA.db.showTeamList = true
	EMA:SetTeamListVisibility()
end

function EMA:HideTeamListCommand()
	EMA.db.showTeamList = false
	EMA:SetTeamListVisibility()
end

function EMA:SetTeamListVisibility()
	if CanDisplayTeamList() == true then
		EMADisplayTeamListFrame:ClearAllPoints()
		EMADisplayTeamListFrame:SetPoint( EMA.db.framePoint, UIParent, EMA.db.frameRelativePoint, EMA.db.frameXOffset, EMA.db.frameYOffset )
		EMADisplayTeamListFrame:SetAlpha( EMA.db.frameAlpha )
		EMADisplayTeamListFrame:Show()
	else
		EMADisplayTeamListFrame:Hide()
	end	
end

function EMA:RefreshTeamListControlsHide()
	if InCombatLockdown() then
		EMA.refreshHideTeamListControlsPending = true
		return
	end
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do	
		characterName = EMAUtilities:AddRealmToNameIfMissing ( characterName ) 
		-- Hide their status bar.
		EMA:HideEMATeamStatusBar( characterName )		
	end
	UpdateEMATeamListDimensions()
end

function EMA:RefreshTeamListControlsShow()
	if InCombatLockdown() then
		EMA.refreshShowTeamListControlsPending = true
		return
	end

	EMA.totalMembersDisplayed = 0
	for index, characterName in EMAApi.TeamListOrdered() do
		characterName = EMAUtilities:AddRealmToNameIfMissing ( characterName )
		-- Is the team member online?
	if EMAApi.GetCharacterOnlineStatus( characterName ) == true then
		-- Checks the player is the party to hide the bar if needed.
			if EMA.db.olnyShowInParty == true then
				if UnitClass(Ambiguate( characterName, "none" ) ) then
				-- Yes, the team member is online, draw their status bars.
					EMA:UpdateEMATeamStatusBar( characterName, EMA.totalMembersDisplayed )		
					EMA.totalMembersDisplayed = EMA.totalMembersDisplayed + 1
				end
			else
					EMA:UpdateEMATeamStatusBar( characterName, EMA.totalMembersDisplayed )		
					EMA.totalMembersDisplayed = EMA.totalMembersDisplayed + 1			
			end
		end
	end
	UpdateEMATeamListDimensions()	
end
	
function EMA:RefreshTeamListControls()
	EMA:RefreshTeamListControlsHide()
	EMA:RefreshTeamListControlsShow()
end

function EMA:SettingsUpdateStatusBarTexture()
	local statusBarTexture = EMA.SharedMedia:Fetch( "statusbar", EMA.db.statusBarTexture )
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do	
		characterStatusBar["followBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["followBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["followBar"]:GetStatusBarTexture():SetVertTile( false )		
		characterStatusBar["experienceBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["experienceBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["experienceBar"]:GetStatusBarTexture():SetVertTile( false )	
		characterStatusBar["reputationBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["reputationBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["reputationBar"]:GetStatusBarTexture():SetVertTile( false )		
		characterStatusBar["healthBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["healthBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["healthBar"]:GetStatusBarTexture():SetVertTile( false )				
		characterStatusBar["powerBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["powerBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["powerBar"]:GetStatusBarTexture():SetVertTile( false )
		characterStatusBar["comboBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["comboBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["comboBar"]:GetStatusBarTexture():SetVertTile( false )
	end
end

function EMA:SettingsUpdateFontStyle()
	local textFont = EMA.SharedMedia:Fetch( "font", EMA.db.fontStyle )
	local textSize = EMA.db.fontSize
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do	
		characterStatusBar["followBarText"]:SetFont( textFont , textSize , "OUTLINE")		
		characterStatusBar["experienceBarText"]:SetFont( textFont , textSize , "OUTLINE")
		characterStatusBar["reputationBarText"]:SetFont( textFont , textSize , "OUTLINE")
		characterStatusBar["healthBarText"]:SetFont( textFont , textSize , "OUTLINE")
		characterStatusBar["powerBarText"]:SetFont( textFont , textSize , "OUTLINE")
		characterStatusBar["comboBarText"]:SetFont( textFont , textSize , "OUTLINE")

	end
end

function EMA:SettingsUpdateBorderStyle()
	local borderStyle = EMA.SharedMedia:Fetch( "border", EMA.db.borderStyle )
	local backgroundStyle = EMA.SharedMedia:Fetch( "background", EMA.db.backgroundStyle )
	local frame = EMADisplayTeamListFrame
	frame:SetBackdrop( {
		bgFile = backgroundStyle, 
		edgeFile = borderStyle, 
		tile = true, tileSize = frame:GetWidth(), edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	frame:SetBackdropColor( EMA.db.frameBackgroundColourR, EMA.db.frameBackgroundColourG, EMA.db.frameBackgroundColourB, EMA.db.frameBackgroundColourA )
	frame:SetBackdropBorderColor( EMA.db.frameBorderColourR, EMA.db.frameBorderColourG, EMA.db.frameBorderColourB, EMA.db.frameBorderColourA )	
end

function EMA:CreateEMATeamStatusBar( characterName, parentFrame )
	local statusBarTexture = EMA.SharedMedia:Fetch( "statusbar", EMA.db.statusBarTexture )
	local textFont = EMA.SharedMedia:Fetch( "font", EMA.db.fontStyle )
	local textSize = EMA.db.fontSize
	
	-- Create the table to hold the status bars for this character.
	EMA.characterStatusBar[characterName] = {}
	-- Get the status bars table.
	local characterStatusBar = EMA.characterStatusBar[characterName]
	-- Set the portrait.
	local portraitName = EMA.globalFramePrefix.."PortraitButton"
	local portraitButton = CreateFrame( "PlayerModel", portraitName, parentFrame )
	portraitButton:ClearModel()
	local portraitName = Ambiguate( characterName, "none" )
	portraitButton:SetUnit( portraitName )
	portraitButton:SetPortraitZoom( 1 )
    portraitButton:SetCamDistanceScale( 1 )
    portraitButton:SetPosition( 0, 0, 0 )
	local portraitButtonClick = CreateFrame( "CheckButton", portraitName.."Click", parentFrame, "SecureActionButtonTemplate" )
	portraitButtonClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	characterStatusBar["portraitButton"] = portraitButton
	characterStatusBar["portraitButtonClick"] = portraitButtonClick
	-- Set the follow bar.
	local followName = EMA.globalFramePrefix.."FollowBar"
	local followBar = CreateFrame( "StatusBar", followName, parentFrame) --, "TextStatusBar,SecureActionButtonTemplate" )
	followBar.backgroundTexture = followBar:CreateTexture( followName.."BackgroundTexture", "ARTWORK" )
	followBar.backgroundTexture:SetColorTexture( 0.58, 0.0, 0.55, 0.15 )
	followBar:SetStatusBarTexture( statusBarTexture )
	followBar:GetStatusBarTexture():SetHorizTile( false )
	followBar:GetStatusBarTexture():SetVertTile( false )
	followBar:SetStatusBarColor( 0.55, 0.15, 0.15, 0.25 )
	followBar:SetMinMaxValues( 0, 100 )
	followBar:SetValue( 100 )
	followBar:SetFrameStrata( "LOW" )
	followBar:SetAlpha( 1 )
	local followBarClick = CreateFrame( "CheckButton", followName.."Click", parentFrame, "SecureActionButtonTemplate" )
	followBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )																			 
	followBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["followBar"] = followBar
	characterStatusBar["followBarClick"] = followBarClick	
	local followBarText = followBar:CreateFontString( followName.."Text", "OVERLAY", "GameFontNormal" )
	followBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	followBarText:SetFont( textFont , textSize, "OUTLINE")
	followBarText:SetAllPoints()
	characterStatusBar["followBarText"] = followBarText
	EMA:SettingsUpdateFollowText( characterName ) --, UnitLevel( Ambiguate( characterName, "none" ) ), nil, nil )
	-- Set the experience bar.
	local experienceName = EMA.globalFramePrefix.."ExperienceBar"
	local experienceBar = CreateFrame( "StatusBar", experienceName, parentFrame, "AnimatedStatusBarTemplate" ) --"TextStatusBar,SecureActionButtonTemplate" )
	experienceBar.backgroundTexture = experienceBar:CreateTexture( experienceName.."BackgroundTexture", "ARTWORK" )
	experienceBar.backgroundTexture:SetColorTexture( 0.0, 0.39, 0.88, 0.15 )
	experienceBar:SetStatusBarTexture( statusBarTexture )
	experienceBar:GetStatusBarTexture():SetHorizTile( false )
	experienceBar:GetStatusBarTexture():SetVertTile( false )
	experienceBar:SetMinMaxValues( 0, 100 )
	experienceBar:SetValue( 100 )
	experienceBar:SetFrameStrata( "LOW" )
	local experienceBarClick = CreateFrame( "CheckButton", experienceName.."Click", parentFrame, "SecureActionButtonTemplate" )
	experienceBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	experienceBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["experienceBar"] = experienceBar
	characterStatusBar["experienceBarClick"] = experienceBarClick
	local experienceBarText = experienceBar:CreateFontString( experienceName.."Text", "OVERLAY", "GameFontNormal" )
	experienceBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	experienceBarText:SetFont( textFont , textSize, "OUTLINE")
	experienceBarText:SetAllPoints()
	experienceBarText.playerExperience = 100
	experienceBarText.playerMaxExperience = 100
	experienceBarText.exhaustionStateID = 1
	experienceBarText.playerLevel = 1
	characterStatusBar["experienceBarText"] = experienceBarText
	EMA:UpdateExperienceStatus( characterName, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil )	
	-- Set the reputation bar.
	local reputationName = EMA.globalFramePrefix.."ReputationBar"
	local reputationBar = CreateFrame( "StatusBar", reputationName, parentFrame, "AnimatedStatusBarTemplate" ) --"TextStatusBar,SecureActionButtonTemplate" )
	reputationBar.backgroundTexture = reputationBar:CreateTexture( reputationName.."BackgroundTexture", "ARTWORK" )
	reputationBar.backgroundTexture:SetColorTexture( 0.0, 0.39, 0.88, 0.15 )
	reputationBar:SetStatusBarTexture( statusBarTexture )
	reputationBar:GetStatusBarTexture():SetHorizTile( false )
	reputationBar:GetStatusBarTexture():SetVertTile( false )
	reputationBar:SetMinMaxValues( 0, 100 )
	reputationBar:SetValue( 100 )
	reputationBar:SetFrameStrata( "LOW" )
	local reputationBarClick = CreateFrame( "CheckButton", reputationName.."Click", parentFrame, "SecureActionButtonTemplate" )
	reputationBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	reputationBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["reputationBar"] = reputationBar
	characterStatusBar["reputationBarClick"] = reputationBarClick
	local reputationBarText = reputationBar:CreateFontString( reputationName.."Text", "OVERLAY", "GameFontNormal" )
	reputationBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	reputationBarText:SetFont( textFont , textSize, "OUTLINE")
	reputationBarText:SetAllPoints()
	reputationBarText.reputationName = "Faction"
	reputationBarText.reputationStandingID = 4
	reputationBarText.reputationBarMin = 0
	reputationBarText.reputationBarMax = 100
	reputationBarText.reputationBarValue = 100
	characterStatusBar["reputationBarText"] = reputationBarText
	EMA:UpdateReputationStatus( characterName, nil, nil, nil )
	-- Set the health bar.
	
	local healthName = EMA.globalFramePrefix.."HealthBar"
	local healthBar = CreateFrame( "StatusBar", healthName, parentFrame, "TextStatusBar","SecureActionButtonTemplate" )
	healthBar.backgroundTexture = healthBar:CreateTexture( healthName.."BackgroundTexture", "ARTWORK" )
	healthBar.backgroundTexture:SetColorTexture( 0.58, 0.0, 0.55, 0.15 )
	healthBar:SetStatusBarTexture( statusBarTexture )
	healthBar:GetStatusBarTexture():SetHorizTile( false )
	healthBar:GetStatusBarTexture():SetVertTile( false )
	healthBar:SetMinMaxValues( 0, 100 )
	healthBar:SetValue( 100 )
	healthBar:SetFrameStrata( "LOW" )
	healthBar:SetAlpha( 1 )

	
	local healthIncomingName = EMA.globalFramePrefix.."HealthIncomingBar"
	local healthIncomingBar = CreateFrame( "StatusBar", healthIncomingName, parentFrame, "TextStatusBar","SecureActionButtonTemplate" )
	healthIncomingBar.backgroundTexture = healthIncomingBar:CreateTexture( healthIncomingName.."BackgroundTexture", "ARTWORK" )
	healthIncomingBar.backgroundTexture:SetColorTexture( 0.58, 0.0, 0.55, 0.15 )
	healthIncomingBar:SetStatusBarTexture( statusBarTexture )
	healthIncomingBar:GetStatusBarTexture():SetHorizTile( false )
	healthIncomingBar:GetStatusBarTexture():SetVertTile( false )
	healthIncomingBar:SetMinMaxValues( 0, 100 )
	healthIncomingBar:SetValue( 0 )
	healthIncomingBar:SetFrameStrata( "BACKGROUND" )
	healthIncomingBar:SetAlpha( 1 )
	
	-- Set the heal Incoming bar	

	local healthBarClick = CreateFrame( "CheckButton", healthName.."Click"..characterName, parentFrame, "SecureActionButtonTemplate" )
	healthBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	healthBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["healthBar"] = healthBar
	characterStatusBar["healthIncomingBar"] = healthIncomingBar
	characterStatusBar["healthBarClick"] = healthBarClick
	local healthBarText = healthBar:CreateFontString( healthName.."Text", "OVERLAY", "GameFontNormal" )
	healthBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	healthBarText:SetFont( textFont , textSize, "OUTLINE")
	healthBarText:SetAllPoints()
	healthBarText.playerHealth = 100
	healthBarText.playerMaxHealth = 100
	characterStatusBar["healthBarText"] = healthBarText
	EMA:UpdateHealthStatus( characterName, nil, nil )
	
	
	-- Set the power bar.
	local powerName = EMA.globalFramePrefix.."PowerBar"
	local powerBar = CreateFrame( "StatusBar", powerName, parentFrame, "TextStatusBar","SecureActionButtonTemplate" )
	powerBar.backgroundTexture = powerBar:CreateTexture( powerName.."BackgroundTexture", "ARTWORK" )
	powerBar.backgroundTexture:SetColorTexture( 0.58, 0.0, 0.55, 0.15 )
	powerBar:SetStatusBarTexture( statusBarTexture )
	powerBar:GetStatusBarTexture():SetHorizTile( false )
	powerBar:GetStatusBarTexture():SetVertTile( false )
	powerBar:SetMinMaxValues( 0, 100 )
	powerBar:SetValue( 100 )
	powerBar:SetFrameStrata( "LOW" )
	powerBar:SetAlpha( 1 )
	local powerBarClick = CreateFrame( "CheckButton", powerName.."Click"..characterName, parentFrame, "SecureActionButtonTemplate" )
	powerBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	powerBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["powerBar"] = powerBar
	characterStatusBar["powerBarClick"] = powerBarClick
	local powerBarText = powerBar:CreateFontString( powerName.."Text", "OVERLAY", "GameFontNormal" )
	powerBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	powerBarText:SetFont( textFont , textSize, "OUTLINE")
	powerBarText:SetAllPoints()
	powerBarText.playerPower = 100
	powerBarText.playerMaxPower = 100
	characterStatusBar["powerBarText"] = powerBarText
	EMA:UpdatePowerStatus( characterName, nil, nil, nil )
	-- Set the Combo Points bar.
	local comboName = EMA.globalFramePrefix.."ComboBar"
	local comboBar = CreateFrame( "StatusBar", comboName, parentFrame, "TextStatusBar","SecureActionButtonTemplate" )
	comboBar.backgroundTexture = comboBar:CreateTexture( comboName.."BackgroundTexture", "ARTWORK" )
	comboBar.backgroundTexture:SetColorTexture( 0.58, 0.0, 0.55, 0.15 )
	comboBar:SetStatusBarTexture( statusBarTexture )
	comboBar:GetStatusBarTexture():SetHorizTile( false )
	comboBar:GetStatusBarTexture():SetVertTile( false )
	comboBar:SetStatusBarColor( 1.00, 0.0, 0.0, 1.00 )
	comboBar:SetMinMaxValues( 0, 5 )
	comboBar:SetValue( 5 )
	comboBar:SetFrameStrata( "LOW" )
	comboBar:SetAlpha( 1 )
	local comboBarClick = CreateFrame( "CheckButton", comboName.."Click"..characterName, parentFrame, "SecureActionButtonTemplate" )
	comboBarClick:SetAttribute( "unit", characterName )
	comboBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["comboBar"] = comboBar
	characterStatusBar["comboBarClick"] = comboBarClick
	local comboBarText = comboBar:CreateFontString( comboName.."Text", "OVERLAY", "GameFontNormal" )
	comboBarText:SetTextColor( 1.00, 1.00, 0.0, 1.00 )
	comboBarText:SetFont( textFont , textSize, "OUTLINE")
	comboBarText:SetAllPoints()
	comboBarText.playerCombo = 0
	comboBarText.playerMaxCombo = 5
	characterStatusBar["comboBarText"] = comboBarText
	EMA:UpdateComboStatus( characterName, nil, nil )
	-- Add the health and power click bars to ClickCastFrames for addons like Clique to use.
	--Ebony if Support for Clique if not on then default to target unit
	--TODO there got to be a better way to doing this for sure but right now i can not be assed to do this for now you need to reload the UI when turning off and on clique support. 
	ClickCastFrames = ClickCastFrames or {}
	if EMA.db.enableClique == true then
		ClickCastFrames[portraitButtonClick] = true
		ClickCastFrames[followBarClick] = true
		ClickCastFrames[experienceBarClick] = true
		ClickCastFrames[reputationBarClick] = true
		ClickCastFrames[healthBarClick] = true
		ClickCastFrames[powerBarClick] = true
		ClickCastFrames[comboBarClick] = true
	else
		portraitButtonClick:SetAttribute( "type1", "target")
		followBarClick:SetAttribute( "type1", "target")
		experienceBarClick:SetAttribute( "type1", "target")
		reputationBarClick:SetAttribute( "type1", "target")
		healthBarClick:SetAttribute( "type1", "target")
		powerBarClick:SetAttribute( "type1", "target")
		comboBarClick:SetAttribute( "type1", "target")
	end
end


function EMA:HideEMATeamStatusBar( characterName )	
	local parentFrame = EMADisplayTeamListFrame
	-- Get (or create and get) the character status bar information.
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		EMA:CreateEMATeamStatusBar( characterName, parentFrame )
		characterStatusBar = EMA.characterStatusBar[characterName]
	end
	--if characterStatusBar ~= nil then
	-- Hide the bars.
	characterStatusBar["portraitButton"]:Hide()
	characterStatusBar["portraitButtonClick"]:Hide()
	characterStatusBar["followBar"]:Hide()
	characterStatusBar["followBarClick"]:Hide()
	characterStatusBar["experienceBar"]:Hide()
	characterStatusBar["experienceBarClick"]:Hide()
	characterStatusBar["reputationBar"]:Hide()
	characterStatusBar["reputationBarClick"]:Hide()	
	characterStatusBar["healthBar"]:Hide()
	characterStatusBar["healthIncomingBar"]:Hide()
	characterStatusBar["healthBarClick"]:Hide()
	characterStatusBar["powerBar"]:Hide()
	characterStatusBar["powerBarClick"]:Hide()
	characterStatusBar["comboBar"]:Hide()
	characterStatusBar["comboBarClick"]:Hide()
	--end
end	


function EMA:UpdateEMATeamStatusBar( characterName, characterPosition )	
	local parentFrame = EMADisplayTeamListFrame
	-- Get (or create and get) the character status bar information.
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		EMA:CreateEMATeamStatusBar( characterName, parentFrame )
		characterStatusBar = EMA.characterStatusBar[characterName]
	end
	-- Set the positions.
	local characterHeight = GetCharacterHeight()
	local characterWidth = GetCharacterWidth()
	local positionLeft = 0
	local positionTop = -EMA.db.teamListTitleHeight - (EMA.db.teamListVerticalSpacing * 2)
	local charactersPerRow = EMA.db.charactersPerRow
	if EMA.db.teamListHorizontal == true then
		if characterPosition < charactersPerRow then
			positionLeft = -6 + (characterPosition * characterWidth) + (EMA.db.teamListHorizontalSpacing * 3)
			parentFrame:SetWidth( (EMA.db.teamListVerticalSpacing * 3) + (GetCharacterWidth() ) + ( positionLeft ) )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() ) 
		-- Row 2
		elseif 	characterPosition < ( charactersPerRow * 2 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight)
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + ( GetCharacterHeight() ) * 2 ) 
		-- Row 3	
		elseif 	characterPosition < ( charactersPerRow * 3 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow * 2 ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight * 2 )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() * 3 )
			-- Row 4	
		elseif 	characterPosition < ( charactersPerRow * 4 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow * 3 ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight * 3 )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() * 4 )
		-- Row 5
		elseif 	characterPosition < ( charactersPerRow * 5 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow * 4 ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight * 4 )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() * 5)
		-- Row 6
		elseif 	characterPosition < ( charactersPerRow * 6 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow * 5 ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight * 5 )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() * 6 )				
		--Row 7
		elseif 	characterPosition < ( charactersPerRow * 7 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow * 6 ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight * 6 )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() * 7 )
		--Row 8
		elseif 	characterPosition < ( charactersPerRow * 8 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow * 7 ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight * 7 )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() * 8 )				
		--Row 9
		elseif 	characterPosition < ( charactersPerRow * 9 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow * 8 ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight * 8 )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() * 9 )
			--Row 10
		elseif 	characterPosition < ( charactersPerRow * 10 ) then
			positionLeft = -6 + (characterPosition - charactersPerRow * 9 ) * ( characterWidth ) + (EMA.db.teamListHorizontalSpacing * 3)
			positionTop = (positionTop - characterHeight * 9 )
			parentFrame:SetHeight( EMA.db.teamListTitleHeight + (EMA.db.teamListVerticalSpacing * 3) + GetCharacterHeight() * 10 )
		else		
			return
		end	
	--Old code kept for Legacy Purpose
		--positionLeft = -6 + (characterPosition * characterWidth) + (EMA.db.teamListHorizontalSpacing * 3)
	else
		positionLeft = 6
		positionTop = positionTop - (characterPosition * characterHeight)
	end
	-- Display the portrait.

	local portraitButton = characterStatusBar["portraitButton"]
	local portraitButtonClick = characterStatusBar["portraitButtonClick"]
	if EMA.db.showCharacterPortrait == true then
		portraitButton:ClearModel()
		local portraitName = Ambiguate( characterName, "none" )
		portraitButton:SetUnit( portraitName )
		portraitButton:SetPortraitZoom( 1 )
        portraitButton:SetCamDistanceScale( 1 )
        portraitButton:SetPosition( 0, 0, 0 )
        portraitButton:SetWidth( EMA.db.characterPortraitWidth )
		portraitButton:SetHeight( EMA.db.characterPortraitWidth )
		portraitButton:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		portraitButtonClick:SetWidth( EMA.db.characterPortraitWidth )
		portraitButtonClick:SetHeight( EMA.db.characterPortraitWidth )
		portraitButtonClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		portraitButton:Show()
		portraitButtonClick:Show()
		positionLeft = positionLeft + EMA.db.characterPortraitWidth + EMA.db.teamListHorizontalSpacing
	else
		portraitButton:Hide()
		portraitButtonClick:Hide()
	end	
	-- Display the follow bar.
	local followBar	= characterStatusBar["followBar"]
	local followBarClick = characterStatusBar["followBarClick"]
	if EMA.db.showFollowStatus == true then
		followBar.backgroundTexture:SetAllPoints()
		followBar:SetWidth( EMA.db.followStatusWidth )
		followBar:SetHeight( EMA.db.followStatusHeight )
		followBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		followBarClick:SetWidth( EMA.db.followStatusWidth )
		followBarClick:SetHeight( EMA.db.followStatusHeight )
		followBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		followBar:Show()
		followBarClick:Show()
		if EMA.db.barsAreStackedVertically == true then
			positionTop = positionTop - EMA.db.followStatusHeight - EMA.db.barVerticalSpacing
		else
			positionLeft = positionLeft + EMA.db.followStatusWidth + EMA.db.teamListHorizontalSpacing
		end
	else
		followBar:Hide()
		followBarClick:Hide()
	end
	-- Display the experience bar.
	local experienceBar	= characterStatusBar["experienceBar"]
	local experienceBarClick = characterStatusBar["experienceBarClick"]
	local reputationBar	= characterStatusBar["reputationBar"]
	local reputationBarClick = characterStatusBar["reputationBarClick"]	
	if EMA.db.showExperienceStatus == true then
		--EMA:Print("TestLevel", characterName, level, maxLevel, xpDisabled, showXP, showArtifact )
		local showBarCount = 0
		if EMA.db.showXpStatus == true then
			showBarCount = showBarCount + 1
			showBeforeBar = parentFrame
			showXP = true
		end		
		if EMA.db.showRepStatus == true then
			--EMA:Print("Show Reputation")
			showBarCount = showBarCount + 1
			if EMA.db.showXpStatus == true then
				--EMA:Print("Show Reputation 1")
				showRepBeforeBar = experienceBar
				setRepPoint = "BOTTOMLEFT"
				setRepLeft = 0
				setRepTop = -1				
			else
				--EMA:Print("Show Reputation 4")
				showRepBeforeBar = parentFrame
				setRepPoint = "TOPLEFT"
				setRepLeft = positionLeft
				setRepTop = positionTop
			end		
		end
		if showBarCount < 1 then
			showBarCount = showBarCount + 1
		end	
		--EMA:Print("showBarCountTest", showBarCount)
		--Xp Bar
			experienceBar.backgroundTexture:SetAllPoints()
			experienceBar:SetWidth( EMA.db.experienceStatusWidth )
			experienceBar:SetHeight( EMA.db.experienceStatusHeight / showBarCount )
			experienceBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft , positionTop )
			experienceBarClick:SetWidth( EMA.db.experienceStatusWidth )
			experienceBarClick:SetHeight( EMA.db.experienceStatusHeight / showBarCount )
			experienceBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )		
		if EMA.db.showXpStatus == true then
			experienceBar:Show()
			experienceBarClick:Show()
		else
			experienceBar:Hide()
			experienceBarClick:Hide()
		end		
		--rep
			reputationBar.backgroundTexture:SetAllPoints()
			reputationBar:SetWidth( EMA.db.experienceStatusWidth )
			reputationBar:SetHeight( EMA.db.experienceStatusHeight / showBarCount )
			reputationBar:SetPoint( "TOPLEFT", showRepBeforeBar , setRepPoint, setRepLeft, setRepTop )
			reputationBarClick:SetPoint( "TOPLEFT", showRepBeforeBar , setRepPoint, setRepLeft, setRepTop )
			reputationBarClick:SetWidth( EMA.db.experienceStatusWidth )
			reputationBarClick:SetHeight( EMA.db.experienceStatusHeight / showBarCount )
		if EMA.db.showRepStatus == true then
			reputationBar:Show()
			reputationBarClick:Show()
		else
			reputationBar:Hide()
			reputationBarClick:Hide()		
		end	
		
		if EMA.db.barsAreStackedVertically == true then
			positionTop = positionTop - EMA.db.experienceStatusHeight - EMA.db.barVerticalSpacing
		else
			positionLeft = positionLeft + EMA.db.experienceStatusWidth + EMA.db.teamListHorizontalSpacing
		end
	
	else
		experienceBar:Hide()
		experienceBarClick:Hide()
	end		
	-- Display the health bar.
	local healthBar	= characterStatusBar["healthBar"]
	local healthIncomingBar = characterStatusBar["healthIncomingBar"]
	local healthBarClick = characterStatusBar["healthBarClick"]
	if EMA.db.showHealthStatus == true then
		healthBar.backgroundTexture:SetAllPoints()
		healthBar:SetWidth( EMA.db.healthStatusWidth )
		healthBar:SetHeight( EMA.db.healthStatusHeight )
		healthBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		healthBarClick:SetWidth( EMA.db.healthStatusWidth )
		healthBarClick:SetHeight( EMA.db.healthStatusHeight )
		healthBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		healthBar:Show()
		healthBarClick:Show()
		if EMA.db.barsAreStackedVertically == true then
			positionTop = positionTop - EMA.db.healthStatusHeight - EMA.db.barVerticalSpacing
		else
			positionLeft = positionLeft + EMA.db.healthStatusWidth + EMA.db.teamListHorizontalSpacing
		end
	else
		healthBar:Hide()
		healthBarClick:Hide()
	end
	-- Display the health Incoming bar.
	if EMA.db.showHealthStatus == true then
		healthIncomingBar.backgroundTexture:SetAllPoints()
		healthIncomingBar:SetWidth( EMA.db.healthStatusWidth )
		healthIncomingBar:SetHeight( EMA.db.healthStatusHeight )
		healthIncomingBar:SetPoint( "TOPLEFT", healthBar, "TOPLEFT", 0, 0 )
		healthIncomingBar:Show()
	else
		healthIncomingBar:Hide()
		--healthBarClick:Hide()
	end			
	-- Display the power bar.
	local powerBar = characterStatusBar["powerBar"]
	local powerBarClick = characterStatusBar["powerBarClick"]
	if EMA.db.showPowerStatus == true then
		powerBar.backgroundTexture:SetAllPoints()
		powerBar:SetWidth( EMA.db.powerStatusWidth )
		powerBar:SetHeight( EMA.db.powerStatusHeight )
		powerBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		powerBarClick:SetWidth( EMA.db.powerStatusWidth )
		powerBarClick:SetHeight( EMA.db.powerStatusHeight )
		powerBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		powerBar:Show()
		powerBarClick:Show()
		if EMA.db.barsAreStackedVertically == true then
			positionTop = positionTop - EMA.db.powerStatusHeight - EMA.db.barVerticalSpacing
		else
			positionLeft = positionLeft + EMA.db.powerStatusWidth + EMA.db.teamListHorizontalSpacing
		end
	else
		powerBar:Hide()
		powerBarClick:Hide()
	end
	-- Display the Combo Point bar.
	local comboBar = characterStatusBar["comboBar"]
	local comboBarClick = characterStatusBar["comboBarClick"]
	if EMA.db.showComboStatus == true then
		comboBar.backgroundTexture:SetAllPoints()
		comboBar:SetWidth( EMA.db.comboStatusWidth )
		comboBar:SetHeight( EMA.db.comboStatusHeight )
		comboBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		comboBarClick:SetWidth( EMA.db.comboStatusWidth )
		comboBarClick:SetHeight( EMA.db.comboStatusHeight )
		comboBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		comboBar:Show()
		comboBarClick:Show()
		if EMA.db.barsAreStackedVertically == true then
			positionTop = positionTop - EMA.db.comboStatusHeight - EMA.db.barVerticalSpacing
		else
			positionLeft = positionLeft + EMA.db.comboStatusWidth + EMA.db.teamListHorizontalSpacing
		end
	else
		comboBar:Hide()
		comboBarClick:Hide()
	end		
end

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreateDisplayOptions( top )
	-- Get positions.
	local checkBoxHeight = EMAHelperSettings:GetCheckBoxHeight()
	local labelContinueHeight = EMAHelperSettings:GetContinueLabelHeight()
	local sliderHeight = EMAHelperSettings:GetSliderHeight()
	local mediaHeight = EMAHelperSettings:GetMediaHeight()
	local left = EMAHelperSettings:LeftOfSettings()
	local headingHeight = EMAHelperSettings:HeadingHeight()
	local headingWidth = EMAHelperSettings:HeadingWidth( true )
	local horizontalSpacing = EMAHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = EMAHelperSettings:GetVerticalSpacing()
	local sectionSpacing = verticalSpacing * 4
	local halfWidthSlider = (headingWidth - horizontalSpacing) / 2
	local thirdWidth = (headingWidth - (horizontalSpacing * 2)) / 3
	local column2left = left + halfWidthSlider
	local left2 = left + thirdWidth
	local left3 = left + (thirdWidth * 2)
	local movingTop = top
	-- A blank to get layout to show right?
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L[""], movingTop, false )
	movingTop = movingTop - headingHeight	
	-- Create show.
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L["DISPLAY_HEADER"], movingTop, true )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.displayOptionsCheckBoxShowTeamList = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["SHOW_TEAM_FRAME"],
		EMA.SettingsToggleShowTeamList,
		L["SHOW_TEAM_FRAME_HELP"]
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsCheckBoxShowTeamListOnlyOnMaster = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["ONLY_ON_MASTER"],
		EMA.SettingsToggleShowTeamListOnMasterOnly,
		L["ONLY_ON_MASTER_HELP"]
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsCheckBoxHideTeamListInCombat = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["HIDE_IN_COMBAT"],
		EMA.SettingsToggleHideTeamListInCombat,
		L["HIDE_IN_COMBAT_HELP_DT"]
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsCheckBoxEnableClique = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["ENABLE_CLIQUE"],
		EMA.SettingsToggleEnableClique,
		L["ENABLE_CLIQUE_HELP"]
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsCheckBoxOlnyShowInParty = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["SHOW_PARTY"],
		EMA.SettingsToggleOlnyShowinParty,
		L["SHOW_PARTY_HELP"]
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsCheckBoxHpManaOutOfParty = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["HEALTH_POWER_GROUP"],
		EMA.SettingsToggleHpManaOutOfParty,
		L["HEALTH_POWER_GROUP_HELP"]
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	-- Create appearance & layout.
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L["APPEARANCE_LAYOUT_HEALDER"], movingTop, true )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.displayOptionsCheckBoxShowListTitle = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["SHOW_TITLE"],
		EMA.SettingsToggleShowTeamListTitle,
		L["SHOW_TITLE_HELP"]
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsCheckBoxStackVertically = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["STACK_VERTICALLY_HELP"],
		EMA.SettingsToggleStackVertically,
		L["STACK_VERTICALLY_HELP"]
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsCharactersPerBar = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["CHARACTERS_PER_BAR"]
	)
	EMA.settingsControl.displayOptionsCharactersPerBar:SetSliderValues( 1, 10, 1 )
	EMA.settingsControl.displayOptionsCharactersPerBar:SetCallback( "OnValueChanged", EMA.SettingsChangeCharactersPerBar )

	
	EMA.settingsControl.displayOptionsTeamListScaleSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["SCALE"]
	)
	EMA.settingsControl.displayOptionsTeamListScaleSlider:SetSliderValues( 0.5, 2, 0.01 )
	EMA.settingsControl.displayOptionsTeamListScaleSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeScale )
	movingTop = movingTop - sliderHeight - verticalSpacing

	EMA.settingsControl.displayOptionsTeamListTransparencySlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["TRANSPARENCY"]
	)
	EMA.settingsControl.displayOptionsTeamListTransparencySlider:SetSliderValues( 0, 1, 0.01 )
	EMA.settingsControl.displayOptionsTeamListTransparencySlider:SetCallback( "OnValueChanged", EMA.SettingsChangeTransparency )
	movingTop = movingTop - sliderHeight - verticalSpacing	
	EMA.settingsControl.displayOptionsTeamListMediaStatus = EMAHelperSettings:CreateMediaStatus( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["BAR_TEXTURES"]
	)
	EMA.settingsControl.displayOptionsTeamListMediaStatus:SetCallback( "OnValueChanged", EMA.SettingsChangeStatusBarTexture )
	movingTop = movingTop - mediaHeight - verticalSpacing
	EMA.settingsControl.displayOptionsTeamListMediaBorder = EMAHelperSettings:CreateMediaBorder( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["BORDER_STYLE"]
	)
	EMA.settingsControl.displayOptionsTeamListMediaBorder:SetCallback( "OnValueChanged", EMA.SettingsChangeBorderStyle )
	EMA.settingsControl.displayOptionsBorderColourPicker = EMAHelperSettings:CreateColourPicker(
		EMA.settingsControl,
		halfWidthSlider,
		column2left + 15,
		movingTop - 15,
		L["BORDER COLOUR"]
	)
	EMA.settingsControl.displayOptionsBorderColourPicker:SetHasAlpha( true )
	EMA.settingsControl.displayOptionsBorderColourPicker:SetCallback( "OnValueConfirmed", EMA.SettingsBorderColourPickerChanged )	
	movingTop = movingTop - mediaHeight - verticalSpacing
	EMA.settingsControl.displayOptionsTeamListMediaBackground = EMAHelperSettings:CreateMediaBackground( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["BACKGROUND"]
	)
	EMA.settingsControl.displayOptionsTeamListMediaBackground:SetCallback( "OnValueChanged", EMA.SettingsChangeBackgroundStyle )
	EMA.settingsControl.displayOptionsBackgroundColourPicker = EMAHelperSettings:CreateColourPicker(
		EMA.settingsControl,
		halfWidthSlider,
		column2left + 15,
		movingTop - 15,
		L["BG_COLOUR"]
	)
	EMA.settingsControl.displayOptionsBackgroundColourPicker:SetHasAlpha( true )
	EMA.settingsControl.displayOptionsBackgroundColourPicker:SetCallback( "OnValueConfirmed", EMA.SettingsBackgroundColourPickerChanged )
	--Set the font
	movingTop = movingTop - mediaHeight - verticalSpacing
	EMA.settingsControl.displayOptionsTeamListMediaFont = EMAHelperSettings:CreateMediaFont( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["FONT"]
	)
	EMA.settingsControl.displayOptionsTeamListMediaFont:SetCallback( "OnValueChanged", EMA.SettingsChangeFontStyle )
	EMA.settingsControl.displayOptionsSetFontSize = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["FONT_SIZE"]
	)
	EMA.settingsControl.displayOptionsSetFontSize:SetSliderValues( 8, 20 , 1 )
	EMA.settingsControl.displayOptionsSetFontSize:SetCallback( "OnValueChanged", EMA.SettingsChangeFontSize )
	movingTop = movingTop - mediaHeight - sectionSpacing	
	-- Create portrait.
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L["PORTRAIT_HEADER"], movingTop, true )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.displayOptionsCheckBoxShowPortrait = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["SHOW"],
		EMA.SettingsToggleShowPortrait,
		L["SHOW_CHARACTER_PORTRAIT"]
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsPortraitWidthSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["WIDTH"]
	)
	EMA.settingsControl.displayOptionsPortraitWidthSlider:SetSliderValues( 15, 300, 1 )
	EMA.settingsControl.displayOptionsPortraitWidthSlider:SetCallback( "OnValueChanged", EMA.SettingsChangePortraitWidth )
	movingTop = movingTop - sliderHeight - sectionSpacing
	-- Create follow status.
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L["FOLLOW_BAR_HEADER"], movingTop, true )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.displayOptionsCheckBoxShowFollowStatus = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["SHOW"],
		EMA.SettingsToggleShowFollowStatus,
		L["SHOW_FOLLOW_BAR"]
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowFollowStatusName = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["NAME"],
		EMA.SettingsToggleShowFollowStatusName,
		L["SHOW_NAME"]
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsFollowStatusWidthSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["WIDTH"]
	)
	EMA.settingsControl.displayOptionsFollowStatusWidthSlider:SetSliderValues( 15, 300, 1 )
	EMA.settingsControl.displayOptionsFollowStatusWidthSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeFollowStatusWidth )
	EMA.settingsControl.displayOptionsFollowStatusHeightSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["HEIGHT"]
	)
	EMA.settingsControl.displayOptionsFollowStatusHeightSlider:SetSliderValues( 15, 100, 1 )
	EMA.settingsControl.displayOptionsFollowStatusHeightSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeFollowStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing
	-- Create experience status.
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L["EXPERIENCE_HEADER"], movingTop, true )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatus = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["SHOW"],
		EMA.SettingsToggleShowExperienceStatus,
		L["SHOW_XP_BAR"]
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatusValues = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["VALUES"],
		EMA.SettingsToggleShowExperienceStatusValues,
		L["VALUES_HELP"] 
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatusPercentage = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["PERCENTAGE"],
		EMA.SettingsToggleShowExperienceStatusPercentage,
		L["PERCENTAGE_HELP"]
	)		
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsCheckBoxShowXpStatus = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["SHOW_XP"],
		EMA.SettingsToggleShowXpStatus,
		L["SHOW_XP_HELP"]
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowRepStatus = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["REPUTATION_BAR"],
		EMA.SettingsToggleShowRepStatus,
		L["REPUTATION_BAR_HELP"]
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsExperienceStatusWidthSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["WIDTH"]
	)
	EMA.settingsControl.displayOptionsExperienceStatusWidthSlider:SetSliderValues( 15, 300, 1 )
	EMA.settingsControl.displayOptionsExperienceStatusWidthSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeExperienceStatusWidth )
	EMA.settingsControl.displayOptionsExperienceStatusHeightSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["HEIGHT"]
	)
	EMA.settingsControl.displayOptionsExperienceStatusHeightSlider:SetSliderValues( 15, 100, 1 )
	EMA.settingsControl.displayOptionsExperienceStatusHeightSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeExperienceStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing	
	-- Create health status.
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L["HEALTH_BAR_HEADER"], movingTop, true )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.displayOptionsCheckBoxShowHealthStatus = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["SHOW"],
		EMA.SettingsToggleShowHealthStatus,
		L["SHOW_HEALTH"]
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowHealthStatusValues = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["VALUES"],
		EMA.SettingsToggleShowHealthStatusValues,
		L["VALUES_HELP"]
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowHealthStatusPercentage = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["PERCENTAGE"],
		EMA.SettingsToggleShowHealthStatusPercentage,
		L["PERCENTAGE_HELP"]
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing		
	EMA.settingsControl.displayOptionsCheckBoxShowClassColors = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["SHOW_CLASS_COLORS"],
		EMA.SettingsToggleShowClassColors,
		L["SHOW_CLASS_COLORS_HELP"] 
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsHealthStatusWidthSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["WIDTH"]
	)
	EMA.settingsControl.displayOptionsHealthStatusWidthSlider:SetSliderValues( 15, 300, 1 )
	EMA.settingsControl.displayOptionsHealthStatusWidthSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeHealthStatusWidth )
	EMA.settingsControl.displayOptionsHealthStatusHeightSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["HEIGHT"]
	)
	EMA.settingsControl.displayOptionsHealthStatusHeightSlider:SetSliderValues( 15, 100, 1 )
	EMA.settingsControl.displayOptionsHealthStatusHeightSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeHealthStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing	
	-- Create power status.
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L["POWER_BAR_HEADER"], movingTop, true )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.displayOptionsCheckBoxShowPowerStatus = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["SHOW"],
		EMA.SettingsToggleShowPowerStatus,
		L["POWER_HELP"]
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowPowerStatusValues = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["VALUES"],
		EMA.SettingsToggleShowPowerStatusValues,
		L["VALUES_HELP"]
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowPowerStatusPercentage = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["PERCENTAGE"],
		EMA.SettingsToggleShowPowerStatusPercentage,
		L["PERCENTAGE_HELP"]
	)			
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsPowerStatusWidthSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["WIDTH"]
	)
	EMA.settingsControl.displayOptionsPowerStatusWidthSlider:SetSliderValues( 15, 300, 1 )
	EMA.settingsControl.displayOptionsPowerStatusWidthSlider:SetCallback( "OnValueChanged", EMA.SettingsChangePowerStatusWidth )
	EMA.settingsControl.displayOptionsPowerStatusHeightSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["HEIGHT"]
	)
	EMA.settingsControl.displayOptionsPowerStatusHeightSlider:SetSliderValues( 10, 100, 1 )
	EMA.settingsControl.displayOptionsPowerStatusHeightSlider:SetCallback( "OnValueChanged", EMA.SettingsChangePowerStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing
	-- Create Combo Point status.
	EMAHelperSettings:CreateHeading( EMA.settingsControl, L["COMBO_BAR_HEADER"], movingTop, true )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.displayOptionsCheckBoxShowComboStatus = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["SHOW"],
		EMA.SettingsToggleShowComboStatus,
		L["CLASS_POWER"] 
	)	
	EMA.settingsControl.displayOptionsCheckBoxShowComboStatusValues = EMAHelperSettings:CreateCheckBox( 
		EMA.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["VALUES"],
		EMA.SettingsToggleShowComboStatusValues,
		L["VALUES_HELP"]
	)			
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	EMA.settingsControl.displayOptionsComboStatusWidthSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["WIDTH"]
	)	
	EMA.settingsControl.displayOptionsComboStatusWidthSlider:SetSliderValues( 15, 300, 1 )
	EMA.settingsControl.displayOptionsComboStatusWidthSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeComboStatusWidth )
	EMA.settingsControl.displayOptionsComboStatusHeightSlider = EMAHelperSettings:CreateSlider( 
		EMA.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["HEIGHT"]
	)
	EMA.settingsControl.displayOptionsComboStatusHeightSlider:SetSliderValues( 10, 100, 1 )
	EMA.settingsControl.displayOptionsComboStatusHeightSlider:SetCallback( "OnValueChanged", EMA.SettingsChangeComboStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing
	return movingTop
end

local function SettingsCreate()
	EMA.settingsControl = {}
	-- Create the settings panel.
	EMAHelperSettings:CreateSettings( 
		EMA.settingsControl, 
		EMA.moduleDisplayName, 
		EMA.parentDisplayName, 
		EMA.SettingsPushSettingsClick,
		EMA.moduleIcon,
		EMA.moduleOrder		
	)
	local bottomOfDisplayOptions = SettingsCreateDisplayOptions( EMAHelperSettings:TopOfSettings() )
	EMA.settingsControl.widgetSettings.content:SetHeight( -bottomOfDisplayOptions )
	-- Help
	local helpTable = {}
	EMAHelperSettings:CreateHelp( EMA.settingsControl, helpTable, EMA:GetConfiguration() )		
end

-------------------------------------------------------------------------------------------------------------
-- Settings Populate.
-------------------------------------------------------------------------------------------------------------

function EMA:BeforeEMAProfileChanged()	
	EMA:RefreshTeamListControlsHide()
end

function EMA:OnEMAProfileChanged()	
	EMA:SettingsRefresh()
end

function EMA:SettingsRefresh()
	EMA.settingsControl.displayOptionsCheckBoxShowTeamList:SetValue( EMA.db.showTeamList )
	EMA.settingsControl.displayOptionsCheckBoxShowTeamListOnlyOnMaster:SetValue( EMA.db.showTeamListOnMasterOnly )
	EMA.settingsControl.displayOptionsCheckBoxHideTeamListInCombat:SetValue( EMA.db.hideTeamListInCombat )
	EMA.settingsControl.displayOptionsCheckBoxEnableClique:SetValue( EMA.db.enableClique )
	EMA.settingsControl.displayOptionsCharactersPerBar:SetValue( EMA.db.charactersPerRow )
	EMA.settingsControl.displayOptionsCheckBoxStackVertically:SetValue( EMA.db.barsAreStackedVertically )
	EMA.settingsControl.displayOptionsCheckBoxShowListTitle:SetValue( EMA.db.showListTitle )
	EMA.settingsControl.displayOptionsCheckBoxOlnyShowInParty:SetValue( EMA.db.olnyShowInParty )
	EMA.settingsControl.displayOptionsCheckBoxHpManaOutOfParty:SetValue ( EMA.db.healthManaOutOfParty )
	EMA.settingsControl.displayOptionsTeamListTransparencySlider:SetValue( EMA.db.frameAlpha )
	EMA.settingsControl.displayOptionsTeamListScaleSlider:SetValue( EMA.db.teamListScale )
	EMA.settingsControl.displayOptionsTeamListMediaStatus:SetValue( EMA.db.statusBarTexture ) 
	EMA.settingsControl.displayOptionsTeamListMediaBorder:SetValue( EMA.db.borderStyle )
	EMA.settingsControl.displayOptionsTeamListMediaBackground:SetValue( EMA.db.backgroundStyle )
	EMA.settingsControl.displayOptionsTeamListMediaFont:SetValue( EMA.db.fontStyle )
	EMA.settingsControl.displayOptionsSetFontSize:SetValue( EMA.db.fontSize )	
	EMA.settingsControl.displayOptionsCheckBoxShowPortrait:SetValue( EMA.db.showCharacterPortrait )
	EMA.settingsControl.displayOptionsPortraitWidthSlider:SetValue( EMA.db.characterPortraitWidth )
	EMA.settingsControl.displayOptionsCheckBoxShowFollowStatus:SetValue( EMA.db.showFollowStatus )
	EMA.settingsControl.displayOptionsCheckBoxShowFollowStatusName:SetValue( EMA.db.followStatusShowName )
	EMA.settingsControl.displayOptionsFollowStatusWidthSlider:SetValue( EMA.db.followStatusWidth )
	EMA.settingsControl.displayOptionsFollowStatusHeightSlider:SetValue( EMA.db.followStatusHeight )
	EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatus:SetValue( EMA.db.showExperienceStatus )
	EMA.settingsControl.displayOptionsCheckBoxShowXpStatus:SetValue( EMA.db.showXpStatus )
	EMA.settingsControl.displayOptionsCheckBoxShowRepStatus:SetValue( EMA.db.showRepStatus )
	EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatusValues:SetValue( EMA.db.experienceStatusShowValues )
	EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatusPercentage:SetValue( EMA.db.experienceStatusShowPercentage )
	EMA.settingsControl.displayOptionsExperienceStatusWidthSlider:SetValue( EMA.db.experienceStatusWidth )
	EMA.settingsControl.displayOptionsExperienceStatusHeightSlider:SetValue( EMA.db.experienceStatusHeight )
	EMA.settingsControl.displayOptionsCheckBoxShowHealthStatus:SetValue( EMA.db.showHealthStatus )
	EMA.settingsControl.displayOptionsCheckBoxShowClassColors:SetValue( EMA.db.showClassColors )
	EMA.settingsControl.displayOptionsCheckBoxShowHealthStatusValues:SetValue( EMA.db.healthStatusShowValues )
	EMA.settingsControl.displayOptionsCheckBoxShowHealthStatusPercentage:SetValue( EMA.db.healthStatusShowPercentage )	
	EMA.settingsControl.displayOptionsHealthStatusWidthSlider:SetValue( EMA.db.healthStatusWidth )
	EMA.settingsControl.displayOptionsHealthStatusHeightSlider:SetValue( EMA.db.healthStatusHeight )	
	EMA.settingsControl.displayOptionsCheckBoxShowPowerStatus:SetValue( EMA.db.showPowerStatus )
	EMA.settingsControl.displayOptionsCheckBoxShowPowerStatusValues:SetValue( EMA.db.powerStatusShowValues )
	EMA.settingsControl.displayOptionsCheckBoxShowPowerStatusPercentage:SetValue( EMA.db.powerStatusShowPercentage )
	EMA.settingsControl.displayOptionsPowerStatusWidthSlider:SetValue( EMA.db.powerStatusWidth )
	EMA.settingsControl.displayOptionsPowerStatusHeightSlider:SetValue( EMA.db.powerStatusHeight )
	EMA.settingsControl.displayOptionsCheckBoxShowComboStatus:SetValue( EMA.db.showComboStatus )
	EMA.settingsControl.displayOptionsCheckBoxShowComboStatusValues:SetValue( EMA.db.comboStatusShowValues )
	EMA.settingsControl.displayOptionsComboStatusWidthSlider:SetValue( EMA.db.comboStatusWidth )
	EMA.settingsControl.displayOptionsComboStatusHeightSlider:SetValue( EMA.db.comboStatusHeight )	
	EMA.settingsControl.displayOptionsBackgroundColourPicker:SetColor( EMA.db.frameBackgroundColourR, EMA.db.frameBackgroundColourG, EMA.db.frameBackgroundColourB, EMA.db.frameBackgroundColourA )
	EMA.settingsControl.displayOptionsBorderColourPicker:SetColor( EMA.db.frameBorderColourR, EMA.db.frameBorderColourG, EMA.db.frameBorderColourB, EMA.db.frameBorderColourA )
--	EMA.settingsControl.displayOptionsCheckBoxShowEquippedOnly:SetValue( EMA.db.ShowEquippedOnly )	
	-- State.
	-- Trying to change state in combat lockdown causes taint. Let's not do that. Eventually it would be nice to have a "proper state driven team display",
	-- but this workaround is enough for now.
	if not InCombatLockdown() then
		EMA.settingsControl.displayOptionsCheckBoxShowTeamListOnlyOnMaster:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxHideTeamListInCombat:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxEnableClique:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCharactersPerBar:SetDisabled(not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxStackVertically:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxShowListTitle:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxOlnyShowInParty:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxHpManaOutOfParty:SetDisabled( not EMA.db.showTeamList)
		EMA.settingsControl.displayOptionsTeamListScaleSlider:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsTeamListTransparencySlider:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsTeamListMediaStatus:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsTeamListMediaBorder:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsTeamListMediaBackground:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsTeamListMediaFont:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsSetFontSize:SetDisabled( not EMA.db.showTeamList )		
		EMA.settingsControl.displayOptionsCheckBoxShowPortrait:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsPortraitWidthSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showCharacterPortrait )
		EMA.settingsControl.displayOptionsCheckBoxShowFollowStatus:SetDisabled( not EMA.db.showTeamList)
		EMA.settingsControl.displayOptionsCheckBoxShowFollowStatusName:SetDisabled( not EMA.db.showTeamList or not EMA.db.showFollowStatus )
		EMA.settingsControl.displayOptionsFollowStatusWidthSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showFollowStatus )
		EMA.settingsControl.displayOptionsFollowStatusHeightSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showFollowStatus)
		EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatus:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxShowXpStatus:SetDisabled( not EMA.db.showTeamList or not EMA.db.showExperienceStatus)
		EMA.settingsControl.displayOptionsCheckBoxShowRepStatus:SetDisabled( not EMA.db.showTeamList or not EMA.db.showExperienceStatus )
		EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatusValues:SetDisabled( not EMA.db.showTeamList or not EMA.db.showExperienceStatus )
		EMA.settingsControl.displayOptionsCheckBoxShowExperienceStatusPercentage:SetDisabled( not EMA.db.showTeamList or not EMA.db.showExperienceStatus )
		EMA.settingsControl.displayOptionsExperienceStatusWidthSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showExperienceStatus)
		EMA.settingsControl.displayOptionsExperienceStatusHeightSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showExperienceStatus )
		EMA.settingsControl.displayOptionsCheckBoxShowHealthStatus:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxShowClassColors:SetDisabled( not EMA.db.showTeamList or not EMA.db.showHealthStatus )
		EMA.settingsControl.displayOptionsCheckBoxShowHealthStatusValues:SetDisabled( not EMA.db.showTeamList or not EMA.db.showHealthStatus )
		EMA.settingsControl.displayOptionsCheckBoxShowHealthStatusPercentage:SetDisabled( not EMA.db.showTeamList or not EMA.db.showHealthStatus )
		EMA.settingsControl.displayOptionsHealthStatusWidthSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showHealthStatus )
		EMA.settingsControl.displayOptionsHealthStatusHeightSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showHealthStatus )
		EMA.settingsControl.displayOptionsCheckBoxShowPowerStatus:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxShowPowerStatusValues:SetDisabled( not EMA.db.showTeamList or not EMA.db.showPowerStatus )
		EMA.settingsControl.displayOptionsCheckBoxShowPowerStatusPercentage:SetDisabled( not EMA.db.showTeamList or not EMA.db.showPowerStatus )
		EMA.settingsControl.displayOptionsPowerStatusWidthSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showPowerStatus )
		EMA.settingsControl.displayOptionsPowerStatusHeightSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showPowerStatus )
		EMA.settingsControl.displayOptionsCheckBoxShowComboStatus:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsCheckBoxShowComboStatusValues:SetDisabled( not EMA.db.showTeamList or not EMA.db.showComboStatus )
		EMA.settingsControl.displayOptionsComboStatusWidthSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showComboStatus)
		EMA.settingsControl.displayOptionsComboStatusHeightSlider:SetDisabled( not EMA.db.showTeamList or not EMA.db.showComboStatus)
		EMA.settingsControl.displayOptionsBackgroundColourPicker:SetDisabled( not EMA.db.showTeamList )
		EMA.settingsControl.displayOptionsBorderColourPicker:SetDisabled( not EMA.db.showTeamList )
		if EMA.teamListCreated == true then
			EMA:RefreshTeamListControls()
			EMA:SettingsUpdateBorderStyle()
			EMA:SettingsUpdateStatusBarTexture()
			EMA:SettingsUpdateFontStyle()
			EMA:SetTeamListVisibility()	
			EMA:SettingsUpdateFollowTextAll()
			EMA:SettingsUpdateExperienceAll()
			EMA:SettingsUpdateReputationAll()
			EMA:SettingsUpdateHealthAll()
			EMA:SettingsUpdatePowerAll()
			EMA:SettingsUpdateComboAll()
		end
	else
		EMA.updateSettingsAfterCombat = true
	end
end

-- Settings received.
function EMA:EMAOnSettingsReceived( characterName, settings )	
	if characterName ~= EMA.characterName then
		-- Update the settings.
		EMA.db.showTeamList = settings.showTeamList
		EMA.db.showTeamListOnMasterOnly = settings.showTeamListOnMasterOnly
		EMA.db.hideTeamListInCombat = settings.hideTeamListInCombat
		EMA.db.enableClique = settings.enableClique
		EMA.db.charactersPerRow = settings.charactersPerRow
		EMA.db.barsAreStackedVertically = settings.barsAreStackedVertically
		EMA.db.teamListHorizontal = settings.teamListHorizontal
		EMA.db.showListTitle = settings.showListTitle
		EMA.db.olnyShowInParty = settings.olnyShowInParty
		EMA.db.healthManaOutOfParty = settings.healthManaOutOfParty
		EMA.db.teamListScale = settings.teamListScale
		EMA.db.statusBarTexture = settings.statusBarTexture
		EMA.db.borderStyle = settings.borderStyle
		EMA.db.backgroundStyle = settings.backgroundStyle
		EMA.db.fontStyle = settings.fontStyle
		EMA.db.fontSize = settings.fontSize
		EMA.db.showCharacterPortrait = settings.showCharacterPortrait
		EMA.db.characterPortraitWidth = settings.characterPortraitWidth
		EMA.db.showFollowStatus = settings.showFollowStatus
		EMA.db.followStatusWidth = settings.followStatusWidth
		EMA.db.followStatusHeight = settings.followStatusHeight
		EMA.db.followStatusShowName = settings.followStatusShowName
		EMA.db.showExperienceStatus = settings.showExperienceStatus
		EMA.db.showXpStatus = settings.showXpStatus
--		EMA.db.showHonorStatus = settings.showHonorStatus
		EMA.db.showRepStatus = settings.showRepStatus
		EMA.db.experienceStatusWidth = settings.experienceStatusWidth
		EMA.db.experienceStatusHeight = settings.experienceStatusHeight
		EMA.db.experienceStatusShowValues = settings.experienceStatusShowValues
		EMA.db.experienceStatusShowPercentage = settings.experienceStatusShowPercentage
		EMA.db.showHealthStatus = settings.showHealthStatus
		EMA.db.showClassColors = settings.showClassColors
		EMA.db.healthStatusWidth = settings.healthStatusWidth
		EMA.db.healthStatusHeight = settings.healthStatusHeight
		EMA.db.healthStatusShowValues = settings.healthStatusShowValues
		EMA.db.healthStatusShowPercentage = settings.healthStatusShowPercentage
		EMA.db.showPowerStatus = settings.showPowerStatus
		EMA.db.powerStatusWidth = settings.powerStatusWidth
		EMA.db.powerStatusHeight = settings.powerStatusHeight		
		EMA.db.powerStatusShowValues = settings.powerStatusShowValues
		EMA.db.powerStatusShowPercentage = settings.powerStatusShowPercentage
		EMA.db.showComboStatus = settings.showComboStatus
		EMA.db.comboStatusWidth = settings.comboStatusWidth
		EMA.db.comboStatusHeight = settings.comboStatusHeight		
		EMA.db.comboStatusShowValues = settings.comboStatusShowValues
		EMA.db.comboStatusShowPercentage = settings.comboStatusShowPercentage
		EMA.db.frameAlpha = settings.frameAlpha
		EMA.db.framePoint = settings.framePoint
		EMA.db.frameRelativePoint = settings.frameRelativePoint
		EMA.db.frameXOffset = settings.frameXOffset
		EMA.db.frameYOffset = settings.frameYOffset
		EMA.db.frameBackgroundColourR = settings.frameBackgroundColourR
		EMA.db.frameBackgroundColourG = settings.frameBackgroundColourG
		EMA.db.frameBackgroundColourB = settings.frameBackgroundColourB
		EMA.db.frameBackgroundColourA = settings.frameBackgroundColourA
		EMA.db.frameBorderColourR = settings.frameBorderColourR
		EMA.db.frameBorderColourG = settings.frameBorderColourG
		EMA.db.frameBorderColourB = settings.frameBorderColourB
		EMA.db.frameBorderColourA = settings.frameBorderColourA		
		-- Refresh the settings.
		EMA:SettingsRefresh()
		-- Tell the player.
		EMA:Print( L["SETTINGS_RECEIVED_FROM_A"]( characterName ) )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Settings Callbacks.
-------------------------------------------------------------------------------------------------------------

function EMA:SettingsPushSettingsClick( event )
	EMA:EMASendSettings()
end

function EMA:SettingsToggleShowTeamList( event, checked )
	EMA.db.showTeamList = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowTeamListOnMasterOnly( event, checked )
	EMA.db.showTeamListOnMasterOnly = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleHideTeamListInCombat( event, checked )
	EMA.db.hideTeamListInCombat = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleEnableClique( event, checked )
	EMA.db.enableClique = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeCharactersPerBar( event, value )
	EMA.db.charactersPerRow = tonumber( value )
	EMA:SettingsRefresh()
end


function EMA:SettingsToggleStackVertically( event, checked )
	EMA.db.barsAreStackedVertically = checked;
	EMA.db.teamListHorizontal = checked;
	EMA:SettingsRefresh();
end


function EMA:SettingsToggleShowTeamListTitle( event, checked )
	EMA.db.showListTitle = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleOlnyShowinParty( event, checked )
	EMA.db.olnyShowInParty = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleHpManaOutOfParty( event, checked )
	EMA.db.healthManaOutOfParty = checked
	EMA:SettingsRefresh()
end


function EMA:SettingsChangeScale( event, value )
	EMA.db.teamListScale = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeTransparency( event, value )
	EMA.db.frameAlpha = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeStatusBarTexture( event, value )
	EMA.db.statusBarTexture = value
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeBorderStyle( event, value )
	EMA.db.borderStyle = value
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeBackgroundStyle( event, value )
	EMA.db.backgroundStyle = value
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeFontStyle( event, value )
	EMA.db.fontStyle = value
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeFontSize( event, value )
	EMA.db.fontSize = value
	EMA:SettingsRefresh()
end


function EMA:SettingsToggleShowPortrait( event, checked )
	EMA.db.showCharacterPortrait = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsChangePortraitWidth( event, value )
	EMA.db.characterPortraitWidth = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowFollowStatus( event, checked )
	EMA.db.showFollowStatus = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowFollowStatusName( event, checked )
	EMA.db.followStatusShowName = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowToolTipInfo( event, checked )
	EMA.db.showToolTipInfo = checked
	EMA:SettingsRefresh()
end


function EMA:SettingsChangeFollowStatusWidth( event, value )
	EMA.db.followStatusWidth = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeFollowStatusHeight( event, value )
	EMA.db.followStatusHeight = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowExperienceStatus( event, checked )
	EMA.db.showExperienceStatus = checked
	EMA:SettingsRefresh()
end
--

function EMA:SettingsToggleShowXpStatus( event, checked )
	EMA.db.showXpStatus = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowRepStatus( event, checked )
	EMA.db.showRepStatus = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowExperienceStatusValues( event, checked )
	EMA.db.experienceStatusShowValues = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowExperienceStatusPercentage( event, checked )
	EMA.db.experienceStatusShowPercentage = checked
	EMA.SettingsRefresh()
end

function EMA:SettingsChangeExperienceStatusWidth( event, value )
	EMA.db.experienceStatusWidth = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeExperienceStatusHeight( event, value )
	EMA.db.experienceStatusHeight = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowHealthStatus( event, checked )
	EMA.db.showHealthStatus = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowClassColors( event, checked )
	EMA.db.showClassColors = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowHealthStatusValues( event, checked )
	EMA.db.healthStatusShowValues = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowHealthStatusPercentage( event, checked )
	EMA.db.healthStatusShowPercentage = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeHealthStatusWidth( event, value )
	EMA.db.healthStatusWidth = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeHealthStatusHeight( event, value )
	EMA.db.healthStatusHeight = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowPowerStatus( event, checked )
	EMA.db.showPowerStatus = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowPowerStatusValues( event, checked )
	EMA.db.powerStatusShowValues = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowPowerStatusPercentage( event, checked )
	EMA.db.powerStatusShowPercentage = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsChangePowerStatusWidth( event, value )
	EMA.db.powerStatusWidth = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsChangePowerStatusHeight( event, value )
	EMA.db.powerStatusHeight = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowComboStatus( event, checked )
	EMA.db.showComboStatus = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowComboStatusValues( event, checked )
	EMA.db.comboStatusShowValues = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsToggleShowComboStatusPercentage( event, checked )
	EMA.db.comboStatusShowPercentage = checked
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeComboStatusWidth( event, value )
	EMA.db.comboStatusWidth = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsChangeComboStatusHeight( event, value )
	EMA.db.comboStatusHeight = tonumber( value )
	EMA:SettingsRefresh()
end

function EMA:SettingsBackgroundColourPickerChanged( event, r, g, b, a )
	EMA.db.frameBackgroundColourR = r
	EMA.db.frameBackgroundColourG = g
	EMA.db.frameBackgroundColourB = b
	EMA.db.frameBackgroundColourA = a
	EMA:SettingsRefresh()
end

function EMA:SettingsBorderColourPickerChanged( event, r, g, b, a )
	EMA.db.frameBorderColourR = r
	EMA.db.frameBorderColourG = g
	EMA.db.frameBorderColourB = b
	EMA.db.frameBorderColourA = a
	EMA:SettingsRefresh()
end

--[[
function EMA:SettingsToggleShowEquippedOnly( event, checked )
	EMA.db.ShowEquippedOnly = checked
	EMA:SettingsRefresh()
end ]]


-------------------------------------------------------------------------------------------------------------
-- Commands.
-------------------------------------------------------------------------------------------------------------

-- A EMA command has been recieved.
function EMA:EMAOnCommandReceived( characterName, commandName, ... )
	EMA:DebugMessage( "EMAOnCommandReceived", characterName )
	--EMA:Print("DebugCommandReceived", characterName, commandName )
	if commandName == EMA.COMMAND_FOLLOW_STATUS_UPDATE then
		EMA:ProcessUpdateFollowStatusMessage( characterName, ... )
	end
	if commandName == EMA.COMMAND_EXPERIENCE_STATUS_UPDATE then
		EMA:ProcessUpdateExperienceStatusMessage( characterName, ... )
	end
	if commandName == EMA.COMMAND_REPUTATION_STATUS_UPDATE then
		EMA:ProcessUpdateReputationStatusMessage( characterName, ... )
	end
	if commandName == EMA.COMMAND_COMBO_STATUS_UPDATE then
		EMA:ProcessUpdateComboStatusMessage( characterName, ... )
	end	
	if commandName == EMA.COMMAND_COMBAT_STATUS_UPDATE then
		EMA:ProcessUpdateCombatStatusMessage( characterName, ... )
	end
	if commandName == EMA.COMMAND_HEALTH_STATUS_UPDATE then
		EMA:ProcessUpdateHealthStatusMessage( characterName, ... )
	end
	if commandName == EMA.COMMAND_POWER_STATUS_UPDATE then
		EMA:ProcessUpdatePowerStatusMessage(characterName, ... )
	end																		  	
end	

-------------------------------------------------------------------------------------------------------------
-- Shared Media Callbacks
-------------------------------------------------------------------------------------------------------------

function EMA:LibSharedMedia_Registered()
end

function EMA:LibSharedMedia_SetGlobal()
end

-------------------------------------------------------------------------------------------------------------
-- Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Range Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function EMA:RangeUpdateCommand()
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do			
		--EMA:Print("name", characterName )
		local name = Ambiguate( characterName, "none" )
		local range = UnitInRange( name )

	end				
end

-------------------------------------------------------------------------------------------------------------
-- Follow Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function EMA:AUTOFOLLOW_BEGIN( event, name, ... )	
	if EMA.isFollowing == false then
		EMA:ScheduleTimer( "SendFollowStatusUpdateCommand", 1 , true)
		EMA.isFollowing = true
	end
end

function EMA:AUTOFOLLOW_END( event, ... )	
	EMA:ScheduleTimer( "SendFollowStatusUpdateCommand", 1 , false )	
end


function EMA:SendFollowStatusUpdateCommand( isFollowing )
	if EMA.db.showTeamList == true and EMA.db.showFollowStatus == true then	
		local canSend = false
		local alpha = AutoFollowStatus:GetAlpha()
		--EMA:Print("testA", alpha)
		if alpha < 1 then
			canSend = true
			EMA.isFollowing = false
		end
		if isFollowing == true then
			canSend = true	
		end	
		-- Check to see if EMAFollow is enabled and follow strobing is on.  If this is the case then
		-- do not send the follow update.
		if EMAApi.Follow ~= nil then
			if EMAApi.Follow.IsFollowingStrobing() == true then
				canSend = false
			end
		end	
		--EMA:Print("canSend", canSend )
		if canSend == true then
			if EMA.db.showTeamListOnMasterOnly == true then
				EMA:EMASendCommandToMaster( EMA.COMMAND_FOLLOW_STATUS_UPDATE, isFollowing )
			else
				EMA:EMASendCommandToTeam( EMA.COMMAND_FOLLOW_STATUS_UPDATE, isFollowing )
			end
		end
	end
end


function EMA:ProcessUpdateFollowStatusMessage( characterName, isFollowing )
	EMA:UpdateFollowStatus( characterName, isFollowing )
end

function EMA:UpdateFollowStatus( characterName, isFollowing )
	--EMA:Print("follow", characterName, "follow", isFollowing)
	if CanDisplayTeamList() == false then
		return
	end
	if EMA.db.showFollowStatus == false then
		return
	end
	characterName = EMAUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local followBar = characterStatusBar["followBar"]
	if isFollowing == true then
		-- Following.
		followBar:SetStatusBarColor( 0.05, 0.85, 0.05, 1.00 )
		LibButtonGlow.HideOverlayGlow(followBar)
	else
		if isFollowLeader == true then
			-- Follow leader.
			followBar:SetStatusBarColor( 0.55, 0.15, 0.15, 0.25 )
			LibButtonGlow.HideOverlayGlow(followBar)
		else
			-- Not following.
		LibButtonGlow.ShowOverlayGlow(followBar)
		followBar:SetStatusBarColor( 0.85, 0.05, 0.05, 1.00 )
		EMA:ScheduleTimer("EndGlowFollowBar", 2 , followBar)
		end
	end
end

function EMA:EndGlowFollowBar(frame)
	LibButtonGlow.HideOverlayGlow(frame)
end

-- TEXT and Combat updates

function EMA:SendCombatStatusUpdateCommand()
	local inCombat = UnitAffectingCombat("player")
	--EMA:Print("canSend", inCombat)
	if EMA.db.showTeamListOnMasterOnly == true then
		EMA:EMASendCommandToMaster( EMA.COMMAND_COMBAT_STATUS_UPDATE, inCombat )
	else
		EMA:EMASendCommandToTeam( EMA.COMMAND_COMBAT_STATUS_UPDATE, inCombat )
	end
end

function EMA:SettingsUpdateFollowTextAll()
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do			
		EMA:SettingsUpdateFollowText( characterName, nil )
	end
end


function EMA:ProcessUpdateCombatStatusMessage( characterName, inCombat )
--	EMA:Print("test", characterName, inCombat )
	EMA:SettingsUpdateFollowText( characterName, inCombat )
end


function EMA:SettingsUpdateFollowText( characterName, inCombat )
	--EMA:Print("FollowTextInfo", characterName, inCombat) -- debug
	if CanDisplayTeamList() == false then
		return
	end
	if EMA.db.showFollowStatus == false then
		return
	end
	characterName = EMAUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local followBarText = characterStatusBar["followBarText"]
	
	if inCombat == true then
		followBarText:SetTextColor(1.0, 0.5, 0.25)
	else
		followBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	end
	
	local text = ""
	if EMA.db.followStatusShowName == true then
		text = text..Ambiguate( characterName, "none" )
	end
	followBarText:SetText( text )
end


-------------------------------------------------------------------------------------------------------------
-- Experience Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function EMA:PLAYER_XP_UPDATE( event, ... )
	EMA:SendExperienceStatusUpdateCommand()	
end

function EMA:UPDATE_EXHAUSTION( event, ... )
	--TODO This Event Is Spaming so we have turned it off for now it does it in rested areas
	--EMA:Print("testSpam")
	--EMA:SendExperienceStatusUpdateCommand()	
end

function EMA:PLAYER_LEVEL_UP( event, ... )
	EMA:SendExperienceStatusUpdateCommand()	
end

function EMA:ARTIFACT_XP_UPDATE(event, ...)
	EMA:SendExperienceStatusUpdateCommand()	
end

--[[ CLEAN UP FOR 8.0
function EMA:HONOR_XP_UPDATE(event, arg1, agr2, ...)
	--EMA:SendExperienceStatusUpdateCommand()	
end

function EMA:HONOR_LEVEL_UPDATE(event, arg1, agr2, ...)
	---EMA:SendExperienceStatusUpdateCommand()	
end

function EMA:HONOR_PRESTIGE_UPDATE(event, arg1, agr2, ...)
	--EMA:SendExperienceStatusUpdateCommand()	
end
]]

function EMA:SendExperienceStatusUpdateCommand()
	if EMA.db.showTeamList == true and EMA.db.showExperienceStatus == true then
		--Player XP
		local playerExperience = UnitXP( "player" )
		local playerMaxExperience = UnitXPMax( "player" )
		local playerMaxLevel = GetMaxPlayerLevel()	
		local playerLevel = UnitLevel("player")
		local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = GetRestState()
		
		--	EMA:Print("testSend", honorXP, honorMax, HonorLevel, honorExhaustionStateID)
		if EMA.db.showTeamListOnMasterOnly == true then
				--EMA:Print("Testtoteam", characterName, name, xp, xpForNextPoint, numPointsAvailableToSpend)
				--EMA:Print("TestTOTEAM", characterName, name, xp, xpForNextPoint, numPointsAvailableToSpend)
				EMA:EMASendCommandToMaster( EMA.COMMAND_EXPERIENCE_STATUS_UPDATE, playerExperience, playerMaxExperience, exhaustionStateID, playerLevel )			
			else
				--EMA:DebugMessage( "SendExperienceStatusUpdateCommand TO TEAM!" )
				--EMA:Print("TestTOTEAM", characterName, name, xp, xpForNextPoint, numPointsAvailableToSpend)
				EMA:EMASendCommandToTeam( EMA.COMMAND_EXPERIENCE_STATUS_UPDATE, playerExperience, playerMaxExperience, exhaustionStateID, playerLevel )
			end
	end
end

function EMA:ProcessUpdateExperienceStatusMessage( characterName, playerExperience, playerMaxExperience, exhaustionStateID, playerLevel )
	EMA:UpdateExperienceStatus( characterName, playerExperience, playerMaxExperience, exhaustionStateID, playerLevel ) 
end

function EMA:SettingsUpdateExperienceAll()
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do			
		EMA:UpdateExperienceStatus( characterName, nil, nil, nil, nil )
	end
end

function EMA:UpdateExperienceStatus( characterName, playerExperience, playerMaxExperience, exhaustionStateID, playerLevel )
--	EMA:Print( "UpdateExperienceStatus", characterName, playerExperience, playerMaxExperience, exhaustionStateID, playerLevel)
--	EMA:Print("honorTest", characterName, honorXP, honorMax, HonorLevel, prestigeLevel, honorExhaustionStateID)
	if CanDisplayTeamList() == false then
		return
	end
	if EMA.db.showExperienceStatus == false then
		return
	end
	characterName = EMAUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	
	local experienceBarText = characterStatusBar["experienceBarText"]	
	local experienceBar = characterStatusBar["experienceBar"]	
	
	if playerExperience == nil then
		playerExperience = experienceBarText.playerExperience
	end
	if playerMaxExperience == nil then
		playerMaxExperience = experienceBarText.playerMaxExperience
	end
	if exhaustionStateID == nil then
		exhaustionStateID = experienceBarText.exhaustionStateID
	end	
	if playerLevel == nil then
		playerLevel = experienceBarText.playerLevel
	end	
	

	experienceBarText.playerExperience = playerExperience
	experienceBarText.playerMaxExperience = playerMaxExperience
	experienceBarText.exhaustionStateID = exhaustionStateID
	experienceBarText.playerLevel = playerLevel
	local min, max = math.min(0, playerExperience), playerMaxExperience

	experienceBar:SetAnimatedValues(playerExperience, min, max , playerLevel)
	
	local text = ""
	if EMA.db.experienceStatusShowValues == true then
		text = text..tostring( AbbreviateLargeNumbers(playerExperience) )..L[" / "]..tostring( AbbreviateLargeNumbers(playerMaxExperience) )..L[" "]
	end
	if EMA.db.experienceStatusShowPercentage == true then
		if EMA.db.experienceStatusShowValues == true then
			text = tostring( AbbreviateLargeNumbers(playerExperience) )..L[" "]..L["("]..tostring( floor( (playerExperience/playerMaxExperience)*100) )..L["%"]..L[")"]
		else
			text = tostring( floor( (playerExperience/playerMaxExperience)*100) )..L["%"]
		end
	end
	experienceBarText:SetText( text )
	if exhaustionStateID == 1 then
		experienceBar:SetStatusBarColor( 0.0, 0.39, 0.88, 1.0 )
		experienceBar.backgroundTexture:SetColorTexture( 0.0, 0.39, 0.88, 0.15 )
	else
		experienceBar:SetStatusBarColor( 0.58, 0.0, 0.55, 1.0 )
		experienceBar.backgroundTexture:SetColorTexture( 0.58, 0.0, 0.55, 0.15 )
	end	

end	




-------------------------------------------------------------------------------------------------------------
-- Reputation Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function EMA:CHAT_MSG_COMBAT_FACTION_CHANGE( event, ... )
	EMA:SendReputationStatusUpdateCommand()	
end

function EMA:SetWatchedFactionIndex( index )
	EMA:ScheduleTimer( "SendReputationStatusUpdateCommand", 5 )
end

function EMA:SendReputationStatusUpdateCommand()
	if EMA.db.showTeamList == true and EMA.db.showRepStatus == true then
		local reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue = GetWatchedFactionInfo()
		if EMA.db.showTeamListOnMasterOnly == true then
			EMA:EMASendCommandToMaster( EMA.COMMAND_REPUTATION_STATUS_UPDATE, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue )
		else
			EMA:EMASendCommandToTeam( EMA.COMMAND_REPUTATION_STATUS_UPDATE, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue )
		end
	end
end

function EMA:ProcessUpdateReputationStatusMessage( characterName, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue)
	EMA:UpdateReputationStatus( characterName, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue)
end

function EMA:SettingsUpdateReputationAll()
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do			
		EMA:UpdateReputationStatus( characterName, nil, nil, nil, nil, nil, nil )
	end
end

function EMA:UpdateReputationStatus( characterName, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue)
	if CanDisplayTeamList() == false then
		return
	end
	if EMA.db.showRepStatus == false then
		return
	end
	characterName = EMAUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local reputationBarText = characterStatusBar["reputationBarText"]	
	local reputationBar = characterStatusBar["reputationBar"]	
	if reputationName == nil then
		reputationName = reputationBarText.reputationName
	end
	if reputationStandingID == nil then
		reputationStandingID = reputationBarText.reputationStandingID
	end
	if reputationBarMin == nil then
		reputationBarMin = reputationBarText.reputationBarMin
	end
	if reputationBarMax == nil then
		reputationBarMax = reputationBarText.reputationBarMax
	end
	if reputationBarValue == nil then
		reputationBarValue = reputationBarText.reputationBarValue
	end
	reputationBarText.reputationName = reputationName
	reputationBarText.reputationStandingID = reputationStandingID
	reputationBarText.reputationBarMin = reputationBarMin
	reputationBarText.reputationBarMax = reputationBarMax
	reputationBarText.reputationBarValue = reputationBarValue
	reputationBar:SetAnimatedValues(reputationBarValue, reputationBarMin, reputationBarMax, 0 )

   if reputationName == 0 then
        reputationBarMin = 0
        reputationBarMax = 100
        reputationBarValue = 100
        reputationStandingID = 1
    end	
	local text = ""
	if EMA.db.experienceStatusShowValues == true then
		text = text..tostring( AbbreviateLargeNumbers(reputationBarValue-reputationBarMin) )..L[" / "]..tostring( AbbreviateLargeNumbers(reputationBarMax-reputationBarMin) )..L[" "]
	end
	if EMA.db.experienceStatusShowPercentage == true then
		local textPercentage = tostring( floor( (reputationBarValue-reputationBarMin)/(reputationBarMax-reputationBarMin)*100 ) )..L["%"]
		if EMA.db.experienceStatusShowValues == true then
			text = tostring( AbbreviateLargeNumbers(reputationBarValue-reputationBarMin) )..L[" "]..L["("]..textPercentage..L[")"]
		else
			text = text..textPercentage
		end
	end
	reputationBarText:SetText( text )
	local barColor = _G.FACTION_BAR_COLORS[reputationStandingID]
	if barColor ~= nil then
		reputationBar:SetStatusBarColor( barColor.r, barColor.g, barColor.b, 1.0 )
		reputationBar.backgroundTexture:SetColorTexture( barColor.r, barColor.g, barColor.b, 0.15 )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Health Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function EMA:UNIT_HEALTH( event, unit, ... )
	--EMA:Print("test2", unit)
	EMA:SendHealthStatusUpdateCommand( unit )
end

function EMA:UNIT_MAXHEALTH( event, unit, ... )
	--EMA:Print("sendtest2", unit )
	EMA:SendHealthStatusUpdateCommand( unit )
end

function EMA:UNIT_HEAL_PREDICTION( event, unit, ... )
	--EMA:Print("test2", unit)
	EMA:SendHealthStatusUpdateCommand( unit )
end


function EMA:SendHealthStatusUpdateCommand(unit)
	--EMA:Print("debugHealthUpd", unit )
	if unit == nil then
		return
	end	
	if EMA.db.showTeamList == true and EMA.db.showHealthStatus == true then
		if EMA.db.healthManaOutOfParty == true then
			if unit == "player" then 
				--EMA:Print("itsme", unit)
				local playerHealth = UnitHealth( unit )
				local playerMaxHealth = UnitHealthMax( unit )
				local _, class = UnitClass ("player")
				
				if EMA.db.showTeamListOnMasterOnly == true then
					--EMA:Print( "SendHealthStatusUpdateCommand TO Master!" )
					EMA:EMASendCommandToMaster( EMA.COMMAND_HEALTH_STATUS_UPDATE, playerHealth, playerMaxHealth, class )
				else
					--EMA:Print( "SendHealthStatusUpdateCommand TO Team!" )
					EMA:EMASendCommandToTeam( EMA.COMMAND_HEALTH_STATUS_UPDATE, playerHealth, playerMaxHealth, class )
				end	
			end
		else
			local playerHealth = UnitHealth( unit )
			local playerMaxHealth = UnitHealthMax( unit )
			local characterName, characterRealm = UnitName( unit )
			local _, class = UnitClass ( unit )
			local character = EMAUtilities:AddRealmToNameIfNotNil( characterName, characterRealm )
			--EMA:Print("HeathStats", character, playerHealth, playerMaxHealth)
			EMA:UpdateHealthStatus( character, playerHealth, playerMaxHealth, class)
		end
	end
end

function EMA:ProcessUpdateHealthStatusMessage( characterName, playerHealth, playerMaxHealth, class )
	EMA:UpdateHealthStatus( characterName, playerHealth, playerMaxHealth, class)
end

function EMA:SettingsUpdateHealthAll()
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do			
		EMA:UpdateHealthStatus( characterName, nil, nil, nil )
	end
end

function EMA:UpdateHealthStatus( characterName, playerHealth, playerMaxHealth, class )
	--EMA:Print("testUpdate", characterName, playerHealth, playerMaxHealth, class ) 
		if characterName == nil then
		return
	end
	if CanDisplayTeamList() == false then
		return
	end
	if EMA.db.showHealthStatus == false then
		return
	end
	characterName = EMAUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local healthBarText = characterStatusBar["healthBarText"]	
	local healthBar = characterStatusBar["healthBar"]
	local healthIncomingBar = characterStatusBar["healthIncomingBar"]
	
	if playerMaxHealth == 0 then 
		playerMaxHealth = healthBarText.playerMaxHealth
	end
	if playerHealth == nil then
		playerHealth = healthBarText.playerHealth
	end
	if playerMaxHealth == nil then
		playerMaxHealth = healthBarText.playerMaxHealth
	end		
	healthBarText.playerHealth = playerHealth
	healthBarText.playerMaxHealth = playerMaxHealth
	-- Set statusBar
	healthBar:SetMinMaxValues( 0, tonumber( playerMaxHealth ) )
	healthBar:SetValue( tonumber( playerHealth ) )
	healthIncomingBar:SetMinMaxValues( 0, tonumber( playerMaxHealth ) )
	healthIncomingBar:SetValue( tonumber( playerHealth ) )	
	
	local text = ""
	if UnitIsDeadOrGhost(Ambiguate( characterName, "none" ) ) == true then
		--EMA:Print("dead", characterName)
		text = text..L["DEAD"]
	else
		if EMA.db.healthStatusShowValues == true then
			text = text..tostring( AbbreviateLargeNumbers(playerHealth) )..L[" / "]..tostring( AbbreviateLargeNumbers(playerMaxHealth) )..L[" "]
		end
		if EMA.db.healthStatusShowPercentage == true then
			if EMA.db.healthStatusShowValues == true then
				text = tostring( AbbreviateLargeNumbers(playerHealth) )..L[" "]..L["("]..tostring( floor( (playerHealth/playerMaxHealth)*100) )..L["%"]..L[")"]
			else
				text = tostring( floor( (playerHealth/playerMaxHealth)*100) )..L["%"]
			end
		end
	end
	healthBarText:SetText( text )		
	EMA:SetStatusBarColourForHealth( healthBar, floor((playerHealth/playerMaxHealth)*100), characterName, class)
end

-- TODO Support for classColors
function EMA:SetStatusBarColourForHealth( statusBar, statusValue, characterName, class )
	--EMA:Print("colour class", statusValue, characterName)
	local classColor = RAID_CLASS_COLORS[class]
	if classColor ~= nil and EMA.db.showClassColors == true then
		-- EMA:Print("test", characterName, class, classColor.r, classColor.g, classColor.b )
		local r = classColor.r
		local g = classColor.g
		local b = classColor.b
		statusBar:SetStatusBarColor( r, g, b, 1 )
	else
		local r, g, b = 0, 0, 0
		statusValue = statusValue / 100
		if( statusValue > 0.5 ) then
			r = (1.0 - statusValue) * 2
			g = 1.0
		else
			r = 1.0
			g = statusValue * 2
		end
		b = b
		statusBar:SetStatusBarColor( r, g, b )
	end
end	

-------------------------------------------------------------------------------------------------------------
-- Power Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function EMA:UNIT_POWER( event, unit, ... )
	EMA:SendPowerStatusUpdateCommand( unit )
end

function EMA:UNIT_DISPLAYPOWER( event, unit, ... )
	EMA:SendPowerStatusUpdateCommand( unit )
end

function EMA:SendPowerStatusUpdateCommand( unit )
	if EMA.db.showTeamList == true and EMA.db.showPowerStatus == true then
		if EMA.db.healthManaOutOfParty == true then
			if unit == "player" then 
				--EMA:Print("itsme", unit)
				local playerPower = UnitPower( unit )
				local playerMaxPower = UnitPowerMax( unit )
				local _, powerToken = UnitPowerType( unit )
				if EMA.db.showTeamListOnMasterOnly == true then
					--EMA:Print( "SendHealthStatusUpdateCommand TO Master!"  )
					EMA:EMASendCommandToMaster( EMA.COMMAND_POWER_STATUS_UPDATE, playerPower, powerToken )
				else
					--EMA:Print( "SendHealthStatusUpdateCommand TO Team!", playerPower, playerMaxPower, powerToken )
					EMA:EMASendCommandToTeam( EMA.COMMAND_POWER_STATUS_UPDATE, playerPower, playerMaxPower, powerToken )
				end	
			end
		else
			local playerPower = UnitPower( unit )
			local playerMaxPower = UnitPowerMax( unit )
			local characterName, characterRealm = UnitName( unit )
			local _, powerToken = UnitPowerType( unit )
			local character = EMAUtilities:AddRealmToNameIfNotNil( characterName, characterRealm )
			--EMA:Print("power", character, playerPower, playerMaxPower )
			EMA:UpdatePowerStatus( character, playerPower, playerMaxPower, powerToken)
		end
	end
end

function EMA:ProcessUpdatePowerStatusMessage( characterName, playerPower, playerMaxPower, powerToken )
	EMA:UpdatePowerStatus( characterName, playerPower, playerMaxPower, powerToken )
end		
																					  
function EMA:SettingsUpdatePowerAll()
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do			
		EMA:UpdatePowerStatus( characterName, nil, nil, nil )
	end
end

function EMA:UpdatePowerStatus( characterName, playerPower, playerMaxPower, powerToken)
	--EMA:Print("testPOwer", characterName, playerPower, playerMaxPower, powerToken )
	if characterName == nil then
		return
	end
	if CanDisplayTeamList() == false then
		return
	end
	if EMA.db.showPowerStatus == false then
		return
	end	
	local originalChatacterName = characterName
	characterName = EMAUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local powerBarText = characterStatusBar["powerBarText"]	
	local powerBar = characterStatusBar["powerBar"]	
	
	if playerMaxPower == 0 then
		playerMaxPower = powerBarText.playerMaxPower
	end
	
	if playerPower == nil then
		playerPower = powerBarText.playerPower
	end
	if playerMaxPower == nil then
		playerMaxPower = powerBarText.playerMaxPower
	end
	powerBarText.playerPower = playerPower
	powerBarText.playerMaxPower = playerMaxPower
	powerBar:SetMinMaxValues( 0, tonumber( playerMaxPower ) )
	powerBar:SetValue( tonumber( playerPower ) )
	local text = ""
	if EMA.db.powerStatusShowValues == true then
		text = text..tostring( AbbreviateLargeNumbers(playerPower) )..L[" / "]..tostring( AbbreviateLargeNumbers(playerMaxPower) )..L[" "]
	end
	if EMA.db.powerStatusShowPercentage == true then
		if EMA.db.powerStatusShowValues == true then
			text = tostring( AbbreviateLargeNumbers(playerPower) )..L[" "]..L["("]..tostring( floor( (playerPower/playerMaxPower)*100) )..L["%"]..L[")"]
		else
			text = tostring( floor( (playerPower/playerMaxPower)*100) )..L["%"]
		end
	end
	powerBarText:SetText( text )		
	EMA:SetStatusBarColourForPower( powerBar, powerToken )--originalChatacterName )
end

function EMA:SetStatusBarColourForPower( statusBar, powerToken )
	local info = PowerBarColor[powerToken]
	if info ~= nil then
	--	EMA:Print("powertest", powerToken, info.r, info.g, info.b )
		statusBar:SetStatusBarColor( info.r, info.g, info.b, 1 )
		statusBar.backgroundTexture:SetColorTexture( info.r, info.g, info.b, 0.25 )
	
	end
end		

-------------------------------------------------------------------------------------------------------------
-- Combo Points Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function EMA:UNIT_POWER_FREQUENT( event, Unit, powerType, ... )
	--TODO there got to be a better way to clean this code up Checking to see if its the event we need and then send the command to the update if it is.	
	--EMA:Print("EventTest", Unit, powerType) 
	if Unit == "player" then
		--EMA:Print("player", Unit, powerType)
		if( event and powerType == "COMBO_POINTS" ) then
			EMA:SendComboStatusUpdateCommand()
		else
			return
		end
	end	
end

function EMA:RUNE_POWER_UPDATE( event, ...)
	EMA:SendComboStatusUpdateCommand()
end

function EMA:SendComboStatusUpdateCommand()
	--EMA:Print("test")
	if EMA.db.showTeamList == true and EMA.db.showComboStatus == true then
		-- get powerType from http://wowprogramming.com/docs/api_types#powerType as there no real API to get this infomation as of yet.
		local Class = select(2, UnitClass("player"))
		local playerCombo = 0
		local playerMaxCombo = MAX_COMBO_POINTS
		if Class == "DRUID" or Class == "ROGUE" then
			playerCombo = GetComboPoints("player", "target")	
		else 
			return
		end	
		
		--EMA:Print ("PowerType", PowerType, playerCombo, playerMaxCombo, Class)
		if EMA.db.showTeamListOnMasterOnly == true then
			EMA:DebugMessage( "SendComboStatusUpdateCommand TO Master!" )
			EMA:EMASendCommandToMaster( EMA.COMMAND_COMBO_STATUS_UPDATE, playerCombo, playerMaxCombo, class )
		else
			EMA:DebugMessage( "SendComboStatusUpdateCommand TO TEAM!" )
			EMA:EMASendCommandToTeam( EMA.COMMAND_COMBO_STATUS_UPDATE, playerCombo, playerMaxCombo, class )
		end
	end	
end

function EMA:ProcessUpdateComboStatusMessage( characterName, playerCombo, playerMaxCombo, class )
	EMA:UpdateComboStatus( characterName, playerCombo , playerMaxCombo, class)
end

function EMA:SettingsUpdateComboAll()
	for characterName, characterStatusBar in pairs( EMA.characterStatusBar ) do			
		EMA:UpdateComboStatus( characterName, nil, nil, nil )
	end
end

function EMA:UpdateComboStatus( characterName, playerCombo, playerMaxCombo, class )
	if CanDisplayTeamList() == false then
		return
	end
	
	if EMA.db.showComboStatus == false then
		return
	end
	
	local characterStatusBar = EMA.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	
	local comboBarText = characterStatusBar["comboBarText"]	
	local comboBar = characterStatusBar["comboBar"]	
	
	if playerCombo == nil then
		playerCombo = comboBarText.playerCombo
	end
	if playerMaxCombo == 0 then
		playerMaxCombo = comboBarText.playerMaxCombo
	end
	if playerMaxCombo == nil then
		playerMaxCombo = comboBarText.playerMaxCombo
	end
	
	comboBarText.playerCombo = playerCombo
	comboBarText.playerMaxCombo = playerMaxCombo
	comboBar:SetMinMaxValues( 0, tonumber( playerMaxCombo ) )
	comboBar:SetValue( tonumber( playerCombo ) )	
	local text = ""
	
	if EMA.db.comboStatusShowValues == true then
		text = text..tostring( AbbreviateLargeNumbers(playerCombo) )..L[" / "]..tostring( AbbreviateLargeNumbers(playerMaxCombo) )..L[" "]
	end
	
	if EMA.db.ComboStatusShowPercentage == true then
		if EMA.db.comboStatusShowValues == true then
			text = text..tostring( AbbreviateLargeNumbers(playerCombo) )..L[" "]..L["("]..tostring( floor( (playerCombo/playerMaxCombo)*100) )..L["%"]..L[")"]
		else
			text = tostring( floor( (playerCombo/playerMaxCombo)*100) )..L["%"]
		end
	end
	comboBarText:SetText( text )
end
		
-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function EMA:OnInitialize()
	EMA.previousSlotsFree = 0
	EMA.previousTotalSlots = 0
	-- Create the settings control.
	SettingsCreate()
	-- Initialise the EMAModule part of this module.
	EMA:EMAModuleInitialize( EMA.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	EMA:SettingsRefresh()
	-- Create the team list frame.
	CreateEMATeamListFrame()
	EMA:SetTeamListVisibility()	
	-- Is Following to stop spam
	EMA.isFollowing = false
end

-- Called when the addon is enabled.
function EMA:OnEnable()
	EMA:RegisterEvent( "PLAYER_REGEN_ENABLED" )
	EMA:RegisterEvent( "PLAYER_REGEN_DISABLED" )
	EMA:RegisterEvent( "AUTOFOLLOW_BEGIN" )
	EMA:RegisterEvent( "AUTOFOLLOW_END" )
	EMA:RegisterEvent( "PLAYER_XP_UPDATE" )
	EMA:RegisterEvent( "UPDATE_EXHAUSTION" )
	EMA:RegisterEvent( "PLAYER_LEVEL_UP" )		
	EMA:RegisterEvent( "UNIT_HEALTH" )
	EMA:RegisterEvent( "UNIT_MAXHEALTH" )
	EMA:RegisterEvent( "UNIT_POWER_UPDATE", "UNIT_POWER" )

	EMA:RegisterEvent( "UNIT_MAXPOWER", "UNIT_POWER" )
	EMA:RegisterEvent( "UNIT_DISPLAYPOWER" )
	EMA:RegisterEvent( "CHAT_MSG_COMBAT_FACTION_CHANGE" )
	EMA:RegisterEvent( "UNIT_POWER_FREQUENT")
	EMA:RegisterEvent( "GROUP_ROSTER_UPDATE" )
	EMA:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	EMA.SharedMedia.RegisterCallback( EMA, "LibSharedMedia_Registered" )
    EMA.SharedMedia.RegisterCallback( EMA, "LibSharedMedia_SetGlobal" )	
	EMA:RegisterMessage( EMAApi.MESSAGE_TEAM_CHARACTER_ADDED, "OnCharactersChanged" )
	EMA:RegisterMessage( EMAApi.MESSAGE_TEAM_CHARACTER_REMOVED, "OnCharactersChanged" )	
	EMA:RegisterMessage( EMAApi.MESSAGE_TEAM_ORDER_CHANGED, "OnCharactersChanged" )
	EMA:RegisterMessage( EMAApi.MESSAGE_TEAM_MASTER_CHANGED, "OnMasterChanged" )
	EMA:RegisterMessage( EMAApi.MESSAGE_CHARACTER_ONLINE, "OnCharactersChanged")
	EMA:RegisterMessage( EMAApi.MESSAGE_CHARACTER_OFFLINE, "OnCharactersChanged")
	
	EMA:SecureHook( "SetWatchedFactionIndex" )
	EMA:ScheduleTimer( "RefreshTeamListControls", 3 )
	EMA:ScheduleTimer( "SendExperienceStatusUpdateCommand", 8 )
	EMA:ScheduleTimer( "SendReputationStatusUpdateCommand", 5 )
	EMA:ScheduleTimer( "SendHealthStatusUpdateCommand", 5, "player" )
	EMA:ScheduleTimer( "SendPowerStatusUpdateCommand", 5, "player" )
	EMA:ScheduleTimer( "SendComboStatusUpdateCommand", 5 )
end

-- Called when the addon is disabled.
function EMA:OnDisable()
end


function EMA:UpdateAll(event, ...)
	EMA:ScheduleTimer( "RefreshTeamListControls", 3 )
	EMA:ScheduleTimer( "SendExperienceStatusUpdateCommand", 2 )
	EMA:ScheduleTimer( "SendReputationStatusUpdateCommand", 2 )
	EMA:ScheduleTimer( "SendComboStatusUpdateCommand", 2 )
end


function EMA:OnMasterChanged( message, characterName )
	EMA:SettingsRefresh()
end

function EMA:GROUP_ROSTER_UPDATE()
	EMA:ScheduleTimer( "RefreshTeamListControls", 1 )
	EMA:ScheduleTimer( "SendExperienceStatusUpdateCommand", 1 )
	EMA:ScheduleTimer( "SendReputationStatusUpdateCommand", 1 )
	EMA:ScheduleTimer( "SendComboStatusUpdateCommand", 1 )
	for index, characterName in EMAApi.TeamListOrderedOnline() do
		unit = Ambiguate( characterName, "none" )
		EMA:ScheduleTimer( "SendHealthStatusUpdateCommand", 2, unit )
		EMA:ScheduleTimer( "SendPowerStatusUpdateCommand", 2, unit )
	end
end

function EMA:UNIT_PORTRAIT_UPDATE(event, ...) 
	if EMA.db.showCharacterPortrait == true then
		EMA:RefreshTeamListControls()
	end
end	

function EMA:PLAYER_REGEN_ENABLED( event, ... )
	if EMA.db.hideTeamListInCombat == true then
		EMA:SetTeamListVisibility()
	end
	if EMA.refreshHideTeamListControlsPending == true then
		EMA:RefreshTeamListControlsHide()
		EMA.refreshHideTeamListControlsPending = false
	end
	if EMA.refreshShowTeamListControlsPending == true then
		EMA:RefreshTeamListControlsShow()
		EMA.refreshShowTeamListControlsPending = false
	end
	if EMA.updateSettingsAfterCombat == true then
		EMA:SettingsRefresh()
		EMA.updateSettingsAfterCombat = false
	end
	-- Ebony added follow bar combat Text Change To Orange
	if EMA.db.showTeamList == true and EMA.db.showFollowStatus == true then
		EMA:ScheduleTimer( "SendCombatStatusUpdateCommand", 1 )
	end
end

function EMA:PLAYER_REGEN_DISABLED( event, ... )
	if EMA.db.hideTeamListInCombat == true then
		EMADisplayTeamListFrame:Hide()
	end
	-- Ebony added follow bar Combat Text Change To Orange
	if EMA.db.showTeamList == true and EMA.db.showFollowStatus == true then
		EMA:ScheduleTimer( "SendCombatStatusUpdateCommand", 1 )
	end
end

function EMA:PLAYER_TALENT_UPDATE(event, ...)
	EMA:SendComboStatusUpdateCommand()
	EMA:ScheduleTimer( "SendExperienceStatusUpdateCommand", 1 )
end

function EMA:OnCharactersChanged()
	EMA:RefreshTeamListControls()
end

