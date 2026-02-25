class UpdateShadiyarsProductionData < ActiveRecord::Migration[7.1]
  def up
    # 1. Soft-delete "Test Client LLP (Main)"
    CompanyRequisite.where("company_name LIKE ?", "%Test Client%").update_all(is_active: false)

    # 2. Update user profile
    user = User.find_by(email: 'client@repair.com') || User.find_by(email: 'shadiyar7@gmail.com')
    if user
      user.update!(
        company_name: "ИП ШАДИЯР А Б",
        legal_address: "Жамбылский район, Аса, УЛИЦА ТЕМИР ЖОЛ, дом 6/1",
        actual_address: "Жамбылский район, Аса, УЛИЦА ТЕМИР ЖОЛ, дом 6/1",
        bin: "980107301250",
        inn: "980107301250",
        director_name: "Шадияр А.Б.",
        acting_on_basis: "Свидетельства ИП"
      )
      
      # 3. Sync all active requisites for this user
      user.company_requisites.where(is_active: true).each do |req|
        req.update!(
          company_name: user.company_name,
          legal_address: user.legal_address,
          actual_address: user.actual_address,
          bin: user.bin,
          inn: user.inn,
          director_name: user.director_name,
          acting_on_basis: user.acting_on_basis
        )
      end
    end
  end

  def down
    # Irreversible migration
  end
end
