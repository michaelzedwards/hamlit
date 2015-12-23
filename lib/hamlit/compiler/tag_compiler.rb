require 'hamlit/parser/haml_util'
require 'hamlit/attribute_compiler'
require 'hamlit/static_analyzer'
require 'hamlit/string_splitter'

module Hamlit
  class Compiler
    class TagCompiler
      def initialize(identity, options)
        @autoclose = options[:autoclose]
        @identity  = identity
        @attribute_compiler = AttributeCompiler.new(identity, options)
      end

      def compile(node, &block)
        attrs    = @attribute_compiler.compile(node)
        contents = compile_contents(node, &block)
        [:html, :tag, node.value[:name], attrs, contents]
      end

      private

      def compile_contents(node, &block)
        case
        when !node.children.empty?
          yield(node)
        when node.value[:value].nil? && self_closing?(node)
          nil
        when node.value[:parse]
          return compile_string(node) if node.value[:escape_interpolation]
          if RubyExpression.string_literal?(node.value[:value]) || StaticAnalyzer.static?(node.value[:value])
            # Optimized in other filters: StringSplitter or StaticAnalyzer
            return [:escape, node.value[:escape_html], [:dynamic, node.value[:value]]]
          end

          var = @identity.generate
          [:multi,
           [:code, "#{var} = (#{node.value[:value]}"],
           [:newline],
           [:code, ')'.freeze],
           [:escape, node.value[:escape_html], [:dynamic, var]]
          ]
        else
          [:static, node.value[:value]]
        end
      end

      # We should handle interpolation here to escape only interpolated values.
      def compile_string(node)
        temple = [:multi]
        StringSplitter.compile(node.value[:value]).each do |type, value|
          case type
          when :static
            value = Hamlit::Utils.escape_html(value) if node.value[:escape_html]
            temple << [:static, value]
          when :dynamic
            temple << [:escape, node.value[:escape_html] || node.value[:escape_interpolation], [:dynamic, value]]
          end
        end
        temple << [:newline]
      end

      def self_closing?(node)
        return true if @autoclose && @autoclose.include?(node.value[:name])
        node.value[:self_closing]
      end
    end
  end
end
