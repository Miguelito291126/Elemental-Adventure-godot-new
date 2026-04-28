extends Control

@onready var list = $List
const TIMEOUT = 3.0

var Serverinfo: PackedScene = preload("res://Scenes/server_info.tscn")

func _ready():
	Network.serverbrowser = self
	Network.http.request_completed.connect(OnRequestCompleted)

	var cleanTimer = Timer.new()
	# Aumentamos a 3 o 5 segundos para no saturar y permitir clics estables
	cleanTimer.wait_time = 1.0 
	cleanTimer.autostart = true
	cleanTimer.timeout.connect(RefreshServerList)
	add_child(cleanTimer)
	
	RefreshServerList() # Primera carga

func RefreshServerList():
	# Evitar peticiones si la anterior no ha terminado (opcional pero recomendado)
	Network.http.request(Network.masterServerUrl + "/list/natural_disaster_game")

func OnRequestCompleted(result, responseCode, headers, body):
	if (responseCode != 200): 
		Network.print_role("Error en Master Server: " + responseCode)
		return

	var json_string = body.get_string_from_utf8()
	var json_data = JSON.parse_string(json_string)

	if json_data == null or not (json_data is Array):
		return

	# Limpiar lista visual de forma segura
	for n in list.get_children():
		n.queue_free()
		
	for serverData in json_data:
		if not (serverData is Dictionary):
			continue
		
		var currentinfo = Serverinfo.instantiate()
		
		# 1. Extraer datos con seguridad .get() para evitar crashes
		var p_ip = str(serverData.get("public_ip", ""))
		var l_ip = str(serverData.get("local_ip", ""))
		var raw_port = serverData.get("port", 4444)
		var raw_players = serverData.get("players", 0)
		var s_name = str(serverData.get("game_id", "Server")) # O "name" según tu Python

		# 2. Corregir tipos (convertir floats de Python a Int y luego a String)
		currentinfo.ip_public_Change = p_ip
		currentinfo.ip_local_Change = l_ip
		currentinfo.port_Change = str(int(raw_port)) # Quita el .0

		# 3. Asignar textos a la UI
		# Usamos find_node o comprobamos si existe para evitar errores de rastreo
		if currentinfo.has_node("Name"):
			currentinfo.get_node("Name").text = s_name + " - "
		
		if currentinfo.has_node("Players"):
			currentinfo.get_node("Players").text = str(int(raw_players)) + " Jugadores"

		# 4. Conectar el botón de unirse
		var btn = currentinfo.get_node_or_null("Join")
		if btn:
			# Si el botón ya tiene una conexión en la escena, esto la duplica, 
			# pero al ser instanciado desde cero está bien.
			if not btn.pressed.is_connected(currentinfo.join_server):
				btn.pressed.connect(currentinfo.join_server)

		list.add_child(currentinfo)