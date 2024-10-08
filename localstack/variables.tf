variable "ec2_instance" {
  type = list(
    object({
      ami_id         = string
      instance_type  = string
      az             = string
      set_public_ip  = bool
      subnet_id      = string
      security_group = list(string)
      tags           = map(string)
      ebs_disks = list(
        object({
          disksize   = number
          encryption = bool
          disktype   = string
          devicename = string
      }))
    })
  )
  default = [
    {
      ami_id        = "ami-02e8cbf7681c3ae51"
      instance_type = "t1.micro"
      az            = "ap-southeast-1"
      set_public_ip = false
      subnet_id     = "subnet-07e73ebcae662e4a3"
      security_group = [
        "dev-node"
      ]
      tags = {
        Name        = "dev-node"
        Environment = "dev"
      }
      ebs_disks = [
        {
          disksize   = 128
          encryption = true
          disktype   = "gp3"
          devicename = "/dev/sdg"
        },
        {
          disksize   = 64
          encryption = false
          disktype   = "gp2"
          devicename = "/dev/sdf"
        }
      ]
    },
    {
      ami_id        = "ami-02e8cbf7681c3ae51"
      instance_type = "t2.micro"
      az            = "ap-southeast-2"
      set_public_ip = false
      subnet_id     = "subnet-3ebcae667e72e4a3"
      security_group = [
        "dev-node"
      ]
      tags = {
        Name        = "dev-node"
        Environment = "dev"
      }
      ebs_disks = [
        {
          disksize   = 128
          encryption = true
          disktype   = "gp3"
          devicename = "/dev/sdf"
        },
        {
          disksize   = 64
          encryption = false
          disktype   = "gp2"
          devicename = "/dev/sdg"
        }
      ]
    },
    {
      ami_id        = "ami-02e8cbf7681c3ae51"
      instance_type = "t3.micro"
      az            = "ap-southeast-3"
      set_public_ip = false
      subnet_id     = "subnet-07e7662e4a3ebcae"
      security_group = [
        "dev-node"
      ]
      tags = {
        Name        = "dev-node"
        Environment = "dev"
      }
      ebs_disks = [
        {
          disksize   = 128
          encryption = true
          disktype   = "gp3"
          devicename = "/dev/sdf"
        },
        {
          disksize   = 64
          encryption = false
          disktype   = "gp2"
          devicename = "/dev/sdg"
        }
      ]
    }
  ]
}

variable "tunnels" {
  type = list(any)
  default = [
    {
      host        = "*.google.com"
      type        = "host"
      address     = "8.8.8.8/32"
      description = "google description"
    },
    {
      host        = "*.example.com"
      type        = "address"
      address     = "0.0.0.0/0"
      description = "example description"
    }
  ]
}

variable "vault_enabled" {
  type    = bool
  default = false
}

variable "consul_enabled" {
  type    = bool
  default = false
}

variable "nomad_enabled" {
  type    = bool
  default = false
}

variable "boundary_enabled" {
  type    = bool
  default = false
}
