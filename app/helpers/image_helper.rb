module ImageHelper

  # This helper generates a picture tag with a fallback image and a WebP version
  # The helper method is equal to the image_tag helper, but it also generates a WebP version
  # Helper: webp_picture_tag "hero.png", width: 300, alt: "My Image"
  # generates the html:
  # <picture>
  #   <source srcset="/assets/webp/hero.webp" type="image/webp">
  #   <img src="/assets/hero.png" width="300" alt="My Image" />
  # </picture>

  def webp_picture_tag(image_basename, **options)
  # image_basename: the fallback image file you’d normally pass to image_tag
  # **: Rails-style keyword args (e.g. width: 300, alt: "Hero") that get forwarded into the image_tag

    # Extract the file parts (extension, base name, and fallback)
    ext        = File.extname(image_basename)
    basename   = File.basename(image_basename, ext)
    fallback   = "#{basename}#{ext}"

    # Generate the WebP path
    webp_path  = "webp/#{basename}.webp"

    # HTML constructor
    # Generate the picture tag with the fallback image and the WebP version
    content_tag :picture do
      concat tag.source(srcset: asset_path(webp_path), type: "image/webp")
      concat image_tag(fallback, options)
    end
  end
end
