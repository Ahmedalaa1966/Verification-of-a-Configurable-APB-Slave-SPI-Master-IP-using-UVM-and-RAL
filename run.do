transcript on

if {[file exists work]} {
    vdel -all -lib work
}
vlib work

file mkdir logs
file mkdir coverage

# save the whole transcript (compile + all runs) to a file
transcript file logs/transcript.log

set TESTS [list \
    spi_reg_rw_test \
    spi_idle_test \
    spi_req_test ]

set INC "+incdir+./verification +incdir+./verification/env +incdir+./verification/apb +incdir+./verification/spi +incdir+./verification/sequences +incdir+./verification/tests"

# ---------------- compile (once) ----------------
# DUT with code coverage
vlog -sv +cover=bcesx ./golden_rtl/*.sv

# interfaces
vlog -sv ./harness/apb_if.sv ./harness/spi_if.sv

# packages in dependency order
vlog -sv $INC ./verification/env/reg_pkg.sv
vlog -sv $INC ./verification/env/spi_pkg.sv
vlog -sv $INC ./verification/sequences/spi_sequence_pkg.sv
vlog -sv $INC ./verification/tests/test_pkg.sv

# top
vlog -sv ./verification/tb/tb_top.sv

vopt +acc spi_tb_top -o spi_tb_top_opt

# ---------------- run every test ----------------
set LAST [lindex $TESTS end]

foreach TEST $TESTS {
    echo "================ running $TEST ================"
    vsim -coverage spi_tb_top_opt -l logs/$TEST.log +UVM_TESTNAME=$TEST
    onfinish stop
    run -all
    coverage save coverage/$TEST.ucdb
    vcover report coverage/$TEST.ucdb -output coverage/${TEST}_report.txt -details

    # close the simulation between tests, but keep the last one open
    if {$TEST ne $LAST} {
        quit -sim
    }
}

# ---------------- merge and report ----------------
set UCDBS {}
foreach TEST $TESTS { lappend UCDBS coverage/$TEST.ucdb }

vcover merge coverage/merged.ucdb {*}$UCDBS
vcover report coverage/merged.ucdb -output coverage/report.txt -details

echo "All tests done. The last simulation ($LAST) is still open."
# ---------------- merge and report ----------------
set UCDBS {}
foreach TEST $TESTS { lappend UCDBS coverage/$TEST.ucdb }

vcover merge coverage/merged.ucdb {*}$UCDBS
vcover report coverage/merged.ucdb -output coverage/report.txt -details

echo "All tests done. Logs in logs/, coverage in coverage/"