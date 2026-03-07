# ============================================================
# DynamoDB Table - Visitor Counter
# ============================================================

resource "aws_dynamodb_table" "visitor_counter" {
  name         = "${var.project_name}-visitor-counter"
  billing_mode = "PAY_PER_REQUEST" # Serverless, scales to zero cost
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Enable server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-visitor-counter"
  })
}

# Seed the counter with initial value
resource "aws_dynamodb_table_item" "visitor_count_seed" {
  table_name = aws_dynamodb_table.visitor_counter.name
  hash_key   = aws_dynamodb_table.visitor_counter.hash_key

  item = <<ITEM
{
  "id": {"S": "visitor_count"},
  "visit_count": {"N": "0"}
}
ITEM

  lifecycle {
    ignore_changes = [item] # Don't reset counter on subsequent applies
  }
}
