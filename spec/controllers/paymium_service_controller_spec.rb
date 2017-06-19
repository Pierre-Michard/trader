require 'rails_helper'

RSpec.describe PaymiumServiceController, type: :controller do

  describe "GET #sdepth" do
    it "returns http success" do
      get :sdepth
      expect(response).to have_http_status(:success)
    end
  end

end
