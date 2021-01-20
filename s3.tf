provider "aws" {
  access_key = "AKIAZYBNCDOFND3OZAIG"
  secret_key = "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"
  region     = "ap-south-1"
}

resource "aws_instance" "myfirstec2" {
    ami = "ami-0a4a70bd98c6d6441"
    instance_type = "t2.micro"
/*                tags {
                    name = "WebServer"
                }
*/
}
