
#include-once
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#forcedef $left, $top, $column, $margin

$debug_edit = GUICtrlCreateEdit("", $left, $top, ($column*3)+($margin+2), 100, $ES_READONLY + $WS_VSCROLL)
GUICtrlSetFont($debug_edit, 8.5, 400 ,0, "Lucida Console")
GUICtrlSetBkColor($debug_edit, 0xE9E9E9)
GUICtrlSetLimit($debug_edit, -1)