# frozen_string_literal: true

class StiDetector
  def self.sti_class?(subject)
    return false unless defined?(ActiveRecord::Base)
    return false unless subject.respond_to?(:descends_from_active_record?)
    return false if subject == :all || subject.descends_from_active_record?
    return false unless subject < ActiveRecord::Base

    true
  end
end
