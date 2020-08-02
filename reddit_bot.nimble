# Package

version       = "0.1.0"
author        = "Jeremy Savor"
description   = "Reddit bot"
license       = "MIT"
srcDir        = "src"
bin           = @["reddit_bot"]



# Dependencies

requires "nim >= 1.2.0"

task doit, "Run the bot":
  exec ". ~/.api_keys/reddit && nimble run reddit_bot.nimble"
