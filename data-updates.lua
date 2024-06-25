local common = require("common")

------------------------------------------------------------------------
-- MODIFY SCRAP STACK SIZES
-- This is in data-updates, not data-final-fixes, so that eg Extended Descriptions mod will see the updated stack sizes.

local scrapStackSize = settings.startup["ProductionScrapForIR3-scrap-stack-size"].value
if scrapStackSize > 0 then
	for _, item in pairs(common.scrapItemNames) do
		if data.raw.item[item] then
			data.raw.item[item].stack_size = scrapStackSize
		end
	end
end