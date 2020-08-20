--data.lua

require("prototypes.item")
require("prototypes.PropHunt")
require("prototypes.TrainRamp")
require("prototypes.TrainSprites")
require("prototypes.BridgeSignal")

data:extend({
  {
    type = "custom-input",
    name = "TeleportTrain",
    key_sequence = "F"
  }
})