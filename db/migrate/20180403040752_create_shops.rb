class CreateShops < ActiveRecord::Migration[5.1]
  def change
    create_table :shops  do |t|
      t.string :shopify_domain, index: true, unique: true
      t.string :nonce
      t.string :access_token
      t.timestamps
    end
  end
end
