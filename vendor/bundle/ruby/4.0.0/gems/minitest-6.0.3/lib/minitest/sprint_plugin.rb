require_relative "../minitest"

# :stopdoc:
class OptionParser # unofficial embedded gem "makeoptparseworkwell"
  def hidden(...)         = define(...).tap { |sw| def sw.summarize(*) = nil }
  def deprecate(from, to) = hidden(from) { abort "#{from} is deprecated. Use #{to}." }
  def topdict(name)       = name.length > 1 ? top.long : top.short
  def alias(from, to)     = (dict = topdict(from) and dict[to] = dict[from])
end unless OptionParser.method_defined? :hidden
# :startdoc:

module Minitest # :nodoc:
  def self.plugin_sprint_options opts, options # :nodoc:
    opts.on "--rake [TASK]", "Report how to re-run failures with rake." do |task|
      options[:sprint] = :rake
      options[:rake_task] = task
    end

    opts.deprecate "--binstub", "--rerun"

    sprint_styles = %w[rake lines names binstub]

    opts.on "-r", "--rerun [STYLE]", sprint_styles, "Report how to re-run failures using STYLE (names, lines)." do |style|
      options[:sprint] = (style || :lines).to_sym
    end
  end

  def self.plugin_sprint_init options
    require_relative "sprint"
    case options[:sprint]
    when :rake then
      self.reporter << Minitest::Sprint::RakeReporter.new(options[:rake_task])
    when :binstub, :names then
      self.reporter << Minitest::Sprint::SprintReporter.new
    when :lines then
      self.reporter << Minitest::Sprint::SprintReporter.new(:lines)
    end
  end
end
