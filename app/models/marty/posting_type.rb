class Marty::PostingType < Marty::Base
  extend Marty::Enum

  validates_presence_of :name
  validates_uniqueness_of :name

  delorean_fn :lookup, sig: 1 do
    |name|
    self.find_by_name(name)
  end

  def self.seed
    ['BASE', 'CLOSE', 'INTRA', 'RULE'].each { |type|
      create name: type
    }
  end
end
