class AddOtpToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_attempt, :string
    add_column :users, :otp_sent_at, :datetime
    add_column :users, :email_confirmed, :boolean
  end
end
