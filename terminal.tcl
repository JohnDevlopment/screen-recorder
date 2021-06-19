namespace eval terminal {
    variable term "mate-terminal"
    variable tid ""
    variable file ""

    namespace import ::cmdline::getopt
    namespace export parseCommand
}

proc ::terminal::parseCommand {args} {
    variable file
    array set options [list command {} window 0 tab 0 callback {} geometry {}]

    do {
        if {[lindex $args 0] eq "--"} {
            lremove args 0
            break
        }
        set code [getopt args "window tab callback.arg geometry.arg" opt optarg]
        if {$code < 0} {return -code error "ERROR: $optarg"}
        switch $opt {
            geometry -
            callback -
            command -
            tab -
            window {
                set options($opt) $optarg
            }
            default {
                if {$opt ne ""} {
                    return -code error -errorcode [list TCL LOOKUP $opt] \
                        "unknown option \"-$opt\""
                }
            }
        }
    } while {$code > 0}

    # The rest of the commandline is interpreted as the command
    set options(command) $args

    if {$options(command) ne ""} {
        set file [_makeScript $options(command)]
        set args [array get options]
        tailcall _execCommand {*}$args
    }

    return -code error "no command provided"
}

proc ::terminal::_execCommand {args} {
    variable file
    variable tid
    variable term

    array set options $args

    if {$file eq ""} {return -code error "\$file is empty"}

    # Parse extra options
    set opts [list]
    if {$options(geometry) ne ""} {
        lappend opts "--geometry=$options(geometry)"
    }

    # Evaluate command
    set code ok
    set errorcode ""
    try {
        set result [eval exec $term $opts -x bash $file]
    } trap CHILDSTATUS {result errorcode} {
        set code error
    }

    # Loop until the file no longer exists
    while {[file exists $file]} {after 1000}

    set tid ""
    set file ""

    if {[string length $options(callback)] > 0} {
        uplevel $options(callback)
    }

    return -code $code -errorcode $errorcode $result
}

proc ::terminal::_makeScript {cmd} {
    set cmd [join $cmd]
    set id [file tempfile file]
    set data "#!/bin/bash\n$cmd\nread -t 60 -p \"Press Enter to exit...\"\nrm -f \"\$0\""
    puts $id $data
    close $id
    return $file
}
