require 'liquid'

module Word
  module IfElseReplacers
    class Base
      attr_accessor :main_doc, :data, :options
      def initialize(main_doc, data, options = {})
        self.main_doc = main_doc
        self.data = data
        self.options = options
      end

      def evaluate_if(placeholder)
        expression = parse_if_else_placeholder(placeholder)[:expression]
        evaluate_expression(expression)
      end

      def parse_if_else_placeholder(placeholder)
        result = placeholder.gsub('{%','').gsub('%}','').match(/if (.+)/)
        expression = result[1].strip.gsub(/[“”]/, "\"") if !result.nil?
        raise "Invalid syntax for if placeholder #{placeholder}" if result.blank? || expression.blank?
        {expression: expression}
      end

      def evaluate_expression(expression)
        expression = expression.gsub(/\s=\s/," == ")
        expression = expression.gsub(/!(?<word>[\w\.]+)/,'\k<word> == null')
        expression = expression.gsub(/\sincludes\s/, ' contains ')

        liquid_if = ::Liquid::If.send(:new,'if',expression,{})
        condition = liquid_if.instance_variable_get("@blocks").first
        context = Liquid::Context.new(sanitize_data(data))
        result = condition.evaluate(context)
        result != false && result.present?
      end

      def sanitize_data(hash)
        hash.each do |k, v|
          if v.is_a?(Hash)
            hash[k] = sanitize_data(v)
          elsif v.is_a?(Array)
            hash[k] = v.map(&:presence)
          else
            hash[k] = v.presence
          end
        end
        hash
      end

    end
  end
end
