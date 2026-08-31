#include-once
#include <File.au3>
#include <Date.au3>
#ignorefunc _guiWriteToDebug
#forcedef $server_title, $verbose_logging, $log, $gui, $error_log

Func _log($string, $function_name, $error=False, $important=False)

   If Not IsDeclared("script_name") Then
	  $script_name = "Unknown"
   EndIf

   Local $log_data = "[" & $script_name & "] > [" & $server_title & "] > [" & $function_name & "] > "

   If $error = True OR $important = True OR ($important = False AND $verbose_logging = True) Then

	  _FileWriteLog($log, $log_data & $string) ; log
	  If $gui = True Then
		 _guiWriteToDebug(_NowCalc() & " : " & $log_data & $string, False)
	  EndIf

   EndIf
   If $error = True Then
	  _FileWriteLog($error_log, $log_data & $string) ; log
	  If $gui = True Then
		 _guiWriteToDebug(_NowCalc() & " : " & $log_data & $string, True)
	  EndIf
   EndIf

EndFunc