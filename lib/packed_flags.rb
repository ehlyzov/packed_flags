module EX

  module PackedFlags

    module SingletonMethods

      def get_flags_stamp(*flags)
        flags.map {|flag| "#{self.to_s}::#{flag.to_s.upcase}".constantize}.inject(0) {|stamp, flag| stamp | flag}
      end

      def define_flag(flag)
        upcased_flag = flag.to_s.upcase
        if constants.include?(upcased_flag)
          raise ExistedFlagError
        else
          class_eval {
            has_flags_code = lambda { has_flags?(flag) }
            define_method(flag.to_s + '?', has_flags_code)
            define_method(flag.to_s, has_flags_code)
            define_method(flag.to_s + '=') { |value| (value.to_i > 0) ? add_flags(flag) : remove_flags(flag) }
          }
          const_set(upcased_flag, 2**read_inheritable_attribute(:flags_count))
          write_inheritable_attribute :flags_count, read_inheritable_attribute(:flags_count) + 1
        end
      end

      def set_flags_column(column)
        raise ArgumentError, "Unknown column" unless column_names.include?(column.to_s)
        write_inheritable_attribute :flags_column, column
      end

      def flags_column
        read_inheritable_attribute(:flags_column)
      end

      def flags_count
        read_inheritable_attribute(:flags_count)
      end
    end

    module ClassMethods
      def serialize_flags(column, *flags)

        extend EX::PackedFlags::SingletonMethods
        include EX::PackedFlags::InstanceMethods

        self.class_eval do
          write_inheritable_attribute :flags_count, 0
          write_inheritable_attribute :flags_column, 'flags'
          class_inheritable_reader :flags_column
          class_inheritable_reader :flags_count
        end

        named_scope :by_flags, lambda {|*flags| { :conditions => "(#{self.table_name}.#{read_inheritable_attribute(:flags_column)} | #{get_flags_stamp(*flags)}) > 0"}}

        set_flags_column(column)
        flags.each {|flag| define_flag(flag) }
      end

    end

    module InstanceMethods
      def get_flags_stamp(*flags)
        self.class.get_flags_stamp(*flags)
      end

      def has_flags?(*flags)
        (flags_stamp & get_flags_stamp(*flags)) > 0
      end

      def add_flags(*flags)
        self.flags_stamp = (get_flags_stamp(*flags) | flags_stamp)
      end

      def remove_flags(*flags)
        stamp = get_flags_stamp(*flags)
        self.flags_stamp = ((2**(Math.log(flags_stamp)/Math.log(2)).ceil - stamp - 1) & flags_stamp)
      end

      def set_flags(*flags)
        self.flags_stamp=get_flags_stamp(*flags)
      end

      def drop_flags
        self.flags_stamp = 0
      end

      def flags_stamp=(stamp)
        update_attribute(self.class.flags_column, stamp)
      end

      def flags_stamp
        read_attribute(self.class.flags_column)
      end

    end
  end
end
