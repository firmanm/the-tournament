class DocsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    path = "#{Rails.root}/app/views/docs"
    files = Dir.glob("#{File.expand_path(path)}/**/_*").map{|m| m.split(/app\/views\/docs\//).last}
    @docs_by_categories = files.group_by{|file| file.split('/')[0] }.sort.to_h
  end

  def show
    path = "#{Rails.root}/app/views/docs/**/_#{params[:title]}.html.haml"
    file = Dir.glob("#{File.expand_path(path)}").map{|m| m.split(/app\/views\/docs\//).last}.first

    @category = file.split('/').first
  end
end
