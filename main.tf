# provider "aws" {
#   region = "us-east-1"  # Change to your region
# }

# # Get existing instance details
# data "aws_instance" "existing_instance" {
#   instance_id = var.instance_id
# }
# data "aws_region" "current" {}

# # Get existing volume details
# data "aws_ebs_volume" "existing_volume" {
#   filter {
#     name   = "attachment.instance-id"
#     values = [var.instance_id]
#   }

#   filter {
#     name   = "attachment.device"
#     values = [var.device_name]
#   }
# }

# # Create snapshot of existing volume
# resource "aws_ebs_snapshot" "ebs_snapshot" {
#   volume_id = data.aws_ebs_volume.existing_volume.id
  
#   tags = {
#     Name = "Snapshot-${data.aws_instance.existing_instance.id}"
#   }
# }

# # Create encrypted copy of snapshot
# resource "aws_ebs_snapshot_copy" "encrypted_snapshot" {
#   source_snapshot_id = aws_ebs_snapshot.ebs_snapshot.id
#   source_region     = data.aws_region.current.name
#   encrypted         = true
  
#   tags = {
#     Name = "Encrypted-Snapshot-${data.aws_instance.existing_instance.id}"
#   }
# }

# # Create new encrypted volume
# resource "aws_ebs_volume" "encrypted_volume" {
#   availability_zone = data.aws_instance.existing_instance.availability_zone
#   snapshot_id      = aws_ebs_snapshot_copy.encrypted_snapshot.id
#   encrypted        = true
  
#   tags = {
#     Name = "Encrypted-Volume-${data.aws_instance.existing_instance.id}"
#   }
# }

# # Stop the EC2 instance
# resource "null_resource" "stop_instance" {
#   provisioner "local-exec" {
#     command = "aws ec2 stop-instances --instance-ids ${var.instance_id} && aws ec2 wait instance-stopped --instance-ids ${var.instance_id}"
#   }
# }

# # Detach the existing volume
# resource "null_resource" "detach_volume" {
#   provisioner "local-exec" {
#     command = "aws ec2 detach-volume --volume-id ${data.aws_ebs_volume.existing_volume.id} --instance-id ${var.instance_id} --device ${var.device_name} && sleep 30"
#   }

#   depends_on = [null_resource.stop_instance]
# }

# # Attach new encrypted volume
# resource "null_resource" "attach_volume" {
#   provisioner "local-exec" {
#     command = "aws ec2 attach-volume --volume-id ${aws_ebs_volume.encrypted_volume.id} --instance-id ${var.instance_id} --device ${var.device_name} && sleep 30"
#   }

#   depends_on = [
#     null_resource.detach_volume,
#     aws_ebs_volume.encrypted_volume
#   ]
# }

# # Start the instance
# resource "null_resource" "start_instance" {
#   provisioner "local-exec" {
#     command = "aws ec2 start-instances --instance-ids ${var.instance_id}"
#   }

#   depends_on = [null_resource.attach_volume]
# }

provider "aws" {
  region = "us-east-1"  # Change to your region
}

# Get existing instance details
data "aws_instance" "existing_instance" {
  instance_id = var.instance_id
}

data "aws_region" "current" {}

# Get existing volume details
data "aws_ebs_volume" "existing_volume" {
  filter {
    name   = "attachment.instance-id"
    values = [var.instance_id]
  }

  filter {
    name   = "attachment.device"
    values = [var.device_name]
  }
}

# Create snapshot of existing volume
resource "aws_ebs_snapshot" "ebs_snapshot" {
  volume_id = data.aws_ebs_volume.existing_volume.id
  
  tags = {
    Name = "Snapshot-${data.aws_instance.existing_instance.id}"
  }
}

# Create encrypted copy of snapshot
resource "aws_ebs_snapshot_copy" "encrypted_snapshot" {
  source_snapshot_id = aws_ebs_snapshot.ebs_snapshot.id
  source_region      = data.aws_region.current.name
  encrypted          = true
  
  tags = {
    Name = "Encrypted-Snapshot-${data.aws_instance.existing_instance.id}"
  }
}

# Create new encrypted volume
resource "aws_ebs_volume" "encrypted_volume" {
  availability_zone = data.aws_instance.existing_instance.availability_zone
  snapshot_id       = aws_ebs_snapshot_copy.encrypted_snapshot.id
  encrypted         = true
  
  tags = {
    Name = "Encrypted-Volume-${data.aws_instance.existing_instance.id}"
  }
}

# Stop the EC2 instance
resource "null_resource" "stop_instance" {
  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${var.instance_id} && aws ec2 wait instance-stopped --instance-ids ${var.instance_id}"
  }
}

# Detach the existing volume
resource "null_resource" "detach_volume" {
  provisioner "local-exec" {
    command = "aws ec2 detach-volume --volume-id ${data.aws_ebs_volume.existing_volume.id} --instance-id ${var.instance_id} --device ${var.device_name} && sleep 30"
  }

  depends_on = [null_resource.stop_instance]
}

# Delete the existing volume
resource "null_resource" "delete_volume" {
  provisioner "local-exec" {
    command = "aws ec2 delete-volume --volume-id ${data.aws_ebs_volume.existing_volume.id}"
  }

  depends_on = [null_resource.detach_volume]
}

# Delete the snapshot of the unencrypted EBS volume
resource "null_resource" "delete_unencrypted_snapshot" {
  provisioner "local-exec" {
    command = "aws ec2 delete-snapshot --snapshot-id ${aws_ebs_snapshot.ebs_snapshot.id}"
  }

  depends_on = [aws_ebs_snapshot.ebs_snapshot]
}

# Attach new encrypted volume
resource "null_resource" "attach_volume" {
  provisioner "local-exec" {
    command = "aws ec2 attach-volume --volume-id ${aws_ebs_volume.encrypted_volume.id} --instance-id ${var.instance_id} --device ${var.device_name} && sleep 30"
  }

  depends_on = [
    null_resource.delete_volume,
    aws_ebs_volume.encrypted_volume
  ]
}

# Start the instance
resource "null_resource" "start_instance" {
  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${var.instance_id}"
  }

  depends_on = [null_resource.attach_volume]
}


