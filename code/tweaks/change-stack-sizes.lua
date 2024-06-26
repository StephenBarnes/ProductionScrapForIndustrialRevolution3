local stackMultiplier = settings.startup["ProductionScrapForIR3-scrap-stack-multiplier"].value
if stackMultiplier ~= 1 then
	local scrapItemNames = require("code.constants.scrap-item-names")
	for _, item in pairs(scrapItemNames) do
		if data.raw.item[item] then
			local newVal = math.max(1, math.ceil(data.raw.item[item].stack_size * stackMultiplier))
			data.raw.item[item].stack_size = newVal
		end
	end
end