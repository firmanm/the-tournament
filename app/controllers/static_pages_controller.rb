require 'open-uri'

class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_blog_rss, only: :top


  def about
    sample_id = (Rails.env=='production') ? 158 : 1
    @tournament = Tournament.find(sample_id)
    @shop_url = 'https://spike.cc/shop/user_1688032006/products/Kgoa0Zmt'
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
    @pickup = Tournament.where(pickup: true).order(created_at: :desc).first
    @tournaments = Tournament.finished.limit(10)
    @unfinished_tnmts = Tournament.where(finished: false).limit(10)
  end


  private

    def set_blog_rss
      @rss= SimpleRSS.parse open('http://blog.the-tournament.jp/rss')
    end
end
