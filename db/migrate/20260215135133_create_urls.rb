class CreateUrls < ActiveRecord::Migration[8.1]
  def change
    create_table :urls do |t|
      t.string :short_code, limit: 15
      t.string :target_url
      t.boolean :is_active

      t.timestamps
    end
  end
end
