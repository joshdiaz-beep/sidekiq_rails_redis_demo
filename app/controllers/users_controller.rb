class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # This is the key line for this demo. Instead of sending the
      # welcome email synchronously (which would block this HTTP
      # request until the email provider responds), we hand the
      # work off to Sidekiq. Rails serializes the arguments,
      # pushes a job payload into Redis, and returns immediately.
      WelcomeEmailJob.perform_later(@user.id)

      redirect_to users_path, notice: "User created! A welcome email job was enqueued for #{@user.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @users = User.order(created_at: :desc)
  end

  private

  def user_params
    params.require(:user).permit(:email)
  end
end
