module ApplicationHelper
  include ActsAsTaggableOn::TagsHelper

  def profile_img(user)
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    img_url = "https://secure.gravatar.com/avatar/#{gravatar_id}"
    image_tag(img_url, alt: user.email, class: 'img-circle')
  end

  def fa_icon(icon, option=nil)
    content_tag(:i, nil, class: "fa fa-#{icon} #{option}")
  end

  def embed_height(tournament_size)
    case tournament_size
    # トーナメント単体のサイズ＋余白
    when 128; 4300
    when 64; 2250
    when 32; 1230
    when 16; 725
    when 8;  465
    when 4;  380
    end
  end
end
