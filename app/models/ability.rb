class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    can :manage, :all if user.admin?

    can :manage, Tournament, user_id: user.id
    # 誰でも閲覧はできるけど、private設定されてるときはオーナーのみ
    can [:read, :raw, :photos, :games, :players], Tournament do |tournament|
      (tournament.private) ? false : true
    end

    can :manage, User, id: user.id  if user.id != 1  #ゲストユーザーは編集させない
  end
end
