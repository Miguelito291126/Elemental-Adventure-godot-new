extends Node

@onready var X509_cert_path = "res://Certificated/X509_Certificate.crt"
@onready var X509_key_path = "res://Certificated/X509_Certificate.key"

var CN = "ElementalAdventure"
var O = "Michael2911"
var C = "NL"
var not_before = "20140101000000"
var not_after = "20340101000000"

@onready var load_key = load(X509_key_path)
@onready var load_certs = load(X509_cert_path)
@onready var server_tls_options = TLSOptions.server(load_key, load_certs)
@onready var client_tls_options = TLSOptions.client_unsafe(load_certs)

func _ready():
	var directory = DirAccess
	if directory.dir_exists_absolute("res://Certificated/"):
		pass
	else:
		directory.make_dir_absolute("res://Certificated/")
	
	CreateX509Cert()

	print("Certificated created")

func CreateX509Cert():
	var CNOC = "CN=" + CN + ",O=" + O + ",C=" + C
	var crypto = Crypto.new()
	var crypto_key = crypto.generate_rsa(4096)
	var X509_cert = crypto.generate_self_signed_certificate(crypto_key, CNOC, not_before, not_after)
	X509_cert.save(X509_cert_path)
	crypto_key.save(X509_key_path )
