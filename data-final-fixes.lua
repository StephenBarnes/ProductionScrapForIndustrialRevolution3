local scrapAmt = settings.startup["ProductionScrapForIR3-scrap-per-ingredient"].value
local addPelletRecipes = settings.startup["ProductionScrapForIR3-add-pellet-recipes"].value
local pelletsFromScrap = settings.startup["ProductionScrapForIR3-pellets-from-scrap"].value

------------------------------------------------------------------------
--- BASIC FUNCTIONS

function extend(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
end

function increaseKey(t, k, v)
	if t[k] == nil then
		t[k] = v
	else
		t[k] = t[k] + v
	end
end

function listToSet(l)
	-- Convert {a, b, c} to {a=true, b=true, c=true} so that we can check membership faster.
	local result = {}
	for _,v in ipairs(l) do
		result[v] = true
	end
	return result
end

------------------------------------------------------------------------
--- SET UP TABLE OF SCRAP-PRODUCING INGREDIENTS

local regularMaterialsToScrap = {
	copper="copper-scrap", tin="tin-scrap", bronze="bronze-scrap", iron="iron-scrap", steel="steel-scrap",
	gold="gold-scrap", lead="lead-scrap", brass="brass-scrap",
	chromium="steel-scrap", -- Chromium items produce steel scrap, as in base IR3.
}
local regularItemsToMultiplier = {ingot=1, plate=1, rod=2, foil=2, cable=2}
	-- Not all of these exist, eg there's no tin-foil or gold-rod. So below, we check what exists.
	-- Note the 2's here to halve the scrap for that item, bc 1 ingot makes 2 rods or 2 foils.
	-- Note I'm including cables (copper, tin, gold) even though those recipes aren't very simple, because they're still strictly more expensive.
local scrapProducingItems = { -- maps ingredient item to {scrap item}
	-- Some irregular scrap.
	["glass"] = {"glass-scrap", 1},
	["wood-beam"] = {"wood-chips", 1}, -- 1 wood = 2 wood beams = 2 wood chips.
	["wood"] = {"wood-chips", 2},
	["iron-stick"] = {"iron-scrap", 2}, -- "stick" is only used for iron-stick (from vanilla), other materials use "rod".
	-- Not adding anything for stone or concrete-block, bc I don't think that makes sense with the recipes we have.
}
-- Add regular scrap.
for material, scrapItem in pairs(regularMaterialsToScrap) do
	for item, multiplier in pairs(regularItemsToMultiplier) do
		local materialItem = material .. "-" .. item
		if data.raw.item[materialItem] ~= nil then
			scrapProducingItems[materialItem] = {scrapItem, multiplier}
		end
	end
end

------------------------------------------------------------------------
--- MODIFY RECIPES TO PRODUCE SCRAP

-- Some categories of recipes should never produce scrap because it doesn't really make sense.
-- For science packs (subgroup "analysis"), the recipes allow productivity modules, so disabling scrap for those.
local excludeRecipeCategories = listToSet{"alloying", "molten-alloying", "advanced-molten-alloying", "barrelling", "scrapping", "electroplating"}
local excludeRecipeSubgroups = listToSet{"plate-heavy", "beam", "rod", "ir-trees", "analysis"}
local excludeRecipeNames = listToSet{"chromium-plating-solution", "gold-plating-solution", "refined-concrete", "concrete"}

function shouldModifyRecipe(recipe)
	if (not recipe.ingredients) or (#recipe.ingredients <= 1) then return false end -- Recipe must have 2+ ingredients.
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
			local scrapItem = scrapForItem[1]
			local multiplier = scrapForItem[2]
			increaseKey(scrapProduced, scrapForItem[1], scrapAmt * amount / multiplier)
			-- NOTE this calculation could use IR3's DIR.scrap_divider, though not sure which side of 1 that's on.
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
	extend(recipe.results, scrapResults)
end

if scrapAmt > 0 then
	for name, recipe in pairs(data.raw.recipe) do
		modifyRecipe(recipe)
	end
end

------------------------------------------------------------------------
-- ADD SCRAP-TO-PELLET RECIPES

function doesTechUnlockRecipe(tech, recipeName)
	if not tech.effects then return false end
	for _,effect in pairs(tech.effects) do
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
				energy_required = DIR.standard_crafting_time, -- Uses constant from IR3's DIR
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
				newRecipe.crafting_machine_tints = table.deepcopy(originalPelletRecipe.crafting_machine_tints)
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