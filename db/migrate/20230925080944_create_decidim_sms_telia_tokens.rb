# frozen_string_literal: true

class CreateDecidimSmsTeliaTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :decidim_sms_telia_tokens do |t|
      t.string :access_token
      t.datetime :issued_at
      t.datetime :expires_at

      t.timestamps
    end
  end
end
