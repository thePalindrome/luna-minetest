local exertion = select(1, ...) or exertion;
local MOD_SETTINGS_FILE =
   exertion.MOD_PATH .. "/settings.lua";
local WORLD_SETTINGS_FILE =
   minetest.get_worldpath() .. "/" .. exertion.MOD_NAME .. "_settings.lua";

local settings = {};

local function loadSettingsFile(filePath)
   -- test for existence/readability
   local file = io.open(filePath, 'r');
   if not file then return nil; end;
   file:close();

   local chunk, err = loadfile(filePath);
   return chunk or error(err);
end;

local modSettingsFunc = loadSettingsFile(MOD_SETTINGS_FILE);
local worldSettingsFunc = loadSettingsFile(WORLD_SETTINGS_FILE);
if not modSettingsFunc and not worldSettingsFunc then return settings; end;

-- Setting any "global" variable in the settings files actually modifies the
-- settings table (unless the variable is accessed through another existing
-- table like _G).
local settingsEnv =
   setmetatable(
   {},
   {
      __index = function(self, key)
         local v = settings[key];
         if v ~= nil then return v; else return _G[key]; end;
      end,

      __newindex = function(self, key, value)
         settings[key] = value;
         return true;
      end,
   });

if modSettingsFunc then
   setfenv(modSettingsFunc, settingsEnv);
   modSettingsFunc(settings);
end;

if worldSettingsFunc then
   setfenv(worldSettingsFunc, settingsEnv);
   worldSettingsFunc(settings);
end;

return settings;
