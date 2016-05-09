local exertion = select(1, ...);
local settings = exertion.settings;


local PLAYER_DB_FILE =
   minetest.get_worldpath() .. "/" ..
      exertion.MOD_NAME .. "_playerStatesDb.json";
local SECONDS_PER_DAY =
   (function()
      local ts = tonumber(minetest.setting_get("time_speed"));
      if not ts or ts <= 0 then ts = 72; end;
      return 24 * 60 * 60 / ts;
    end)();
local DF_DT = settings.food_perDay / SECONDS_PER_DAY;
local DW_DT = settings.water_perDay / SECONDS_PER_DAY;
local DP_DT = settings.poison_perDay / SECONDS_PER_DAY;
local DHP_DT = settings.healing_perDay / SECONDS_PER_DAY;


local function clamp(x, min, max)
   if x < min then
      return min;
   elseif x > max then
      return max;
   else
      return x;
   end;
end;

local gameToWallTime;
local wallToGameTime;
do
   local ts = tonumber(minetest.setting_get("time_speed"));
   if not ts or ts <= 0 then ts = 72; end;
   local WALL_MINUS_GAME = nil;

   minetest.after(0,
      function()
         WALL_MINUS_GAME = os.time() - minetest.get_gametime();
      end);

   gameToWallTime = function(tg)
      if not WALL_MINUS_GAME then error("Game time not initialized"); end;
      return tg + WALL_MINUS_GAME;
   end

   wallToGameTime = function(tw)
      if not WALL_MINUS_GAME then error("Game time not initialized"); end;
      return tw - WALL_MINUS_GAME;
   end
end

local function calcMultiplier(mt,
                              exertionStatus,
                              fedStatus,
                              hydratedStatus,
                              poisonedStatus)
   local em = mt.exertion[exertionStatus] or 1.0;
   local fm = mt.fed[fedStatus] or 1.0;
   local hm = mt.hydrated[hydratedStatus] or 1.0;
   local pm = mt.poisoned[poisonedStatus] or 1.0;
   return em * fm * hm * pm;
end;

local function canDrink(player)
   local p = player:getpos();
   local hn = minetest.get_node({ x = p.x, y = p.y + 1, z = p.z });
   if not hn or hn.name ~= "air" then return false; end;
   return
      minetest.find_node_near(p, settings.drinkDistance, { "group:water" });
end;


--- Manages player state for the exertion mod.
 --
 -- @author presitidigitator (as reistered at forum.minetest.net).
 -- @copyright 2015, licensed under WTFPL
 --
local PlayerState = { db = {} };
local PlayerState_meta = {};
local PlayerState_ops = {};
local PlayerState_inst_meta = {};

setmetatable(PlayerState, PlayerState_meta);
PlayerState_inst_meta.__index = PlayerState_ops;

--- Constructs a PlayerState, loading from the database if present there, or
 -- initializing to an initial state otherwise.
 --
 -- Call with one of:
 --    PlayerState.new(player)
 --    PlayerState(player)
 --
 -- @return a new PlayerState object
 --
function PlayerState.new(player)
   local playerName = player:get_player_name();
   if not playerName or playerName == "" then
      error("Argument is not a player");
   end;

   local state = PlayerState.db[playerName];
   local newState = false;
   if not state then
      state = {};
      PlayerState.db[playerName] = state;
      newState = true;
   end;

   local self =
      setmetatable({ player = player, state = state; }, PlayerState_inst_meta);
   self:initialize(newState);

   return self;
end;
PlayerState_meta.__call =
   function(class, ...) return PlayerState.new(...); end;

--- Loads the PlayerState DB from the world directory (call only when the mod
 -- is first loaded).
 --
function PlayerState.load()
   local playerDbFile = io.open(PLAYER_DB_FILE, 'r');
   if playerDbFile then
      local ps = minetest.parse_json(playerDbFile:read('*a'));
      if ps then PlayerState.db = ps; end;
      playerDbFile:close();
   end;
end;

--- Saves the PlayerState DB to the world directory.  This is done periodically
 -- and when the server is shutting down normally, but it doesn't hurt to also
 -- do it at key times to avoid data loss.
 --
function PlayerState.save()
   local playerDbFile = io.open(PLAYER_DB_FILE, 'w');
   if playerDbFile then
      local json, err = minetest.write_json(PlayerState.db);
      if not json then playerDbFile:close(); error(err); end;
      playerDbFile:write(json);
      playerDbFile:close();
   end;
end;

--- Initializes a PlayerState object that is either newly created or loaded
 -- from the database from a previous login.
 --
 -- @param newState
 --    Boolean indicating that this is a newly created state object rather than
 --    one loaded from the database.
 --
function PlayerState_ops:initialize(newState)
   local tw = os.time();
   local tg = minetest.get_gametime();
   if newState then
      self.state.fed = settings.fedMaximum;
      self.state.hydrated = settings.hydratedMaximum;
      self.state.poisoned = 0;
      self.state.foodLost = 0;
      self.state.waterLost = 0;
      self.state.poisonLost = 0;
      self.state.hpGained = 0;
      self.state.airLost = 0;
      self.state.updateGameTime = tg;
      self.state.updateWallTime = tw;

      self.activity = 0;
      self.activityPolls = 0;
      self.builds = 0;

      self:updatePhysics();
      self:updateHud();
   else
      local dt;
      if settings.useWallclock and
         self.state.updateWallTime and
         self.state.updateWallTime <= tw
      then
         dt = tw - self.state.updateWallTime;
      elseif self.state.updateGameTime and
             self.state.updateGameTime <= tg
      then
         dt = tg - self.state.updateGameTime;
      else
         dt = 0;
      end;

      self.state.fed = self.state.fed or 0;
      self.state.hydrated = self.state.hydrated or 0;
      self.state.poisoned = self.state.poisoned or 0;
      self.state.foodLost = self.state.foodLost or 0;
      self.state.waterLost = self.state.waterLost or 0;
      self.state.poisonLost = self.state.poisonLost or 0;
      self.state.hpGained = self.state.hpGained or 0;
      self.state.airLost = 0;

      self.activity = 0;
      self.activityPolls = 0;
      self.builds = 0;

      self:update(tw, dt);
      self:updateHud();
   end;
end;

--- Calculates the player's exertion status based on activities detected so far
 -- during the current accounting period.  Normally this is used internally,
 -- and doesn't need to be called from outside the class.  However, it might be
 -- useful for logging/debugging.
 --
 -- @return
 --    One of the status strings configured in the mod settings (or 'none').
 --
function PlayerState_ops:calcExertionStatus()
   local polls = self.activityPolls;
   local ar = (polls > 0 and self.activity / polls) or 0;
   local b = self.builds;

   local status = nil;
   local priority = nil;
   for s, c in pairs(settings.exertionStatuses) do
      if c then
         local pc = c.priority;
         if not priority or (pc and pc > priority) then
            local arc = c.activityRatio;
            local bc = c.builds;
            if (arc and ar >= arc) or (bc and b >= bc)
            then
               status = s;
               priority = pc;
            end;
         end;
      end;
   end;

   return status or 'none';
end;

--- Calculates the player's fed status based on the current value of the fed
 -- bar.  Normally this is used internally, and doesn't need to be called from
 -- outside the class.  However, it might be useful for logging/debugging.
 --
 -- @return
 --    One of the status strings configured in the mod settings (or 'none').
 --
function PlayerState_ops:calcFedStatus()
   local fed = self.state.fed;

   local status = nil;
   local threshold = nil;
   for s, t in pairs(settings.fedStatuses) do
      if (not threshold or t > threshold) and fed >= t then
         status = s;
         threshold = t;
      end;
   end;

   return status or 'none';
end;

--- Calculates the player's hydrated status based on the current value of the
 -- hydrated bar.  Normally this is used internally, and doesn't need to be
 -- called from outside the class.  However, it might be useful for
 -- logging/debugging.
 --
 -- @return
 --    One of the status strings configured in the mod settings (or 'none').
 --
function PlayerState_ops:calcHydratedStatus()
   local hyd = self.state.hydrated;

   local status = nil;
   local threshold = nil;
   for s, t in pairs(settings.hydratedStatuses) do
      if (not threshold or t > threshold) and hyd >= t then
         status = s;
         threshold = t;
      end;
   end;

   return status or 'none';
end;

--- Calculates the player's poisoned status based on the current value of the
 -- poisoned bar.  Normally this is used internally, and doesn't need to be
 -- called from outside the class.  However, it might be useful for
 -- logging/debugging.
 --
 -- @return
 --    One of the status strings configured in the mod settings (or 'none').
 --
function PlayerState_ops:calcPoisonedStatus()
   local poi = self.state.poisoned;

   local status = nil;
   local threshold = nil;
   for s, t in pairs(settings.poisonedStatuses) do
      if (not threshold or t > threshold) and poi >= t then
         status = s;
         threshold = t;
      end;
   end;

   return status or 'none';
end;

--- Sets the value of the fed bar to the given amount.
 --
 -- @param amount
 --    The new value to assign the bar.  Must be a number, which is clamped to
 --    the valid range configured in the settings.
 -- @param deferHudUpdate
 --    If true, the HUD will not be updated implicitly.  The updateHud() method
 --    should be called after all visible changes to the bars have been
 --    completed.
 --
function PlayerState_ops:setFed(amount, deferHudUpdate)
   amount = tonumber(amount);
   if not amount then return; end;

   self.state.fed = clamp(math.floor(amount), 0, settings.fedMaximum);
   self.state.foodLost = 0;

   if not deferHudUpdate then self:updateHud(); end;
end;

--- Sets the value of the hydrated bar to the given amount.
 --
 -- @param amount
 --    The new value to assign the bar.  Must be a number, which is clamped to
 --    the valid range configured in the settings.
 -- @param deferHudUpdate
 --    If true, the HUD will not be updated implicitly.  The updateHud() method
 --    should be called after all visible changes to the bars have been
 --    completed.
 --
function PlayerState_ops:setHydrated(amount, deferHudUpdate)
   amount = tonumber(amount);
   if not amount then return; end;

   self.state.hydrated =
      clamp(math.floor(amount), 0, settings.hydratedMaximum);
   self.state.poisonLost = 0;

   if not deferHudUpdate then self:updateHud(); end;
end;

--- Sets the value of the poisoned bar to the given amount.
 --
 -- Note that poisoned values are always rounded UP.
 --
 -- @param amount
 --    The new value to assign the bar.  Must be a number, which is clamped to
 --    the valid range configured in the settings.
 -- @param deferHudUpdate
 --    If true, the HUD will not be updated implicitly.  The updateHud() method
 --    should be called after all visible changes to the bars have been
 --    completed.
 --
function PlayerState_ops:setPoisoned(amount, deferHudUpdate)
   amount = tonumber(amount);
   if not amount then return; end;

   self.state.poisoned =
      clamp(math.ceil(amount), 0, settings.poisonedMaximum);
   self.state.poisonLost = 0;

   if not deferHudUpdate then self:updateHud(); end;
end;

--- Sets the value of the HP bar to the given amount.  Accepts non-integer
 -- values, keeping track of fractions to decrease future healing time.
 --
 -- @param amount
 --    The new value to assign the bar.  Must be a number, which is clamped to
 --    the valid range of HP.
 --
function PlayerState_ops:setHp(amount)
   amount = tonumber(amount);
   if not amount then return; end;

   local n, f;
   if amount < 1.0 then
      n, f = 0, 0;
   else
      n, f = math.modf(amount);
   end;

   self.player:set_hp(n);
   self.state.hpGained = f;
end;

--- Sets the value of the breath bar to the given amount.
 --
 -- @param amount
 --    The new value to assign the bar.  Must be a number, which is clamped to
 --    the valid range of breath.
 --
function PlayerState_ops:setBreath(amount)
   amount = tonumber(amount);
   if not amount then return; end;

   self.player:set_breath(math.floor(amount));
   self.state.airLost = 0;
end;

--- Adds an amount (positive or negative) to the fed bar.  Non-integer amounts
 -- are allowed, though they only increase the time until the next incremental
 -- change when positive.
 --
 -- @param amount
 --    The value to add to the bar.  Must be a number.
 -- @param deferHudUpdate
 --    If true, the HUD will not be updated implicitly, even if the change
 --    results in an incremental change in the bar's points (half-icons).  The
 --    updateHud() method should be called after all visible changes to the
 --    bars have been completed.
 -- @return
 --    If the bar's incremental points (half-icons) have potentially increased
 --    or decreased, making the change visible.  May still return true if the
 --    final value is unchanged due to being clamped.
 --
function PlayerState_ops:addFood(df, deferHudUpdate)
   df = tonumber(df);
   if not df then return false; end;

   local fedChanged = false;

   if df > 0 then
      if df >= 1.0 then
         local dfn = math.floor(df);
         self.state.fed = clamp(self.state.fed + dfn, 0, settings.fedMaximum);
         self.state.foodLost = 0;
         fedChanged = true;
      else
         self.state.foodLost = clamp(self.state.foodLost - df, 0, 1.0);
      end;
   elseif df < 0 then
      df = self.state.foodLost - df;  -- now positive
      if df >= 1.0 then
         local dfn, dff = math.modf(df);
         self.state.fed = clamp(self.state.fed - dfn, 0, settings.fedMaximum);
         self.state.foodLost = dff;
         fedChanged = true;
      else
         self.state.foodLost = clamp(df, 0, 1.0);
      end;
   end;

   if fedChanged and not deferHudUpdate then self:updateHud(); end;

   return fedChanged;
end;

--- Adds an amount (positive or negative) to the hydrated bar.  Non-integer
 -- amounts are allowed, though they only increase the time until the next
 -- incremental change when positive.
 --
 -- @param amount
 --    The value to add to the bar.  Must be a number.
 -- @param deferHudUpdate
 --    If true, the HUD will not be updated implicitly, even if the change
 --    results in an incremental change in the bar's points (half-icons).  The
 --    updateHud() method should be called after all visible changes to the
 --    bars have been completed.
 -- @return
 --    If the bar's incremental points (half-icons) have potentially increased
 --    or decreased, making the change visible.  May still return true if the
 --    final value is unchanged due to being clamped.
 --
function PlayerState_ops:addWater(dw, deferHudUpdate)
   dw = tonumber(dw);
   if not dw then return false; end;

   local hydratedChanged = false;

   if dw > 0 then
      if dw >= 1.0 then
         local dwn = math.floor(dw);
         self.state.hydrated =
            clamp(self.state.hydrated + dwn, 0, settings.hydratedMaximum);
         self.state.waterLost = 0;
         hydratedChanged = true;
      else
         self.state.waterLost = clamp(self.state.waterLost - dw, 0, 1.0);
      end;
   elseif dw < 0 then
      dw = self.state.waterLost - dw;  -- now positive
      if dw >= 1.0 then
         local dwn, dwf = math.modf(dw);
         self.state.hydrated =
            clamp(self.state.hydrated - dwn, 0, settings.hydratedMaximum);
         self.state.waterLost = dwf;
         hydratedChanged = true;
      else
         self.state.waterLost = clamp(dw, 0, 1.0);
      end;
   end;

   if hydratedChanged and not deferHudUpdate then self:updateHud(); end;

   return hydratedChanged;
end;

--- Adds an amount (positive or negative) to the poisoned bar.  Non-integer
 -- amounts are allowed, though they only increase the time until the next
 -- incremental change when negative.
 --
 -- Note that positive poisoned changes are always rounded UP, and also reset
 -- the time before poison is removed naturally.
 --
 -- @param amount
 --    The value to add to the bar.  Must be a number.
 -- @param deferHudUpdate
 --    If true, the HUD will not be updated implicitly, even if the change
 --    results in an incremental change in the bar's points (half-icons).  The
 --    updateHud() method should be called after all visible changes to the
 --    bars have been completed.
 -- @return
 --    If the bar's incremental points (half-icons) have potentially increased
 --    or decreased, making the change visible.  May still return true if the
 --    final value is unchanged due to being clamped.
 --
function PlayerState_ops:addPoison(dp, deferHudUpdate)
   dp = tonumber(dp);
   if not dp then return false; end;

   local poisonedChanged = false;

   if dp > 0 then
      local dpn = math.ceil(dp);
      local dpf = dpn - dp;
      self.state.poisoned =
         clamp(self.state.poisoned + dpn, 0, settings.poisonedMaximum);
      self.state.poisonLost = 0;
      poisonedChanged = true;
   elseif dp < 0 then
      dp = self.state.poisonLost - dp;  -- now positive
      if dp >= 1.0 then
         local dpn, dpf = math.modf(dp);
         self.state.poisoned =
            clamp(self.state.poisoned - dpn, 0, settings.poisonedMaximum);
         self.state.poisonLost = dpf;
         poisonedChanged = true;
      else
         self.state.poisonLost = clamp(dp, 0, 1.0);
      end;
   end;

   if poisonedChanged and not deferHudUpdate then self:updateHud(); end;

   return poisonedChanged;
end;

--- Adds an amount (positive or negative) to the player's HP.  Non-integer
 -- amounts are allowed.
 --
 -- The benefit of calling this method rather than using Player:get_hp() and
 -- Player:set_hp() directly is that it accepts non-integer amounts and ties in
 -- well with time-based healing.  There is no harm in doing both.
 --
 -- @param amount
 --    The number of HP to add.  Must be a number.
 -- @return
 --    If the bar's incremental points (half-icons) have potentially increased
 --    or decreased, making the change visible.  May still return true if the
 --    final value is unchanged due to being clamped.
 --
function PlayerState_ops:addHp(dhp)
   dhp = tonumber(dhp);
   if not dhp then return false; end;

   local hpChanged = false;

   dhp = self.state.hpGained + dhp;
   if dhp < 0 or dhp >= 1.0 then
      local dhpf = dhp % 1.0;
      local dhpn = dhp - dhpf;
      self.player:set_hp(self.player:get_hp() + dhpn);
      self.state.hpGained = dhpf;
      hpChanged = true;
   else
      self.state.hpGained = dhp;
   end;

   return hpChanged;
end;

--- Adds an amount (positive or negative) to the player's remaining breath
 -- bubbles.  Non-integer amounts are allowed.
 --
 -- The benefit of calling this method rather than using Player:get_breath()
 -- and Player:set_breath() directly is that it accepts non-integer amounts and
 -- ties in well with other mechanisms like retching.  There is no harm in
 -- doing both.
 --
 -- @param amount
 --    The number of breath points to add.  Must be a number.  If the player
 --    isn't holding his/her breath, this value is ignored and no change is
 --    made.
 -- @return
 --    If the bar's incremental points (half-icons) have potentially increased
 --    or decreased, making the change visible.  May still return true if the
 --    final value is unchanged due to being clamped.
 --
function PlayerState_ops:addBreath(db)
   db = tonumber(db);
   if not db then return false; end;

   local player = self.player;
   local b0 = player:get_breath();
   local breathChanged = false;

   if b0 < 11 then
      if db > 0 then
         if db > 1.0 then
            local dbn = math.floor(db);
            player:set_breath(b0 + dbn);
            self.state.airLost = 0;
            breathChanged = true;
         else
            self.state.airLost = clamp(self.state.airLost - db, 0, 1.0);
         end;
      elseif db < 0 then
         db = self.state.airLost - db;  -- now positive
         if db > 1.0 then
            local dbn, dbf = math.modf(db);
            player:set_breath(b0 - dbn);
            self.state.airLost = dbf;
            breathChanged = true;
         else
            self.state.airLost = clamp(db, 0, 1.0);
         end;
      end;
   else
      self.state.airLost = 0;
   end;

   return breathChanged;
end;

--- Fully updates the player's statuses, drinking water if available, healing
 -- when appropriate, consuming food and water, and randomly retching all based
 -- on the configuration settings.  Also called during player state
 -- initialization if the state was loaded from the database.
 --
 -- Automatically updates HUDs when bars are changed.
 --
 -- @param tw
 --    Wallclock time.  Defaults to os.time().
 -- @param dt
 --    Time since last update.  Defaults to the difference between dt and the
 --    last call to this method.
 --
function PlayerState_ops:update(tw, dt)
   local player = self.player;
   if tw == nil then tw = os.time(); end;
   if dt == nil then dt = tw - self.state.updateWallTime; end;

   local hudChanged = false;
   local es = self:calcExertionStatus();
   local fs = self:calcFedStatus();
   local hs = self:calcHydratedStatus();
   local ps = self:calcPoisonedStatus();

   local rpm = calcMultiplier(settings.retchProbMultipliers, es, fs, hs, ps);
   local retchProb = rpm * settings.retchProb_perPeriod;
   local retching = math.random() <= retchProb;

   if self.state.fed > 0 then
      local fm = calcMultiplier(settings.foodMultipliers, es, fs, hs, ps);
      local df = -DF_DT * fm * dt;
      if retching then df = df - settings.retchingFoodLoss; end;
      hudChanged = self:addFood(df, true) or hudChanged;
   end;

   if canDrink(player) then
      hudChanged =
         self:addWater(settings.drinkAmount_perPeriod, true) or hudChanged;
   elseif self.state.hydrated > 0 then
      local wm = calcMultiplier(settings.waterMultipliers, es, fs, hs, ps);
      local dw = -DW_DT * wm * dt;
      if retching then dw = dw - settings.retchingWaterLoss; end;
      hudChanged = self:addWater(dw, true) or hudChanged;
   end;

   if self.state.poisoned > 0 then
      local dp = -DP_DT * dt;
      hudChanged = self:addPoison(dp, true) or hudChanged;
   end;

   local hpm = calcMultiplier(settings.healingMultipliers, es, fs, hs, ps);
   local dhp = DHP_DT * hpm * dt;
   if retching then dhp = dhp - settings.retchingDamage; end;
   self:addHp(dhp);

   self:addBreath((retching and -settings.retchingAirLoss) or 0);

   if retching then
      player:set_physics_override({ speed = 0.01, jump = 0.01 });
      minetest.after(settings.retchDuration_seconds,
                     self.updatePhysics, self, es, fs, hs, ps);

      local sound = settings.retchingSound;
      if sound and sound.name then
         minetest.sound_play(
            sound.name,
            {
               object = player,
               gain = sound.gain,
               max_hear_distance = sound.maxDist,
               loop = false
            });
      end;
   else
      self:updatePhysics(es, fs, hs, ps);
   end;

   if hudChanged then self:updateHud(); end;

   self.activity = 0;
   self.activityPolls = 0;
   self.builds = 0;
   self.state.updateGameTime = wallToGameTime(tw);
   self.state.updateWallTime = tw;
end;

--- Updates player game physics overrides based on statuses and the
 -- configuration settings.  Called automatically during initialization,
 -- updates, and after periods of paralysis due to retching.  May be
 -- incompatible with physics changes made by other mods (REVISIT: fix this
 -- somehow).
 --
function PlayerState_ops:updatePhysics(es, fs, hs, ps)
   if not es then es = self:calcExertionStatus(); end;
   if not fs then fs = self:calcFedStatus(); end;
   if not hs then hs = self:calcHydratedStatus(); end;
   if not ps then ps = self:calcPoisonedStatus(); end;

   local sm = calcMultiplier(settings.speedMultipliers, es, fs, hs, ps);
   local jm = calcMultiplier(settings.jumpMultipliers, es, fs, hs, ps);

   self.player:set_physics_override({ speed = sm, jump = jm });
end;

--- Refreshes GUI to show changes to player state (fed, hydrated, and poisoned
 -- bars).  This is done automatically during initialization and update, and
 -- by methods that directly change the state unless deferral is requested.
 --
function PlayerState_ops:updateHud()
   local player = self.player;

   local fh = self.fedHudId;
   if not fh then
      local def = table.copy(settings.fedHud);
      def.number = self.state.fed;
      fh = player:hud_add(def);
      self.fedHudId = fh;
   else
      player:hud_change(fh, 'number', self.state.fed);
   end;

   local hh = self.hydratedHudId;
   if not hh then
      local def = table.copy(settings.hydratedHud);
      def.number = self.state.hydrated;
      hh = player:hud_add(def);
      self.hydratedHudId = hh;
   else
      player:hud_change(hh, 'number', self.state.hydrated);
   end;

   local ph = self.poisonedHudId;
   if not ph then
      local def = table.copy(settings.poisonedHud);
      def.number = self.state.poisoned;
      ph = player:hud_add(def);
      self.poisonedHudId = ph;
   else
      player:hud_change(ph, 'number', self.state.poisoned);
   end;
end;

--- Tests whether the user is engaging in strenuous movement (based on the
 -- control keys) or holding his/her breath.  Called automatically, but could
 -- also be called other times explicitly.  Exertion status is modified based
 -- on the ratio of hits to total polls.
 --
function PlayerState_ops:pollForActivity()
   local player = self.player;

   self.activityPolls = self.activityPolls + 1;

   local activeControls = player:get_player_control();
   local testControls = settings.exertionControls;
   for _, ctrl in ipairs(testControls) do
      if activeControls[ctrl] then
         self.activity = self.activity + 1;
         return;
      end;
   end;

   if player:get_breath() <= settings.exertionHoldingBreathMax then
      self.activity = self.activity + 1;
      return;
   end;
end;

--- Adds to the build count of digs and node placements.  Exertion status is
 -- modified based on the number of builds between calls to the update method.
 -- Called automatically, but could be called explicitly for things other than
 -- normal node dig/place that should be counted.
 --
 -- @param node
 --    The node (object) being dug or placed.  The call is ignored if the node
 --    is in the "oddly_breakable_by_hand" and/or "dig_immediate" groups.
 --
function PlayerState_ops:markBuildAction(node)
   local nodeName = node.name;
   if not (minetest.get_node_group(nodeName, "oddly_breakable_by_hand") > 0 or
           minetest.get_node_group(nodeName, "dig_immediate") > 0)
   then
      self.builds = self.builds + 1;
   end;
end;

--- Resets activity (polls) and build counts to zero.
 --
function PlayerState_ops:clearExertionStats()
   self.activity = 0;
   self.activityPolls = 0;
   self.builds = 0;
end;


return PlayerState;
