#include-once
#include <StaticConstants.au3>
#ignorefunc _getMembers
#forcedef $top, $margin, $left, $column, $row, $members_online

$top = $top + $margin/2
GUICtrlCreateGraphic($left, $top, $column, 1, $SS_GRAYRECT)

$top = $top + $margin/2

$members_label = GUICtrlCreateLabel("Members Online: ", $left, $top, $column, $row)
GUICtrlSetFont($members_label, 8.5, 400 ,0)

If $members_online > 0 Then
   Local $member_string = ""
   Local $members = _getMembers()
   For $i = 1 To UBound($members)-1
	  $member_string &= $members[$i] & ", "
   Next
   $member_string = StringLeft($member_string, StringLen($member_string)-2)
   GUICtrlSetData($members_label, "Members Online: " & $members_online & " " & $member_string)
Else
   GUICtrlSetData($members_label, "Members Online: " & $members_online)
EndIf