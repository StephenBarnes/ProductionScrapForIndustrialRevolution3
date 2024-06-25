data:extend({
    {
        type = "double-setting",
        name = "ProductionScrapForIR3-scrap-per-ingredient",
        setting_type = "startup",
        default_value = 0.1,
        minimum_value = 0.0,
        order = "1",
    },
    {
        type = "bool-setting",
        name = "ProductionScrapForIR3-science-produces-scrap",
        setting_type = "startup",
        default_value = true,
        order = "2",
    },
    {
        type = "int-setting",
        name = "ProductionScrapForIR3-scrap-stack-size",
        setting_type = "startup",
        default_value = 99, -- TODO check what the default is in IR3, and decide what to change the default to.
        order = "3",
    },
    {
        type = "string-setting",
        name = "ProductionScrapForIR3-scrap-processing-recipe",
        setting_type = "startup",
        allowed_values = {
            "none",
            "pellets",
            "pellets-and-rivets",
        },
        default_value = "pellets-and-rivets",
        order = "4",
    },
    {
        type = "double-setting",
        name = "ProductionScrapForIR3-pellets-from-scrap",
        setting_type = "startup",
        default_value = 2,
        minimum_value = 0,
        order = "5",
    },
    {
        type = "double-setting",
        name = "ProductionScrapForIR3-rivets-from-scrap",
        setting_type = "startup",
        default_value = 1.5,
        minimum_value = 0,
        order = "6",
    },
})