module ApplicationHelper
  def avatar_image_tag(user, options = {})
    options[:class] ||= 'avatar-small'
    options[:alt] ||= user.full_name

    if user.avatar_image.attached?
      image_tag(user.avatar_image, options)
    elsif user.avatar_url.present?
      image_tag(user.avatar_url, options.merge(onerror: "this.src='https://via.placeholder.com/150'"))
    else
      image_tag('https://via.placeholder.com/150', options)
    end
  end

  def flash_class(level)
    case level.to_sym
    when :notice then 'alert-success'
    when :alert then 'alert-danger'
    when :error then 'alert-danger'
    when :warning then 'alert-warning'
    when :info then 'alert-info'
    else 'alert-info'
    end
  end
end

