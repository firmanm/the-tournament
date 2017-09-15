require 'open-uri'

class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_blog_rss, only: [:top, :about]


  def about
    sample_id = 158
    @tournament = Tournament.find(sample_id)
  end

  def top
    @tournaments = Tournament.finished.limit(10)
    @unfinished_tnmts = Tournament.where(finished: false).limit(10)
  end


  private

    def set_blog_rss
      @rss= SimpleRSS.parse open('http://blog.the-tournament.jp/feed')
    end
end
