module Api
  module V1
    class CompanyRequisitesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_company_requisite, only: [:show, :update, :destroy]

      # GET /api/v1/company_requisites
      def index
        @company_requisites = current_user.company_requisites
        render json: CompanyRequisiteSerializer.new(@company_requisites).serializable_hash
      end

      # GET /api/v1/company_requisites/:id
      def show
        render json: CompanyRequisiteSerializer.new(@company_requisite).serializable_hash
      end

      # POST /api/v1/company_requisites
      def create
        @company_requisite = current_user.company_requisites.build(company_requisite_params)

        if @company_requisite.save
          render json: CompanyRequisiteSerializer.new(@company_requisite).serializable_hash, status: :created
        else
          render json: @company_requisite.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/company_requisites/:id
      def update
        if @company_requisite.update(company_requisite_params)
          render json: CompanyRequisiteSerializer.new(@company_requisite).serializable_hash
        else
          render json: @company_requisite.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/company_requisites/:id
      def destroy
        @company_requisite.destroy
        head :no_content
      end

      private

      def set_company_requisite
        @company_requisite = current_user.company_requisites.find(params[:id])
      end

      def company_requisite_params
        params.require(:company_requisite).permit(
          :company_name, :bin, :legal_address, :actual_address, 
          :director_name, :acting_on_basis, :inn, 
          :iban, :swift, :kbe, :bank_name
        )
      end
    end
  end
end
