# == Schema Information
#
# Table name: tournaments
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  size              :integer
#  title             :string(255)
#  place             :string(255)
#  detail            :text
#  created_at        :datetime
#  updated_at        :datetime
#  consolation_round :boolean          default(TRUE)
#  url               :string(255)
#  secondary_final   :boolean          default(FALSE)
#  scoreless         :boolean          default(FALSE)
#  finished          :boolean          default(FALSE)
#  pickup            :boolean          default(FALSE)
#  facebook_album_id :string(255)
#  teams             :json
#  results           :json
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tournament, class: 'Tournament' do
    association :user
    title {Faker::Company.name}
    size 8
    consolation_round true
    secondary_final false
  end

  factory :se_tnmt, parent: :tournament, class: 'SingleElimination' do
    type 'SingleElimination'
  end

  factory :de_tnmt, parent: :tournament, class: 'DoubleElimination' do
    type 'DoubleElimination'
  end
end
