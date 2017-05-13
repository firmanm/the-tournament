class UsersController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show, :token_auth]
  load_and_authorize_resource except: [:token_auth]


  def show
    @tournaments = @user.tournaments.page(params[:page]).per(15)

    if @user.facebook_url
      match = @user.facebook_url.match(/https?:\/\/www\.facebook\.com\/(.*?)\/?$/)
      gon.fb_id = match[1] if match
      gon.fb_token = ENV['FACEBOOK_APP_TOKEN'].sub('%7C', '|')
    end
  end


  def edit
  end


  def update
    if @user.update(user_params)
      redirect_to user_path(@user), notice: 'Success on updating user info.'
    else
      flash.now[:alert] = 'Failed on updating user info.'
      render edit_user_path(@user)
    end
  end


  def token_auth
    tournament = Tournament.find_by(token: params[:token])
    if tournament
      sign_in(User.find(1))
      session[:tournament_token] = params[:token]
      redirect_to edit_tournament_path(tournament)
    else
      flash[:alert] = '認証に失敗しました。お手数ですが編集用URLを再度ご確認ください。。'
      redirect_to root_path
    end
  end



  private
    def user_params
      params.require(:user).permit(:email, :email_subscription, :name, :url, :facebook_url, :profile)
    end
end
