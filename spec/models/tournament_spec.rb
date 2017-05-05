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

require 'spec_helper'

describe Tournament, :type => :model do
  before :each do
    @user = create(:user)
  end

  describe 'basic validations' do
    it 'is valid with a proper attrs' do
      tournament = build(:tournament, user:@user)
      expect(tournament).to be_valid
    end

    it 'is invalid without a user_id' do
      expect(build(:tournament, user:nil)).not_to be_valid
    end

    it 'should has a size in a multiplier of 2' do
      expect(build(:tournament, user:@user, size:5)).not_to be_valid
    end

    it 'should order from the newest' do
      @tournament = create(:se_tnmt, user:@user)
      2.times do |i|
        create(:se_tnmt, user:@user)
      end
      expect(Tournament.last).to eq(@tournament)
    end
  end

  describe 'method after creation' do
    context 'when single elimination' do
      before :each do
        @tournament = create(:se_tnmt, user:@user)
      end

      describe 'create_players' do
        it 'should have players equal to its size' do
          expect(@tournament.players.size).to eq(8)
        end
      end

      describe 'create_games' do
        it 'should have right number of games' do
          expect(@tournament.games.size).to eq(8)
        end
      end
    end

    context 'when double elimination' do
      before :each do
        @tournament = create(:de_tnmt, user:@user)
      end

      describe 'create_players' do
        it 'should have players equal to its size' do
          expect(@tournament.players.size).to eq(8)
        end
      end

      describe 'create_games' do
        it 'should have right number of games' do
          expect(@tournament.games.where(bracket:1).count).to eq(7)
          expect(@tournament.games.where(bracket:2).count).to eq(6)
          expect(@tournament.games.where(bracket:3).count).to eq(3)
        end
      end
    end
  end

  describe 'round_num' do
    it 'should return the correct round num' do
      [2,3,4].each do |i|
        tournament = create(:se_tnmt, user:@user, size:2**i)
        expect(tournament.round_num).to eq(i)
      end
    end
  end

  describe 'third-place' do
    context 'when single elimination' do
      context 'when it has a third-party placement' do
        it 'should return the game for the third-place playoff' do
          @tournament = create(:se_tnmt, user:@user)
          expect(@tournament.third_place).to eq(@tournament.games.find_by(bracket:1, round:3, match:2))
        end
      end

      context 'when it doesnot have a third-party placement' do
        it 'should return nil for the third-place playoff' do
          @tournament = create(:se_tnmt, user:@user, consolation_round:false)
          expect(@tournament.third_place).to eq(nil)
        end
      end
    end

    context 'when double elimination' do
      context 'when it has a third-party placement' do
        it 'should return the game for the third-place playoff' do
          @tournament = create(:de_tnmt, user:@user)
          expect(@tournament.third_place).to eq(@tournament.games.find_by(bracket:3, round:1, match:2))
        end
      end

      context 'when it doesnot have a third-party placement' do
        it 'should return nil for the third-place playoff' do
          @tournament = create(:de_tnmt, user:@user, consolation_round:false)
          expect(@tournament.third_place).to eq(nil)
        end
      end
    end
  end

  describe 'set_first_rounds' do
    context 'when single elimination' do
      it 'should have first-round game with game_records' do
        @tournament = create(:se_tnmt, user:@user)
        @tournament.games.where(round:1).each do |game|
          expect(game.game_records.count).to eq(2)
        end

        @tournament.games.where(round:2).each do |game|
          expect(game.game_records.count).to eq(0)
        end
      end
    end

    context 'when double elimination' do
      it 'should have first-round game with game_records' do
        @tournament = create(:de_tnmt, user:@user)
        @tournament.games.where(bracket:1,round:1).each do |game|
          expect(game.game_records.count).to eq(2)
        end

        @tournament.games.where(bracket:1,round:2).each do |game|
          expect(game.game_records.count).to eq(0)
        end
      end
    end
  end

  describe 'category' do
    before :each do
      tags = ['サッカー', 'バスケ']
      @category_name = 'スポーツ'
      tags.each do |tag|
        create(:category, tag_name: tag, category_name: @category_name)
      end
      create(:category, tag_name: '将棋', category_name: 'ゲーム')
      @tournament = create(:se_tnmt, user:@user)
    end

    context 'when without category tag' do
      it 'should have no category' do
        expect(@tournament.category).to eq(nil)
      end
    end

    context 'when with single category tag' do
      it 'should have category' do
        @tournament.tag_list.add('サッカー')
        expect(@tournament.category.category_name).to eq(@category_name)
      end
    end

    context 'when with multiple category tag' do
      it 'should return first matched category' do
        @tournament.tag_list.add('サッカー', '将棋')
        expect(@tournament.category.category_name).to eq(@category_name)
      end
    end
  end

  describe 'de?' do
    it 'should return true for de' do
      @tournament = create(:de_tnmt, user:@user)
      expect(@tournament.de?).to be true
    end

    it 'should return false for se' do
      @tournament = create(:se_tnmt, user:@user)
      expect(@tournament.de?).to be false
    end
  end

  describe 'round_name' do
    context 'when single elimination' do
      before :each do
        @tournament = create(:se_tnmt, user:@user)
      end

      it 'should return proper round name' do
        expect(@tournament.round_name(bracket:1, round:1)).to eq('1回戦')
        expect(@tournament.round_name(bracket:1, round:2)).to eq('準決勝')
        expect(@tournament.round_name(bracket:1, round:3)).to eq('決勝ラウンド')
      end
    end

    context 'when double elimination' do
      before :each do
        @tournament = create(:de_tnmt, user:@user)
      end

      it 'should return proper round name' do
        expect(@tournament.round_name(bracket:1, round:1)).to eq('1回戦')
        expect(@tournament.round_name(bracket:1, round:2)).to eq('2回戦')
        expect(@tournament.round_name(bracket:1, round:3)).to eq('準決勝')
        expect(@tournament.round_name(bracket:2, round:1)).to eq('1回戦')
        expect(@tournament.round_name(bracket:2, round:2)).to eq('2回戦')
        expect(@tournament.round_name(bracket:2, round:4)).to eq('準決勝')
        expect(@tournament.round_name(bracket:3, round:1)).to eq('決勝ラウンド')
      end
    end
  end

  describe 'is_finished?' do
    context 'when not finished' do
      before :each do
        @tournament = create(:se_tnmt, user:@user, size: 4)
      end

      it 'should return false' do
        expect(@tournament.is_finished?).to eq(false)
      end
    end

#  context 'when finished' do
#    before :each do
#      @tournament = create(:se_tnmt, user:@user)
#    end

#    it 'should return true' do
#      @game = create(:game_with_winner, tournament:@tournament, round:2)
#      expect(@tournament.is_finished?).to eq(true)
#    end
#  end

#  context 'when de finished' do
#    before :each do
#      @tournament = create(:de_tnmt, user:@user)
#    end

#    it 'should return true' do
#      @game = create(:game_with_winner, tournament:@tournament, round:3)
#      expect(@tournament.is_finished?).to eq(true)
#    end
#  end
  end
end
