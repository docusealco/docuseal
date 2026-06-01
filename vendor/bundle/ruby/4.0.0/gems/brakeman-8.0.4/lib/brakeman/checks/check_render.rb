require 'brakeman/checks/base_check'

#Check calls to +render()+ for dangerous values
class Brakeman::CheckRender < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds calls to render that might allow file access or code execution"

  def run_check
    tracker.find_call(:target => nil, :method => :render).each do |result|
      process_render_result result
    end
  end

  def process_render_result result
    return unless node_type? result[:call], :render

    case result[:call].render_type
    when :partial, :template, :action, :file
      check_for_dynamic_path(result)
    when :inline
    when :js
    when :json
    when :text
    when :update
    when :xml
    end
  end

  #Check if path to action or file is determined dynamically
  def check_for_dynamic_path result
    view = result[:call][2]

    if sexp? view and original? result
      return if renderable?(view)

      if input = has_immediate_user_input?(view)
        if string_interp? view
          confidence = :medium
        else
          confidence = :high
        end
      else
        return
      end

      return if input.type == :model #skip models
      return if safe_param? input.match

      message = msg("Render path contains ", msg_input(input))

      warn :result => result,
        :warning_type => "Dynamic Render Path",
        :warning_code => :dynamic_render_path,
        :message => message,
        :user_input => input,
        :confidence => confidence,
        :cwe_id => [22]
    end
  end

  def safe_param? exp
    if params? exp and call? exp
      method_name = exp.method

      if method_name == :[]
        arg = exp.first_arg
        symbol? arg and [:controller, :action].include? arg.value
      else
        boolean_method? method_name
      end
    end
  end

  def renderable? exp
    return false unless call?(exp) and constant?(exp.target)

    if exp.method == :with_content
      exp = exp.target
    end

    return false unless constant?(exp.target)
    target_class_name = class_name(exp.target)
    known_renderable_class?(target_class_name) or tracker.find_method(:render_in, target_class_name)
  end

  def known_renderable_class? class_name
    klass = tracker.find_class(class_name)
    return false if klass.nil?
    knowns = [
      :"ViewComponent::Base",
      :"ViewComponentContrib::Base",
      :"Phlex::HTML"
    ]
    knowns.any? { |k| klass.ancestor? k }
  end
end
