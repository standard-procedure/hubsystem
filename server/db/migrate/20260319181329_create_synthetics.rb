class CreateSynthetics < ActiveRecord::Migration[8.1]
  def change
    create_table :synthetics do |t|
      t.string :personality, default: ""
      t.decimal :temperature, precision: 3, scale: 2, default: 0.4
      t.integer :fatigue, default: 0
      t.json :emotions, default: {
        "joy" => 50, "sadness" => 10, "fear" => 10, "anger" => 10,
        "surprise" => 20, "disgust" => 5, "anticipation" => 30, "trust" => 50
      }
      t.timestamps
    end
  end
end
