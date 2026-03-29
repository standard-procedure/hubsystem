class CreateSyntheticClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :synthetic_classes do |t|
      t.string :name, null: false
      t.string :llm_tier, null: false, default: "low"
      t.text :operating_system, default: ""
      t.timestamps
    end

    add_reference :synthetics, :synthetic_class, foreign_key: true
  end
end
