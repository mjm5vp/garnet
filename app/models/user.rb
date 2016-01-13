class User < ActiveRecord::Base
  validates :username, presence: true, uniqueness: true, format: {with: /\A[a-zA-Z0-9\-_]+\z/, message: "Only letters, numbers, hyphens, and underscores are allowed."}
  validates :github_id, allow_blank: true, uniqueness: true
  validate :validates_name_if_no_github_id

  has_many :memberships, dependent: :destroy
  has_many :cohorts, through: :memberships

  has_many :observations, through: :memberships
  has_many :admin_observations, class_name: "Observation", foreign_key: "admin_id"

  has_many :submissions, through: :memberships
  has_many :admin_submissions, class_name: "Submission", foreign_key: "admin_id"
  has_many :assignments, through: :submissions

  has_many :attendances, through: :memberships
  has_many :admin_attendances, class_name: "Attendance", foreign_key: "admin_id"
  has_many :events, through: :attendances

  before_save :downcase_username, :dont_update_blank_password
  attr_accessor :password

  def downcase_username
    self.username.downcase!
  end

  def validates_name_if_no_github_id
    if !self.github_id && self.name.strip.blank?
      errors[:base].push("Please include your full name!")
    end
  end

  def dont_update_blank_password
    if self.password && !self.password.strip.blank?
      self.password_digest = User.new_password(self.password)
    end
  end

  def to_param
    "#{self.username}"
  end

  def self.named username
    User.find_by(username: username)
  end

  def name
    read_attribute(:name) || self.username
  end

  def gh_url
    "https://www.github.com/#{self.username}" if self.github_id
  end

  def first_name
    return self.username.capitalize unless name.present?
    name.split.first.capitalize
  end

  def last_name
    return self.username.capitalize unless name.present?
    name.split.last.capitalize
  end

  def self.new_password password
    BCrypt::Password.create(password)
  end

  def password_ok? password
    BCrypt::Password.new(self.password_digest).is_password?(password)
  end

  def owned_cohorts
    @owned_cohorts ||= self.memberships.where(is_owner: true).collect(&:cohort)
  end
  alias_method :adminned_cohorts, :owned_cohorts

  # TODO: reimplement using tags -ab
  # def priority_cohorts
  #   @priority_cohorts ||= self.memberships.where(is_owner: true, is_priority: true).collect(&:cohort)
  # end

  def cohorts_adminned_by user
    self.cohorts & user.adminned_cohorts
  end

  def records_accessible_by user, attribute_name
    records = self.send(attribute_name)
    my_cohorts = records.collect(&:cohort).uniq
    common_cohorts = my_cohorts & user.adminned_cohorts
    return records.select{|r| common_cohorts.include?(r.cohort)}
  end

  def is_admin_of_anything?
    self.memberships.exists?(is_owner: true)
  end

  # TODO: Optimize and remove inactive students memberships
  def get_due model_name
    records = adminned_cohorts.map(&:memberships).flatten.collect{|m| m.send(model_name).where(status: nil)}.flatten.uniq
    records.select!{|r| adminned_cohorts.include?(r.cohort)}
    if self.is_a? Submission
      records.select!{|r| r.assignment.due_date <= DateTime.now}
    end
    return records
  end

  def is_member_of cohort
    cohort.memberships.exists?(user: self)
  end

end
