# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    "Name" = "${var.environment}-vpc"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    "Name" = "${var.environment}-igw"
  }
}

# 퍼블릭 서브넷
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.azs.names)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.azs.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    "Name" = format(
      "${var.environment}-pub-subnet-%s",
      substr(data.aws_availability_zones.azs.names[count.index], -1, 1),
    )
  }
}

# 퍼블릭 서브넷용 라우팅 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    "Name" = "${var.environment}-pub-rtb"
  }
}

# 각각의 퍼블릭 서브넷에 위에서 생성한 라우팅 테이블 연동
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 퍼블릭 서브넷에 연동된 라우팅 테이블에 인터넷 게이트웨이로 가능 경로 추가
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = "0.0.0.0/0"
}

# NAT 게이트웨이에 부여할 EIP
resource "aws_eip" "nat" {
  count = var.create_private_subnet ? 1 : 0

  domain = "vpc"
}

# NAT 게이트웨이
resource "aws_nat_gateway" "this" {
  count = var.create_private_subnet ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    "Name" = "${var.environment}-nat-gw"
  }
}

# 프라이빗 서브넷
resource "aws_subnet" "private" {
  count = var.create_private_subnet ? length(data.aws_availability_zones.azs.names) : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = format(
      "${var.environment}-pri-subnet-%s",
      substr(data.aws_availability_zones.azs.names[count.index], -1, 1),
    )
  }
}

# 프라이빗 서브넷용 라우팅 테이블
resource "aws_route_table" "private" {
  count = var.create_private_subnet ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    "Name" = "${var.environment}-pri-rtb"
  }
}

# 각각의 프라이빗 서브넷에 위에서 생성한 라우팅 테이블 연동
resource "aws_route_table_association" "private" {
  count = var.create_private_subnet ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# 프라이빗 서브넷에 연동된 라우팅 테이블에 NAT 게이트웨이로 가능 경로 추가
resource "aws_route" "nat" {
  count = var.create_private_subnet ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  nat_gateway_id         = aws_nat_gateway.this[0].id
  destination_cidr_block = "0.0.0.0/0"
}

# DB 서브넷
resource "aws_subnet" "db" {
  count = var.create_db_subnet ? length(data.aws_availability_zones.azs.names) : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index + 20)
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = format(
      "${var.environment}-db-subnet-%s",
      substr(data.aws_availability_zones.azs.names[count.index], -1, 1),
    )
  }
}

# DB 서브넷용 라우팅 테이블
resource "aws_route_table" "db" {
  count = var.create_db_subnet ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = {
    "Name" = "${var.environment}-db-rtb"
  }
}

# 각각의 DB 서브넷에 위에서 생성한 라우팅 테이블 연동
resource "aws_route_table_association" "db" {
  count = var.create_db_subnet ? length(aws_subnet.db) : 0

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[0].id
}