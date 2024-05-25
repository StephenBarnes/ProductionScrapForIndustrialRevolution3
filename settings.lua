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
        name = "ProductionScrapForIR3-add-pellet-recipes",
        setting_type = "startup",
        default_value = true,
        order = "2",
    },
    {
        type = "int-setting",
        name = "ProductionScrapForIR3-pellets-from-scrap",
        setting_type = "startup",
        default_value = 5,
        minimum_value = 0,
        order = "3",
    },
})