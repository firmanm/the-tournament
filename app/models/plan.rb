# == Schema Information
#
# Table name: plans
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  count      :integer          not null
#  size       :integer          not null
#  expires_at :date             not null
#  created_at :datetime
#  updated_at :datetime
#

class Plan < ApplicationRecord
  belongs_to :user
  DEFAULT_SIZE = 128
end
