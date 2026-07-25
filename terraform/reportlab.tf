resource "aws_lambda_layer_version" "reportlab" {
  filename   = "${path.module}/../layers/reportlab/reportlab-layer.zip"
  layer_name = "reportlab-layer"

  compatible_runtimes = [
    "python3.12"
  ]

  compatible_architectures = [
    "x86_64"
  ]

  source_code_hash = filebase64sha256(
    "${path.module}/../layers/reportlab/reportlab-layer.zip"
  )
}