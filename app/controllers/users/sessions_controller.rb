class Users::SessionsController < Devise::SessionsController
  skip_before_action :require_no_authentication, :only => [ :new ]
  before_action :signout_guest, only: [:new]

  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    super
  end


  private

    def signout_guest
      sign_out(current_user) if current_user && current_user.guest?
    end
end
