class Api::V1::ProductsController < ApplicationController
  def index
    products = Product.all
    render json: ProductSerializer.new(products).serializable_hash
  end

  def show
    product = Product.find(params[:id])
    render json: ProductSerializer.new(product).serializable_hash
  end
end
