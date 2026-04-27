variable "tenancy_ocid" {
  description = "OCID tenancy Oracle Cloud"
}

variable "user_ocid" {
  description = "OCID usera OCI"
}

variable "fingerprint" {
  description = "Fingerprint klucza API OCI"
}

variable "private_key_path" {
  description = "Ścieżka do pliku PEM klucza API OCI"
}

variable "region" {
  description = "Region OCI, np. eu-frankfurt-1"
}

variable "github_token" {
  description = "GitHub PAT do rejestracji runnerów"
  sensitive   = true
}

variable "github_repo" {
  description = "Repo w formacie org/repo, np. dariusz-org/bobr-agent"
}

variable "bastion_allowed_cidr" {
  description = "CIDR dopuszczony do sesji Bastion (Twoje IP lub 0.0.0.0/0)"
  default     = "0.0.0.0/0"
}

variable "ssh_public_key" {
  description = "Publiczny klucz SSH do instancji (zawartość .pub)"
}
