# == Schema Information
#
# Table name: games
#
#  id            :integer          not null, primary key
#  tournament_id :integer
#  bracket       :integer
#  round         :integer
#  match         :integer
#  bye           :boolean
#  created_at    :datetime
#  updated_at    :datetime
#  type          :string(255)      default("Winner")
#


#coding: utf-8
class Game < ActiveRecord::Base
  has_many :game_records, -> { order(record_num: :asc) }, dependent: :destroy
  has_many :players, through: :game_records
  belongs_to :tournament

  accepts_nested_attributes_for :game_records

  validates_associated :game_records
  validates :tournament_id, presence: true, on: :update
  validates :bracket, presence: true, inclusion: {in: [1,2,3]}
  validates :round, presence: true, numericality: {only_integer: true}
  validates :match, presence: true, numericality: {only_integer: true}
  validates :bye, inclusion: {in: [true, false]}, allow_nil: true
  validate  :has_valid_winner?, on: :update
  validates :comment, length: {maximum: 50}

  after_update :reset_ancestors, :set_parent_game_record, :set_loser_game_record, if: :winner_changed?
  after_update :set_finished_flg, if: :final?
  after_update :upload_tournament_data

  def has_valid_winner?
    winners = Array.new
    game_records.each do |r|
      winners << r  if r.winner == true
    end

    if winners.size == 1
      loser = (game_records - winners).first
      winner = winners.first
      if winner.score >= loser.score
        return true
      end
    end
    return false
  end

  def reset_ancestors
    self.ancestor_records.map{|record| record.delete}
    self.loser_ancestor_records.map{|record| record.delete}
    self.ancestor_loser_records.map{|record| record.delete}
  end

  def winner_changed?
    changed = false
    self.game_records.each do |r|
      changed = true if r.previous_changes[:winner].present?
    end
    changed
  end

  def parent
    if self.final?
      nil
    elsif self.semi_final?
      self.tournament.final
    else
      self.tournament.games.find_by(bracket: self.bracket, round: self.round+1, match: self.parent_match_id)
    end
  end

  def ancestor_records
    ancestor_records = Array.new
    game = self.parent
    while game.try(:parent).present?
      ancestor_records << game.parent_game_record if game.parent_game_record.persisted?
      game = game.parent
    end

    if self.tournament.third_place.present? && self.third_place_record.try(:persisted?) && !self.semi_final?
      ancestor_records << self.third_place_record
    end
    ancestor_records
  end

  def loser_ancestor_records
    return [] unless self.tournament.de?

    loser_ancestor_records = Array.new
    game = self.loser_game
    while game.try(:parent).present?
      if game.parent_game_record.persisted? && !game.parent.final?
        loser_ancestor_records << game.parent_game_record
      end
      game = game.parent
    end

    if self.tournament.third_place.present? && self.bracket == 1 && !self.semi_final?
      third_place_record = self.loser_game.third_place_record
      loser_ancestor_records << third_place_record
    end
    loser_ancestor_records
  end

  def ancestor_loser_records
    return [] unless self.tournament.de? && self.bracket==1

    ancestor_loser_records = Array.new
    game = self
    while game.parent.present?
      if game.parent.loser_game.present? && game.parent.loser_game_record.persisted?
        ancestor_loser_records << game.parent.loser_game_record
      end
      game = game.parent
    end
    ancestor_loser_records
  end

  def parent_game_record
    GameRecord.find_or_initialize_by(game: self.parent, record_num: self.parent_record_num) if self.parent.present?
  end

  def loser_game_record
    GameRecord.find_or_initialize_by(game: self.loser_game, record_num: self.loser_record_num) if self.loser_game.present?
  end

  def third_place_record
    unless self.third_place?
      GameRecord.find_or_initialize_by(game: self.tournament.third_place, record_num: self.third_place_record_num) if self.tournament.third_place.present?
    end
  end

  def set_parent_game_record
    if self.parent.present?
      target_record = self.parent_game_record
      target_record.player = self.winner
      target_record.save!

      self.parent.game_records.map{|r| r.reset_result}
    end
  end

  def set_loser_game_record
    if self.loser_game.present?
      target_record = self.loser_game_record
      target_record.player = self.loser
      target_record.save!

      self.loser_game.game_records.map{|r| r.reset_result}
    end
  end

  def ready?
    self.game_records.count == 2
  end

  def finished?
    self.winner.present?
  end

  def winner
    self.game_records.find_by(winner: true).try(:player) if self.game_records.count == 2
  end

  def loser
    self.game_records.find_by(winner: false).try(:player) if self.winner.present?
  end

  def match_name
    if self.final?
      if self.bracket == 3 && self.round == 2
        '再決勝'
      else
        '決勝戦'
      end
    elsif self.third_place?
      '3位決定戦'
    else
      "第#{self.match}試合"
    end
  end

  def set_finished_flg
    self.tournament.update(finished: true) if self.has_valid_winner? && !self.tournament.finished?
  end

  def upload_tournament_data
    self.tournament.upload_json
    self.tournament.upload_img
  end

  def final?
    (self.round==self.tournament.round_num) && (self.match==1)
  end

  def third_place?
    (self.round==self.tournament.round_num) && (self.match==2)
  end
end
