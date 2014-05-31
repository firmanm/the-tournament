class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_locale, :authenticate_user!

  # $BA4%j%s%/$K(Blocale$B>pJs$r%;%C%H$9$k(B
  def default_url_options(options={})
    {locale: I18n.locale}
  end

  # $B%j%s%/$NB?8@8l2=$KBP1~$9$k(B
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
