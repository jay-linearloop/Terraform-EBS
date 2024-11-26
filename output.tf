output "new_encrypted_volume_id" {
  value = aws_ebs_volume.encrypted_volume.id
}

output "old_volume_id" {
  value = data.aws_ebs_volume.existing_volume.id
}