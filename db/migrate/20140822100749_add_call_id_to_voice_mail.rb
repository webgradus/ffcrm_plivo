class AddCallIdToVoiceMail < ActiveRecord::Migration
  def change
    add_column :voice_mails, :call_id, :integer
  end
end
