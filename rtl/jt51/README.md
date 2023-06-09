# JT51
YM2151 clone in verilog. FPGA proven.
(c) Jose Tejada 2016. Twitter: @topapate

You can show your appreciation through
* [Patreon](https://patreon.com/jotego), by supporting releases
* [Paypal](https://paypal.me/topapate), with a donation

Originally posted in opencores. The Github repository is now the main one.

## Using JT51 in a git project

If you are using JT51 in a git project, the best way to add it to your project is:

1. Optionally fork JT51's repository to your own GitHub account
2. Add it as a submodule to your git project: `git submodule add https://github.com/jotego/jt51.git`
3. Now you can refer to the RTL files in **jt51/hdl**

The advantages of a using a git submodule are:

1. Your project contains a reference to a commit of the JT51 repository
2. As long as you do not manually update the JT51 submodule, it will keep pointing to the same commit
3. Each time you make a commit in your project, it will include a pointer to the JT51 commit used. So you will always know the JT51 that worked for you
4. If JT51 is updated and you want to get the changes, simply update the submodule using git. The new JT51 commit used will be annotated in your project's next commit. So the history of your project will reflect that change too.
5. JT51 files will be intact and you will use the files without altering them.

## Folders

* **jt51/doc** contains documentation related to JT51 and YM2151
* **jt51/hdl** contains all the Verilog source code to implement JT51 on FPGA or ASIC
* **jt51/hdl/filter** contains an interpolator to use as first stage to on-chip sigma-delta DACs
* **jt51/syn** contains some use case examples. It has synthesizable projects in various platforms
* **jt51/syn/xilinx/contra** sound board of the arcade Contra. Checkout **hdl** subfolder for the verilog files

## Usage
All files are in **jt51/hdl**. The top level file is jt51.v. You need all files in the **jt51/hdl** folder to synthesize or simulate the design.

Alternatively you can just use the file jt51_v1.1.v at the release folder. It contains all the necessary files concatenated inside. It is generated by the script in bin/jt51_singlefile.sh

Simulation modules are added if macros
    - SIMULATION
    - JT51_DEBUG
are defined

Use macro JT51_ONLYTIMERS in order to avoid simulating the FM signal chain but keep the timer modules working. This is useful if a CPU depends on the timer interrupts but you do not want to simulate the full FM sound (to speed up sims).

## Related Projects

Other sound chips from the same author

Chip                   | Repository
-----------------------|------------
YM2203, YM2612, YM2610 | [JT12](https://github.com/jotego/jt12)
YM2151                 | [JT51](https://github.com/jotego/jt51)
YM3526                 | [JTOPL](https://github.com/jotego/jtopl)
YM2149                 | [JT49](https://github.com/jotego/jt49)
sn76489an              | [JT89](https://github.com/jotego/jt89)
OKI 6295               | [JT6295](https://github.com/jotego/jt6295)
OKI MSM5205            | [JT5205](https://github.com/jotego/jt5205)

This sound core has been used at least in the following arcade cores for FPGA

* [JTCPS1](https://github.com/jotego/jtcps1): CAPCOM SYSTEM arcade clone
* [JTDD](https://github.com/jotego/jtdd): Double Dragon 1 & 2 arcade clone
* [JTGNG](https://github.com/jotego/jt_gng): arcade clones of pre-CPS CAPCOM games. Some use YM2151 through JT51

More to come soon!
