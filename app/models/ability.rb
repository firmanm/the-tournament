class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    can :manage, :all if user.admin?

    can :manage, Tournament, user_id: user.id
    can [:read, :raw, :photos, :games, :players], Tournament

    can :manage, User, id: user.id  if user.id != 1  #ゲストユーザーは編集させない
  end
end
