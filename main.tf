provider "aws" {
  region = "eu-central-1"
  shared_credentials_file = "~/.aws/credenitals"
}
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id=aws_subnet.main.id
  route_table_id =aws_route_table.default.id
}


resource "aws_instance" "nginx" {
  subnet_id = aws_subnet.main.id
  ami           = "ami-005b8739bcc8cf104"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}",]
  key_name = "ted"

  connection {
        agent = false
        type     = "ssh"
        user     = "bitnami"
        private_key = file("./ted.pem")
        host = self.public_ip   
        }

  

  provisioner "file" {
    source      = "./app/src/main/resources/static"
    destination = "~/static"
  }

  provisioner "file" {
    source      = "./nginx.conf"
    destination = "~/nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i 's/tedapp/${aws_instance.example.private_ip}/g' ~/nginx.conf",
      "sudo mv ~/nginx.conf /opt/bitnami/nginx/conf",
    ]
  }

  tags = {
    Name = "nginx"
  }
}

resource "aws_instance" "example" {
  subnet_id = aws_subnet.main.id
  ami           = "ami-0c115dbd34c69a004"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}",]
  key_name = "ted"

  tags = {
    Name = "app"
  }

    connection {
        agent = false
        type     = "ssh"
        user     = "ec2-user"
        private_key = file("./ted.pem")
        host = self.public_ip   
        }
    
    provisioner "file" {
      source      = "./app/target"
      destination = "/tmp"
    }
    provisioner "file" {
      source      = "./app/application.properties"
      destination = "/tmp/target/application.properties"
    }
    provisioner "remote-exec" {
      inline = [
        #"sudo rm -f /var/run/yum.pid 20360",
        "sudo yum update -y",
        "sudo yum install java -y",
        "chmod 700 /tmp/target/embedash-1.1-SNAPSHOT.jar ",
        "echo 'memcached.cache.servers: ${aws_instance.memcache.2.private_ip}:11211, ${aws_instance.memcache.0.private_ip}:11211, ${aws_instance.memcache.1.private_ip}:11211' >> /tmp/target/application.properties",
        "nohup java -jar /tmp/target/embedash-1.1-SNAPSHOT.jar --spring.config.location=/tmp/target/application.properties &",
        "sleep 5"
        
      ]
    }

}


resource "aws_instance" "memcache" {
  subnet_id = aws_subnet.main.id
  ami           ="ami-027aa2d9ec85953e1"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.memcache.id}",]
  key_name = "ted"
  count = 3

  tags = {
    Name = "memcache"
  }


}

resource "aws_security_group" "instance" {
  vpc_id       = aws_vpc.main.id
  name = "my_first_terraform"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0",]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0",]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0",]
  }
  ingress {
    from_port   = 9191
    to_port     = 9191
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0",]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "memcache" {
  vpc_id       = aws_vpc.main.id
  name = "memcache"
  ingress {
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0",]
  }
}

