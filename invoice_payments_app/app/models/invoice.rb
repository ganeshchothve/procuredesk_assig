class Invoice < ApplicationRecord
  CENTS_PER_DOLLAR = 100

  has_many :payments, dependent: :destroy

  validates :invoice_total, presence: true, numericality: { greater_than: 0 }
  before_validation :convert_invoice_total_to_cents, if: :invoice_total_changed?

  def fully_paid?
    amount_owed <= 0
  end

  def amount_owed
    to_dollars(invoice_total - payments.sum(:amount))
  end

  def record_payment(amount_paid, payment_method)
    return false unless amount_paid.positive?

    result = transaction do
      # Pessimistic lock to prevent concurrent payment race conditions
      lock!

      # Recalculate amount owed with locked record
      current_amount_owed = to_dollars(invoice_total - payments.sum(:amount))
      amount_in_cents = to_cents(amount_paid)

      # Prevent overpayment
      if amount_in_cents > (invoice_total - payments.sum(:amount))
        errors.add(:base, "Payment amount ($#{amount_paid}) exceeds amount owed ($#{current_amount_owed})")
        raise ActiveRecord::Rollback
      end

      payment = payments.create!(amount: amount_in_cents, raw_payment_method: payment_method)
      payment
    end

    result || false
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.record.errors.full_messages.join(", "))
    false
  end

  private

  def to_cents(dollars)
    (dollars.to_f * CENTS_PER_DOLLAR).round
  end

  def to_dollars(cents)
    (cents.to_f / CENTS_PER_DOLLAR).round(2)
  end

  def convert_invoice_total_to_cents
    # Always convert if the value looks like dollars (not already in cents range)
    if invoice_total && invoice_total < 10000  # Assume values under 10000 are in dollars
      self.invoice_total = to_cents(invoice_total)
    end
  end
end
