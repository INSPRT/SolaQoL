--[[--------------------------------------------------------------------
  SolaQoL - Localization (English Default)
--------------------------------------------------------------------]]--

SolaQoL_L = {}
local L = SolaQoL_L

-- ===== Default Messages =====
L.MSG_HELLO_DEFAULT     = "Hello"
L.MSG_GG_DEFAULT        = "Good game"
L.MSG_FULL              = "Party is full!"
L.MSG_NEW_APPLICANT     = "New party applicant!!"

-- ===== Tooltip / Item Level =====
L.ILVL_COLON            = "Item Level:"
L.ILVL_PREFIX           = "Item Level: "
L.ILVL_LOADING          = "Loading..."

-- ===== Garbage Detection =====
L.GARBAGE_UNKNOWN1      = "Something"
L.GARBAGE_UNKNOWN2      = "Unknown"

-- ===== Chat Output =====
L.PARTY_JOIN_HEADER     = "[Party Joined]"
L.PARTY_ILVL_HEADER     = "[Party Item Levels]"
L.NOTICE                = "[Notice]"
L.PARTY_RECRUIT         = "[Party Recruit]"
L.APPLICANT_WAITING_FMT = " (Waiting: %d)"
L.PORTAL_ACTIVATED_FMT  = "%s portal spell activated!"
L.NO_GROUP              = "You are not in a group."
L.GREETING_CHANGED_FMT  = "Greeting changed: %s"
L.GREETING_CHANGED_RAND_FMT = "Greeting changed: %s |cff888888(one of these will be randomly sent)|r"
L.GG_CHANGED_FMT        = "End message changed: %s"
L.GG_CHANGED_RAND_FMT   = "End message changed: %s |cff888888(one of these will be randomly sent)|r"
L.AUTO_GREET_FEEDBACK_FMT = "Auto greeting printed: %s seconds"
L.TOGGLE_MSG_FMT        = "%s has been turned %s."
L.TOGGLE_ON_MSG         = "ON"
L.TOGGLE_OFF_MSG        = "OFF"

-- ===== Portal UI =====
L.PORTAL_LABEL          = "Dungeon Portal"
L.CANCEL                = "Cancel"
L.ANNOUNCE_DESTINATION  = "Announce"
L.ANNOUNCE_MSG_FMT      = "[SolaQoL] Destination: %3$s"
L.OVERLAY_PORTAL_FMT    = "Party Joined: %s"
L.BTN_TEST_MODE         = "Move / Resize"
L.BTN_TEST_MODE_OFF     = "Done Editing"
L.TEST_MODE_LABEL       = "Left Click: Move / Wheel: Resize"

-- ===== Config UI - Categories =====
L.CAT_GREETINGS         = "Greetings & Alerts"
L.CAT_GREETINGS_SUB     = "Greetings"
L.SOUND_TITLE_SETTINGS  = "Sound Settings"
L.CAT_CONVENIENCE       = "QoL"
L.CAT_COMBAT_PARTY      = "Combat & Party"
L.CAT_PLAYER_INFO       = "Personal Settings"
L.CAT_TRADE_RESULT_ALERTS = "Trade Result Alerts"
L.CAT_ILVL_SCAN         = "Player Info"
L.CAT_TRADE             = "Trade Alerts"
L.UI_SCALE              = "UI Scale"
L.MINIMAP               = "Minimap Button"
L.MINIMAP_TOOLTIP       = "Left Click: Toggle Settings\nDrag: Move Button"

-- ===== Config UI - Options =====
L.WELCOME_MSG_FMT       = "|cff00ccff[SolaQoL]|r %s Activated. Settings command: |cff00ccff/SQ|r. |cfffeca57Made by Sola-Azshara|r"
L.OPT_AUTO_GREET        = "Auto Party Greeting |cff888888(separated by commas)|r"
L.OPT_AUTO_GREET_MSG    = "Auto Party Greeting"
L.OPT_GREET_ONCE        = "Greet only once as a party member"
L.OPT_GG_COMPLETE       = "Keystone Dungeon Completion Greeting |cff888888(separated by commas)|r"
L.OPT_GG_COMPLETE_MSG   = "Keystone Dungeon Completion Greeting"
L.OPT_RAID_SOUND        = "[Raid] Player Join Alert Sound"
L.OPT_AUTO_PORTAL       = "Show Mythic+ Dungeon Info Overlay"
L.OPT_SHOW_SPEC_ON_ENTER = "Show active talent build on instance entry"
L.OPT_SHOW_SPEC_ON_ENTER_DESC = "Move Position: ALT + Left Click\nResize Font: ALT + Mouse Wheel"
L.SPEC_DISPLAY_FORMAT     = "Active Talents: %s"
L.OPT_SHOW_ILVL         = "Auto-summarize party item levels & specs (self only)"
L.OPT_SHOW_ILVL_SHORT   = "Auto-summarize party item levels & specs"
L.OPT_TOOLTIP_ILVL      = "Show item level & M+ score in mouseover tooltips"
L.MYTHIC_SCORE_PREFIX   = "M+ Score: "
L.OPT_LUST_BAR_ENABLE   = "Enable Bloodlust Duration Bar"
L.BTN_TEST_LUST_BAR     = "Test Bar"
L.LUST_BAR_WIDTH        = "Width"
L.LUST_BAR_HEIGHT       = "Height"
L.BTN_TEST_STOP         = "Stop Test"

-- ===== Config UI - Buttons =====
L.SAVE                  = "Save"
L.PLAY                  = "▶ Play"
L.OPEN_SETTINGS         = "Settings"
L.OPEN_SOUND_SETTINGS   = "Custom Alert Sound Path.."

-- ===== Sound Config Window =====
L.SOUND_TITLE           = "Sound Path Settings"
L.SOUND_HINT            = "* Saving with an empty field will use the default alert sound."
L.SOUND_NEW_LABEL       = "Custom Party Join Alert Sound"
L.SOUND_NEW_SAVED       = "Party join sound path saved"
L.SOUND_FULL_LABEL      = "Custom Full Party Alert Sound"
L.SOUND_FULL_SAVED      = "Full party sound path saved"
L.SOUND_APP_LABEL       = "Custom New Applicant Alert Sound"
L.SOUND_APP_SAVED       = "New applicant sound path saved"
L.SOUND_GUIDE1          = "Place your sound files (mp3, ogg) inside the Interface folder."
L.SOUND_GUIDE2          = "Example: Interface\\AddOns\\SolaQoL\\Your_Sound.mp3"
L.SOUND_WARNING         = "* If you added new sound files, you must fully restart the game client."
L.SOUND_ERROR_EMPTY     = "Please enter a sound path."
L.SOUND_ERROR_INVALID   = "Invalid sound path format. It must start with 'Interface\\' and end with .mp3, .ogg, or .wav."

-- ===== Toggle State =====
L.TOGGLE_ON             = "|cff88ff88ON|r"
L.TOGGLE_OFF            = "|cffff8888OFF|r"
L.SOUND_NEW_ON          = "Party join alert sound |cff66ff66enabled|r."
L.SOUND_NEW_OFF         = "Party join alert sound |cffff6666disabled|r."
L.SOUND_FULL_ON         = "Full party alert sound |cff66ff66enabled|r."
L.SOUND_FULL_OFF        = "Full party alert sound |cffff6666disabled|r."
L.SOUND_APP_ON          = "New applicant alert sound |cff66ff66enabled|r."
L.SOUND_APP_OFF         = "New applicant alert sound |cffff6666disabled|r."

-- ===== Trade Report =====
L.CAT_TRADE             = "Trade Report"
L.OPT_TRADE_ENABLE      = "Enable Trade Report Summary"
L.TRADE_LOG_ENABLE      = "Trade History Log"
L.TRADE_LOG_CLEAR       = "Clear"
L.TRADE_LOG_EMPTY       = "No trade history recorded."
L.TRADE_LOG_TAMPERED    = "[TAMPERED]"
L.OPT_TRADE_WHISPER     = "Whisper trade summary to target"
L.OPT_TRADE_PARTY       = "Announce trade summary to Party/Raid"
L.TRADE_SUMMARY_BOTH    = "Received %s / Gave %s"
L.TRADE_SUMMARY_GAVE    = "Gave %s"
L.TRADE_SUMMARY_RECV    = "Received %s"
L.TRADE_SUMMARY_EMPTY   = "Nothing Exchanged"
L.TRADE_GOLD            = " Gold "
L.TRADE_SILVER          = " Silver "
L.TRADE_COPPER          = " Copper "
L.TRADE_SUCCESS         = "[Trade Complete]"
L.TRADE_CANCELLED       = "[Trade Cancelled]"
L.TRADE_ERROR_HDR       = "[Trade Error]"
L.TRADE_REASON_ME       = "Cancelled by Me"
L.TRADE_REASON_TARGET   = "Cancelled by target"
L.TRADE_REASON_UNKNOWN  = "Unknown reason"
L.TRADE_ERROR           = "Trade Error"
L.TRADE_WITH_UNKNOWN    = "Unknown Target"

-- ===== Keyword Alert =====
L.OPT_KEYWORD_ALERT       = "Enable Keyword Alert"
L.OPT_KEYWORD_ALERT_SHORT = "Keyword Alert"
L.OPT_KEYWORD_LIST         = "Alert keywords (comma separated):"
L.OPT_KEYWORD_SOUND        = "Alert Sound:"
L.KEYWORD_SOUND_WHISPER     = "Whisper Ding"
L.KEYWORD_SOUND_READY_CHECK = "Ready Check"
L.KEYWORD_SOUND_RAID_WARNING = "Raid Warning"
L.KEYWORD_SOUND_LEVEL_UP    = "Level Up"
L.KEYWORD_SOUND_ALARM       = "Alarm Clock"
L.BTN_KEYWORD_TEST          = "\226\150\182 Play"
L.SOUND_OPT_CUSTOM          = "Custom Path"
L.SOUND_OPT_DEFAULT         = "Default Sound"
L.OPT_KEYWORD_AUTO_PLAYER       = "Automatically add current character name to alert keywords"
L.OPT_KEYWORD_AUTO_PLAYER_SHORT = "Auto Add Character Name"

-- ===== Auto-Release Spirit =====
L.OPT_AUTO_RELEASE          = "Auto-Release Spirit on Death"
L.OPT_AUTO_RELEASE_SHORT    = "Auto-Release Spirit"
L.OPT_AUTO_RELEASE_DESC     = "Does not release if Soulstone, Reincarnation, or combat rez is pending. (For raid progression)"
L.OPT_DISABLE_AUTO_RELEASE_HUD = "Disable Auto-Release HUD Indicator"

-- ===== Dungeon Portals =====
L.DungeonPortals = {
    ["Seat of the Triumvirate"]  = 1254551,
    ["Pit of Saron"]             = 1254555,
    ["Skyreach"]                 = 159898,
    ["Windrunner Spire"]         = 1254400,
    ["Magister's Terrace"]       = 1254572,
    ["Nexus-Point Xenas"]        = 1254563,
    ["Maisara Caverns"]          = 1254559,
    ["Algeth'ar Academy"]        = 393273,
}

L.DungeonShortNames = {
    ["Seat of the Triumvirate"]  = "SoT",
    ["Pit of Saron"]             = "PoS",
    ["Skyreach"]                 = "SR",
    ["Windrunner Spire"]         = "WS",
    ["Magister's Terrace"]       = "MT",
    ["Nexus-Point Xenas"]        = "NPX",
    ["Maisara Caverns"]          = "MC",
    ["Algeth'ar Academy"]        = "AA",
}

-- ===== Random Hearthstone =====
L.CAT_RANDOM_HEARTHSTONE  = "Random Toy Hearthstone Cast"
L.OPT_RANDOM_HEARTHSTONE  = "Random Hearthstone"
L.BIND_NOT_SET            = "Set Keybind"
L.BTN_HEARTHSTONE_LIST    = "Manage List"
L.HEARTHSTONE_POPUP_TITLE = "Hearthstone List"
L.MSG_UNBOUND             = "Keybind deleted"
L.OPT_HEARTHSTONE_ON_CLEAR= "Show a random hearthstone cast popup when Mythic+ completes"

L.OPT_BLOODLUST_ALERT_ENABLE = "Enable Bloodlust Text & Audio Alert"
L.OPT_BLOODLUST_START_ALERT = "Bloodlust Start Alert"
L.OPT_BLOODLUST_READY_ALERT = "Bloodlust Ready Alert (Lust Classes Only)"
L.OPT_BLOODLUST_ALERT_PERSIST = "Keep 'Ready' Text Visible Until Next Cast"

L.OPT_LUST_MODE_BOTH = "Text & Audio Alert"
L.OPT_LUST_MODE_TEXT = "Text Alert Only"
L.OPT_LUST_MODE_AUDIO = "Audio Alert Only"
L.OPT_LUST_MODE_OFF = "Disabled"
L.BTN_TEST_BLOODLUST_ALERT = "Test Lust Alert"
L.MSG_BLOODLUST_READY = "Lust Ready"
L.MSG_BLOODLUST_START = "Lust On"
L.SOUND_BLOODLUST_READY = "LustRdy.mp3"
L.SOUND_BLOODLUST_START = "LustOn.mp3"
L.HUD_AUTO_RELEASE = "Auto-Rel"

L.UPDATE_NOTE_LATEST = "- Added Bloodlust Text & Audio Alert features for start and ready events."

L.CAT_CHANGELOG = "Changelog"
L.UPDATE_POPUP_TEXT = "26-07-08 / 0.5.2\n\n |cffD4A745[ New Feature ]|r\n\n - A feature has been added that alerts you with text and voice when Bloodlust is started or becomes ready again.\n\n Type |cffffff00/SQ|r and check it out in the settings menu."
L.CHANGELOG_TEXT = "26-07-08 / 0.5.2\n - Added Bloodlust Text & Audio Alert features for start and ready events.\n\n26-07-07 / 0.5.1\n - Minor bug fixes\n\n26-07-06 / 0.5.0\n - The addon has been renamed to 'SolaQoL'.\n\n26-07-01 / 0.4.4\n - Added Random Hearthstone feature. You can add/remove desired toys in the Hearthstone list from the settings. You can also assign a keybind to it.\n\n26-06-30 / 0.4.3\n - Fixed an issue where changing the position and size of the dungeon portal overlay did not save properly\n\n26-06-27 / 0.4.2\n - Fixed an issue where the destination notification button did not work properly\n\n26-06-26 / 0.4.1\n - Added a feature to automatically add the current character's name to the alert keywords\n\n26-06-26 / 0.4.0\n - Fixed auto-release spirit feature not working properly in raids\n\n26-06-25 / 0.3.9\n - Revamped UI, memory leak & performance improvements, minor bug fixes\n - Added Chat Keyword Alert feature\n - Added ultra-fast Auto-Release Spirit feature (for raid progression)\n - Added persistent Trade History table (retained across reload/re-log with edit detection)\n - Various audio selections are now available for alert sounds."

-- ===== Key Bindings =====
BINDING_HEADER_SOLAQOL = "SolaQoL"
BINDING_NAME_PG_RANDOM_HEARTHSTONE = "Random Hearthstone Toy"
L.BTN_CONFIRM_CLOSE = "Confirm & Close"
L.BTN_ADD = "Add"
L.BTN_DELETE = "Delete"
L.BTN_CLOSE = "Close"
L.BTN_UNBIND = "Delete"
