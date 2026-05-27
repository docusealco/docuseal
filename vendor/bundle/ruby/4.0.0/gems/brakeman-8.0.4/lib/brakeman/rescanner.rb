require 'brakeman/scanner'
require 'brakeman/util'
require 'brakeman/differ'

#Class for rescanning changed files after an initial scan
class Brakeman::Rescanner < Brakeman::Scanner
 include Brakeman::Util
  KNOWN_TEMPLATE_EXTENSIONS = Brakeman::TemplateParser::KNOWN_TEMPLATE_EXTENSIONS

  #Create new Rescanner to scan changed files
  def initialize options, processor, changed_files
    super(options)

    @old_tracker = processor.tracked_events

    @paths = changed_files.map {|f| tracker.app_tree.file_path(f) }
    @old_results = @old_tracker.filtered_warnings.dup  #Old warnings from previous scan
    @changes = nil                 #True if files had to be rescanned
    @reindex = Set.new
  end

  #Runs checks.
  #Will rescan files if they have not already been scanned
  def recheck
    rescan if @changes.nil?

    if @changes
      tracker.run_checks
      Brakeman.filter_warnings(tracker, options) # Actually sets ignored_filter
      Brakeman::RescanReport.new @old_results, tracker
    else
      # No changes, fake no new results
      Brakeman::RescanReport.new @old_results, @old_tracker
    end
  end

  #Rescans changed files
  def rescan
    raise "Cannot rescan: set `support_rescanning: true`" unless @old_tracker.options[:support_rescanning]

    tracker.file_cache = @old_tracker.pristine_file_cache

    template_paths = []
    ruby_paths = []

    # Remove changed files from the cache.
    # Collect files to re-parse.
    @paths.each do |path|
      file_cache.delete path

      if path.exists?
        if path.relative.match? KNOWN_TEMPLATE_EXTENSIONS
          template_paths << path
        elsif path.relative.end_with? '.rb'
          ruby_paths << path
        end
      end
    end

    # Try to skip rescanning files that do not impact
    # Brakeman results
    if @paths.all? { |path| ignorable? path }
      @changes = false
    else
      @changes = true
      process(ruby_paths:, template_paths:)
    end

    self
  end

  IGNORE_PATTERN = /\.(md|txt|js|ts|tsx|json|scss|css|xml|ru|png|jpg|pdf|gif|svg|webm|ttf|sql)$/

  def ignorable? path
    path.relative.match? IGNORE_PATTERN
  end
end

#Class to make reporting of rescan results simpler to deal with
class Brakeman::RescanReport
  include Brakeman::Util
  attr_reader :old_results, :new_results

  def initialize old_results, tracker
    @tracker = tracker
    @old_results = old_results
    @all_warnings = nil
    @diff = nil
  end

  #Returns true if any warnings were found (new or old)
  def any_warnings?
    not all_warnings.empty?
  end

  #Returns an array of all warnings found
  def all_warnings
    @all_warnings ||= @tracker.filtered_warnings
  end

  #Returns an array of warnings which were in the old report but are not in the
  #new report after rescanning
  def fixed_warnings
    diff[:fixed]
  end

  #Returns an array of warnings which were in the new report but were not in
  #the old report
  def new_warnings
    diff[:new]
  end

  #Returns true if there are any new or fixed warnings
  def warnings_changed?
    not (diff[:new].empty? and diff[:fixed].empty?)
  end

  #Returns a hash of arrays for :new and :fixed warnings
  def diff
    @diff ||= Brakeman::Differ.new(all_warnings, @old_results).diff
  end

  #Returns an array of warnings which were in the old report and the new report
  def existing_warnings
    @old ||= all_warnings.select do |w|
      not new_warnings.include? w
    end
  end

  #Output total, fixed, and new warnings
  def to_s
    <<~OUTPUT
      Total warnings: #{all_warnings.length}
      Fixed warnings: #{fixed_warnings.length}
      New warnings: #{new_warnings.length}
    OUTPUT
  end
end
