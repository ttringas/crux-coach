require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with required attributes" do
    user = build(:user)
    expect(user).to be_valid
  end

  it "requires an email" do
    user = build(:user, email: nil)
    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "requires a unique email" do
    create(:user, email: "taken@example.com")
    user = build(:user, email: "taken@example.com")
    expect(user).not_to be_valid
  end

  it "requires a role" do
    user = build(:user, role: nil)
    expect(user).not_to be_valid
    expect(user.errors[:role]).to be_present
  end

  it "normalizes email to lowercase and stripped" do
    user = create(:user, email: "  FOO@Bar.COM  ")
    expect(user.email).to eq("foo@bar.com")
  end

  it "does not require a password" do
    user = build(:user, password: nil)
    expect(user.password_required?).to be false
  end

  describe "roles" do
    it "supports climber, coach, and admin roles" do
      expect(User.roles.keys).to contain_exactly("climber", "coach", "admin")
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:climber_profile).dependent(:destroy) }
    it { is_expected.to have_one(:coach).dependent(:destroy) }
    it { is_expected.to have_many(:ai_interactions).dependent(:destroy) }
  end
end
