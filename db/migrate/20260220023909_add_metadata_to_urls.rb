class AddMetadataToUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :urls, :title, :string, limit: 500
    add_column :urls, :fetch_status_code, :integer
    add_column :urls, :fetched_at, :datetime # default: -> { "CURRENT_TIMESTAMP" }
  end
end
