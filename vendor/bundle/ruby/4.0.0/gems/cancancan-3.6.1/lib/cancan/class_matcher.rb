require_relative 'sti_detector'

# This class is responsible for matching classes and their subclasses as well as
# upmatching classes to their ancestors.
# This is used to generate sti connections
class SubjectClassMatcher
  def self.matches_subject_class?(subjects, subject)
    subjects.any? do |sub|
      has_subclasses = subject.respond_to?(:subclasses)
      matching_class_check(subject, sub, has_subclasses)
    end
  end

  def self.matching_class_check(subject, sub, has_subclasses)
    matches = matches_class_or_is_related(subject, sub)
    if has_subclasses
      return matches unless StiDetector.sti_class?(sub)

      matches || subject.subclasses.include?(sub)
    else
      matches
    end
  end

  def self.matches_class_or_is_related(subject, sub)
    sub.is_a?(Module) && (subject.is_a?(sub) ||
        subject.class.to_s == sub.to_s ||
        (subject.is_a?(Module) && subject.ancestors.include?(sub)))
  end
end
