# == Schema Information
#
# Table name: documents
#
#  id          :integer          not null, primary key
#  category_id :integer
#  document_id :integer
#  title       :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Document < ApplicationRecord
  CATEGORIES = {
    1 => '基本機能の使い方',
    2 => '大会情報の設定',
    3 => '参加者の登録',
    4 => '試合結果の登録',
    5 => 'その他',
  }.freeze
end
