local scrapProducingIngredients = {}
	-- Maps scrap-producing ingredient to a table of [scrap item name] => [num produced].
	-- For example, scrapProducingItems["tin-cable"] = {["tin-scrap"] = 0.5, ["copper-scrap"] = 0.5}.
	-- Later we multiply those numbers by the global scrap-amount setting.

-- Add regular scrap.
local regularMaterialsToScrap = {
	copper="copper-scrap", tin="tin-scrap", bronze="bronze-scrap", iron="iron-scrap", steel="steel-scrap",
	gold="gold-scrap", lead="lead-scrap", brass="brass-scrap",
	chromium="steel-scrap", -- Chromium items produce steel scrap, as in base IR3.
	-- TODO add concrete scrap?
}
local regularItemsToScrapAmt = {ingot=1, plate=1, rod=0.5, foil=0.5, cable=0.5}
	-- Note the 0.5's here to halve the scrap for that item, bc 1 ingot makes 2 rods or 2 foils or 2 cables.
	-- Not all of these exist, eg there's no tin-foil or gold-rod. So below, we check what exists.
if settings.startup["ProductionScrapForIR3-reinforced-plate-ingredients-produce-scrap"].value then
	regularItemsToScrapAmt["plate-heavy"] = 2.5 -- 1 plate-heavy <== 2 plate + 1 rivets <== 2 ingots + 0.5 ingots.
end
for material, scrapItem in pairs(regularMaterialsToScrap) do
	for item, scrapAmt in pairs(regularItemsToScrapAmt) do
		local materialItem = material .. "-" .. item
		if data.raw.item[materialItem] ~= nil then
			scrapProducingIngredients[materialItem] = { [scrapItem] = scrapAmt }
		end
	end
end

-- Add irregular scrap.
scrapProducingIngredients["glass"] = {["glass-scrap"] = 0.5} -- You can smelt 1x glass fragments to 2x glass, so we halve the scrap.
scrapProducingIngredients["wood"] = {["wood-chips"] = 0.5}
scrapProducingIngredients["iron-stick"] = {["iron-scrap"] = 0.5} -- "stick" is only used for iron-stick (from vanilla), other materials use "rod".
scrapProducingIngredients["tin-cable"] = { -- overwrite to make both tin and copper scrap
	-- Base IR3 has 2 tin cable <== 2 copper cable + 1 tin ingot <== 1 copper ingot + 1 tin ingot.
	["tin-scrap"] = 0.5,
	["copper-scrap"] = 0.5,
}
scrapProducingIngredients["gold-cable"] = {
	-- Base IR3 has 2 gold cable <== 2 copper cable + 10 gold-plating solution.
	-- Base IR3 also has 40 gold-plating solution <== 4 gold ingots + water + sulfuric acid.
	-- So in base IR3, 1 gold cable needs 1 copper cable + 5 gold-plating solution, which is 0.5 of each ingot.
	["copper-scrap"] = 0.5,
	["gold-scrap"] = 0.5,
}
scrapProducingIngredients["copper-cable-heavy"] = { -- Recipe is called heavy-copper-cable.
	-- Base IR3 has 1 heavy copper cable <== 8 copper cable + 1 rubber <== 4 copper ingots + 1 rubber.
	["copper-scrap"] = 4,
}

if settings.startup["ProductionScrapForIR3-beam-ingredients-produce-scrap"].value then
	scrapProducingIngredients["wood-beam"] = {["wood-chips"] = 1} -- 1 wood = 2 wood beams = 2 wood chips.
	scrapProducingIngredients["copper-beam"] = { -- made from 2 copper plates + 1 copper rivets + 1 wood beam.
		["copper-scrap"] = 2.5,
		["wood-chips"] = 1,
	}
	scrapProducingIngredients["bronze-beam"] = { -- made from 2 bronze plates + 1 bronze rivets + 1 wood beam.
		["bronze-scrap"] = 2.5,
		["wood-chips"] = 1,
	}
	-- Iron/steel beams made from 2 plates + 1 rivet + 1 ingot <== 2 + 0.5 + 1 ingots.
	scrapProducingIngredients["iron-beam"] = { ["iron-scrap"] = 3.5 }
	scrapProducingIngredients["steel-beam"] = { ["steel-scrap"] = 3.5 }
	-- Chromed beams made from 2 plates + 1 rivet + 2 rods <== 2 + 0.5 + 1 ingots.
	scrapProducingIngredients["chromium-beam"] = { ["steel-scrap"] = 3.5 }
end

return scrapProducingIngredients