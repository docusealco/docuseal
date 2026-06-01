# frozen_string_literal: true

require 'zlib'

class RedisClient
  class HashRing
    POINTS_PER_SERVER = 160

    class << self
      attr_writer :digest

      def digest
        @digest ||= begin
          require 'digest/md5'
          Digest::MD5
        end
      end
    end

    attr_reader :nodes

    def initialize(nodes = [], replicas: POINTS_PER_SERVER, digest: self.class.digest)
      @replicas = replicas
      @ring = {}
      @digest = digest
      ids = {}
      @nodes = nodes.dup.freeze
      nodes.each do |node|
        id = node.id || node.config.server_url
        if ids[id]
          raise ArgumentError, "duplicate node id: #{id.inspect}"
        end

        ids[id] = true

        replicas.times do |i|
          @ring[server_hash_for("#{id}:#{i}".freeze)] = node
        end
      end
      @sorted_keys = @ring.keys
      @sorted_keys.sort!
    end

    # get the node in the hash ring for this key
    def node_for(key)
      hash = hash_for(key)
      idx = binary_search(@sorted_keys, hash)
      @ring[@sorted_keys[idx]]
    end

    def nodes_for(*keys)
      keys.flatten!
      mapping = {}
      keys.each do |key|
        (mapping[node_for(key)] ||= []) << key
      end
      mapping
    end

    private

    def hash_for(key)
      Zlib.crc32(key)
    end

    def server_hash_for(key)
      @digest.digest(key).unpack1("L>")
    end

    # Find the closest index in HashRing with value <= the given value
    def binary_search(ary, value)
      upper = ary.size
      lower = 0

      while lower < upper
        mid = (lower + upper) / 2
        if ary[mid] > value
          upper = mid
        else
          lower = mid + 1
        end
      end

      upper - 1
    end
  end
end
