# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :assert_reset_token_passed
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # Allow password reset using the password recovery system of AWS Cognito.
  # In this case, the sign up procedure is still handled by Rails on the local database (see below),
  # therefore account confirmation (with Devise’s :confirmable  module) is handled by Devise without any changes.
  def create
    raise ArgumentError, "Unexpected block given for requested action: #{params.inspect}" if block_given?

    begin
      client = Aws::CognitoIdentityProvider::Client.new
      resp = client.forgot_password({
        client_id: ENV["AWS_COGNITO_CLIENT_ID"],
        username: params[:user][:email]
      })

      session[:reset_password_email] = params[:user][:email]
      redirect_to edit_user_password_path
    rescue
      flash[:alert] = I18n.t("devise.errors.unknown_error")
      redirect_to new_user_password_path
    end
  end

  def edit
    gon.flash_notice = I18n.t("devise.notices.change_password_email")
    super
  end

  def update
    if params[:user][:password].blank?
      flash[:alert] = I18n.t("activerecord.errors.models.user.attributes.password.blank")
      redirect_to edit_user_password_path(reset_password_token: params[:user][:reset_password_token])
    elsif params[:user][:password] != params[:user][:password_confirmation]
      flash[:alert] = I18n.t("activerecord.errors.models.user.attributes.password.mismatch")
      redirect_to edit_user_password_path(reset_password_token: params[:user][:reset_password_token])
    elsif params[:user][:reset_password_token].blank?
      flash[:alert] = I18n.t("devise.errors.verification_code_missing")
      redirect_to edit_user_password_path(reset_password_token: params[:user][:reset_password_token])
    elsif session[:reset_password_email].nil?
      flash[:alert] = I18n.t("devise.errors.verification_code_expired")
      redirect_to new_user_password_path
    else
      begin
        client = Aws::CognitoIdentityProvider::Client.new
        resp = client.confirm_forgot_password({
          client_id: ENV["AWS_COGNITO_CLIENT_ID"],
          confirmation_code: params[:user][:reset_password_token],
          username: session[:reset_password_email],
          password: params[:user][:password]
        })

        session.delete :reset_password_email
        redirect_to unauthenticated_root_path, notice: I18n.t("devise.notices.password_changed")

      rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
        flash[:alert] = e.to_s
        redirect_to edit_user_password_path(reset_password_token: params[:user][:reset_password_token])
      rescue
        flash[:alert] = I18n.t("devise.errors.unknown_error")
        redirect_to edit_user_password_path(reset_password_token: params[:user][:reset_password_token])
      end
    end
  end
end
