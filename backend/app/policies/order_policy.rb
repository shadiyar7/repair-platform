class OrderPolicy < ApplicationPolicy
  def show?
    user.admin? || record.user_id == user.id || user.warehouse? || user.driver? || user.director? || user.supervisor?
  end

  def update?
    user.admin? || record.user_id == user.id || user.warehouse? || user.driver? || user.director? || user.supervisor?
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.warehouse?
        scope.all
      elsif user.driver?
        scope.where(driver_id: user.id).or(scope.where(status: 'driver_search'))
      else
        scope.where(user: user)
      end
    end
  end
end
