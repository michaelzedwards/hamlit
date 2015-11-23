require 'ripper'

module Hamlit
  class RubyExpression < Ripper
    class ParseError < StandardError; end

    def self.syntax_error?(code)
      self.new(code).parse
      false
    rescue ParseError
      true
    end

    def self.string_literal?(code)
      return false if syntax_error?(code)

      type, instructions = Ripper.sexp(code)
      return false if type != :program
      return false if instructions.size > 1

      type, _ = instructions.first
      type == :string_literal
    end

    def self.strip_comment(code)
      code = code.strip
      return code if syntax_error?(code)

      tokens = Ripper.lex(code)
      while tokens.last && %i[on_comment on_sp].include?(tokens.last[1])
        _, _, str = tokens.pop
        code.sub!(/#{str}\z/, '')
      end
      code
    end

    private

    def on_parse_error(*)
      raise ParseError
    end
  end
end
