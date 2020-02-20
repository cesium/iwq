require "image_processing/vips"
require "rqrcode"
require "csv"
require "tempfile"

FRONTEND_URL = "https://enei.pt/user/"

def gen_credential(base, uuid, name, food, housing)
  text = Vips::Image.text(
    name,
    width: 3900,
    align: :centre,
    dpi: 2400,
    font: "Novecento sans Bold"
  )
  overlay = (text.new_from_image [255, 255, 255]).copy interpretation: :srgb
  overlay = overlay.bandjoin text

  logo = ""
  
  if base == "staff"
    logo = "logos/logo_full_all.png"
  elsif base == "attendee"
    if housing == "Alojamento D. Maria II"
      logo = "logos/logo_full_dona.png"
    elsif housing == "Alojamento Alberto Sampaio"
      logo = "logos/logo_full_esas.png"
    elsif food
      logo = "logos/logo_food.png"
    else
      logo = "logos/logo_nothing.png"
    end
  end

  ImageProcessing::Vips
    .source("base_#{base}.png")
    .composite(logo,  
      mode: "over",          
      gravity: "north-west", 
      offset: [285, 240],
    )
    .composite("qrcodes/logo_#{name}_#{uuid}.png",  
      mode: "over",          
      gravity: "north", 
      offset: [0, 2200],
    )
    .composite(overlay,
      mode: "over",
      gravity: "north",
      offset: [0, 4710],
    )
    .colourspace(:cmyk)
    .call(destination: "final/final_#{name}_#{uuid}.png")
end

def gen_qrcode(uuid, name)
  qrcode = RQRCode::QRCode.new("#{FRONTEND_URL}#{uuid}")
  png = qrcode.as_png(
    bit_depth: 1,
    border_modules: 4,
    color_mode: ChunkyPNG::COLOR_GRAYSCALE,
    color: "white",
    file: nil,
    fill: ChunkyPNG::Color.rgba(0, 0, 0, 0),
    module_px_size: 6,
    resize_exactly_to: false,
    resize_gte_to: false,
    size: 2500
  )
  IO.write("qrcodes/#{name}_#{uuid}.png", png.to_s)

  ImageProcessing::Vips
    .source("qrcodes/#{name}_#{uuid}.png")
    .composite("logo.png",  
      gravity: "centre", 
    )
    .call(destination: "qrcodes/logo_#{name}_#{uuid}.png")
end

CSV.foreach(ARGV[0], headers: true) do |row|
  uuid = row.fetch("uuid")
  name = row.fetch("name").split(" ").values_at(0, -1).join(" ").upcase
  volunteer = row.fetch("volunteer")
  food = row.fetch("food")
  housing = row.fetch("housing")

  gen_qrcode(uuid, name)

  if volunteer
    gen_credential("staff", uuid, name, food, housing)
  else
    gen_credential("attendee", uuid, name, food, housing)
  end
end
