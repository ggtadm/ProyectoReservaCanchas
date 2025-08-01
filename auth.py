from flask import Blueprint, render_template, request, redirect, url_for, flash
from werkzeug.security import check_password_hash
from flask_login import login_user, logout_user, login_required, UserMixin
from conexion import conectar

auth = Blueprint('auth', __name__)

# Clase para representar al usuario logueado
class Usuario(UserMixin):
    def __init__(self, id, nombre, correo, rol):
        self.id = id
        self.nombre = nombre
        self.correo = correo
        self.rol = rol

    def get_id(self):
        return str(self.id)  # Flask-Login requiere que el ID sea string

# Mostrar formulario de login
@auth.route('/login')
def login():
    return render_template('login.html')

# Procesar login
@auth.route('/login', methods=['POST'])
def login_post():
    correo = request.form['correo']
    contrasena = request.form['contrasena']

    conn = conectar()
    cursor = conn.cursor()
    cursor.execute("SELECT UsuarioID, Nombre, Correo, Contrasena, Rol FROM Usuarios WHERE Correo = ?", (correo,))
    usuario = cursor.fetchone()
    conn.close()

    if usuario:
        usuario_id, nombre, correo_bd, contrasena_bd, rol = usuario
        if contrasena == contrasena_bd:  # 🔐 Mejor reemplazar con check_password_hash(contrasena_bd, contrasena)
            user = Usuario(usuario_id, nombre, correo_bd, rol)
            login_user(user)
            flash("✅ Inicio de sesión exitoso")
            return redirect(url_for('index'))
        else:
            flash("❌ Contraseña incorrecta")
    else:
        flash("❌ Usuario no encontrado")

    return redirect(url_for('auth.login'))

# Cerrar sesión
@auth.route('/logout')
@login_required
def logout():
    logout_user()
    flash("⛔ Sesión cerrada correctamente")
    return redirect(url_for('auth.login'))
