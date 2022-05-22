# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token
  # before_action :configure_sign_in_params, only: [:create]
  # before_filter :restrict_access, only: [:aws_auth]

  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    super
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  end

  def aws_auth
    defaults = {
      id: nil,
      first_name: nil,
      last_name: nil,
      email: nil,
      authentication_hash: nil
    }
    user = User.where(email: params[:email]).first

    if user
      answer = user.as_json(only: defaults.keys)
      answer[:user_exists] = true
      answer[:success] = user.valid_password?(params[:password])
    else
      answer = defaults
      answer[:success] = false
      answer[:user_exists] = false
    end

    respond_to do |format|
      format.json { render json: answer }
    end
  end

  # (...)
  private def restrict_access
    head :unauthorized unless params[:access_token] == TOKEN_AUTH_OF_YOUR_CHOICE
  end
end
