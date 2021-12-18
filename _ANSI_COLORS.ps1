# SETUP COLOR
$C          = "$([char]27)"
$clear      = "$C[0m"

$fgred      = "$C[38;2;255;0;0m"
$fgGreen    = "$C[38;2;0;255;0m"
$fgWhite    = "$C[38;2;255;255;255m"
$fgYellow   = "$C[38;2;255;255;153m"
$fgBlue     = "$C[38;2;0;128;255m"
$fgViolet   = "$C[38;2;153;153;255m"

$fgdGreen    = "$C[2;3;38;2;0;255;0m"

$hlred      = "$C[7;38;2;255;0;0m"
$hlGreen    = "$C[7;38;2;0;255;0m"
$hlWhite    = "$C[7;38;2;255;255;255m"
$hlYellow   = "$C[7;38;2;255;255;153m"
$hlBlue     = "$C[7;38;2;0;128;255m"
$hlViolet   = "$C[7;38;2;153;153;255m"

$hlbred      = "$C[5;7;38;2;255;0;0m"
$hlbGreen    = "$C[5;7;38;2;0;255;0m"
$hlbYellow   = "$C[5;7;38;2;255;255;153m"

$hldGreen    = "$C[2;7;38;2;0;255;0m"

$CHECK = "$([char]0x2713)"
$XMARK = "$([char]0x2718)"
$WARN = "$([char]0x26A0)"
$SKULL = "$([char]0x2620)"

$Rainbow = @($fgRed, $fgGreen, $fgYellow, $fgBlue, $fgViolet)