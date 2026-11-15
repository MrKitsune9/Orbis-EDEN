// SPDX-License-Identifier: GPL-3.0-or-later
// eden-ps4: the game list shown before the emulator starts.

#pragma once

#include <string>
#include <vector>

/// One game in the list: its file name and where it was found ("INT" for the console's own
/// storage, "USB0".."USB7" for an external drive).
struct MenuEntry {
    std::string name;
    std::string source;
};

/// Shows `entries` with `initial` selected: Up/Down move (held: repeat), Cross picks, Triangle
/// changes the menu language (English, Portuguese, Spanish; remembered in lang.txt).
/// Returns the chosen index, or -1 if the display could not be opened (nothing was shown).
int RunRomMenu(const std::vector<MenuEntry>& entries, int initial);
