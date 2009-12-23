module ActiveRecord
  module ArEnumerations

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods

      def enumeration_for(name, values, options = { :single => false })
        enumeration_attribute(name, values, options[:single])
      end
      
      def enumeration_attribute_options(name)
        enumeration_attributes = read_inheritable_attribute(:enumeration_attributes) || {}
        if enumeration_attributes.include?(name)
          enumeration_attributes[name]
        else
          raise ArgumentError, "Could not find enumeration attribute `#{name}` in class #{self.class.name}"
        end
      end      

    protected
    
      def enumeration_accessors(name)
        class_eval <<-EOE
          def #{name}; enumeration_read(:#{name}); end
          def #{name}=(new_value); enumeration_write(:#{name}, new_value); end
        EOE
      end

      def enumeration_attribute(name, values, single)
        enumeration_attributes = read_inheritable_attribute(:enumeration_attributes) || {}
        options = {}
        options[:values] = values
        options[:single] = single
        enumeration_attributes[name] = options
        write_inheritable_attribute(:enumeration_attributes, enumeration_attributes)
        enumeration_accessors(name)
      end

    end

    module InstanceMethods

      def enumeration_read(name)
        attribute_options = self.class.enumeration_attribute_options(name)
        unless self[name].nil?
          result = attribute_options[:values].reject { |r| ((self[name] || 0) & 2**attribute_options[:values].index(r)).zero? }  
          if attribute_options[:single]
            result.first 
          else
            result
          end
        else
          nil
        end
      end

      def enumeration_write(name, new_value)
        attribute_options = self.class.enumeration_attribute_options(name)
        value = new_value.is_a?(Array) ? new_value.map(&:to_s) : [new_value].map(&:to_s)
        self[name] = (value & attribute_options[:values]).map { |r| 2**attribute_options[:values].index(r) }.sum
        new_value
      end
      
      def enumeration_options(name)
        attribute_options = self.class.enumeration_attribute_options(name)
        attribute_options[:values]
      end

    end
  end
end
