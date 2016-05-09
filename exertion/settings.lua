local defaults = select(1, ...) or {};

---- Basic Definitions

--- Food points (half-icons) for the the maximum, fully fed bar.
 --
 -- default: fedMaximum = 20;
 --
fedMaximum = 20;

--- Water points (half-icons) for the the maximum, fully hydrated bar.
 --
 -- default: hydratedMaximum = 20;
 --
hydratedMaximum = 20;

--- Poison points (half-icons) for the maximum poisoned amount.
 --
 -- default: poisonedMaximum = 4;
 --
poisonedMaximum = 4;


---- Rates and Times

--- Whether to use wallclock time, so fed and hydrated amounts go down not just
 -- when logged off, but when the server isn't running (falls back to game time
 -- if server's time has been set backwards enough to "go back in time").  Note
 -- that poison is NOT modified while logged out, though it also doesn't cause
 -- damage, etc.
 --
 -- default: useWallclock = true;
 --
useWallclock = true;

--- Base amount of food that needs to be consumed each day to stay fed, in both
 -- points (half-icons) and conventional food "HP gain".
 --
 -- default: food_perDay = 4;
 --
food_perDay = 4;

--- Base amount of water (hydration) lost each day, in points (half-icons).
 --
 -- default: water_perDay = 8;
 --
water_perDay = 8;

--- Amount poison decreases each day, in points (half-icons).
 --
 -- default: poison_perDay = 4;
 --
poison_perDay = 8;

--- Amount HP (half-icons) healed per day if properly fed, hydrated, and not
 -- poisoned.
 --
 -- default: healing_perDay = 8;
 --
healing_perDay = 8;

--- Distance water must be from player while player's head is in air to drink.
 --
 -- default: drinkingDistance = 1.5;
 --
drinkDistance = 1;

--- Amount of water to drink in points (half-icons) each period when able.
 --
 -- default: drinkAmount_perPeriod = 4.0;
 --
drinkAmount_perPeriod = 4.0;

--- Period between tests of user controls for testing movement exertion.
 -- Decrease if not responsive enough; increase if its creating too much server
 -- lag.
 --
 -- default: controlTestPeriod_seconds = 0.1;
 --
controlTestPeriod_seconds = 0.1;

--- Length of an accounting period.
 --
 -- default: accountingPeriod_seconds = 10.0;
 --
accountingPeriod_seconds = 10.0;

--- Amount of time spent retching (can't walk or jump).
 --
 -- default: retchDuration_seconds = 2.0;
 --
retchDuration_seconds = 1.0;

--- Time between saves.
 --
 -- default: savePeriod_seconds = 300.0;
 --
savePeriod_seconds = 300.0;


---- Enumerated Statuses

--- Status values indicating how hard the player is exerting him-/herself.  Each
 -- key is a status value.  Each value is a condition object indicating when
 -- the player has that status.  Each condition object has the following fields:
 --    * priority - The status that is used is the one with the highest priority
 --         and any of its condition(s) met.
 --    * activityRatio - The minimum ratio of strenuous movement/breath
 --         activities noted to total number of times activity is polled in an
 --         accounting period to meet the status condition.
 --    * builds - The minimum number of digs or node placements that must occur
 --         during an accounting period to meet the status condition.  Nodes
 --         with the 'dig_immediate' and/or 'oddly_breakable_by_hand' groups are
 --         not counted.
 -- If no status conditions are met, the special status 'none' is used.
 --
 -- defaults:
 --    exertionStatuses = defaults.exertionStatuses or {};
 --    exertionStatuses.light =
 --       { priority = 1, activityRatio = 0.25, builds = 5 };
 --    exertionStatuses.heavy =
 --       { priority = 2, activityRatio = 0.75, builds = 10 };
 --
exertionStatuses = defaults.exertionStatuses or {};
exertionStatuses.light =
   { priority = 1, activityRatio = 0.25, builds = 5 };
exertionStatuses.heavy =
   { priority = 2, activityRatio = 0.75, builds = 10 };

--- Status values indicating how well fed the player is.  Each key is a status.
 -- Each value is a threshold for the minimum fed points (half-icons) for that
 -- status.  The highest threshold has precedence.  Behavior is undefined if the
 -- same threshold is used for multiple status keys.  The special status 'none'
 -- is used when no others apply.
 --
 -- defaults:
 --    fedStatuses = defaults.fedStatuses or {};
 --    fedStatuses.starving = 0;
 --    fedStatuses.hungry   = 1;
 --    fedStatuses.full     = 10;
 --
fedStatuses = defaults.fedStatuses or {};
fedStatuses.starving = 0;
fedStatuses.hungry   = 1;
fedStatuses.full     = 10;

--- Status values indicating how well hydrated the player is.  Each key is a
 -- status.  Each value is a threshold for the minimum hydrated points
 -- (half-icons) for that status.  The highest threshold has precedence.
 -- Behavior is undefined if the same threshold is used for multiple status
 -- keys.  The special status 'none' is used when no others apply.
 --
 -- defaults:
 --    hydratedStatuses = defaults.hydratedStatuses or {};
 --    hydratedStatuses.dehydrated = 0;
 --    hydratedStatuses.thirsty    = 1;
 --    hydratedStatuses.hydrated   = 10;
 --
hydratedStatuses = defaults.hydratedStatuses or {};
hydratedStatuses.dehydrated = 0;
hydratedStatuses.thirsty    = 1;
hydratedStatuses.hydrated   = 10;

--- Status values indicating how badly poisoned the player is.  Each key is a
 -- status. Each value is a threshold for the minimum hydrated points
 -- (half-icons) for that status.  The highest threshold has precedence.
 -- Behavior is undefined if the same threshold is used for multiple status
 -- keys.  The special status 'none' is used when no others apply.
 --
 -- defaults:
 --    poisonedStatuses = defaults.poisonedStatuses or {};
 --    poisonedStatuses.poisoned = 1;
 --
poisonedStatuses = defaults.poisonedStatuses or {};
poisonedStatuses.poisoned = 1;


---- Status Conditions/Events

--- Control keys (from Player:get_player_control()) that indicates the player is
 -- engaging in strenuous movement.  Any time these controls are detected
 -- (and/or the player is holding his/her breath), it contributes to the
 -- activity ratio.
 --
 -- default: exertionControls = { 'up', 'down', 'left', 'right', 'jump' };
 --
exertionControls = { 'up', 'down', 'left', 'right', 'jump' };

--- Breath (from Player:get_breath()) max (inclusive) threshold that indicates
 -- the player is straining to hold his/her breath.  Any time the player's
 -- breath is less than or equal to this (or the player is moving), it
 -- contributes to the activity ratio.
 --
 -- default: exertionBreathMax = 10;
 --
exertionHoldingBreathMax = 10;

--- Probability for each unit of (normally good) food eaten that it is poisoned.
 --
 -- default: foodPoisoningProb = 0.025;
 --
foodPoisoningProb = 0.025;


---- Status Effects

--- Rate multipliers for amount of food decrease per period for each status
 -- (exertion, fed, hydrated, poisoned).  Each multiplier defaults to 1.0 if the
 -- applicable status is not present.
 --
 -- defaults:
 --    foodMultipliers = defaults.foodMultipliers or
 --       { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
 --    foodMultipliers.exertion.none  = 1.0;
 --    foodMultipliers.exertion.light = 2.0;
 --    foodMultipliers.exertion.heavy = 3.0;
 --
foodMultipliers = defaults.foodMultipliers or
   { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
foodMultipliers.exertion.none  = 1.0;
foodMultipliers.exertion.light = 2.0;
foodMultipliers.exertion.heavy = 3.0;

--- Rate multipliers for amount of food decrease per period for each status
 -- (exertion, fed, hydrated, poisoned).  Each multiplier defaults to 1.0 if the
 -- applicable status is not present.
 --
 -- defaults:
 --    waterMultipliers = defaults.waterMultipliers or
 --       { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
 --    waterMultipliers.exertion.none  = 1.0;
 --    waterMultipliers.exertion.light = 2.0;
 --    waterMultipliers.exertion.heavy = 3.0;
 --
waterMultipliers = defaults.waterMultipliers or
   { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
waterMultipliers.exertion.none  = 1.0;
waterMultipliers.exertion.light = 2.0;
waterMultipliers.exertion.heavy = 3.0;

--- Rate multipliers for healing per period for each status (exertion, fed,
 -- hydrated, poisoned).  Each multiplier defaults to 1.0 if the applicable
 -- status is not present.
 --
 -- defaults:
 --    healingMultipliers = defaults.healingMultipliers or
 --       { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
 --    healingMultipliers.exertion.none       = 1.0;
 --    healingMultipliers.exertion.light      = 1.0;
 --    healingMultipliers.exertion.heavy      = 0.5;
 --    healingMultipliers.fed.starving        = 0.0;
 --    healingMultipliers.fed.hungry          = 0.0;
 --    healingMultipliers.fed.full            = 1.0;
 --    healingMultipliers.hydrated.dehydrated = 0.0;
 --    healingMultipliers.hydrated.thirsty    = 0.0;
 --    healingMultipliers.hydrated.hydrated   = 1.0;
 --    healingMultipliers.poisoned.none       = 1.0;
 --    healingMultipliers.poisoned.poisoned   = 0.0;
 --
healingMultipliers = defaults.healingMultipliers or
   { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
healingMultipliers.exertion.none       = 1.0;
healingMultipliers.exertion.light      = 1.0;
healingMultipliers.exertion.heavy      = 0.5;
healingMultipliers.fed.starving        = 0.0;
healingMultipliers.fed.hungry          = 0.0;
healingMultipliers.fed.full            = 1.0;
healingMultipliers.hydrated.dehydrated = 0.0;
healingMultipliers.hydrated.thirsty    = 0.0;
healingMultipliers.hydrated.hydrated   = 1.0;
healingMultipliers.poisoned.none       = 1.0;
healingMultipliers.poisoned.poisoned   = 0.0;

--- Multipliers for running speed per period for each status (exertion, fed,
 -- hydrated, poisoned).  Each multiplier defaults to 1.0 if the applicable
 -- status is not present.
 --
 -- defaults:
 --    speedMultipliers = defaults.speedMultipliers or
 --       { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
 --    speedMultipliers.fed.starving        = 0.8;
 --    speedMultipliers.fed.hungry          = 1.0;
 --    speedMultipliers.fed.full            = 1.0;
 --    speedMultipliers.hydrated.dehydrated = 0.8;
 --    speedMultipliers.hydrated.thirsty    = 1.0;
 --    speedMultipliers.hydrated.hydrated   = 1.0;
 --    speedMultipliers.poisoned.none       = 1.0;
 --    speedMultipliers.poisoned.poisoned   = 0.8;
 --
speedMultipliers = defaults.speedMultipliers or
   { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
speedMultipliers.fed.starving        = 0.8;
speedMultipliers.fed.hungry          = 1.0;
speedMultipliers.fed.full            = 1.0;
speedMultipliers.hydrated.dehydrated = 0.8;
speedMultipliers.hydrated.thirsty    = 1.0;
speedMultipliers.hydrated.hydrated   = 1.0;
speedMultipliers.poisoned.none       = 1.0;
speedMultipliers.poisoned.poisoned   = 0.8;

--- Multipliers for jumping per period for each status (exertion, fed, hydrated,
 -- poisoned).  Each multiplier defaults to 1.0 if the applicable status is not
 -- present.
 --
 -- defaults:
 --    jumpMultipliers = defaults.jumpMultipliers or
 --       { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
 --    jumpMultipliers.fed.starving        = 0.95;
 --    jumpMultipliers.fed.hungry          = 1.0;
 --    jumpMultipliers.fed.full            = 1.0;
 --    jumpMultipliers.hydrated.dehydrated = 0.95;
 --    jumpMultipliers.hydrated.thirsty    = 1.0;
 --    jumpMultipliers.hydrated.hydrated   = 1.0;
 --    jumpMultipliers.poisoned.none       = 1.0;
 --    jumpMultipliers.poisoned.poisoned   = 0.95;
 --
jumpMultipliers = defaults.jumpMultipliers or
   { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
jumpMultipliers.fed.starving        = 0.95;
jumpMultipliers.fed.hungry          = 1.0;
jumpMultipliers.fed.full            = 1.0;
jumpMultipliers.hydrated.dehydrated = 0.95;
jumpMultipliers.hydrated.thirsty    = 1.0;
jumpMultipliers.hydrated.hydrated   = 1.0;
jumpMultipliers.poisoned.none       = 1.0;
jumpMultipliers.poisoned.poisoned   = 0.95;

--- Base probability of retching each accounting period.
 --
 -- default: poisonedRetchProbability_perPeriod = 0.1;
 --
retchProb_perPeriod = 0.01;

--- Multipliers for probability of retching for each status (exertion, fed,
 -- hydrated, poisoned).  Each multiplier defaults to 1.0 if the applicable
 -- status is not present.
 --
 -- default:
 --
retchProbMultipliers = defaults.retchProbMultipliers or
   { exertion = {}, fed = {}, hydrated = {}, poisoned = {} };
retchProbMultipliers.exertion.none       = 1.0;
retchProbMultipliers.exertion.light      = 1.5;
retchProbMultipliers.exertion.heavy      = 2.0;
retchProbMultipliers.fed.starving        = 0.5;
retchProbMultipliers.fed.hungry          = 1.0;
retchProbMultipliers.fed.full            = 2.0;
retchProbMultipliers.hydrated.dehydrated = 1.0;
retchProbMultipliers.hydrated.thirsty    = 1.0;
retchProbMultipliers.hydrated.hydrated   = 1.5;
retchProbMultipliers.poisoned.none       = 0.0;
retchProbMultipliers.poisoned.poisoned   = 1.0;

--- Amount of food loss when retching, in points (half-icons).
 -- default: retchingFoodLoss = 2.0;
retchingFoodLoss = 2.0;

--- Amount of food loss when retching, in points (half-icons).
 -- default: retchingWaterLoss = 4.0;
retchingWaterLoss = 4.0;

--- Damage taken when retching, in HP (half-icons).
 -- default: retchingDamage = 0.1;
retchingDamage = 0.1;

--- Amount of air lost when holding breath and retching, in bubbles
 -- (half-icons).
 -- default: retchingAirLoss = 10.0;
retchingAirLoss = 10.0;


---- User Interface

--- Fed HUD bar definition.
 --
 -- default:
 --    fedHud = defaults.fedHud or { number = 0 };
 --    fedHud.hud_elem_type = 'statbar';
 --    fedHud.position = { x = 0.0, y = 1.0 };
 --    fedHud.text = "exertion_toastIcon_24x24.png";
 --    fedHud.direction = 3;
 --    fedHud.size = { x = 24, y = 24 };
 --    fedHud.offset = { x = 2, y = -26 };
 --
fedHud = defaults.fedHud or { number = 0 };
fedHud.hud_elem_type = 'statbar';
fedHud.position = { x = 0.0, y = 1.0 };
fedHud.text = "exertion_toastIcon_24x24.png";
fedHud.direction = 3;
fedHud.size = { x = 24, y = 24 };
fedHud.offset = { x = 2, y = -26 };

--- Hydrated HUD bar definition.
 --
 -- default:
 --    hydratedHud = defaults.hydratedHud or { number = 0 };
 --    hydratedHud.hud_elem_type = 'statbar';
 --    hydratedHud.position = { x = 0.0, y = 1.0 };
 --    hydratedHud.text = "exertion_waterIcon_24x24.png";
 --    hydratedHud.direction = 3;
 --    hydratedHud.size = { x = 24, y = 24 };
 --    hydratedHud.offset = { x = 28, y = -26 };
 --
hydratedHud = defaults.hydratedHud or { number = 0 };
hydratedHud.hud_elem_type = 'statbar';
hydratedHud.position = { x = 0.0, y = 1.0 };
hydratedHud.text = "exertion_waterIcon_24x24.png";
hydratedHud.direction = 3;
hydratedHud.size = { x = 24, y = 24 };
hydratedHud.offset = { x = 28, y = -26 };

--- Poisoned HUD bar definition.
 --
 -- default:
 --    poisonedHud = defaults.poisonedHud or { number = 0 };
 --    poisonedHud.hud_elem_type = 'statbar';
 --    poisonedHud.position = { x = 0.0, y = 1.0 };
 --    poisonedHud.text = "exertion_spiderIcon_24x24.png";
 --    poisonedHud.direction = 3;
 --    poisonedHud.size = { x = 24, y = 24 };
 --    poisonedHud.offset = { x = 54, y = -26 };
 --
poisonedHud = defaults.poisonedHud or { number = 0 };
poisonedHud.hud_elem_type = 'statbar';
poisonedHud.position = { x = 0.0, y = 1.0 };
poisonedHud.text = "exertion_spiderIcon_24x24.png";
poisonedHud.direction = 3;
poisonedHud.size = { x = 24, y = 24 };
poisonedHud.offset = { x = 54, y = -26 };

--- Sound played when retching.
 --
 -- default: retchingSound = "exertion_doubleRetching.ogg";
 --
retchingSound = defaults.retchingSound or {};
retchingSound.name = "exertion_doubleRetching";
retchingSound.gain = 1.0;
retchingSound.maxDist = 16;

--- Message sent to player when eating bad food.
 --
 -- default: foodPoisoningMessage = "Food poisoning!  Bleh!";
 --
foodPoisoningMessage = "Et tu, Brute?";
