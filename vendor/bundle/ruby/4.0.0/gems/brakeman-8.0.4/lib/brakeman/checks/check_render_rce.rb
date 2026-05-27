require 'brakeman/checks/check_render'

class Brakeman::CheckRenderRCE < Brakeman::CheckRender
  Brakeman::Checks.add self

  @description = "Finds calls to render that might be vulnerable to CVE-2016-0752"

  def run_check
    tracker.find_call(:target => nil, :method => :render).each do |result|
      process_render_result result
    end
  end

  def process_render_result result
    return unless node_type? result[:call], :render

    case result[:call].render_type
    when :partial, :template, :action, :file
      check_for_rce(result)
    end
  end

  def check_for_rce result
    return unless version_between? "0.0.0", "3.2.22" or
                  version_between? "4.0.0", "4.1.14" or
                  version_between? "4.2.0", "4.2.5"

    view = result[:call][2]
    if sexp? view and not duplicate? result
      if params? view and not safe_param? view
        add_result result

        warn :result => result,
          :warning_type => "Remote Code Execution",
          :warning_code => :dynamic_render_path_rce,
          :message => msg("Passing query parameters to ", msg_code("render"), " is vulnerable in ", msg_version(rails_version), " ", msg_cve("CVE-2016-0752")),
          :user_input => view,
          :confidence => :high,
          :cwe_id => [22]
      end
    end
  end
end
