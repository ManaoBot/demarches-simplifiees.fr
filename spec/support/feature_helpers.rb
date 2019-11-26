module FeatureHelpers
  include ActiveJob::TestHelper

  def login_admin
    user = create :user
    login_as user, scope: :user
    user
  end

  def login_instructeur
    instructeur = create(:instructeur)
    login_as instructeur, scope: :instructeur
  end

  def create_dossier
    dossier = FactoryBot.create(:dossier)
    dossier
  end

  def sign_in_with(email, password, sign_in_by_link = false)
    fill_in :user_email, with: email
    fill_in :user_password, with: password

    if sign_in_by_link
      Flipper.disable(:instructeur_bypass_email_login_token)
    end

    perform_enqueued_jobs do
      click_on 'Se connecter'
    end

    if sign_in_by_link
      mail = ActionMailer::Base.deliveries.last
      message = mail.html_part.body.raw_source
      instructeur_id = message[/\".+\/connexion-par-jeton\/(.+)\?jeton=(.*)\"/, 1]
      jeton = message[/\".+\/connexion-par-jeton\/(.+)\?jeton=(.*)\"/, 2]

      visit sign_in_by_link_path(instructeur_id, jeton: jeton)
    end
  end

  def sign_up_with(email, password = 'démarches-simplifiées-pwd')
    fill_in :user_email, with: email
    fill_in :user_password, with: password

    perform_enqueued_jobs do
      click_button 'Créer un compte'
    end
  end

  def click_confirmation_link_for(email)
    confirmation_email = open_email(email)
    token_params = confirmation_email.body.match(/confirmation_token=[^"]+/)

    visit "/users/confirmation?#{token_params}"
  end

  def click_reset_password_link_for(email)
    reset_password_email = open_email(email)
    token_params = reset_password_email.body.match(/reset_password_token=[^"]+/)

    visit "/users/password/edit?#{token_params}"
  end

  def blur
    page.find('body').click
  end

  def pause
    $stderr.write 'Spec paused. Press enter to continue:'
    $stdin.gets
  end

  def wait_until
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep(0.1) until (value = yield)
      value
    end
  end

  # Keep the brower window open after a test success of failure, to
  # allow inspecting the page or the console.
  #
  # Usage:
  #  1. Disable the 'headless' mode in `spec_helper.rb`
  #  2. Call `leave_browser_open` at the beginning of your scenario
  def leave_browser_open
    Selenium::WebDriver::Chrome::Service.class_eval do
      def stop
        STDOUT.puts "#{self.class}#stop is a no-op, because leave_browser_open is enabled"
      end
    end

    Selenium::WebDriver::Driver.class_eval do
      def quit
        STDOUT.puts "#{self.class}#quit is a no-op, because leave_browser_open is enabled"
      end
    end

    Capybara::Selenium::Driver.class_eval do
      def reset!
        STDOUT.puts "#{self.class}#reset! is a no-op, because leave_browser_open is enabled"
      end
    end
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
