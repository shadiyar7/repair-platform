class Product < ApplicationRecord
  serialize :characteristics, coder: JSON
end
