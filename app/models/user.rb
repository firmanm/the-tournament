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

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :tournaments, dependent: :destroy
  has_many :plans, dependent: :destroy
  validates :accept_terms, acceptance: true, on: :create

  def current_plan
    self.plans.order(created_at: :desc).where("expires_at >= ?", Date.today).first
  end

  def limit_size
    self.current_plan.try(:size) || Plan::DEFAULT_SIZE
  end

  def creatable_sizes
    {"〜4名"=> 4, "5〜8名"=> 8, "9〜16名"=>16, "17〜32名"=>32, "33〜64名"=>64, "65〜128名"=>128}.select{|k,v| v <= self.limit_size}
  end
end
