class CreateSyntheticClassSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :synthetic_class_skills do |t|
      t.references :synthetic_class, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.timestamps
    end
    add_index :synthetic_class_skills, [:synthetic_class_id, :document_id], unique: true, name: "idx_synthetic_class_skills_unique"
  end
end
