# frozen_string_literal: true

module HanamiAuthApp
  module Actions
    module API
      module Accounts
        class Login < HanamiAuthApp::Action
          def handle(request, response)
            body = JSON.parse(request.body.read)
            use_case = Usecases::Account::Login.new(
              HanamiAuthApp::App.container.resolve(:account_repository)
            )

            result = use_case.call(
              email: body["email"],
              password: body["password"]
            )

            if result.success?
              response.status = 200
              response.body = JSON.generate(
                status: "success",
                token: result.value[:token],
                account: {
                  id: result.value[:account].id,
                  email: result.value[:account].email
                }
              )
            else
              response.status = 401
              response.body = JSON.generate(
                status: "error",
                message: result.error
              )
            end
          end
        end
      end
    end
  end
end
