const TempFileDir [getTempDir]
const PreviewImageSize [list 1000 650]
const FontZeroWidth [getFontWidth TkDefaultFont]
const ConfigFields {
    {CurrentDir    [pwd]}
    {RegionFileDir [pwd]}
    {ACODEC        null }
    {VCODEC        auto }
    {FPS           60   }
    {DURATION      0    }
}
set VCODEC ""
set ACODEC ""
set CurrentDir [pwd]
set RegionFileDir [pwd]
#set AudioSources ""
