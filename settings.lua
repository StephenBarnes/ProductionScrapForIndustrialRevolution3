order = 0
function nextOrder()
    order = order + 1
    return string.format("%03d", order)
end

data:extend({
    {
        type = "double-setting",
        name = "ProductionScrapForIR3-scrap-per-ingredient",
        setting_type = "startup",
        default_value = 0.05,
        minimum_value = 0.0,
        order = nextOrder(),
    },
    {
        type = "bool-setting",
        name = "ProductionScrapForIR3-exclude-annoyances",
        setting_type = "startup",
        default_value = true,
        order = nextOrder(),
    },
    {
        type = "bool-setting",
        name = "ProductionScrapForIR3-science-produces-scrap",
        setting_type = "startup",
        default_value = true,
        order = nextOrder(),
    },
    {
        type = "bool-setting",
        name = "ProductionScrapForIR3-gears-produce-scrap",
        setting_type = "startup",
        default_value = true,
        order = nextOrder(),
    },
    {
        type = "double-setting",
        name = "ProductionScrapForIR3-scrap-stack-multiplier",
        setting_type = "startup",
        default_value = 1,
        order = nextOrder(),
    },
    {
        type = "string-setting",
        name = "ProductionScrapForIR3-scrap-processing-recipe",
        setting_type = "startup",
        allowed_values = {
            "none",
            "pellets",
            "pellets-plus-rivets",
            "all",
        },
        default_value = "all",
        order = nextOrder(),
    },
    {
        type = "double-setting",
        name = "ProductionScrapForIR3-pellets-from-scrap-without-rivets",
        setting_type = "startup",
        default_value = 5,
        minimum_value = 0,
        order = nextOrder(),
    },
    {
        type = "double-setting",
        name = "ProductionScrapForIR3-pellets-from-scrap-with-rivets",
        setting_type = "startup",
        default_value = 2,
        minimum_value = 0,
        order = nextOrder(),
    },
    {
        type = "double-setting",
        name = "ProductionScrapForIR3-rivets-from-scrap",
        setting_type = "startup",
        default_value = 1.5,
        minimum_value = 0,
        order = nextOrder(),
    },
    {
        type = "bool-setting",
        name = "ProductionScrapForIR3-nerf-scrapping-for-analysis-packs",
        setting_type = "startup",
        default_value = true,
        order = nextOrder(),
    },
})