local rcs = table.deepcopy(data.raw["rail-chain-signal"]["rail-chain-signal"])
rcs.name = "rndLabs-rail-chain-signal"
local rcsItem = table.deepcopy(data.raw["item"]["rail-chain-signal"])
rcsItem.name = "rndLabs-rail-chain-signal-item"
rcsItem.icons = {
  {
    icon = rcsItem.icon,
    tint = {r=0, g=0, b=1, a=1}
  }
}
rcsItem.place_result = "rndLabs-rail-chain-signal"

data:extend({ 
   rcs,
   rcsItem,
  { --------- prop recipie ----------
    type = "recipe",
    name = "rndLabs-rail-chain-signal-recipe",
    enabled = true,
    energy_required = 0.5,
    ingredients = 
      {
        {"iron-plate", 1}
      },
    result = "rndLabs-rail-chain-signal-item"
  }
})


local rs = table.deepcopy(data.raw["rail-signal"]["rail-signal"])
rs.name = "rndLabs-rail-signal"
local rsItem = table.deepcopy(data.raw["item"]["rail-signal"])
rsItem.name = "rndLabs-rail-signal-item"
rsItem.icons = {
  {
    icon = rsItem.icon,
    tint = {r=0, g=0, b=1, a=1}
  }
}
rsItem.place_result = "rndLabs-rail-signal"

data:extend({ 
   rs,
   rsItem,
  { --------- prop recipie ----------
    type = "recipe",
    name = "rndLabs-rail-signal-recipe",
    enabled = true,
    energy_required = 0.5,
    ingredients = 
      {
        {"iron-plate", 1}
      },
    result = "rndLabs-rail-signal-item"
  }
})