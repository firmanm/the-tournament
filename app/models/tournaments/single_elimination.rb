# == Schema Information
#
# Table name: tournaments
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  size              :integer
#  type              :string(255)      default("SingleElimination")
#  title             :string(255)
#  place             :string(255)
#  detail            :text
#  created_at        :datetime
#  updated_at        :datetime
#  consolation_round :boolean          default(TRUE)
#  url               :string(255)
#  secondary_final   :boolean          default(FALSE)
#  scoreless         :boolean          default(FALSE)
#

class SingleElimination < Tournament
  def third_place
    Game.find_by(tournament: self, bracket:1, round:self.round_num, match:2) if self.consolation_round
  end

  def final
    Game.find_by(tournament: self, bracket:1, round:self.round_num, match:1)
  end

  def build_third_place_game
    self.games.build(bracket:1, round: self.round_num, match:2)
  end

  def round_name(args)
    round = args[:round]

    if round == self.round_num
      I18n.t('tournament.round_name.final_round')
    elsif round == self.round_num - 1
      I18n.t('tournament.round_name.semi-final_round')
    else
      I18n.t('tournament.round_name.numbered_round', round: round)
    end
  end

  def game_name(args)
    round_num = args[:round]
    game_num = args[:game]

    if round_num == self.round_num
      game_name = (game_num==1) ? '決勝戦' : '3位決定戦'
    else
      game_name = "第#{game_num}試合"
    end
  end

  def is_finished?
    self.final.has_valid_winner?
  end
end
