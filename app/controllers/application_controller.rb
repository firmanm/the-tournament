class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_locale, :authenticate_user!
  #before_action :configure_permitted_parameters, if: :devise_controller?
  http_basic_authenticate_with name: ENV['BASIC_AUTH_USERNAME'], password: ENV['BASIC_AUTH_PASSWORD'] if Rails.env == "production" && ENV['FOG_DIRECTORY'] == 'the-tournament-stg'

  def default_url_options(options={})
    {locale: I18n.locale}
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def after_sign_in_path_for(user)
    # 非ゲストユーザーで、ログイン後リダイレクト先がない場合は、マイページに飛ばす
    if !user.guest?
      stored_location_for(user) || user_path(user)
    else
      super
    end
  end


  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up) << :accept_terms
    end
end
