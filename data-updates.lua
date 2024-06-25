
------------------------------------------------------------------------
-- MODIFY SCRAP STACK SIZES
-- This is in data-updates, not data-final-fixes, so that eg Extended Descriptions mod will see the updated stack sizes.

-- TODO move out to a separate file of constants.
local scrapItemNames = {
	"copper-scrap", "tin-scrap", "bronze-scrap", "iron-scrap", "steel-scrap",
	"gold-scrap", "lead-scrap", "brass-scrap",
	--"chromium-scrap", "nickel-scrap", "platinum-scrap",
	"wood-chips",
}

local scrapStackSize = settings.startup["ProductionScrapForIR3-scrap-stack-size"].value
if scrapStackSize > 0 then
	for _, item in pairs(scrapItemNames) do
		if data.raw.item[item] then
			data.raw.item[item].stack_size = scrapStackSize
		end
	end
end