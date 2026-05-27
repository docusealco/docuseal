require 'uri'

class Brakeman::Report::SARIF < Brakeman::Report::Base
  def generate_report
    sarif_log = {
      :version => '2.1.0',
      :$schema => 'https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0.json',
      :runs => runs,
    }
    JSON.pretty_generate sarif_log
  end

  def runs
    [
      {
        :tool => {
          :driver => {
            :name => 'Brakeman',
            :informationUri => 'https://brakemanscanner.org',
            :semanticVersion => Brakeman::Version,
            :rules => rules,
          },
        },
        :results => results,
      }.merge(original_uri_base_ids)
    ]
  end

  # Output base URIs
  # based on what the user specified for the application path
  # and whether or not --absolute-paths was set.
  def original_uri_base_ids
    if tracker.options[:app_path] == '.'
      # Probably no app_path was specified, as that's the default

      if absolute_paths?
        # Set %SRCROOT% to absolute path
        {
          originalUriBaseIds: {
            '%SRCROOT%' => {
              uri: file_uri(tracker.app_tree.root),
              description: {
                text: 'Base path for application'
              }
            }
          }
        }
      else
        # Empty %SRCROOT%
        # This avoids any paths appearing in the report
        # that are not part of the application directory.
        # Seems fine!
        {
          originalUriBaseIds: {
            '%SRCROOT%' => {
              description: {
                text: 'Base path for application'
              }
            },
          }
        }

      end
    elsif tracker.options[:app_path] != tracker.app_tree.root
      # Path was specified and it was relative

      if absolute_paths?
        # Include absolute root and relative application path
        {
          originalUriBaseIds: {
            PROJECTROOT: {
              uri: file_uri(tracker.app_tree.root),
              description: {
                text: 'Base path for all project files'
              }
            },
            '%SRCROOT%' => {
              # Technically should ensure this doesn't have any '..'
              # but... TODO
              uri: File.join(tracker.options[:app_path], '/'),
              uriBaseId: 'PROJECTROOT',
              description: {
                text: 'Base path for application'
              }
            }
          }
        }
      else
        # Just include relative application path.
        # Not clear this is 100% valid, but there is one example in the spec like this
        {
          originalUriBaseIds: {
            PROJECTROOT: {
              description: {
                text: 'Base path for all project files'
              }
            },
            '%SRCROOT%' => {
              # Technically should ensure this doesn't have any '..'
              # but... TODO
              uri: File.join(tracker.options[:app_path], '/'),
              uriBaseId: 'PROJECTROOT',
              description: {
                text: 'Base path for application'
              }
            }
          }
        }
      end
    else
      # app_path was absolute

      if absolute_paths?
        # Set %SRCROOT% to absolute path
        {
          originalUriBaseIds: {
            '%SRCROOT%' => {
              uri: file_uri(tracker.app_tree.root),
              description: {
                text: 'Base path for application'
              }
            }
          }
        }
      else
        # Empty %SRCROOT%
        # Seems fine!
        {
          originalUriBaseIds: {
            '%SRCROOT%' => {
              description: {
                text: 'Base path for application'
              }
            },
          }
        }
      end
    end
  end

  def rules
    @rules ||= unique_warnings_by_warning_code.map do |warning|
      rule_id = render_id warning
      check_name = warning.check_name
      check_description = render_message check_descriptions[check_name]
      {
        :id => rule_id,
        :name => "#{check_name}/#{warning.warning_type}",
        :fullDescription => {
          :text => check_description,
        },
        :helpUri => warning.link,
        :help => {
          :text => "More info: #{warning.link}.",
          :markdown => "[More info](#{warning.link}).",
        },
        :properties => {
          :tags => [check_name],
        },
      }
    end
  end

  def results
    @results ||= tracker.checks.all_warnings.map do |warning|
      rule_id = render_id warning
      result_level = infer_level warning
      message_text = render_message warning.message.to_s
      result = {
        :ruleId => rule_id,
        :ruleIndex => rules.index { |r| r[:id] == rule_id },
        :level => result_level,
        :message => {
          :text => message_text,
        },
        :locations => [
          :physicalLocation => {
            :artifactLocation => {
              :uri => warning.file.relative,
              :uriBaseId => '%SRCROOT%',
            },
            :region => {
              :startLine => warning.line.is_a?(Integer) ? warning.line : 1,
            },
          },
        ],
      }

      if @ignore_filter && @ignore_filter.ignored?(warning)
        result[:suppressions] = [
          {
            :kind => 'external',
            :justification => @ignore_filter.note_for(warning),
            :location => {
              :physicalLocation => {
                :artifactLocation => {
                  :uri => Brakeman::FilePath.from_app_tree(@app_tree, @ignore_filter.file).relative,
                  :uriBaseId => '%SRCROOT%',
                },
              },
            },
          }
        ]
      end

      result
    end
  end

  # Returns a hash of all check descriptions, keyed by check name
  def check_descriptions
    @check_descriptions ||= Brakeman::Checks.checks.map do |check|
      [check.name.gsub(/^Check/, ''), check.description]
    end.to_h
  end

  # Returns a de-duplicated set of warnings, used to generate rules
  def unique_warnings_by_warning_code
    @unique_warnings_by_warning_code ||= tracker.checks.all_warnings.uniq { |w| w.warning_code }
  end

  def render_id warning
    # Include alpha prefix to provide 'compiler error' appearance
    "BRAKE#{'%04d' % warning.warning_code}" # 46 becomes BRAKE0046, for example
  end

  def render_message message
    return message if message.nil?

    # Ensure message ends with a period
    if message.end_with? "."
      message
    else
      "#{message}."
    end
  end

  def infer_level warning
    # Infer result level from warning confidence
    @@levels_from_confidence ||= Hash.new('warning').update({
      0 => 'error',    # 0 represents 'high confidence', which we infer as 'error'
      1 => 'warning',  # 1 represents 'medium confidence' which we infer as 'warning'
      2 => 'note',     # 2 represents 'weak, or low, confidence', which we infer as 'note'
    })
    @@levels_from_confidence[warning.confidence]
  end

  # File URI as a string with trailing forward-slash
  # as required by SARIF standard
  def file_uri(path)
    URI::File.build(path: File.join(path, '/')).to_s
  end
end
