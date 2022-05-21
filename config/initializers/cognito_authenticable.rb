require 'aws-sdk'
require 'devise/strategies/authenticatable'

# This strategy will create a new local user if Cognito authenticated it, but the user doesn’t exist locally.
module Devise
  module Strategies
    class CognitoAuthenticatable < Authenticatable
      def authenticate!
        if params[:user]

          client = Aws::CognitoIdentityProvider::Client.new

          begin

            # Try to authenticate by email and password
            resp = client.initiate_auth({
              client_id: ENV["AWS_COGNITO_CLIENT_ID"],
              auth_flow: "USER_PASSWORD_AUTH",
              auth_parameters: {
                "USERNAME" => email,
                "PASSWORD" => password
              }
            })

            if resp
              # Find the current user from DB
              user = User.where(email: email).try(:first)
              if user
                success!(user)
              else
                # Failed to find that email, create new email and password
                user = User.create(email: email, password: password, password_confirmation: password)
                if user.valid?
                  success!(user)
                else
                  return fail(:failed_to_create_user)
                end
              end
            else
              return fail(:unknow_cognito_response)
            end

          rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException => e
            return fail(:invalid_login)
          rescue
            return fail(:unknow_cognito_error)
          end
        end
      end

      def email
        params[:user][:email]
      end

      def password
        params[:user][:password]
      end

    end
  end
end