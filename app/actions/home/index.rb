# frozen_string_literal: true

module HanamiAuthApp
  module Actions
    module Home
      class Index < HanamiAuthApp::Action
        include Hanami::Action::Session

        def handle(request, response)
          account_id = request.session[:account_id]
          if account_id
            response.body = "<h1>Welcome!</h1><p>Logged in as account ##{account_id}</p><a href='/logout'>Logout</a>"
          else
            response.body = "<h1>Welcome!</h1><p>Not logged in.</p><a href='/login'>Login</a> | <a href='/create-account'>Register</a>"
          end
        end
      end
    end
  end
end
