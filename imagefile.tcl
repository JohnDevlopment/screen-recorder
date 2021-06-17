oo::class create ImageFile {
    constructor {} {
        my variable FileName Data MetaData
        set FileName ""
        set Data ""
        set MetaData ""
    }

    method read file {
        my variable FileName Data Size

        set id [open $file rb]
        set Data [read $id]
        close $id

        set FileName $file
        set Size [my _image_size $file]

        return [string length $Data]
    }

    method set_meta {field value} {
        my variable MetaData
        dict set MetaData $field $value
        return
    }

    method get_meta {field {default ""}} {
        my variable MetaData
        try {
            dict get $MetaData $field
        } on error err {
            return $default
        }
    }

    method get_data {} {
        my variable Data
        return $Data
    }

    method get_file {} {
        my variable FileName
        return $FileName
    }

    method get_width {} {
        my variable Size
        return [lindex [split $Size x] 0]
    }

    method get_height {} {
        my variable Size
        return [lindex [split $Size x] 1]
    }

    method _image_size file {
        set info [eval exec identify $file]
        set info [lrange [split $info] 0 3]
        return [lindex $info 2]
    }
}
