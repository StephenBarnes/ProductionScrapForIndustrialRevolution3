if settings.startup["ProductionScrapForIR3-nerf-scrapping-for-analysis-packs"].value then
	for _, item in pairs(data.raw.tool) do
		-- For some reason science packs are in data.raw.tool, not .item.
		if item.subgroup == "science-pack" or item.subgroup == "analysis" then
			local scrapRecipeName = "scrap-"..item.name
			if data.raw.recipe[scrapRecipeName] then
				-- I can't find a way to completely disable these recipes. This doesn't work:
				--data.raw.recipe[scrapRecipeName].enabled = false

				-- So instead I'll just halve the amount of scrap produced.
				for _, result in pairs(data.raw.recipe[scrapRecipeName].results) do
					if result.probability ~= nil then
						result.probability = result.probability * 0.5
					else
						if math.floor(result.amount_max * 0.5) > 0 then
							result.amount_min = math.floor(result.amount_min * 0.5)
							result.amount_max = math.floor(result.amount_max * 0.5)
						else
							result.amount_min = 0
							result.amount_max = 1
						end
					end
				end
			end
		end
	end
end