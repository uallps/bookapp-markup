# Prueba de interfaz en Windows: arranca la app, pulsa los controles y guarda
# capturas y la lista de controles en shots/.
# Los textos son controles Static (se buscan por texto); los botones con estilo
# los dibuja SwiftOpenUI (Direct2D). La ventana se coloca siempre en (0,0) con 900x700.
. "$PSScriptRoot/ui.ps1"
$bin = swift build --product BookApp --show-bin-path

function Count-Text([string]$text) { @(Get-Controls $w | Where-Object { $_.Text -eq $text }).Count }
function Count-Like([string]$pattern) { @(Get-Controls $w | Where-Object { $_.Text -like $pattern }).Count }

# Clic en el botón de marcar de una fila: el botón pequeño (24 px) a la izquierda del título.
function Click-Toggle([string]$title) {
    $c = Get-Controls $w | Where-Object { $_.Text -eq $title } | Select-Object -First 1
    if (-not $c) { throw "No hay una fila '$title'" }
    $b = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUICustomButton" -and $_.W -le 32 -and $_.X -lt $c.X } |
        Sort-Object { [math]::Abs(($_.Y + $_.H / 2) - ($c.Y + $c.H / 2)) } | Select-Object -First 1
    if (-not $b) { throw "No hay botón de marcar junto a '$title'" }
    Click-At ($b.X + [int]($b.W / 2)) ($b.Y + [int]($b.H / 2))
}

# Clic en una opción de la barra lateral: el texto más a la izquierda con ese nombre
# (el título de la pantalla también puede llamarse igual).
function Click-Sidebar([string]$text) {
    $c = Get-Controls $w | Where-Object { $_.Text -eq $text -or $_.Text -like "* $text" } |
        Sort-Object X | Select-Object -First 1
    if (-not $c) { return $false }
    Click-At ($c.X + [int]($c.W / 2)) ($c.Y + [int]($c.H / 2))
    return $true
}

# Fichero de fechas del plugin DueDate (la carpeta Documentos del usuario).
$due = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'due-dates.json'
function Due-Text { if (Test-Path $due) { (Get-Content $due -Raw).Trim() } else { "" } }

$app = Start-App "$bin\BookApp.exe" "bookapp"
if ($app.HasExited) { throw "La app se ha cerrado al arrancar" }
$w = Get-AppWindow $app.Id
Snap $w "1-inicio"
if ((Count-Text "El Quijote") -ne 1) { throw "No se ve la lista de libros" }

# Marcar desde la fila no abre el detalle.
Click-Toggle "Clean Code"; Snap $w "2-tercera-marcada"
if ((Count-Text "Clean Code") -ne 1) { throw "Al marcar la fila se ha salido de la lista" }

# Detalle: escribir no debe volver a la lista (fallo de SwiftOpenUI con @Observable, ya arreglado).
if (-not (Click-Text $w "1984")) { throw "No está la fila 1984" }
Snap $w "3-detalle"
if (-not (Click-Class $w "Edit")) { throw "El detalle no tiene campo de título" }
Send-Text "{END} hoy"; Snap $w "4-detalle-editado"
if (-not (Click-Class $w "Edit")) { throw "Al escribir se ha salido del detalle" }
# Plugin DueDate: poner una fecha desde el detalle.
if ((Count-Like "Vence:*") -ne 0) { throw "Al empezar no debería haber fechas" }
if (-not (Click-Text $w "Fecha de vencimiento")) { throw "El detalle no tiene el interruptor del plugin" }
Snap $w "4b-detalle-con-fecha"
if ((Due-Text) -notlike "*bookID*") { throw "El plugin no ha guardado la fecha: '$(Due-Text)'" }
if (-not (Click-Text $w "← Back")) { if (-not (Click-Text $w "Back")) { throw "No hay botón para volver" } }
Snap $w "5-lista-tras-volver"
if ((Count-Text "1984 hoy") -ne 1) { throw "La lista no muestra el título editado" }

# Ajustes: apagar las fechas y comprobarlo en la lista.
if ((Count-Like "Vence:*") -ne 1) { throw "La fila debería mostrar la fecha puesta en el detalle" }
if (-not (Click-Sidebar "Ajustes")) { throw "No está Ajustes en la barra lateral" }
Snap $w "6-ajustes"
if (-not (Click-Text $w "Mostrar fechas de vencimiento")) { throw "No está el ajuste de fechas" }
Snap $w "7-sin-fechas"
if (-not (Click-Sidebar "Libros")) { throw "No está Libros en la barra lateral" }
Snap $w "8-libros-sin-fechas"
if ((Count-Like "Vence:*") -ne 0) { throw "Con el ajuste apagado no debería verse ninguna fecha" }

# Al volver a abrir se conservan los libros y los ajustes.
Stop-Process -Id $app.Id -Force; Start-Sleep -Seconds 2
$app = Start-App "$bin\BookApp.exe" "bookapp2"
if ($app.HasExited) { throw "La app se ha cerrado al volver a abrirla" }
$w = Get-AppWindow $app.Id
Snap $w "9-tras-reiniciar"
if ((Count-Text "1984 hoy") -ne 1) { throw "No se ha conservado el título editado" }
if ((Count-Like "Vence:*") -ne 0) { throw "No se ha conservado el ajuste de fechas" }
if ((Due-Text) -notlike "*bookID*") { throw "Se ha perdido la fecha al reiniciar" }

# Observador: al borrar el libro con el menú contextual, el plugin borra su fecha.
if (-not (Click-Text $w "1984 hoy" -Right)) { throw "No está la fila para borrar" }
Snap $w "10-menu"
Send-Text "{DOWN}{ENTER}"; Snap $w "11-borrada"
if ((Count-Text "1984 hoy") -ne 0) { throw "No se ha borrado el libro" }
Write-Host "due-dates.json: $(Due-Text)"
if ((Due-Text) -ne "[]") { throw "El plugin no ha borrado la fecha del libro borrado" }

Stop-Process -Id $app.Id -Force
Write-Host "Prueba de Windows superada"
