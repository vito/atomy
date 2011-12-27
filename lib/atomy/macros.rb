module Atomy::Macro
  class Environment
    @@salt = 0

    class << self
      def salt
        @@salt
      end

      def salt!(n = 1)
        @@salt += n
      end
    end
  end
end
