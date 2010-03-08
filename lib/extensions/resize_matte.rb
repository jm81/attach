# Add Magick::Image#resize_matte method, to resize with a colored matte, if
# needed (instead of cropping image).
class Magick::Image

  # Resizes and adds background to full dimensions
  # Returns a new image
  def resize_matte(width, height, bg_color = "white", to_png = false)
  
    bg_color = "white" if bg_color.nil?
    
    new_cols = 0
    new_rows = 0
    
    # http://www.imagemagick.org/RMagick/doc/image1.html#change_geometry
    new_image = self.change_geometry(Magick::Geometry.new(width, height)) do |cols, rows, img|
      new_cols = cols; new_rows = rows; 
      img.resize(cols, rows)
    end
    
    bg_color = "none" if to_png

    canvas = Magick::Image.new(width, height) { self.background_color = bg_color }
    if to_png
      canvas.format = "PNG" 
      new_image.format = "PNG"
    end
    
    # http://www.imagemagick.org/RMagick/doc/image1.html#composite
    # http://www.imagemagick.org/RMagick/doc/constants.html#CompositeOperator
    composited = canvas.composite(new_image, Magick::CenterGravity, Magick::OverCompositeOp)
    composited.format = "PNG" if to_png
    composited
  end

end
