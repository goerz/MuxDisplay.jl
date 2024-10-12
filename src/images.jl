using ImageMagick

function get_image_dimensions(filename)
    w, h = ImageMagick.metadata(filename)[1]
    @debug "Pixel dimensions of $filename = ($w, $h)"
    return (w, h)
end
