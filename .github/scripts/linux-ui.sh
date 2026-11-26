#!/bin/bash
# Prueba de interfaz en Linux: pantalla virtual (Xvfb), clics con xdotool y capturas en shots/.
# Sin gestor de ventanas, la ventana (800x600) queda en la esquina superior izquierda.
#   linux-ui.sh               producto base
#   linux-ui.sh Prioridades   producto con el trait Prioridades
set -u
VARIANT=${1:-base}
OUT=shots/$VARIANT
mkdir -p "$OUT"
export DISPLAY=:99 GDK_BACKEND=x11 GSK_RENDERER=cairo LANG=C.UTF-8 LC_ALL=C.UTF-8
pgrep -x Xvfb >/dev/null || { Xvfb :99 -screen 0 1280x800x24 2>/dev/null & sleep 2; }

TRAITS=()
[ "$VARIANT" != base ] && TRAITS=(--traits "$VARIANT")
swift build --product BookApp "${TRAITS[@]}" || exit 1
BIN="$(swift build --product BookApp "${TRAITS[@]}" --show-bin-path)/BookApp"

# Empezar sin datos guardados: libros y fechas (JSON) y ajustes (UserDefaults).
# En el contenedor de GitHub, $HOME (/github/home) no es la carpeta personal del usuario
# (/root), que es donde guarda Foundation: se borra en las dos.
REAL_HOME="$(getent passwd "$(id -un)" | cut -d: -f6)"
for h in "$HOME" "$REAL_HOME"; do
    rm -f "$h/Documents/books.json" "$h/Documents/due-dates.json" "$h/.config/BookApp.plist"
done
DUE="$REAL_HOME/Documents/due-dates.json"

start() { "$BIN" > "$OUT/app.log" 2>&1 & APP=$!; sleep 5; }
shot()  { import -window root "$OUT/$1.png"; echo "captura: $OUT/$1.png"; }
click() { xdotool mousemove "$1" "$2" click 1; sleep 1; }
alive() { kill -0 $APP 2>/dev/null || { echo "La app se ha cerrado"; cat "$OUT/app.log"; exit 1; }; }
fail()  { echo "FALLO: $1"; cat "$OUT/app.log"; exit 1; }

# Barra lateral (Libros / Ajustes) a la izquierda; la lista, a la derecha.
# Sin fechas, todas las filas tienen la misma altura.
if [ "$VARIANT" = base ]; then FILA3=173; TITULO2=124; else FILA3=172; TITULO2=116; fi

start; alive; shot 1-inicio
click 285 $FILA3;   shot 2-tercera-marcada
click 360 $TITULO2; shot 3-detalle                      # abre «1984»
xdotool key End; xdotool type --delay 60 " hoy"; sleep 1
shot 4-detalle-editado                                  # sigue en el detalle
click 284 161;      shot 4b-detalle-con-fecha           # plugin: «Fecha de vencimiento»
grep -q bookID "$DUE" 2>/dev/null || fail "El plugin no ha guardado la fecha en $DUE"
click 42 26;        shot 5-lista-tras-volver            # Back: la fila muestra «Vence: …»
click 77 106;       shot 6-ajustes                      # Ajustes
click 284 100;      shot 7-sin-fechas                   # Mostrar fechas: no
click 77 74;        shot 8-libros-sin-fechas            # Libros
alive
kill $APP; sleep 1

# Al volver a abrir se conservan los libros, las fechas y los ajustes.
start; alive; shot 9-tras-reiniciar
grep -q bookID "$DUE" || fail "Se ha perdido la fecha al reiniciar"

# Observador: al borrar el libro, el plugin borra su fecha.
xdotool mousemove 360 $TITULO2 click 3; sleep 1; shot 10-menu
click 360 $((TITULO2 + 34));                 shot 11-borrada   # «Eliminar libro», bajo el clic
alive
kill $APP
echo "books.json:     $(cat "$REAL_HOME/Documents/books.json")"
echo "due-dates.json: $(cat "$DUE")"
grep -q "1984" "$REAL_HOME/Documents/books.json" && fail "No se ha borrado el libro"
[ "$(cat "$DUE")" = "[]" ] || fail "El plugin no ha borrado la fecha del libro borrado"
echo "Prueba de Linux superada ($VARIANT)"
