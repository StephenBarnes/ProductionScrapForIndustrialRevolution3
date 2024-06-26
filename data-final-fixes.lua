local common = require("common")

local scrapAmt = settings.startup["ProductionScrapForIR3-scrap-per-ingredient"].value
local addPelletRecipes = settings.startup["ProductionScrapForIR3-scrap-processing-recipe"].value == "pellets" -- TODO handle the other possible values.
local pelletsFromScrap = settings.startup["ProductionScrapForIR3-pellets-from-scrap"].value
-- TODO: Maybe add an option to have gears make scrap, and then remove the requirement that recipes have >1 ingredient to produce scrap. Well, first try playing a long game with this, and then decide.

------------------------------------------------------------------------
--- SET UP TABLE OF SCRAP-PRODUCING INGREDIENTS
-- TODO maybe move this to common.lua.

local regularMaterialsToScrap = {
	copper="copper-scrap", tin="tin-scrap", bronze="bronze-scrap", iron="iron-scrap", steel="steel-scrap",
	gold="gold-scrap", lead="lead-scrap", brass="brass-scrap",
	chromium="steel-scrap", -- Chromium items produce steel scrap, as in base IR3.
}
local regularItemsToMultiplier = {ingot=1, plate=1, rod=2, foil=2, cable=2}
	-- Not all of these exist, eg there's no tin-foil or gold-rod. So below, we check what exists.
	-- Note the 2's here to halve the scrap for that item, bc 1 ingot makes 2 rods or 2 foils or 2 cables.
	-- Note I'm including cables (copper, tin, gold) even though those recipes aren't very simple, because they're still strictly more expensive.
local scrapProducingItems = {} -- maps ingredient item to a table of [scrap item name] => [num producible from 1 "ingot"]
-- Add regular scrap.
for material, scrapItem in pairs(regularMaterialsToScrap) do
	for item, multiplier in pairs(regularItemsToMultiplier) do
		local materialItem = material .. "-" .. item
		if data.raw.item[materialItem] ~= nil then
			scrapProducingItems[materialItem] = { [scrapItem] = multiplier }
		end
	end
end
-- Add some irregular scrap.
for k, v in pairs({
	["glass"] = {["glass-scrap"] = 2}, -- You can smelt 1x glass fragments to 2x glass, so we halve the scrap.
	["wood-beam"] = {["wood-chips"] = 1}, -- 1 wood = 2 wood beams = 2 wood chips.
	["wood"] = {["wood-chips"] = 2},
	["iron-stick"] = {["iron-scrap"] = 2}, -- "stick" is only used for iron-stick (from vanilla), other materials use "rod".
	["tin-cable"] = { -- overwrite to make both tin and copper scrap
		-- Base IR3 has 2 tin cable <== 2 copper cable + 1 tin ingot <== 1 copper ingot + 1 tin ingot.
		["tin-scrap"] = 2,
		["copper-scrap"] = 2,
	},
	["gold-cable"] = {
		-- Base IR3 has 2 gold cable <== 2 copper cable + 10 gold-plating solution.
		-- Base IR3 also has 40 gold-plating solution <== 4 gold ingots + water + sulfuric acid.
		-- So in base IR3, 1 gold cable needs 1 copper cable + 5 gold-plating solution, which is 0.5 of each ingot.
		["copper-scrap"] = 2,
		["gold-scrap"] = 2,
	},
	-- Not adding anything for stone or concrete-block, bc I don't think that makes sense with the recipes we have.
}) do
	scrapProducingItems[k] = v
end

------------------------------------------------------------------------
--- MODIFY RECIPES TO PRODUCE SCRAP

-- Some categories of recipes should never produce scrap because it doesn't really make sense.
-- For science packs (subgroup "analysis"), the recipes allow productivity modules, so disabling scrap for those to prevent scrap-and-remake shenanigans.
local excludeRecipeCategories = common.listToSet{"alloying", "alloying-2", "alloying-3", "blast-alloying", "molten-alloying", "advanced-molten-alloying", "barrelling", "scrapping", "electroplating", "melting", "stacking"}
local excludeRecipeSubgroups = common.listToSet{
	"plate", "rod", -- These produce scrap as ingredients, so shouldn't also produce scrap when created.
	"cable", -- Includes foils. These produce scrap as ingredients, so shouldn't also produce scrap when created.
	"ir-trees",
	"rivet", "plate-heavy", "beam", "pellet", -- These are made from rods/plates/ingots/wood, which would all ordinarily produce scrap. But I just don't like making their recipes produce scrap because it seems unrealistic. These also don't produce scrap as ingredients. So this makes recipes that use these items as ingredients a bit more expensive relative to other recipes, since you don't get scrap from your raw materials. But it's like a 5% difference so it won't seriously unbalance IR3.
}
local excludeRecipeNames = common.listToSet{
	-- Chemistry
	"chromium-plating-solution", "gold-plating-solution", "refined-concrete", "concrete", "charcoal-from-ore",
	-- Coating cables shouldn't produce scrap, because we're making them produce scrap when they're ingredients, plus it doesn't make sense.
	"copper-cable-heavy", "tin-cable", "red-wire", "green-wire",
	-- Remove electric pole scrap, because it makes sense for it to take 1 beam and not produce wood chips / scrap.
	"small-electric-pole", "medium-electric-pole", "big-electric-pole", "small-bronze-pole", "small-iron-pole", "big-wooden-pole",
	"rail", -- No scrap from rail because it doesn't make sense.
	"wood-chips", -- Crushing wood to produce wood chips shouldn't also produce extra wood chip scrap.
	"low-density-structure", -- IR3 uses this ID for steel foam.
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
		"combat-shotgun", "rocket-launcher", "flamethrower",
		-- "submachine-gun", "machine-gun", "gun", "pistol", -- These don't work and I don't know why. Recipe still produces scrap.
		"monowheel", "heavy-roller", "heavy-picket", "hydrogen-airship", "helium-airship", "spidertron", "spidertron-remote",
		"car", "tank",
		"transfer-plate", "transfer-plate-2x2",
		"chrome-transmat", "cargo-transmat",
	}) do
		excludeRecipeNames[recipe] = true
	end
end
if not settings.startup["ProductionScrapForIR3-science-produces-scrap"].value then
	excludeRecipeSubgroups["analysis"] = true
end
if not settings.startup["ProductionScrapForIR3-gears-produce-scrap"].value then
	excludeRecipeSubgroups["gear-wheel"] = true
end

function shouldModifyRecipe(recipe)
	if (not recipe.result) -- Recipe must have at least 1 product
		and ((not recipe.results) or (#recipe.results == 0))
		and (not recipe.normal) then
		return false
	end
	if recipe.category and excludeRecipeCategories[recipe.category] then return false end
	if recipe.subgroup and excludeRecipeSubgroups[recipe.subgroup] then return false end
	if excludeRecipeNames[recipe.name] then return false end
	return true
end

function figureOutScrapResults(ingredients)
	-- Returns a list of scrap items to add to the recipe's results list.
	local scrapProduced = {}
	for i, v in pairs(ingredients) do
		local item = v[1] or v.name
		local amount = v[2] or v.amount
		local scrapForItem = scrapProducingItems[item]
		if scrapForItem ~= nil then
			for scrapItem, multiplier in pairs(scrapForItem) do
				common.increaseKey(scrapProduced, scrapItem, scrapAmt * amount / multiplier)
				-- NOTE this calculation could use IR3's DIR.scrap_divider, though not sure which side of 1 that's on.
			end
		end
	end
	-- Now it's in a format like {["iron-scrap"] = 1}; we want this in format like {{name = "iron-scrap", amount=1, type="item"}}
	result = {}
	for scrapItem, numProduced in pairs(scrapProduced) do
		if numProduced > 0 and numProduced < 1 then
			table.insert(result, {name=scrapItem, probability=numProduced, amount=1, type="item"})
		elseif numProduced >= 1 then
			local upperBound = math.floor(numProduced * 2)
			table.insert(result, {name=scrapItem, type="item", amount_min=0, amount_max=upperBound})
		end
	end
	return result
end

function modifyRecipe(recipe)
	-- There are 3 formats for recipes: type 1 has .normal or .expensive; type 2 has .result; type 3 has .results (plural).
	-- We handle types 2 and 3 with modifyRecipeSimple. We handle type 1 by calling modifyRecipeSimple separately for normal and expensive.
	if (recipe.normal == nil) and (recipe.expensive == nil) then
		modifyRecipeSimple(recipe)
	else
		if recipe.normal then
			modifyRecipeSimple(recipe.normal)
		end
		if recipe.expensive then
			modifyRecipeSimple(recipe.expensive)
		end
	end
end

function modifyRecipeSimple(recipe)
	if not shouldModifyRecipe(recipe) then return end
	local scrapResults = figureOutScrapResults(recipe.ingredients)
	if #scrapResults == 0 then return end
	if recipe.results == nil then
		recipe.results = {
			{ name = recipe.result, amount = recipe.result_count or 1 },
		}
		recipe.main_product = recipe.result
			-- This is necessary because if there's only one result, Factorio sets recipe's icon to that result item's icon. But now we're adding an extra result, so we need to tell it which result item's icon to use.
		recipe.result = nil
		recipe.result_count = nil
	else -- already have recipe.results, but it might be only 1 item.
		-- annotate main product of single-result recipes, for the icon
		if recipe.main_product == nil and #recipe.results == 1 then
			recipe.main_product = recipe.results[1].name
		end
	end
	common.extend(recipe.results, scrapResults)
end

if scrapAmt > 0 then
	for _, recipe in pairs(data.raw.recipe) do
		modifyRecipe(recipe)
	end
end

------------------------------------------------------------------------
-- ADD SCRAP-TO-PELLET RECIPES

function doesTechUnlockRecipe(tech, recipeName)
	if not tech.effects then return false end
	for _, effect in pairs(tech.effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipeName then return true end
	end
	return false
end

if addPelletRecipes then
	local possibleScrapPelletMaterials = {"copper", "tin", "bronze", "iron", "steel", "gold", "lead", "brass", "chromium", "nickel", "platinum"}
	local newData = {{
		type = "item-subgroup",
		name = "pellets-from-scrap",
		group = "ir-basics",
		order = "vc",
	}}
	for _, material in ipairs(possibleScrapPelletMaterials) do
		local scrapItem = material .. "-scrap"
		local pelletItem = material .. "-pellet"
		if data.raw.item[scrapItem] and data.raw.item[pelletItem] then
			local newRecipeName = material.."-pellets-from-scrap"
			local newRecipe = {
				type = "recipe",
				name = newRecipeName,
				result = material.."-pellet",
				result_count = pelletsFromScrap,
				enabled = true,
				category = "crafting-small",
				subgroup = "pellets-from-scrap",
				ingredients = {{material.."-scrap", 1}},
				show_amount_in_title = false,
				always_show_products = true,
				energy_required = DIR.standard_crafting_time, -- Uses constant from IR3's DIR.
				localised_name = {"recipe-name.pellets-from-scrap", {"item-name."..material.."-pellet"}},
				icons = {
					{icon = DIR.get_icon_path(pelletItem), icon_size = DIR.icon_size, icon_mipmaps = DIR.icon_mipmaps},
				},
			}
			-- Use IR3's function to combine icons, so it looks the same as the other recipes' icons.
			DIR.add_icons_to_recipe(newRecipe,
				{{icon = DIR.get_icon_path(scrapItem), icon_size = DIR.icon_size, icon_mipmaps = DIR.icon_mipmaps}}, -1)
			-- Add properties from the other pellet recipe.
			local originalPelletRecipe = data.raw.recipe[pelletItem]
			if originalPelletRecipe then
				newRecipe.crafting_machine_tint = table.deepcopy(originalPelletRecipe.crafting_machine_tint)
				newRecipe.enabled = originalPelletRecipe.enabled -- FIXME Might break if that recipe has normal/expensive.
				for _,tech in pairs(data.raw.technology) do
					-- FIXME Might break if technology has normal/expensive separate.
					if doesTechUnlockRecipe(tech, pelletItem) then
						table.insert(tech.effects, {type="unlock-recipe", recipe=newRecipeName})
					end
				end
			end
			table.insert(newData, newRecipe)
		end
		-- Modify the icons of the other pellet recipes, to make them more visually distinct.
		local ingotItem = material .. "-ingot"
		if data.raw.item[pelletItem] and data.raw.item[ingotItem] and data.raw.recipe[pelletItem] then
			DIR.convert_recipe_icon_to_icons(data.raw.recipe[pelletItem])
			DIR.add_icons_to_recipe(data.raw.recipe[pelletItem],
				{{icon = DIR.get_icon_path(ingotItem), icon_size = DIR.icon_size, icon_mipmaps = DIR.icon_mipmaps}}, -1)
		end
	end
	data:extend(newData)
end
--- BASIC FUNCTIONS