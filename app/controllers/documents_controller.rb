class DocumentsController < ApplicationController
  skip_before_action :authenticate_user!
  before_filter :set_documents

  def index
  end

  def show
    @doc = Document.find_by(category_id: params[:category_id].to_i, document_id: params[:document_id].to_i)
    @category = Document::CATEGORIES[@doc.category_id]

    # 前の記事/次の記事を表示
    @prev = Document.find_by(category_id: @doc.category_id, document_id: @doc.document_id - 1)
    @next = Document.find_by(category_id: @doc.category_id, document_id: @doc.document_id + 1)
  end


  private

    def set_documents
      @documents = Document.all.order(:category_id, :document_id)
    end
end
