# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  admin                  :boolean          default(FALSE)
#  email_subscription     :boolean          default(TRUE)
#  name                   :string(255)
#  profile                :text
#  url                    :string(255)
#  facebook_url           :string(255)
#

require 'faker'

FactoryGirl.define do
  factory :user do
    sequence :email do |n|
      "hogehoge#{n}@example.com"
    end
    password "hogehoge"
    password_confirmation "hogehoge"
    admin false
    # provider "facebook"
    # uid { Faker::Number.number(10) }
  end
end
