# Helper for meta tags
# In any view, if a content_for(:meta_key) was defined, the methods below should override DEFAULT_META‘s value. Content_for?(:key) method gets what was previously stored in conrent_fo(:key)
module MetaTagsHelper
  def meta_title
    content_for?(:meta_title) ? content_for(:meta_title) : DEFAULT_META["meta_title"]
  end

  def meta_description
    content_for?(:meta_description) ? content_for(:meta_description) : DEFAULT_META["meta_description"]
  end

  def meta_image
    meta_image = (content_for?(:meta_image) ? content_for(:meta_image) : DEFAULT_META["meta_image"])

    # little twist to make it work equally with an asset or an external
    meta_image.starts_with?("http") ? meta_image : image_url(meta_image)
  end
end
