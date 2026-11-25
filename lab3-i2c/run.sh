#!/usr/bin/env bash
# Simulation + synthesis for lab 3 (I2C, Verilog).
# Needs OSS CAD Suite (iverilog, vvp, yosys, nextpnr-ice40) on PATH.
#   ./run.sh sim    - Icarus Verilog simulation, writes build/i2c.vcd
#   ./run.sh syn    - Yosys + nextpnr for iCE40 HX8K, writes build/*_{yosys,nextpnr}.log
#   ./run.sh        - both
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build

sim() {
  iverilog -g2012 -Wall -o build/tb_i2c.vvp rtl/i2c_master.v rtl/i2c_slave.v tb/tb_i2c.v
  (cd build && vvp -n tb_i2c.vvp) | tee build/sim.log
  grep -q "RESULT: ALL TESTS PASSED" build/sim.log
}

syn_one() {  # $1 = top module
  yosys -q -l "build/$1_yosys.log" -p "read_verilog rtl/i2c_master.v rtl/i2c_slave.v syn/$1.v; \
    synth_ice40 -top $1 -json build/$1.json; stat" > /dev/null
  nextpnr-ice40 --hx8k --package ct256 --freq 50 --pcf-allow-unconstrained \
    --json "build/$1.json" --asc "build/$1.asc" --log "build/$1_nextpnr.log" -q
  grep -E "Max frequency for clock" "build/$1_nextpnr.log" | tail -1
}

syn() {
  syn_one i2c_master_top
  syn_one i2c_slave_top
}

case "${1:-all}" in
  sim) sim ;;
  syn) syn ;;
  *)   sim; syn ;;
esac
