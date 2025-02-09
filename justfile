default:
  @just --list

fmt:
  terraform fmt -recursive -diff
