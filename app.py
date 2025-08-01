from flask import Flask, render_template, request, redirect, url_for, flash
from conexion import conectar

app = Flask(__name__)
app.secret_key = 'secreto123'  # Necesario para mostrar mensajes flash

# Ruta principal
@app.route('/')
def index():
    return render_template('index.html')

# Ruta para mostrar clientes
@app.route('/clientes')
def clientes():
    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Clientes")
    datos = cursor.fetchall()
    conn.close()
    return render_template('clientes.html', clientes=datos)

# Ruta para agregar un cliente
@app.route('/agregar_cliente', methods=['POST'])
def agregar_cliente():
    nombre = request.form['nombre']
    apellido = request.form['apellido']
    telefono = request.form['telefono']
    correo = request.form['correo']
    cedula = request.form['cedula']

    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO Clientes (Nombre, Apellido, Telefono, Correo, CedulaID) VALUES (?, ?, ?, ?, ?)",
                   (nombre, apellido, telefono, correo, cedula))
    conn.commit()
    conn.close()
    flash('Cliente agregado correctamente')
    return redirect(url_for('clientes'))

# Ruta para mostrar canchas
@app.route('/canchas')
def canchas():
    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Canchas")
    datos = cursor.fetchall()
    conn.close()
    return render_template('canchas.html', canchas=datos)

# Ruta para agregar una cancha
@app.route('/agregar_cancha', methods=['POST'])
def agregar_cancha():
    nombre = request.form['nombre']
    tipo = request.form['tipo']
    descripcion = request.form['descripcion']
    precio = request.form['precio']
    estado = request.form['estado']

    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO Canchas (Nombre, Tipo, Descripcion, PrecioPorHora, Estado) VALUES (?, ?, ?, ?, ?)",
                   (nombre, tipo, descripcion, precio, estado))
    conn.commit()
    conn.close()
    flash('Cancha agregada correctamente')
    return redirect(url_for('canchas'))

# Ruta para mostrar reservaciones
@app.route('/reservaciones')
def reservaciones():
    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT r.ReservaID, c.Nombre + ' ' + c.Apellido, ca.Nombre, r.Fecha, r.HoraInicio, r.HoraFin, r.Estado
        FROM Reservaciones r
        JOIN Clientes c ON r.CedulaID = c.CedulaID
        JOIN Canchas ca ON r.CanchaID = ca.CanchaID
    """)
    datos = cursor.fetchall()
    conn.close()
    return render_template('reservaciones.html', reservaciones=datos)

# Ruta para agregar una reservación
@app.route('/agregar_reservacion', methods=['POST'])
def agregar_reservacion():
    cedula = request.form['cedula']
    cancha = request.form['cancha']
    fecha = request.form['fecha']
    hora_inicio = request.form['hora_inicio']
    hora_fin = request.form['hora_fin']
    estado = request.form['estado']

    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO Reservaciones (CedulaID, CanchaID, Fecha, HoraInicio, HoraFin, Estado)
        VALUES (?, ?, ?, ?, ?, ?)""",
        (cedula, cancha, fecha, hora_inicio, hora_fin, estado))
    conn.commit()
    conn.close()
    flash('Reservación agregada correctamente')
    return redirect(url_for('reservaciones'))

# Ruta para mostrar pagos
@app.route('/pagos')
def pagos():
    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Pagos")
    datos = cursor.fetchall()
    conn.close()
    return render_template('pagos.html', pagos=datos)

# Ruta para agregar un pago
@app.route('/agregar_pago', methods=['POST'])
def agregar_pago():
    reserva_id = request.form['reserva_id']
    monto = request.form['monto']
    fecha_pago = request.form['fecha_pago']
    metodo = request.form['metodo']
    estado = request.form['estado']

    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO Pagos (ReservaID, MontoPagado, FechaPago, MetodoPago, EstadoPago)
        VALUES (?, ?, ?, ?, ?)""",
        (reserva_id, monto, fecha_pago, metodo, estado))
    conn.commit()
    conn.close()
    flash('Pago registrado correctamente')
    return redirect(url_for('pagos'))

if __name__ == '__main__':
    app.run(debug=True)



