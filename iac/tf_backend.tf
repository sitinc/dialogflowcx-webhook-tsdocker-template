terraform {
  backend "gcs" {
    bucket = "mega-kitten-test_tfstate"
    prefix = "terraform/state"
  }
}
