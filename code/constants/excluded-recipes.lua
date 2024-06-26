local excludedRecipes = {}

local listToSet = require("code.utils").listToSet

-- Some categories of recipes should never produce scrap because it doesn't really make sense.
excludedRecipes.excludeRecipeCategories = listToSet{
	-- IR3:
	"alloying", "alloying-2", "alloying-3", "blast-alloying", "molten-alloying", "advanced-molten-alloying", "barrelling", "scrapping", "electroplating", "melting",
	-- IR3 Stacking Beltboxes:
	"stacking",
	-- Intermodal Containers:
	"packing",
}

excludedRecipes.excludeRecipeSubgroups = listToSet{
	"plate", "rod", -- These produce scrap as ingredients, so shouldn't also produce scrap when created.
	"beam", "plate-heavy", -- These produce scrap as ingredients (if setting is enabled), so shouldn't also produce scrap when created.
	"cable", -- Includes foils. These produce scrap as ingredients, so shouldn't also produce scrap when created.
	"ir-trees",
	"rivet", "pellet", -- These are made from rods/ingots, which would all ordinarily produce scrap. But it's unrealistic for them to produce scrap as ingredients, and we also don't want the recipes producing them to create scrap because that discourages producing them locally.
}

excludedRecipes.excludeRecipeNames = listToSet{
	-- Chemistry
	"chromium-plating-solution", "gold-plating-solution", "refined-concrete", "concrete", "charcoal-from-ore",
	-- Coating cables shouldn't produce scrap, because we're making them produce scrap when they're ingredients, plus it doesn't make sense.
	"copper-cable-heavy", "tin-cable", "red-wire", "green-wire",
	-- Remove electric pole scrap, because it makes sense for it to take 1 beam and not produce wood chips / scrap.
	"small-electric-pole", "medium-electric-pole", "small-bronze-pole", "small-iron-pole", "big-wooden-pole",
	"rail", -- No scrap from rail because it doesn't make sense.
	"wood-chips", -- Crushing wood to produce wood chips shouldn't also produce extra wood chip scrap.
	"low-density-structure", -- IR3 uses this ID for steel foam.
	"nanoglass", -- Produces scrap as ingredient.
}

-- Exclude stuff you'll only craft manually, no need to inconvenience the player for these.
if settings.startup["ProductionScrapForIR3-exclude-annoyances"].value then
	for _, recipe in pairs({
		"light-armor", "heavy-armor", "modular-armor", "power-armor", "power-armor-mk2",
		"iron-burner-generator-equipment", "battery-discharge-equipment", "solar-panel-equipment", "fusion-reactor-equipment",
		"battery-equipment", "battery-mk2-equipment",
		"copper-roboport-equipment", "personal-roboport-equipment", "personal-roboport-mk2-equipment",
		"night-vision-equipment", "belt-immunity-equipment", "exoskeleton-equipment", "personal-laser-defense-equipment",
		"energy-shield-equipment", "energy-shield-mk2-equipment", "discharge-defense-equipment", "discharge-defense-remote",
		"arc-turret-equipment", "personal-laser-defense-equipment",
		"shotgun", -- IR3 uses this ID for the blunderbuss
		"combat-shotgun", "rocket-launcher", "flamethrower", "pistol", "submachine-gun",
		"monowheel", "heavy-roller", "heavy-picket", "hydrogen-airship", "helium-airship", "spidertron", "spidertron-remote",
		"car", "tank",
		"transfer-plate", "transfer-plate-2x2",
		"chrome-transmat", "cargo-transmat", "rocket-silo",
		"position-beacon", "vehicle-depot", "vehicle-deployer", -- stuff from AAI Programmable Vehicles
	}) do
		excludedRecipes.excludeRecipeNames[recipe] = true
	end
end

if not settings.startup["ProductionScrapForIR3-science-produces-scrap"].value then
	excludedRecipes.excludeRecipeSubgroups["analysis"] = true
end

if not settings.startup["ProductionScrapForIR3-gears-produce-scrap"].value then
	excludedRecipes.excludeRecipeSubgroups["gear-wheel"] = true
end

return excludedRecipes