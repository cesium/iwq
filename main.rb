#!/usr/bin/env ruby

require "image_processing/vips"
require "rqrcode"
require "csv"
require 'tempfile'

CSV.foreach("users.csv", headers: true) do |row|
  qrcode = RQRCode::QRCode.new(row.fetch("uuid"))
  png = qrcode.as_png(
    bit_depth: 1,
    border_modules: 4,
    color_mode: ChunkyPNG::COLOR_GRAYSCALE,
    color: 'white',
    file: nil,
    fill: ChunkyPNG::Color.rgba(0, 0, 0, 0),
    module_px_size: 6,
    resize_exactly_to: false,
    resize_gte_to: false,
    size: 340
  )
  IO.write("qrcodes/#{row.fetch("name")}_#{row.fetch("uuid")}.png", png.to_s)

  text = Vips::Image.text(row.fetch("name"), width: 500, dpi: 500, font: 'Novecento Sans Light')
  overlay = (text.new_from_image [255, 128, 128]).copy interpretation: :srgb
  overlay = overlay.bandjoin text

  ImageProcessing::Vips
    .source("qrcodes/#{row.fetch("name")}_#{row.fetch("uuid")}.png")
    .composite("logo.png",
      gravity: "centre",
    )
    .call(destination: "qrcodes/logo_#{row.fetch("name")}_#{row.fetch("uuid")}.png")

  ImageProcessing::Vips
    .source("back.png")
    .composite("qrcodes/logo_#{row.fetch("name")}_#{row.fetch("uuid")}.png",
      mode: "over",
      gravity: "north",
      offset: [0, 250],
    )
    .composite(overlay,
      mode: "over",
      gravity: "north",
      offset: [0, 170],
    )
    .call(destination: "final/final_#{row.fetch("name")}_#{row.fetch("uuid")}.png")
end
