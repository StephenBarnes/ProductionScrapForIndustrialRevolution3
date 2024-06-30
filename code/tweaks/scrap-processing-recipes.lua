
local processingRecipeSetting = settings.startup["ProductionScrapForIR3-scrap-processing-recipe"].value
local pelletsFromScrapWithoutRivets = settings.startup["ProductionScrapForIR3-pellets-from-scrap-without-rivets"].value
local pelletsFromScrapWithRivets = settings.startup["ProductionScrapForIR3-pellets-from-scrap-with-rivets"].value
local rivetsFromScrap = settings.startup["ProductionScrapForIR3-rivets-from-scrap"].value

local possibleMaterials = {"copper", "tin", "bronze", "iron", "steel", "gold", "lead", "brass", "chromium", "nickel", "platinum"}

function doesTechUnlockRecipe(tech, recipeName)
	if not tech.effects then return false end
	for _, effect in pairs(tech.effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipeName then return true end
	end
	return false
end

function getOutputFractional(item, amount)
	if 0 < amount and amount < 1 then
		return {name=item, probability=amount, amount=1, type="item"}
	elseif amount ~= math.floor(amount) then
		if amount - math.floor(amount) == 0.5 then
			return {name=item, type="item", amount_min=math.floor(amount), amount_max=math.ceil(amount)}
		else
			return {name=item, type="item", amount_min=0, amount_max=math.floor(2 * amount)}
		end
	else
		return {name=item, amount=amount, type="item"}
	end
end

function addScrapToPelletRecipes()
	local newData = {{
		type = "item-subgroup",
		name = "scrap-to-pellets",
		group = "ir-basics",
		order = "vc",
	}}
	for i, material in ipairs(possibleMaterials) do
		local scrapItem = material .. "-scrap"
		local pelletItem = material .. "-pellet"
		if data.raw.item[scrapItem] and data.raw.item[pelletItem] then
			local newRecipeName = material.."-scrap-to-pellets"
			local newRecipe = {
				type = "recipe",
				name = newRecipeName,
				enabled = true,
				category = "crafting-small",
				subgroup = "scrap-to-pellets",
				order = "vc-"..i,
				ingredients = {{material.."-scrap", 1}},
				show_amount_in_title = false,
				always_show_products = true,
				energy_required = DIR.standard_crafting_time, -- Uses constant from IR3's DIR.
				localised_name = {"recipe-name.scrap-to-pellets", {"item-name."..material.."-scrap"}},
				icons = {
					{icon = DIR.get_icon_path(pelletItem), icon_size = DIR.icon_size, icon_mipmaps = DIR.icon_mipmaps},
				},
			}
			newRecipe.results = {getOutputFractional(pelletItem, pelletsFromScrapWithoutRivets)}
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

function addScrapToPelletsAndRivetsRecipes()
	local newData = {{
		type = "item-subgroup",
		name = "scrap-to-pellets-and-rivets",
		group = "ir-basics",
		order = "vd",
	}}
	for i, material in ipairs(possibleMaterials) do
		local scrapItem = material .. "-scrap"
		local pelletItem = material .. "-pellet"
		local rivetItem = material .. "-rivet"
		if data.raw.item[scrapItem] and data.raw.item[rivetItem] then
			local newRecipeName = material.."-scrap-to-pellets-and-rivets"
			local newRecipe = {
				type = "recipe",
				name = newRecipeName,
				enabled = true,
				category = "crafting-small",
				subgroup = "scrap-to-pellets-and-rivets",
				order = "vd-"..i,
				ingredients = {{material.."-scrap", 1}},
				show_amount_in_title = false,
				always_show_products = true,
				energy_required = DIR.standard_crafting_time, -- Uses constant from IR3's DIR.
				localised_name = {"recipe-name.scrap-to-pellets-and-rivets", {"item-name."..material.."-scrap"}},
				icons = {
					{icon = DIR.get_icon_path(scrapItem), icon_size = DIR.icon_size, icon_mipmaps = DIR.icon_mipmaps},
				},
				allow_as_intermediate = false, -- Otherwise handcrafting gets "stuck" thinking all rivets must come from scrap.
			}
			newRecipe.results = { getOutputFractional(rivetItem, rivetsFromScrap) }
			if data.raw.item[pelletItem] then
				table.insert(newRecipe.results, getOutputFractional(pelletItem, pelletsFromScrapWithRivets))
			end
			DIR.add_result_icons_to_recipe(newRecipe, false, nil, nil)
			-- Add properties from the other rivet recipe.
			local originalRecipe = data.raw.recipe[rivetItem]
			if originalRecipe then
				newRecipe.crafting_machine_tint = table.deepcopy(originalRecipe.crafting_machine_tint)
				newRecipe.enabled = originalRecipe.enabled -- FIXME Might break if that recipe has normal/expensive.
				for _,tech in pairs(data.raw.technology) do
					-- FIXME Might break if technology has normal/expensive separate.
					if doesTechUnlockRecipe(tech, pelletItem) then
						table.insert(tech.effects, {type="unlock-recipe", recipe=newRecipeName})
					end
				end
			end
			table.insert(newData, newRecipe)
		end
	end
	data:extend(newData)
end
-- TODO de-duplicate some of the code between these two functions.

------------------------------------------------------------------------

if processingRecipeSetting == "pellets" or processingRecipeSetting == "all" then
	addScrapToPelletRecipes()
end

if processingRecipeSetting == "pellets-plus-rivets" or processingRecipeSetting == "all" then
	addScrapToPelletsAndRivetsRecipes()
end