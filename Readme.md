# Irem M92 Core

![](docs/header-small.png)

This is the MiSTer FPGA core for the Irem M92 arcade system (http://www.system16.com/hardware.php?id=747). The Irem M92 system is known for its high-quality graphics and sound, and this core brings these games to the MiSTer platform for arcade enthusiasts to enjoy.

The Irem M92 core includes numerous games that have not been ported elsewhere, providing a unique and authentic arcade experience. Some of the popular games available in this core are:

- In the Hunt
- Gunforce
- R-Type Leo
- Hook
- Blade Master
- Mystic Riders
- Undercover Cops
- Ninja Baseball Batman

## Controls
All of the games use standard 8-way input with two buttons with the exception of *Superior Soldiers* which uses six button input. Several of the games support 3 or 4 players but you will need to change a DIP switch in the DIP switch menu to enable that. By default the button buttons are mapped to the MiSTers SNES-like layout as `B,A,X,Y,L,R`. The `Coin` and `Start` buttons are mapped to Select and Start. There are two additional buttons that can be mapped that are not mapped by default. `P2 Start` maps the the second players start button. The only purpose this serves is for accessing the service menu with a single controller since most games require pressing P1 and P2 start to access it. The second unmapped button is `Pause` which pauses the core.

Standard MAME keyboard controls are also supported for up to 4-players.


## Cheats
Cheats are defined in the MRA files within the `<cheats>` block. Each cheat is made up of one or more 16-byte codes, similar to game genie codes. They are broken up into four, big-endian, 4-byte sections: `Flags`, `Addr`, `Comp` and `Data`. When the CPU reads the memory address specified by `Addr` it will override the data store there with the value specified in `Data`. If the `Compare` flag is set to `1` then it will only override the value if the value in the `Comp` field matches what is currently in memory. The `Size` field in the `Flags` specifies how large the `Comp` and `Data` values are. The `Addr` must be aligned to that size. The `Method` flag specifies how the memory is overridden. It can completely replace the value, be OR'd with the memory value or AND'd with it.

```
     Flags     Addr     Comp     Data
    00000021 000E0002 00001000 00001234
         |||
         ||+-- Compare: 0 = always override, 1 = only if compare matches
         |+--- Size:    1, 2 or 4
         +---- Method:  0 = replace memory with Data, 1 = OR with Data, 2 = AND with Data
```
The above cheat code would return `0x1234` when reading from memory address `0xE0002` if the value `0x1000` was currently stored at that address.


Cheats don't write to memory, they replace the memory values as they are being read. So when a cheat is disabled the modifications disappear. Be aware that if you have cheats enabled during startup then the game will almost certainly fail its RAM and/or ROM startup tests.

The initial cheats are all converted from [Pugsy's Cheats](https://www.mamecheat.co.uk/).

## Thanks
Many people, knowingly or not, contributed to this work.
- Mark, for his R-Type Leo PCB and his support through the years.
- @sorgelig, for developing and maintaining MiSTer.
- @RobertPeip, for the v30mz cpu I am using as the basis for the v33 & v35.
- @jotego, for the YM2151 implementation and analog adjustment module.
- @ArtemioUrbina, for their support building [MDfourier](https://junkerhq.net/MDFourier/) tests.
- @zakk4223, for hiscore support.
- @birdybro, @Toryalai1 & @wwark for MRA help.
- Sanborn, for help with the docs.
- The people from PLD Archive collecting and archiving PAL information https://wiki.pldarchive.co.uk/index.php?title=Category:Irem_M92
- [Pugsy's Cheats](https://www.mamecheat.co.uk/) for maintaining an excellent selection of cheats.
- The MiSTer FPGA discord server for support, advice and testing.


