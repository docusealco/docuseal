# frozen_string_literal: true

# == Schema Information
#
# Table name: lock_events
#
#  id         :integer          not null, primary key
#  event_name :string           not null
#  key        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_lock_events_on_event_name_and_key  (event_name,key) UNIQUE WHERE event_name IN ('start', 'complete')
#  index_lock_events_on_key                 (key)
#
class LockEvent < ApplicationRecord
  enum :event_name, {
    complete: 'complete',
    fail: 'fail',
    start: 'start',
    retry: 'retry'
  }, scope: false
end
