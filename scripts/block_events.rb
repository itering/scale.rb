require "scale"


client = SubstrateClient.new("ws://127.0.0.1:9944/")
client.init
metadata = client.get_metadata nil

the_module = metadata.get_module("CertificateModule")
puts ""
puts "CertificateModule calls:"
puts "---------------------------------------"
puts the_module[:calls]

the_call = metadata.get_module_call("CertificateModule", "create_entity")
puts ""
puts "create_entity call:"
puts "---------------------------------------"
puts the_call


puts ""
puts "CertificateModule storages:"
puts "---------------------------------------"
puts the_module[:storage][:items]

# Scale::TypeRegistry.instance.metadata = metadata.value
# puts metadata.value.event_index["0400"][1]
# puts metadata.value.event_index["0401"][1]
# puts metadata.value.event_index["0402"][1]
# hex_events = "0x0c000000000000001027000001010000010000000400be07e2c28688db5368445c33d32b3c7bcad15dab1ec802ba8cccc1c22b86574f6992da89ff412eaf9bafac4024ca23eea8c988a437fc96a1c6445148a8ebb4d2000001000000000010270000000100"
# scale_bytes = Scale::Bytes.new(hex_events)
# Scale::Types.get("Vec<EventRecord>").decode(scale_bytes).value.each do |er|
#   puts er.value
# end