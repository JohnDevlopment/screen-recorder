# 1000x650 -> Size of image label

proc dialog args {
    set specs {
        {title.arg   "Information" "Title of the dialog"}
        {icon.arg    "info"        "Icon to display"}
        {message.arg ""            "Message summary"}
        {type.arg    "ok"          "Controls what buttons show in the dialog"}
        {parent.arg  .             "Parent of the window"}
        {default.arg ""            "Default button if the user pressed Enter"}
        {detail.arg  ""            "Detailed message"}
    }

    if {[catch [list ::cmdline::getoptions args $specs] temp]} {
        puts $args
        return -code error "commandline wrong: $temp"
    }

    dict for {k v} $temp {
        set "options($k)" $v
    }

    # Mac OS
    set windowingsystem [tk windowingsystem]
    if {$windowingsystem eq "aqua"} {
    	switch -- $options(icon) {
    	    "error"     {set options(icon) "stop"}
    	    "warning"   {set options(icon) "caution"}
    	    "info"      {set options(icon) "note"}
    	}
    }

    if {! [winfo exists $options(parent)]} {
        return -code errror -errorcode [list TK LOOKUP WINDOW $options(parent)] \
            "invalid \"-parent\" window $options(parent)"
    }

    switch -- $options(type) {
        yesno {
            set names [list yes no]
            set labels [list &Yes &No]
            set cancel no
        }
        yesnocancel {
            set names [list yes no cancel]
            set labels [list &Yes &No &Cancel]
            set cancel cancel
        }
        okcancel {
            set names [list ok cancel]
            set labels [list &Ok &Cancel]
            set cancel cancel
        }
        retrycancel {
            set names [list retry cancel]
            set labels [list &Retry &Cancel]
            set cancel cancel
        }
        ok {
            set names [list ok]
            set labels {&Ok}
            set cancel ok
        }
        abortretryignore {
            set names [list abort retry ignore]
            set labels [list &Abort &Retry &Ignore]
            set cancel abort
        }

        default {
            return -code error -errorcode [list TK LOOKUP DLG_TYPE $options(type)] \
                "bad -type value \"$option(type)\": must be yesno, yesnocancel,\
                okcancel, retrycancel, ok, or abortretryignore"
        }
    }

    set buttons {}
    foreach name $names lab $labels {
        lappend buttons [list $name -text $lab]
    }
    unset name lab

    # If no default, default is first button
    if {$options(default) eq ""} {
        set options(default) [lindex [lindex $buttons 0] 0]
    }

    set valid 0
    foreach btn $buttons {
        if {[lindex $btn 0] eq $options(default)} {
            set valid 1
            break
        }
    }

    if {! $valid} {
        return -code error -errorcode {TK MSGBOX DEFAULT} \
            "invalid -default \"$options(default)\": must be\
            ok, cancel, retry, abort, ignore, yes, or no"
    }
    unset valid btn

    if {$options(parent) ne "."} {
        set dlg $options(parent).infoDlg
    } else {
        set dlg .infoDlg
    }

    # There is only one background colour for the whole dialog
    set bg [ttk::style lookup . -background]

    # Create dialog window
    toplevel $dlg -class Dialog -background $bg
    wm title $dlg $options(title)
    wm iconname $dlg Dialog
    wm protocol $dlg WM_DELETE_WINDOW [list $dlg.$cancel invoke]

    # (Directly ripped from msgbox.tcl):
    # Message boxes should be transient with respect to their parent so that
    # they always stay on top of the parent window.  But some window managers
    # will simply create the child window as withdrawn if the parent is not
    # viewable (because it is withdrawn or iconified).  This is not good for
    # "grab"bed windows.  So only make the message box transient if the parent
    # is viewable.
    if {[winfo viewable [winfo toplevel $options(parent)]] } {
	       wm transient $dlg $options(parent)
    }

    if {$windowingsystem eq "aqua"} {
        ::tk::unsupported::MacWindowStyle style $dlg moveableModal {}
    } elseif {$windowingsystem eq "x11"} {
        wm attributes $dlg -type dialog
    }

    pack [ttk::frame $dlg.frBot] -side bottom -fill both
    grid anchor $dlg.frBot center
    pack [ttk::frame $dlg.frTop] -side top -fill both -expand 1

    # Add overriddable option for text field width
    option add *Dialog.txMsg.width 50
    option add *Dialog.txMsg.background white

    text $dlg.txMsg -wrap word
    $dlg.txMsg insert end "$options(message)\n\n"
    $dlg.txMsg tag add Message 1.0 "end - 2 chars"
    $dlg.txMsg tag configure Message -font TkCaptionFont
    if {$options(detail) ne ""} {
        $dlg.txMsg insert end $options(detail)
    }

    if {$options(icon) ne ""} {
        switch $options(icon) {
            error {
                ttk::label $dlg.lbBitmap -image ::tk::icons::error
            }
            info {
                ttk::label $dlg.lbBitmap -image ::tk::icons::information
            }
            question {
                ttk::label $dlg.lbBitmap -image ::tk::icons::question
            }
            default {
                ttk::label $dlg.lbBitmap -image ::tk::icons::warning
            }
        }
    }

    grid $dlg.lbBitmap $dlg.txMsg -in $dlg.frTop -padx 2m -pady 2m -sticky nsew
    grid configure $dlg.lbBitmap -sticky nw
    grid columnconfigure $dlg.frTop 1 -weight 1
    grid rowconfigure $dlg.frTop 0 -weight 1

    # Create a row of buttons

    set i 0
    foreach but $buttons {
        set name [lindex $but 0]
        set opts [lrange $but 1 end]
        if {! [llength $opts]} {
            set capName [string toupper $name 0]
            set opts [list -text $capName]
        }

        eval [list ::tk::AmpWidget ttk::button $dlg.$name] $opts \
            [list -command [list set ::tk::Priv(button) $name]]

        if {$name eq $options(default)} {
            $dlg.$name configure -default active
        } else {
            $dlg.$name configure -default normal
        }

        grid $dlg.$name -row 0 -column $i -in $dlg.frBot -padx 3m -pady 2m -sticky ew
        grid columnconfigure $dlg.frBot $i -uniform buttons

        # We boost the size of some Mac buttons for l&f (ripped from msgbox.tcl)
        if {$windowingsystem eq "aqua"} {
            set temp [string tolower $name]
            if {$temp eq "ok" || $temp eq "cancel" || $temp eq "yes" ||
                $temp eq "no" || $temp eq "abort" || $temp eq "retry" ||
                $temp eq "ignore"} {
                    grid columnconfigure $flg.frBot $i -minsize 90
            }
            grid configure $dlg.$name -pady 7
        }
        incr i
    }

    bind $dlg <Alt-Key> [list ::tk::AltKeyBinding $dlg %A]

    if {$options(default) ne ""} {
        bind $dlg <FocusIn> {
            if {[winfo class %W] in "Button TButton"} {
                %W configure -default active
            }
        }
        bind $dlg <FocusOut> {
            if {[winfo class %W] in "Button TButton"} {
                %W configure -default normal
            }
        }
    }

    # Create bindings for <Return>, <Escape> and <Destroy> on the dialog

    bind $dlg <Return> {
        if {[winfo class %W] in "Button TButton"} {%W invoke}
    }

    # Invoke the designated cancelling operation
    bind $dlg <Escape> [list $dlg.$cancel invoke]

    # At <Destroy> the buttons have vanished, so must do this directly.
    bind $dlg.txMsg <Destroy> [list set tk::Priv(button) $cancel]

    # Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display (Motif style) and de-iconify it.

    ::tk::PlaceWindow $dlg widget $options(parent)

    # Set a grab and claim the focus too.

    if {$options(default) ne ""} {
	       set focus $dlg.$options(default)
    } else {
	       set focus $dlg
    }
    ::tk::SetFocusGrab $dlg $focus

    # Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    vwait ::tk::Priv(button)
    # Copy the result now so any <Destroy> that happens won't cause
    # trouble
    set result $::tk::Priv(button)

    ::tk::RestoreFocusGrab $dlg $focus

    return $result
}

proc getAudioSources {} {
    set id [file tempfile]
    eval exec pactl list short sources >@ $id
    seek $id 0 start

    # Read each line
    set data [list]
    while {[gets $id line] > 0} {
        lappend data [regexp -all -inline {\S+} $line]
        lindex $line
    }
    close $id

    return $data
}

proc getFontWidth {font} {
    set fw 0
    set scale [tk scaling -displayof .]
    set fontAttr [font actual $font]

    if {! [dict exists $fontAttr -size]} {
        set fw 10
    } else {
        set fw [dict get $fontAttr -size]
        if {$fw > 0} {
            set fw [expr $fw * [tk scaling -displayof .]]
        } elseif {! $fw} {
            set fw 10
            puts stderr "Font size of $font is zero! What? Setting default of $fw"
        }
    }

    return [expr $fw * 0.5]
}

namespace eval ::statusMessage {variable afterID ""}

proc showStatusMessage {msg {timer 5}} {
    global FontZeroWidth

    namespace upvar ::statusMessage afterID AfterID

    # Invalid parameter, is not an integer
    if {! [string is digit $timer]} {
        return -code error -errorcode [list TCL PARAM INVALID $timer] \
        "invalid parameter \"$timer\": must be a valid integer"
    }

    # If the time value is <= 0, set it to the default
    if {$timer <= 0} {set timer 5}

    # Cancel a previously started after-command
    if {$AfterID ne ""} {
        after cancel $AfterID
        set AfterID ""
        place forget $w
    }

    set w .lbStatus
    set ms [expr $timer * 1000]

    # Calculate width of label based on text
    set label(font) [$w cget -font]
    set label(width) [expr "round($FontZeroWidth * [string length $msg])" ]

    $w configure -text $msg
    place $w -in .frMain.nb -anchor ne -relx 0.9 -rely 0 -y 30 -width $label(width)

    # Hide label after a certain amount of time
    set AfterID [after $ms [subst {
        place forget $w
        set ::statusMessage::afterID ""
    }]]
}

proc recordVideo {} {
    global OUTPUT_FILE FPS ACODEC VCODEC WIDTH HEIGHT X_OFFSET Y_OFFSET RECORD_MODE

    jdebug::print trace "Entered function \"recordVideo\""

    if {$OUTPUT_FILE eq ""} {
        return [displayError "No output file selected." \
            "Make sure to provide a file name in the field on top."]
    }

    # Verify that each field is nonempty
    set code 0
    foreach var {FPS ACODEC VCODEC} name {fps "audio codec" "video codec"} {
        if {[deref $var] eq ""} {
            set code 1
            set errmsg "The $name field is empty"
            break
        }
    }
    if {$code} {return [displayError $errmsg]}

    set detail [list "FPS: $FPS" "Source: x11grab"]

    jdebug::header "### "

    # Region or the whole screen?
    if {$RECORD_MODE eq "region"} {
        set x $X_OFFSET
        set y $Y_OFFSET
        set w $WIDTH
        set h $HEIGHT
        jdebug::print trace "Record video in region mode\nRegion: ($x,$y) ${w}$h"
    } else {
        set x 0
        set y 0
        set w [winfo screenwidth .]
        set h [winfo screenheight .]
        jdebug::print trace "Screen resolution: ${w}$h"
    }

    lappend detail "Resolution: ${w}x$h" "Input: 0.0"
    if {$RECORD_MODE eq "region"} {
        lappend detail "Region Offset: $x,$y"
    }

    # Concatenate the command

    set cmd [list ffmpeg -f x11grab -r $FPS -s "${w}x$h" -i ":0.0+$x,$y"]
    jdebug::print trace "Command with initial parameters: \"$cmd\""
    set codecs [list]

    # Video duration
    global DURATION
    if {$DURATION > 0} {
        set cmd [linsert $cmd 3 -t $DURATION]
        jdebug::print trace "Added \"-t $DURATION\" to command\nUpdated command: $cmd"
        lappend detail "Duration: $DURATION seconds"
    }

    # Video codec
    if {$VCODEC ne "auto"} {
        lappend codecs -vcodec $VCODEC
        lappend detail "Video Codec: $VCODEC"
        jdebug::print trace "Specified video codec: $VCODEC"
    }

    # Audio source
    if {$ACODEC ne "null"} {
        set audioInput [.frMain.nb.frOptions.frParams.cbASrc get]
        lappend cmd -f pulse -i [regexp -inline {^[0-9]+} $audioInput]
        jdebug::print trace

        set audioInput [lindex [regexp -inline {[0-9]+(.+)} $audioInput] 1]
        lappend detail "Audio Source: pulse" "Audio Input: $audioInput"

        # Audio codec
        if {$ACODEC ne "auto"} {
            lappend codecs -acodec $ACODEC
            lappend detail "Audio Codec: $ACODEC"
        }

        # Audio duration
        if {$DURATION > 0} {
            set cmd [linsert $cmd end-2 -t $DURATION]
        }
    }

    lappend cmd {*}$codecs $OUTPUT_FILE

    jdebug::header ""

    # Confirmation dialog
    set detail [join $detail "\n"]
    set result [dialog -icon question -title "Confirm?" \
        -type yesno -message "Go with these options?" \
        -detail [subst $detail]]
    if {$result eq "no"} return

    # Delete some variables that are no longer needed
    unset -nocomplain audioInput codecs result code var name

    set geo [split [wm geometry .] "+x"]
    lassign $geo x y w h
    set x [expr "round($w / 2 + $x)"]
    set y [expr "round($h / 2 + $y)"]

    # Attempt to execute the FFMpeg commandline in a terminal
    try {
        wm withdraw .
        terminal::parseCommand -geometry "80x30+$x+$y" -- $cmd
    } on error errmsg {
        displayError $errmsg
    } finally {
        wm deiconify .
    }
}

proc _getGloballyUniqueName {} {
    global GUID
    if {! [info exists GUID]} {set GUID 1}
    return "guid$GUID"
}

proc getCodecsFromFile {which {onlyKeys 0}} {
    upvar #0 "CodecDict($which)" Codecs
    global ConfigDir

    set file [file join $ConfigDir "${which}codecs.json"]

    if {! [info exists Codecs]} {
        jdebug::print debug "Reading from \"$file\""
        set Codecs [readJsonFromFile $file]
    }

    if {$onlyKeys} {
        return [dict keys $Codecs]
    }
    return $Codecs
}

proc readJsonFromFile {file} {
    set id [open $file]
    set data [read $id]
    close $id

    return [::json::json2dict $data]
}

proc spinboxVariableSetter {name1 name2 op} {
    upvar $name1 Var
    switch -exact $name1 {
        FPS {
            .frMain.nb.frOptions.frParams.sbFps set $Var
        }
        DURATION {
            .frMain.nb.frOptions.frParams.sbDuration set $Var
        }
        default {}
    }
    return
}

# Make sure to only call this when all widgets have been created.
proc openConfigFile {} {
    global ConfigFields ConfigDir

    foreach field $ConfigFields {global [lindex $field 0]}

    trace add variable FPS write spinboxVariableSetter
    trace add variable DURATION write spinboxVariableSetter

    set configFile [file join $ConfigDir config.tcl]

    jdebug::print debug "Config directory: $ConfigDir"
    if {! [file exists $configFile]} {
        jdebug::print debug "Creating new config file: $configFile"
        writeConfigFile 1
        return
    }

    return [source $configFile]
}

proc writeConfigFile {{init 0}} {
    global ConfigDir ConfigFields

    set configFile [file join $ConfigDir config.tcl]

    # Directory doesn't exist
    if {! [file isdirectory $ConfigDir]} {
        file mkdir $ConfigDir
        jdebug::print debug "Created directory: $ConfigDir"
    }

    # Each element in $ConfigFields is a list, with 1. the name of a global variable,
    # and 2. the variable's default value when not set by the config file.
    set data ""
    foreach field $ConfigFields {
        set var [lindex $field 0]
        global $var

        # Initialize and/or get the value of the global variable
        if {$init} {
            set value [subst [lindex $field 1]]
            jdebug::print trace "Initialize $var to \"$value\""
            set $var $value
        } else {
            set value [deref $var]
        }

        # Enclose the string in quotes if it has spaces in it
        if {[regexp {\s+} $value]} {
            set value "\"$value\""
        }

        append data "\nset $var $value"
    }

    # Some additional stuff that could not be included above
    if {$init} {
        # This is otherwise done in openConfigFile: setup FPS and DURATION to
        # modify the value of their respective spinbox window.
        trace add variable FPS write spinboxVariableSetter
        set FPS $FPS
        trace add variable DURATION write spinboxVariableSetter
        set DURATION $DURATION

        # Append the initial geometry of the window
        append data "\nwm geometry . 1124x744+0+0"
    } else {
        append data "\nwm geometry . [wm geometry .]"
    }

    # Open and write to the configuration file
    set id [open $configFile w]
    puts $id [string trimleft $data]
    close $id

    jdebug::print trace \
        "Wrote configuration file: $configFile\ndata:\n###############$data\n###############"
}

proc captureScreen {} {
    global TempFileDir

    set tempfile [file join $TempFileDir "image[random string 10].png"]

    # Capture the screen into an image
    eval exec import -window root $tempfile

    # temp.png PNG 1920x1080 1920x1080+0+0 8-bit sRGB 141KB 0.000u 0:00.000
    set imginfo [eval exec identify $tempfile]

    # temp.png PNG 1920x1080 1920x1080+0+0
    set imginfo [lrange [split $imginfo] 0 3]

    jdebug::eval {
        puts "Image Info:"
        foreach name {File Format Size Geometry} value $imginfo {
            puts "\t$name: $value"
        }
    }

    return [concat $tempfile $imginfo]
}

proc loadPreviewImage {{crop ""}} {
    global PreviewImageSize PreviewImageData

    lassign [captureScreen] imgfile imginfo

    # Crop and resize the image
    if {$crop != ""} {
        eval exec mogrify $imgfile -crop $crop $imgfile
    }
    eval exec mogrify $imgfile -resize [join $PreviewImageSize x] $imgfile

    try {
        PreviewImage blank; PreviewImage read $imgfile
        setPreviewRegion [winfo screenwidth .] [winfo screenheight .] 0 0
    } finally {
        file delete $imgfile
        jdebug::print trace "Deleted $imgfile"
    }
}

proc setPreviewRegion {width height x y} {
    set width [expr "$width <= 0 ? 1000 : $width"]
    set height [expr "$height <= 0 ? 650 : $height"]
    set x [expr "max($x, 0)"]
    set y [expr "max($y, 0)"]

    .frMain.nb.frScreen.lbGeometry configure -text "Geometry: ${width}x$height / :0.0+$x,$y"

    return
}

proc getTempDir {} {
    set id [file tempfile tempname]
    close $id
    file delete -force $tempname
    after idle {rename getTempDir ""}
    return [file dirname $tempname]
}

proc displayError {msg {detail ""} {title "Application Error"}} {
    tk_messageBox -icon error -title $title -message $msg
    return
}
