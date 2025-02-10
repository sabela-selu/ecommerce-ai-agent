# frozen_string_literal: true

class OrderManagement
  extend Langchain::ToolDefinition

  define_function :create_order, description: "Order Management Service: Create a new order" do
    property :customer_id, type: "number", description: "Customer ID", required: true
    property :order_items, type: "array", description: "List of order items that each contain 'sku' and 'quantity' properties", required: true do
      property :items, type: "object", description: "Order item" do
        property :sku, type: "string", description: "Product SKU", required: true
        property :quantity, type: "number", description: "Quantity of the product", required: true
      end
    end
    property :amount, type: "number", description: "Total amount (USD) of the order", required: true
  end

  define_function :mark_as_refunded, description: "Order Management Service: Mark order as refunded" do
    property :order_id, type: "string", description: "Order ID", required: true
  end

  define_function :find_order, description: "Order Management Service: Find order by ID" do
    property :order_id, type: "string", description: "Order ID", required: true
  end

  def create_order(customer_id:, amount:, order_items: [])
    Langchain.logger.info("[ 📦 ] Creating Order record for customer ID: #{customer_id}")

    return "Order items cannot be empty" if order_items.empty?

    order = Order.create(
      customer_id: customer_id,
      created_at: Time.now,
      amount: amount
    )

    return "Order not found" if order.nil?

    order_items.each do |item|
      OrderItem.create(order_id: order.id, sku: item[:sku], quantity: item[:quantity])
    end

    { success: true, order_id: order.id }
  end

  def mark_as_refunded(order_id:)
    Langchain.logger.info("[ 📦 ] Refunding order ID: #{order_id}")

    order = Order.find(id: order_id)

    return "Order not found" if order.nil?

    { success: !!order.destroy }
  end

  def find_order(order_id:)
    Langchain.logger.info("[ 📦 ] Looking up Order record for ID: #{order_id}")

    order = Order.find(id: order_id)

    return "Order not found" if order.nil?

    { order: order.to_hash.merge(order_items: order.order_items.map(&:to_hash)) }
  end
end