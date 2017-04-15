class TournamentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :embed, :raw, :photos]
  before_action :set_tournament, only: [:show, :edit, :update, :destroy, :embed, :upload, :players]
  load_and_authorize_resource


  def index
    tournaments = Tournament.search_tournaments(params)
    @tournaments = tournaments.page(params[:page]).per(15)
  end


  def show
    redirect_to pretty_tournament_path(@tournament, @tournament.encoded_title), status: 301 if params[:title] != @tournament.encoded_title

    if Rails.env.production?
      file_path = "https://#{ENV['FOG_DIRECTORY']}.storage.googleapis.com/embed/json/#{@tournament.id.to_s}.json?t=#{Time.now.to_i}"
      json = JSON.parse(open(file_path).read)
    else
      json = JSON.parse(@tournament.to_json)
    end

    gon.push(json)
  end


  def raw
    gon.push({
      tournament_data: @tournament.tournament_data,
      skip_secondary_final: (@tournament.de?) ? !@tournament.secondary_final : false,
      skip_consolation_round: !@tournament.consolation_round,
      countries: @tournament.players.map{|p| p.country.try(:downcase)},
      match_data: @tournament.match_data,
      scoreless: @tournament.scoreless?
    })
    render layout: false
  end


  def embed
    gon.push({
      tournament_data: @tournament.tournament_data,
      skip_secondary_final: (@tournament.de?) ? !@tournament.secondary_final : false,
      skip_consolation_round: !@tournament.consolation_round,
      countries: @tournament.players.map{|p| p.country.try(:downcase)},
      match_data: @tournament.match_data,
      scoreless: @tournament.scoreless?
    })
    render layout: false
  end


  def upload
    json = @tournament.to_json
    File.write("tmp/#{@tournament.id}.json", json)
    uploader = TournamentUploader.new
    src = File.join(Rails.root, "/tmp/#{@tournament.id}.json")
    src_file = File.new(src)

    uploader.store!(src_file)
    render json: json
  end


  def new
    @tournament = Tournament.new
  end


  def create
    @tournament = SingleElimination.new(tournament_params)  #TODO: Fix when enabling double elimination
    @tournament.user = current_user

    respond_to do |format|
      if @tournament.save
        # GAにイベントを送信
        flash[:log] = "<script>ga('send', 'event', 'tournament', 'create');</script>".html_safe

        flash[:notice] = I18n.t('flash.tournament.create.success')
        format.html { redirect_to tournament_path(@tournament) }
        format.json { render action: 'show', status: :created, location: @tournament }
      else
        flash.now[:alert] = I18n.t('flash.tournament.create.failure')
        format.html { render action: 'new' }
        format.json { render json: @tournament.errors, status: :unprocessable_entity }
      end
    end
  end


  def edit
  end


  def update
    # Players一覧更新時
    if params[:tournament][:players_attributes].present?
      success_url = tournament_edit_games_path(@tournament)
      success_notice = I18n.t('flash.players.update.success')
      failure_url = 'players/edit_all'
      failure_notice = I18n.t('flash.players.update.failure')

      # 一括登録利用時
      players = params[:tournament][:players_all][:players]
      if players != @tournament.players_list
        players.lines.each_with_index do |line, i|
          break if i >= @tournament.size
          params[:tournament][:players_attributes]["#{i}"]["name"] = line.chomp
        end
      end
      params[:tournament][:players_all] = nil
    else
      success_url = tournament_edit_players_path(@tournament)
      success_notice = I18n.t('flash.tournament.update.success')
      failure_url = {action: 'edit'}
      failure_notice = I18n.t('flash.tournament.update.failure')
    end

    if @tournament.update(tournament_params)
      redirect_to success_url, notice: success_notice
    else
      flash.now[:alert] = failure_notice
      render failure_url
    end
  end


  def destroy
    @tournament.destroy
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'トーナメントを削除しました' }
      format.json { head :no_content }
    end
  end


  def photos
    gon.album_id = @tournament.facebook_album_id
    gon.fb_token = ENV['FACEBOOK_APP_TOKEN'].sub('%7C', '|')
  end


  def players
    @players = @tournament.teams.flatten
  end


  def edit_players
    @players = @tournament.teams.flatten
  end


  private
    def set_tournament
      @tournament = Tournament.find(params[:id])
    end

    def tournament_params
      params.require(:tournament).permit(:id, :title, :user_id, :detail, :type, :place, :url, :size, :consolation_round, :tag_list, :double_elimination, :scoreless, :facebook_album_id, players_attributes: [:id, :name, :group, :country], players_all: [:players])
    end
end
