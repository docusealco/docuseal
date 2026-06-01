# frozen_string_literal: true

class Pagy
  module I18n
    module P11n
      path = ROOT.join('lib/pagy/modules/i18n/p11n')
      autoload :Arabic,          path.join('arabic')
      autoload :EastSlavic,      path.join('east_slavic')
      autoload :OneOther,        path.join('one_other')
      autoload :OneUptoTwoOther, path.join('one_upto_two_other')
      autoload :Other,           path.join('other')
      autoload :Polish,          path.join('polish')
      autoload :WestSlavic,      path.join('west_slavic')
    end
  end
end
