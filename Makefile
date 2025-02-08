QUARTUS_DIR = C:/intelFPGA_lite/17.0/quartus/bin64
PROJECT = Arcade-IremM92
CONFIG = Arcade-IremM92-Fast
MISTER = root@mister-dev
OUTDIR = output_files

FAST_RBF = $(OUTDIR)/$(CONFIG).rbf

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

SRCS = \
	$(call rwildcard,sys,*.v *.sv *.vhd *.vhdl *.qip *.sdc) \
	$(call rwildcard,rtl,*.v *.sv *.vhd *.vhdl *.qip *.sdc) \
	$(wildcard *.sdc *.v *.sv *.vhd *.vhdl *.qip)

all: run

$(OUTDIR)/Arcade-IremM92-Fast.rbf: $(SRCS)
	$(QUARTUS_DIR)/quartus_sh --flow compile $(PROJECT) -c Arcade-IremM92-Fast

$(OUTDIR)/Arcade-IremM92.rbf: $(SRCS)
	$(QUARTUS_DIR)/quartus_sh --flow compile $(PROJECT) -c Arcade-IremM92

deploy.done: $(FAST_RBF) releases/m92.mra
	scp $(FAST_RBF) $(MISTER):/media/fat/_Arcade/cores/IremM92.rbf
	scp releases/m92.mra $(MISTER):/media/fat/_Arcade/m92.mra
	echo done > deploy.done

deploy: deploy.done

run: deploy.done 
	ssh $(MISTER) "echo load_core _Arcade/m92.mra > /dev/MiSTer_cmd"

fast: $(OUTDIR)/Arcade-IremM92-Fast.rbf
release: $(OUTDIR)/Arcade-IremM92.rbf

.PHONY: all run deploy release fast
