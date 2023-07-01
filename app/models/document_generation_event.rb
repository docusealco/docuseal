# frozen_string_literal: true

# == Schema Information
#
# Table name: document_generation_events
#
#  id           :bigint           not null, primary key
#  event_name   :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  submitter_id :bigint           not null
#
# Indexes
#
#  index_document_generation_events_on_submitter_id                 (submitter_id)
#  index_document_generation_events_on_submitter_id_and_event_name  (submitter_id,event_name) UNIQUE WHERE ((event_name)::text = ANY ((ARRAY['start'::character varying, 'complete'::character varying])::text[]))
#
# Foreign Keys
#
#  fk_rails_...  (submitter_id => submitters.id)
#
class DocumentGenerationEvent < ApplicationRecord
  belongs_to :submitter

  enum :event_name, {
    complete: 'complete',
    fail: 'fail',
    start: 'start',
    retry: 'retry'
  }, scope: false
end
