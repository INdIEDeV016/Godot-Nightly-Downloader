extends Control

var current_os = OS.get_name()
var download_link = ''
var file_name = ''
var file_name_suffix = 'godot-nightly'
var file_ext = ''
var date = ''
var up_to_date = false

onready var OSSelector = $VBoxContainer2/VBoxContainer/HBoxContainer/OSSelector
onready var SystemSelector = $VBoxContainer2/VBoxContainer/HBoxContainer2/SystemSelector
onready var DownloadButton = $VBoxContainer2/HBoxContainer2/DownloadButton
onready var CancelButton = $VBoxContainer2/HBoxContainer2/VBoxContainer/CancelButton
onready var RetryButton = $VBoxContainer2/HBoxContainer2/VBoxContainer/RetryButton
onready var downloaded = $HBoxContainer3/Downloaded
onready var indicator = $HBoxContainer3/Indicator
onready var total = $HBoxContainer3/Total
onready var progress_bar = $ProgressBar

func _ready():
	match current_os:
		"Windows":
			OSSelector.select(0)
			file_ext = ".zip"
			_disable_arch(false)
		"OSX":
			OSSelector.select(1)
			file_ext = ".dmg"
			_disable_arch(true)
		"X11":
			OSSelector.select(2)
			file_ext = ".AppImage"
			_disable_arch(true)

	# Add the date and extension to the file name to compare to previous versions
	date = OS.get_date(true)
	date = str(date['day']) + '-' + str(date['month']) + '-' + str(date['year'])
	_update_file_name()
	
	$CanvasLayer2/TitleBar.connect("close_dialog", $CanvasLayer/CloseDialog, "popup")
	CancelButton.disabled = true
	
	$ProgressBar.value = 0
	up_to_date = is_up_to_date()
	update_download_link()

func update_progress_bar(value):
	$HBoxContainer3/Indicator.text = String(value) + "%"
	$ProgressBar.value = value
	$HTTPRequest.get_downloaded_bytes()

func is_up_to_date():
	# Check if the daily zip already exists on our system
	var dir = Directory.new()
	if dir.file_exists(OS.get_user_data_dir() + '/' + file_name):
		DownloadButton.text = "Open Directory"
		DownloadButton.disabled = false
		return true
	return false


func update_download_link():
	# Get the proper download link
	if OSSelector.selected == 0:
		download_link = 'https://archive.hugo.pro/builds/godot/master/editor/godot-windows-nightly-x86_64.zip'
		if SystemSelector.selected == 1:
			download_link = 'https://archive.hugo.pro/builds/godot/master/editor/godot-windows-nightly-x86.zip'
	elif OSSelector.selected == 1:
		download_link = 'https://archive.hugo.pro/builds/godot/master/editor/godot-macos-nightly-x86_64.dmg'
	else:
		download_link = 'https://archive.hugo.pro/builds/godot/master/editor/godot-linux-nightly-x86_64.zip'
	
	print('[+] Updating download link: ', download_link)



func _on_AboutButton_pressed():
	$AboutDialog.popup()

func _on_OSSelector_item_selected(ID):
	match ID:
		0:
			file_ext = ".zip"
			_disable_arch(false)
		1:
			file_ext = ".dmg"
			_disable_arch(true)
		2:
			file_ext = ".AppImage"
			_disable_arch(true)
			
	update_download_link()
	update_download_button("Download")


func _disable_arch(_bool):
	SystemSelector.disabled = _bool
	SystemSelector.select(0)

func _on_SystemSelector_item_selected(_ID):
	update_download_link()
	up_to_date = false
	update_download_button("Download")


func update_download_button(text):
	DownloadButton.text = text

func _on_DownloadButton_pressed():
	_update_file_name()
	
	var file_path = "user://" + file_name
	
	if up_to_date:
		# It would be nice to open the downloaded file directly
		# but I've been having a lot of issues doing this so
		# I think that opening the container dir is enough for now
		OS.shell_open(OS.get_user_data_dir())
	else:
		# No file found here so we can go ahead and download
		# the latest version
		CancelButton.disabled = false
		print("[+] Starting download")
		DownloadButton.disabled = true
		DownloadButton.text = "Downloading..."
		# Checking if a previous version exists and removing them
		print(list_files_in_directory(OS.get_user_data_dir()))
		var dir = Directory.new()
		for file in list_files_in_directory(OS.get_user_data_dir()):
			if 'godot-nightly' in file:
				dir.remove('user://' + file)
			
		# Downloading file
		$HTTPRequest.set_download_file(file_path)
		$HTTPRequest.request(download_link)
		print(calculate_bytes($HTTPRequest.get_body_size()))


func _process(_delta):
	var size = 0
	var current = 0
	if $HTTPRequest.get_body_size() != -1:
		size = $HTTPRequest.get_body_size()
		current = $HTTPRequest.get_downloaded_bytes()
		update_progress_bar(current*100/size)
		downloaded.text = calculate_bytes(current)
		total.text = calculate_bytes(size)
		
	if not up_to_date:
		RetryButton.disabled = true
		
	if result == 2:
		$CanvasLayer2/Label2.text = "Can't connect to server"

var result
var response_code
func _on_HTTPRequest_request_completed(_result, _response_code, _headers, _body):
	result = _result
	response_code = _response_code
	# When the zip is downloaded
	print("[+] Download completed ", result, ", ", response_code)
	var cwd = OS.get_user_data_dir()
	if current_os == "Windows":
		# Unzip file
		var uncompressed = OS.execute("unzip.exe", [cwd + '/' + file_name, '-d', cwd], true)
		OS.execute("mv", [cwd + '/godot.exe', cwd + '/godot-nightly.exe'], true)
		up_to_date = is_up_to_date()
		# Open the dir
		OS.shell_open(cwd)
	elif current_os == "X11":
		OS.execute('/usr/bin/chmod', ['+x', cwd + '/' + file_name], false)
		up_to_date = is_up_to_date()
		OS.shell_open(cwd)
	else:
		print('Todo on osx')


func list_files_in_directory(path):
	# By volzhs
	# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files
	
func _update_file_name():
	file_name = file_name_suffix + '-' + date + file_ext


func _on_CancelButton_pressed():
	if not up_to_date:
		reset()
		print("[-] Canceled the current download...")
		DownloadButton.text = "Download again"
		$HTTPRequest.cancel_request()
		update_progress_bar(0)
		DownloadButton.disabled = false


func _on_RetryButton_pressed():
	print("[+] Retrying download...")
	$HTTPRequest.cancel_request()
	$HTTPRequest.request(download_link)
	RetryButton.disabled = true


func calculate_bytes(amount: float) -> String:
	return String().humanize_size(amount).replacen("i", "")


func reset() -> void:
	progress_bar.value = 0
	total.text = "0 B"
	downloaded.text = "0 B"
	indicator.text = "0%"
