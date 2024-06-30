local excludedRecipes = require("code.constants.excluded-recipes")
local scrapProducingIngredients = require("code.constants.scrap-producing-ingredients")
local utils = require("code.utils")

local scrapAmt = settings.startup["ProductionScrapForIR3-scrap-per-ingredient"].value

function shouldModifyRecipe(recipe)
	if (not recipe.result) -- Recipe must have at least 1 product
		and ((not recipe.results) or (#recipe.results == 0))
		and (not recipe.normal) then
		return false
	end
	if recipe.category and excludedRecipes.excludeRecipeCategories[recipe.category] then return false end
	if recipe.subgroup and excludedRecipes.excludeRecipeSubgroups[recipe.subgroup] then return false end
	if excludedRecipes.excludeRecipeNames[recipe.name] then return false end
	return true
end

function figureOutScrapResults(ingredients)
	-- Returns a list of scrap items to add to the recipe's results list.
	local scrapProduced = {}
	for i, v in pairs(ingredients) do
		local item = v[1] or v.name
		local amount = v[2] or v.amount
		local scrapForItem = scrapProducingIngredients[item]
		if scrapForItem ~= nil then
			for scrapItem, multiplier in pairs(scrapForItem) do
				utils.increaseKey(scrapProduced, scrapItem, scrapAmt * amount * multiplier)
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
			recipe.main_product = recipe.results[1].name or recipe.results[1][1]
		end
	end
	utils.extend(recipe.results, scrapResults)
end

if scrapAmt > 0 then
	for _, recipe in pairs(data.raw.recipe) do
		modifyRecipe(recipe)
	end
end