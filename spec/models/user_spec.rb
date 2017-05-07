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

require 'spec_helper'

describe Tournament, :type => :model do
  before :each do
    @user = create(:user)
    @admin = create(:user, admin: true)
  end

  describe 'creatable?' do
    context 'admin' do
      it 'should be true with less than 3 tournaments' do
        create(:se_tnmt, user:@admin)
        expect(@admin.creatable?).to be_truthy
      end

      it 'should be true with more than 3 tournaments' do
        5.times do
          create(:se_tnmt, user:@admin)
        end
        expect(@admin.creatable?).to be_truthy
      end
    end

    context 'non-paid user' do
      it 'should be true with less than 3 tournaments' do
        2.times do
          create(:se_tnmt, user:@user)
        end
        expect(@user.creatable?).to be_truthy
      end

      it 'should be true with more than 3 tournaments' do
        3.times do
          create(:se_tnmt, user:@user)
        end
        expect(@user.creatable?).to be_falsey
      end
    end
  end
end
