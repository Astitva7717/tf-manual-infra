resource "aws_instance" "ubuntu" {
  ami           = "ami-062df10d14676e201"
  instance_type = "t2.micro"

  tags = {
    Name = "ubuntu"
    SpotInstanceAMIBackup = "yes"
  }
}
