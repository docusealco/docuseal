require "semantic_range"
namespace :shakapacker do
  desc "Verifies if Node.js is installed"
  task :check_node do
    begin
      node_version = `node -v || nodejs -v`.strip
      raise Errno::ENOENT if node_version.blank?

      pkg_path = Pathname.new("#{__dir__}/../../../package.json").realpath
      node_range = JSON.parse(pkg_path.read)["engines"]["node"]
      is_valid = SemanticRange.satisfies?(node_version, node_range) rescue false
      semver_major = node_version[/\d+/] rescue nil
      is_unstable = semver_major.to_i.odd? rescue false

      if is_unstable
        $stderr.puts "Warning: you are using an unstable release of Node.js (#{node_version}). If you encounter issues with Node.js, consider switching to an Active LTS release. More info: https://docs.npmjs.com/try-the-latest-stable-version-of-node"
      end

      unless is_valid
        $stderr.puts "Shakapacker requires Node.js \"#{node_range}\" and you are using #{node_version}"
        $stderr.puts "Please upgrade Node.js https://nodejs.org/en/download/"
        $stderr.puts "Exiting!"
        exit!
      end
    rescue Errno::ENOENT
      $stderr.puts "Node.js not installed. Please download and install Node.js https://nodejs.org/en/download/"
      $stderr.puts "Exiting!"
      exit!
    end
  end
end
