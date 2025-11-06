# Sample data for testing the Invoice & Payment system

puts "🌱 Seeding database..."

# Clear existing data
Payment.destroy_all
Invoice.destroy_all

# Create sample invoices
invoice1 = Invoice.create!(invoice_total: 500.00)
invoice1.record_payment(250.00, :cash)
invoice1.record_payment(250.00, :charge)
puts "✅ Created fully paid invoice ##{invoice1.id} for $500.00"

invoice2 = Invoice.create!(invoice_total: 1000.00)
invoice2.record_payment(600.00, :check)
puts "✅ Created partially paid invoice ##{invoice2.id} for $1000.00 (owes $#{invoice2.amount_owed})"

invoice3 = Invoice.create!(invoice_total: 150.00)
puts "✅ Created unpaid invoice ##{invoice3.id} for $150.00"

invoice4 = Invoice.create!(invoice_total: 750.00)
invoice4.record_payment(250.00, :cash)
invoice4.record_payment(250.00, :check)
invoice4.record_payment(250.00, :charge)
puts "✅ Created fully paid invoice ##{invoice4.id} with multiple payments"

puts ""
puts "📊 Summary:"
puts "  Total Invoices: #{Invoice.count}"
puts "  Total Payments: #{Payment.count}"
puts "  Fully Paid: #{Invoice.all.count { |i| i.fully_paid? }}"
puts "  Partially Paid: #{Invoice.all.count { |i| !i.fully_paid? && i.payments.any? }}"
puts "  Unpaid: #{Invoice.all.count { |i| i.payments.empty? }}"
puts ""
puts "✅ Seeding complete!"
