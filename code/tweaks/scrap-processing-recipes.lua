
local addPelletRecipes = settings.startup["ProductionScrapForIR3-scrap-processing-recipe"].value == "pellets" -- TODO handle the other possible values.
local pelletsFromScrap = settings.startup["ProductionScrapForIR3-pellets-from-scrap"].value

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