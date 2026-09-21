XRUN?=xrun
VERILATOR?=verilator-cli
TEST?=apb_test
SEED?=random
.PHONY: uvm regress lint smoke clean
uvm:
	mkdir -p results
	$(XRUN) -64bit -sv -uvm -f sim/files.f -top tb_top +UVM_TESTNAME=$(TEST) -svseed $(SEED) -access +rwc -coverage all -covoverwrite -covworkdir results/xcelium_cov -l results/xrun_$(TEST).log
regress:
	@for seed in 3 17 37 67 103;do $(MAKE) uvm SEED=$$seed||exit 1;done
lint:
	$(VERILATOR) --lint-only --sv --timing -Wall -Wno-fatal rtl/apb3_register_slave.sv
smoke:
	rm -rf build/obj_apb;mkdir -p build
	$(VERILATOR) --binary --sv --timing --assert -Wall -Wno-fatal -Wno-SYNCASYNCNET --top-module tb_apb_smoke --Mdir build/obj_apb rtl/apb3_register_slave.sv tb/assertions/apb_sva.sv tb/smoke/tb_apb_smoke.sv
	bash -o pipefail -c './build/obj_apb/Vtb_apb_smoke | tee results_smoke.log'
clean:
	rm -rf build xcelium.d INCA_libs waves.shm results *.log *.key
