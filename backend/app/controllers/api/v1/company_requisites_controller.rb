module Api
  module V1
    class CompanyRequisitesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_company_requisite, only: [:show, :update, :destroy]

      # GET /api/v1/company_requisites
      def index
        @company_requisites = current_user.company_requisites.where(is_active: true)
        render json: CompanyRequisiteSerializer.new(@company_requisites).serializable_hash
      end

      # GET /api/v1/company_requisites/:id
      def show
        render json: CompanyRequisiteSerializer.new(@company_requisite).serializable_hash
      end

      # POST /api/v1/company_requisites
      def create
        @company_requisite = current_user.company_requisites.build(company_requisite_params)
        
        # Auto-fill company details from User profile if not provided
        # This allows Frontend to only send bank details
        @company_requisite.company_name = current_user.company_name if @company_requisite.company_name.blank?
        @company_requisite.bin = current_user.bin if @company_requisite.bin.blank?
        @company_requisite.inn = current_user.inn if @company_requisite.inn.blank?
        @company_requisite.director_name = current_user.director_name if @company_requisite.director_name.blank?
        @company_requisite.acting_on_basis = current_user.acting_on_basis if @company_requisite.acting_on_basis.blank?
        @company_requisite.legal_address = current_user.legal_address if @company_requisite.legal_address.blank?
        @company_requisite.actual_address = current_user.actual_address if @company_requisite.actual_address.blank?

        if @company_requisite.save
          render json: CompanyRequisiteSerializer.new(@company_requisite).serializable_hash, status: :created
        else
          render json: @company_requisite.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/company_requisites/:id
      def update
        if order_exists?(@company_requisite)
          # Soft delete the old one and create a new one to preserve history
          @company_requisite.update!(is_active: false)
          
          # Clone the attributes and merge with new ones
          new_attributes = @company_requisite.attributes.except('id', 'created_at', 'updated_at').merge(company_requisite_params.to_h)
          new_attributes['is_active'] = true
          
          # Auto-sync with latest user profile if not provided in params
          new_attributes['company_name'] = current_user.company_name if company_requisite_params[:company_name].blank?
          new_attributes['bin'] = current_user.bin if company_requisite_params[:bin].blank?
          new_attributes['inn'] = current_user.inn if company_requisite_params[:inn].blank?
          new_attributes['director_name'] = current_user.director_name if company_requisite_params[:director_name].blank?
          new_attributes['acting_on_basis'] = current_user.acting_on_basis if company_requisite_params[:acting_on_basis].blank?
          new_attributes['legal_address'] = current_user.legal_address if company_requisite_params[:legal_address].blank?
          new_attributes['actual_address'] = current_user.actual_address if company_requisite_params[:actual_address].blank?

          @new_company_requisite = current_user.company_requisites.build(new_attributes)
          
          if @new_company_requisite.save
            render json: CompanyRequisiteSerializer.new(@new_company_requisite).serializable_hash
          else
            # Rollback the soft-delete if save fails
            @company_requisite.update!(is_active: true)
            render json: @new_company_requisite.errors, status: :unprocessable_entity
          end
        else
          # Safe to update in-place
          attrs_to_update = company_requisite_params.to_h
          attrs_to_update['company_name'] = current_user.company_name if attrs_to_update['company_name'].blank?
          attrs_to_update['bin'] = current_user.bin if attrs_to_update['bin'].blank?
          attrs_to_update['inn'] = current_user.inn if attrs_to_update['inn'].blank?
          attrs_to_update['director_name'] = current_user.director_name if attrs_to_update['director_name'].blank?
          attrs_to_update['acting_on_basis'] = current_user.acting_on_basis if attrs_to_update['acting_on_basis'].blank?
          attrs_to_update['legal_address'] = current_user.legal_address if attrs_to_update['legal_address'].blank?
          attrs_to_update['actual_address'] = current_user.actual_address if attrs_to_update['actual_address'].blank?

          if @company_requisite.update(attrs_to_update)
            render json: CompanyRequisiteSerializer.new(@company_requisite).serializable_hash
          else
            render json: @company_requisite.errors, status: :unprocessable_entity
          end
        end
      end

      # DELETE /api/v1/company_requisites/:id
      def destroy
        if order_exists?(@company_requisite)
          @company_requisite.update!(is_active: false)
        else
          @company_requisite.destroy
        end
        head :no_content
      end

      private

      def order_exists?(company_requisite)
        Order.exists?(company_requisite_id: company_requisite.id)
      end

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
