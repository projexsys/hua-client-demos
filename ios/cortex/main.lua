-- main.lua

-- This is here to assist development by clearing the loaded modules.
package.loaded = { }

-- imports
local story = require('storyboard')
local widget = require('widget')
widget.setTheme('theme_ios')

-- go to initial scene
story.gotoScene('sessions')
