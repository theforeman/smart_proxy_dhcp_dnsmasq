module Proxy::DHCP::Dnsmasq
  Tags = Struct.new(:tags, :sets) do
    def tag
      tags.first if tags.count == 1
    end

    def set
      sets.first if sets.count == 1
    end
  end

  def self.parse_tags(data)
    tags = { tags: [], sets: [] }
    while (matches = /(set|tag):(\w+)/.match(data.first))
      if matches[1] == 'set'
        tags[:sets] << matches[2]
      else
        tags[:tags] << matches[2]
      end
      data.shift
    end
    Tags.new tags[:tags], tags[:sets]
  end
end
