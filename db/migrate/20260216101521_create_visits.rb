class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :url, null: false, foreign_key: true
      t.string :ip_address, limit: 45
      t.string :country, limit: 100
      t.string :city, limit: 100
      t.string :country_code, limit: 10
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :user_agent, limit: 255
      t.string :referer, limit: 255
      t.datetime :visited_at

      t.timestamps
    end
  end
end
