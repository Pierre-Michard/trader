require 'rails_helper'

RSpec.describe StatsController, type: :controller do

  describe "GET #balance" do
    it "returns http success" do
      get :balance
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #marge" do
    it "returns http success" do
      get :marge
      expect(response).to have_http_status(:success)
    end
  end

end
