require 'hamlit/hamlit'
require 'hamlit/object_ref'
require 'hamlit/utils'

module Hamlit::AttributeBuilder
  BOOLEAN_ATTRIBUTES = %w[disabled readonly multiple checked autobuffer
                       autoplay controls loop selected hidden scoped async
                       defer reversed ismap seamless muted required
                       autofocus novalidate formnovalidate open pubdate
                       itemscope allowfullscreen default inert sortable
                       truespeed typemustmatch].freeze

  # NOTE: Since this module is used on runtime, its methods are designed to be
  # class methods which takes all options as arguments for performance.
  class << self
    def build(escape_attrs, quote, format, object_ref, *hashes)
      buf    = []
      hashes = hashes.map { |h| stringify_keys(h) }
      hashes << Hamlit::ObjectRef.parse(object_ref) if object_ref

      keys = hashes.map(&:keys).flatten.sort.uniq
      keys.each do |key|
        values = hashes.map { |h| h[key] }.compact
        case key
        when 'id'.freeze
          buf << " id=#{quote}#{build_id(escape_attrs, *values)}#{quote}"
        when 'class'.freeze
          buf << " class=#{quote}#{build_class(escape_attrs, *values)}#{quote}"
        when 'data'.freeze
          buf << build_data(escape_attrs, quote, *values)
        when *BOOLEAN_ATTRIBUTES, /\Adata-/
          build_boolean!(escape_attrs, quote, format, buf, key, values)
        else
          buf << " #{key}=#{quote}#{escape_html(escape_attrs, values.first.to_s)}#{quote}"
        end
      end
      buf.join
    end

    def build_data(escape_attrs, quote, *hashes)
      attrs = []
      if hashes.size > 1
        hash = merge_hashes(hashes)
      else
        hash = hashes.first
      end
      hash = flatten_attributes(data: hash)

      hash.sort_by(&:first).each do |key, value|
        case value
        when true
          attrs << " #{key}"
        when nil, false
          # noop
        else
          attrs << " #{key}=#{quote}#{escape_html(escape_attrs, value.to_s)}#{quote}"
        end
      end
      attrs.join
    end

    private

    def merge_hashes(hashes)
      merged = {}
      hashes.each do |hash|
        hash.each do |h, k|
          merged[h] = k
        end
      end
      merged
    end

    def flatten_attributes(attributes)
      flattened = {}

      attributes.each do |key, value|
        case value
        when attributes
        when Hash
          flatten_attributes(value).each do |k, v|
            if k
              flattened["#{key}-#{k.to_s.gsub(/_/, '-')}"] = v
            else
              flattened[key] = v
            end
          end
        else
          flattened[key] = value if value
        end
      end
      flattened
    end

    def stringify_keys(hash)
      result = {}
      hash.each do |key, value|
        result[key.to_s] = value
      end
      result
    end

    def build_boolean!(escape_attrs, quote, format, buf, key, values)
      value = values.last
      case value
      when true
        case format
        when :xhtml
          buf << " #{key}=#{quote}#{key}#{quote}"
        else
          buf << " #{key}"
        end
      when false, nil
        # omitted
      else
        buf << " #{key}=#{quote}#{escape_html(escape_attrs, value)}#{quote}"
      end
    end

    def escape_html(escape_attrs, str)
      if escape_attrs
        Hamlit::Utils.escape_html(str)
      else
        str
      end
    end
  end
end
