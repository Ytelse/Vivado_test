proc latchCheck() {
    set num_latches [llength [all_latches]]
    if {${num_latches} > 0} {
        set msg "Design contains $num_latches latch(es). Check the synthesis log."
        create_drc_violation -name {Latch} -msg $msg
        return -code error ${num_latches}
    } else {
        return {}
    }
}
