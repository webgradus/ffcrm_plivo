class CreateCalls < ActiveRecord::Migration
  def change
    create_table :calls do |t|
      t.string :uuid
      t.string :event
      t.integer :from_id
      t.string :from_type
      t.string :to

      t.timestamps
    end
  end
end
