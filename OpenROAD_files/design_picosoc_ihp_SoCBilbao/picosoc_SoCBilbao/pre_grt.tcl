# pre_grt.tcl
# Destruye las redes desconectadas justo antes del Global Routing

set block [[[ord::get_db] getChip] getBlock]
set redes_eliminadas 0

foreach net [$block getNets] {
    if {[$net getSigType] == "SIGNAL" || [$net getSigType] == "CLOCK"} {
        set iterm_count [llength [$net getITerms]]
        set bterm_count [llength [$net getBTerms]]
        
        if {($iterm_count + $bterm_count) == 1} {
            odb::dbNet_destroy $net
            incr redes_eliminadas
        }
    }
}
puts "\n*** INFO ORFS: Se han destruido $redes_eliminadas redes fantasmas antes de GRT. ***\n"
