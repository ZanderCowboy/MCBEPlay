#include-once
#include <AutoItConstants.au3>
#ignorefunc _log, _BDSBusy, _BDSRollback, _BDSSave, _BDSResponse, _BDSExit, _serverGetTitle, _BDSProcessOutput
#forcedef $session_dir, $error_file, $restart_file, $server_file, $window_title, $rollback, $server, $server_dir, $saved_file

Func _BDSStart()

   Local $function_name = "Start Server"
   _log($function_name & " Function Started", $function_name, False, True)
   Local $iPID

   ; Get timestamp again for new $bds_file
   Global $timestamp = @YEAR&@MON&@MDAY&@HOUR&@MIN&@SEC ; YYYYMMDDHHMMSS
   Global $bds_file = $session_dir & "\bds-" & $timestamp & "[1].txt"

   ; Delete error file if exists
   If FileExists($error_file) Then
	  FileDelete($error_file)
   EndIf

   ; Delete restart file if exists
   If FileExists($restart_file) Then
	  FileDelete($restart_file)
   EndIf

   ; Do a quick check to make sure the bedrock_server.exe process is not running. Somehow this can end up running on it's own
   If ProcessExists($server_file) Then
	  _log("A server process is already running", $function_name, True)
	  $iPID = ProcessExists($server_file)		; Just incase process stays open
	  ProcessClose($iPID)
	  Sleep(300)
	  ;MsgBox(48, "Alert", "A server process is already running")
	  Exit
   EndIf

   ; Send busy signal
   _BDSBusy(True)

   Local $attempt = 1
   Local $result
   Local $rolled_back = False

   While 1

	  _log("Attempting Start Process [" & $attempt & "/3]", $function_name, False, True)
	  $result = _BDSStartProcess()

	  If $result = True Then
		 _log("Start process succesfull", $function_name)
		 ExitLoop
	  EndIf

	  _log("Start process failed", $function_name, True)
	  If $attempt < 3 Then ; If first and second try doesn't work then kill processes and try again
		 WinClose($window_title)
		 WinClose($server_file)
		 $iPID = ProcessExists($server_file)		; Just incase process stays open
		 ProcessClose($iPID)
		 $attempt = $attempt + 1
		 Sleep(300)
		 ContinueLoop
	  EndIf

	  If $rollback = "true" And $rolled_back = False Then ; If 3 tries fail then rollback once
		 _log("Auto rollback system active. Rolling back", $function_name, False, True)
		 $rolled_back = True
		 If _BDSRollback() = True Then
			_BDSSave()
			$attempt = 1
			ContinueLoop
		 EndIf
		 _log("Auto Rollback system failed. Closing Server", $function_name, True)
		 _BDSResponse("Auto rollback system failed Closing server")
		 _BDSExit()
	  Else
		 If $rolled_back Then
			_log("Start failed after rollback. Closing Server", $function_name, True)
			_BDSResponse("Start failed after rollback. Closing server")
		 Else
			_log("Auto rollback system inactive. Closing Server", $function_name, False, True)
			_BDSResponse("Auto rollback system inactive. Closing server")
		 EndIf
		 _BDSExit()
	  EndIf

   WEnd
   ; Remove busy signal
   _BDSBusy(False)

EndFunc

Func _BDSStartProcess()

   Local $function_name = "Start Server Process"

   ; All we're going to do is start the server and loop a read / write command
   Local $cmd = '"' & $server
   #forceref $cmd
   ;Global $PID = Run(@ComSpec & " /K " & $server, $server_dir, @SW_SHOW, $STDIN_CHILD + $STDOUT_CHILD) ; Testing
   Global $PID = Run(@ComSpec & " /K " & $server, $server_dir, @SW_HIDE, $STDIN_CHILD + $STDOUT_CHILD) ; Release
   Sleep(1000) ; !!! sleep !! or process is NOT in the list yet !!

   Local $title = _serverGetTitle($PID)
   WinSetTitle($title, "", $window_title)
   Local $hWnd = WinGetHandle($window_title)
   #forceref $hWnd

   Local $keyword = "Server started."
   Local $services_keyword = "Waiting for Minecraft services"
   Local $keylen = StringLen($keyword)
   #forceref $keylen
   Local $pos
   Local $response
   Local $result
   Local $start_timer = TimerInit()
   Local $last_wait_log = 0
   Local $error_found = False
   Local $logged_services = False
   ; Cold boot / Mojang auth often sits on "Waiting for Minecraft services..." for over 60s.
   Local $start_timeout_ms = 300000

   _log("Wating for Start Response (timeout " & Int($start_timeout_ms / 1000) & "s)", $function_name, False, True)
   While 1

	  $response = _BDSProcessOutput()

	  sleep(250)

	  If $logged_services = False And StringInStr($response, $services_keyword) > 0 Then
		 $logged_services = True
		 _log("BDS is waiting for Minecraft services; keeping process alive", $function_name, False, True)
	  EndIf

	  ;    Find data based on keyword search
	  $pos = StringInStr($response, $keyword, 0, -1)

	  ;    Returns 0 if key not found
	  If $pos > 0 Then
		 $result = "Server started succesfully"
		 _log("Server started succesfully", $function_name, False, True)
		 ExitLoop
	  EndIf

	  If TimerDiff($start_timer) > 5000 And Not ProcessExists($server_file) Then
		 $error_found = True
		 $result = "Server failed to start"
		 _log("bedrock_server.exe exited before Server started.", $function_name, True)
		 ExitLoop
	  EndIf

	  If TimerDiff($start_timer) > $start_timeout_ms Then
		 $error_found = True
		 $result = "Server failed to start"
		 _log("Server failed to start after " & Int(TimerDiff($start_timer) / 1000) & "s", $function_name, True)
		 ExitLoop
	  EndIf

	  If TimerDiff($start_timer) - $last_wait_log >= 30000 Then
		 $last_wait_log = TimerDiff($start_timer)
		 _log("Still waiting for Server started. (" & Int($last_wait_log / 1000) & "s / " & Int($start_timeout_ms / 1000) & "s)", $function_name, False, True)
	  EndIf

   WEnd

   _BDSResponse($result)

   If $error_found = True Then
	  Return False
   EndIf

   ; Create saved file (Because we want the last save time to be the time the server started last)
   ; The server will / should have saved when it was shut down before
   If FileExists($saved_file) Then
	  FileDelete($saved_file)
   EndIf
   Local $oFile = FileOpen($saved_file, 2)
   FileClose($oFile)

   Return True
EndFunc


