# Monkeypatch loofah to fix JRuby issue
# https://github.com/flavorjones/loofah/issues/38
if defined?(JRUBY_VERSION)
  module Loofah::ScrubBehavior::Node
    def scrub_with_jruby!(scrubber)
      return self if Nokogiri::XML::DocumentFragment === self and children.empty?
      scrub_without_jruby!(scrubber)
    end
    alias_method_chain :scrub!, :jruby
  end
end

