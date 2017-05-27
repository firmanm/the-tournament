# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup}.
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }]}
#   Mayor.create(name: 'Emanuel', city: cities.first}

Document.create([
  {category_id: 1, document_id: 1, title: 'トーナメントを作成する'},
  {category_id: 1, document_id: 2, title: '参加者を登録する'},
  {category_id: 1, document_id: 3, title: '試合結果を登録する'},
  {category_id: 1, document_id: 4, title: '一度作ったトーナメントを編集する'},
  {category_id: 2, document_id: 1, title: '３位決定戦の有無を変更する'},
  {category_id: 2, document_id: 2, title: 'スコアがない形式の大会に利用する'},
  {category_id: 5, document_id: 1, title: 'ログインせずにトーナメント表を作成する'},
])
