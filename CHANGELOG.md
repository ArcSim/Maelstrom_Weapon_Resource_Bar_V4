## 4.0.12

- **Texture error fixed** - Fixed a load error about an invalid border file that some players saw with other addons installed. The Blizzard border and background choices that were missing after that error are back in the dropdowns.

## 4.0.11

- **Updated for patch 12.1.5** - the addon no longer shows as out of date.

## 4.0.10

- **Options panel always shows the display** - With "Hide Out of Combat" enabled, the display now stays visible while the options window is open, so you can see what you are configuring. It hides again when you close the panel.

- **Stale stacks after leaving combat** - With "Hide Out of Combat" on, the display no longer comes back showing the old stack count after Maelstrom Weapon expired while it was hidden. It always shows the real count now.
- **Empty icons at login** - The display no longer flashes empty icons at login and zone-ins when "Hide Out of Combat" is enabled.
- **Bar could not be dragged** - Two causes fixed: the stack number's invisible drag area was much bigger than the number and sat on top of the bar, stealing clicks meant for it; and on the icon displays, larger icon sizes or spacing pushed the icons outside the clickable area. The number's drag area now hugs the number, and the icon display's drag area always matches the icons.
- **Locked frames no longer block clicks** - A locked bar or number no longer swallows mouse clicks meant for things under it.

## 4.0.9

- **Updated for patch 12.1** - the addon no longer shows as out of date.
- **Hardened stack reading** against WoW's new secret-value protection so the bar can never error in restricted content. Maelstrom Weapon tracking keeps working everywhere, including Mythic+ and raids.
