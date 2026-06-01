$stdout.sync = true

namespace :shakapacker do
  desc "Compile JavaScript packs using webpack for production with digests"
  task compile: ["shakapacker:verify_install", :environment] do
    Shakapacker.with_node_env(ENV.fetch("NODE_ENV", "production")) do
      Shakapacker.ensure_log_goes_to_stdout do
        exit! unless Shakapacker.compile
      end
    end
  end
end

def invoke_shakapacker_compile_in_assets_precompile_task
  Rake::Task["assets:precompile"].enhance do |task|
    prefix = task.name.split(/#|assets:precompile/).first

    Rake::Task["#{prefix}shakapacker:compile"].invoke
  end
end

if Shakapacker.config.shakapacker_precompile?
  if Rake::Task.task_defined?("assets:precompile")
    invoke_shakapacker_compile_in_assets_precompile_task
  else
    Rake::Task.define_task("assets:precompile" => ["shakapacker:compile"])
  end
end
