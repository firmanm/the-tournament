class CreateDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :documents do |t|
      t.integer :category_id
      t.integer :document_id
      t.string :title, limit: 255

      t.timestamps
    end
  end
end
