class AddSessionIdToUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :urls, :session_id, :string
  end
end
