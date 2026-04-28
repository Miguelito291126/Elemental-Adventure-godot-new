extends Control

@onready var label = $"../Label"
@onready var list = $List
const TIMEOUT = 3.0

var Serverinfo: PackedScene = preload("res://Scenes/server_info.tscn")

func _ready():
	Network.serverbrowser = self;

	Network.http.request_completed.connect(OnRequestCompleted);

	var cleanTimer = Timer.new();
	# CAMBIO: 5 segundos para que de tiempo a hacer clic sin que la lista desaparezca
	cleanTimer.wait_time = 1.0 
	cleanTimer.autostart = true
	cleanTimer.timeout.connect(RefreshServerList); 
	add_child(cleanTimer, true);

func RefreshServerList():
	Network.http.request(Network.masterServerUrl + "/list/elemental_adventure");

func  OnRequestCompleted(result, responseCode, headers, body):
	if (responseCode != 200): return;

	var json_string = body.get_string_from_utf8();
	var json_data = JSON.parse_string(json_string)

	if json_data == null or not (json_data is Array):
		print("Error: El servidor no devolvió una lista válida.")
		return

	# Limpiar lista visual
	for n in list.get_children():
		n.queue_free()
		
	for serverData in json_data:
		if not (serverData is Dictionary):
				continue
		
		var currentinfo = Serverinfo.instantiate();
		
		# CORRECCIÓN DE DATOS: Aseguramos que el puerto sea string limpio
		currentinfo.ip_public_Change = str(serverData["public_ip"]);
		currentinfo.ip_local_Change = str(serverData["local_ip"]);
		# Usamos Mathf.Floor para quitar el ".0" si es que viene de Python como float
		var portInt = str_to_var(str(serverData["port"])); 
		currentinfo.port_Change = str(portInt);

		var playersFloat = str_to_var(str(serverData["players"]));
		var playersInt = floor(playersFloat); # Convertimos 1.0 a 1

		currentinfo.get_node("Name").text = str(serverData["name"]) + " - ";;
		currentinfo.get_node("Players").text = str(playersInt) + " - ";;

		# CONEXIÓN MANUAL: Esto asegura que el click funcione
		var btn = currentinfo.get_node("Join"); # Asegúrate que el nombre sea "Button" en tu escena
		btn.pressed.connect(currentinfo.join_server);

		list.add_child(currentinfo);
		
	
