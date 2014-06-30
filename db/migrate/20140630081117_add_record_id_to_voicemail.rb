class AddRecordIdToVoicemail < ActiveRecord::Migration
  def change
    add_column :voice_mails, :record_id, :string
  end
end
