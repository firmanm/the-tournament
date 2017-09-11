class TournamentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :raw, :photos, :games, :players, :new, :create]
  load_and_authorize_resource
  before_action :authenticate_guest_user, only: [:edit, :update, :destroy, :edit_players, :update_players, :edit_games, :edit_game, :update_game]


  def index
    if params[:q]
      @title = "「#{params[:q]}」のトーナメント検索結果"
    elsif params[:tag]
      @title = "#{params[:tag]}のトーナメント一覧"
    else
      @title = "トーナメント一覧"
    end
    @page_title = (params[:page]) ? "#{@title} #{params[:page]}ページ目" : @title

    tournaments = Tournament.search_tournaments(params)
    per_page = 30
    @tournaments = tournaments.page(params[:page]).per(per_page)

    @page_start_count = params[:page] ? (params[:page].to_i - 1) * per_page + 1 : 1
    @page_end_count = @page_start_count + @tournaments.count - 1
  end


  def show
    redirect_to pretty_tournament_path(@tournament, @tournament.encoded_title), status: 301 if params[:title] != @tournament.encoded_title
  end


  def raw
    render layout: false
  end


  def new
    @tournament = Tournament.new

    # ゲストユーザーでログインしたまま来たら、tokenを変えるので一度ログアウトさせる
    sign_out(current_user) if current_user && current_user.guest?
    @token = SecureRandom.hex(8) if !current_user
  end


  def create
    @tournament = Tournament.new(tournament_params)

    # 未ログインの場合、ゲストユーザーとしてログインさせる
    if !current_user
      sign_in(User.find(1))
      session[:tournament_token] = tournament_params[:token]
    end

    @tournament.user = current_user

    if @tournament.save
      flash[:notice] = I18n.t('flash.tournament.create.success')
      redirect_to tournament_edit_players_path(@tournament)
    else
      @token = session[:tournament_token]
      flash.now[:alert] = I18n.t('flash.tournament.create.failure')
      render action: 'new'
    end
  end


  def edit
  end


  def update
    if @tournament.update(tournament_params)
      redirect_to tournament_edit_players_path(@tournament), notice: I18n.t('flash.tournament.update.success')
    else
      flash.now[:alert] = I18n.t('flash.tournament.update.failure')
      render 'tournaments/edit'
    end
  end


  def destroy
    @tournament.destroy
    redirect_to root_path, notice: 'トーナメントを削除しました'
  end


  def photos
    gon.album_id = @tournament.facebook_album_id
    gon.fb_token = ENV['FACEBOOK_APP_TOKEN'].sub('%7C', '|')
  end


  def players
    @players = @tournament.teams
  end


  def edit_players
    set_teams_text
  end


  def update_players
    teams = []
    # 通常入力
    if params[:input_type] == 'array'
      params[:tournament][:teams_array].each_with_index do |team, i|
        team_data = team['name'].present? ? { name: team['name'], flag: team['flag'].try(:downcase) } : nil
        teams << team_data
      end
    # まとめて入力
    elsif params[:input_type] == 'text'
      params[:tournament][:teams_text].lines.each_with_index do |line, i|
        team = line.chomp.split(",")
        team_data = (team[0].present?) ? {name: team[0], flag: team[1].try(:downcase)} : nil
        teams << team_data
      end
    end

    if @tournament.update({teams: teams})
      @tournament.update_bye_games
      redirect_to tournament_edit_games_path(@tournament), notice: I18n.t('flash.players.update.success')
    else
      set_teams_text
      @tournament.teams = @tournament.teams.in_groups_of(@tournament.size).first

      flash.now[:alert] = @tournament.errors.full_messages.first
      render 'tournaments/edit_players'
    end
  end


  def games
  end

  def edit_games
  end

  def edit_game
    set_game
  end

  def update_game
    set_game

    if params[:game]['winner'].blank?
      flash.now[:alert] = '勝者が選択されていません。試合結果の登録を取り消したい場合は、「試合結果リセット」をクリックしてください。'
      render :edit_game and return
    end

    game_params = {
      score: params[:game]['score'],
      winner: params[:game]['winner'].to_i,
      comment: params[:game]['comment'],
      finished: true
    }
    @tournament.results[@round_num-1][@game_num-1] = game_params

    tournament_params = { results: @tournament.results }
    tournament_params[:finished] = true if @round_num == @tournament.round_num && @game_num == 1

    if @tournament.update(tournament_params)
      redirect_to tournament_edit_games_path(@tournament), notice: I18n.t('flash.game.update.success')
    else
      flash.now[:alert] = I18n.t('flash.game.update.failure')
      render :edit_game
    end
  end


  private
    def tournament_params
      params.require(:tournament).permit(:id, :title, :user_id, :detail, :place, :url, :size, :consolation_round, :tag_list, :double_elimination, :scoreless, :facebook_album_id, :teams, :results, :token)
    end

    def set_teams_text
      @teams_text = ""
      @tournament.teams.each do |m|
        @teams_text += m['name'] if m
        @teams_text += ",#{m['flag']}" if m && m['flag'].present?
        @teams_text += "\r\n"
      end
    end

    def set_game
      @round_num = params[:round_num].to_i
      @game_num = params[:game_num].to_i
      @game = @tournament.results[@round_num-1][@game_num-1]

      @players = [
        @tournament.winner_team(@round_num, @game_num, 0),
        @tournament.winner_team(@round_num, @game_num, 1)
      ]
    end

    # ゲストユーザーの編集時は、tokenがトーナメントのものと一致するかチェックする
    def authenticate_guest_user
      return if !current_user.guest?

      message = '編集権限がありません。ゲストで作成したトーナメントを編集する際は、編集用URLから再度アクセスしてください。'
      raise CanCan::AccessDenied.new(message, :edit, Tournament) if session[:tournament_token] != @tournament.token
    end
end
