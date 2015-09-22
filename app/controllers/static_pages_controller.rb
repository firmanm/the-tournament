class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!
  def about
    sample_id = (Rails.env=='production') ? 158 : 1
    @tournament = Tournament.find(sample_id)
    gon.push({
      tournament_data: @tournament.tournament_data,
      skip_secondary_final: (@tournament.de?) ? !@tournament.secondary_final : false,
      skip_consolation_round: !@tournament.consolation_round,
      countries: @tournament.players.map{|p| p.country.try(:downcase)},
      match_data: @tournament.match_data,
      scoreless: @tournament.scoreless?
    })
  end

  def top
    @tournaments = Tournament.finished.limit(5)
  end

  def howto
  end
end
