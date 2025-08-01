-- SCRIPT PARA SISTEMA DE RESERVA DE CANCHAS
-- Autor: JJMRG
-- Base de Datos: ReservasCanchas
-- Crear usuario
USE master;
GO
 -- Asegurar que estás en la base de datos correcta
USE ReservasCanchas;
GO

-- Agregar el usuario al rol db_owner (permiso total en la base de datos)
ALTER ROLE db_owner ADD MEMBER admin;
GO



-- Crear login a nivel servidor
CREATE LOGIN admin WITH PASSWORD = 'admin123';
GO

-- Cambiar a la base de datos
USE ReservasCanchas;
GO

-- Crear usuario dentro de la base de datos
CREATE USER admin FOR LOGIN admin;
GO



-- Asignar permisos de lectura, escritura y ejecución
EXEC sp_addrolemember 'db_datareader', 'admin';
EXEC sp_addrolemember 'db_datawriter', 'admin';
EXEC sp_addrolemember 'db_executor', 'admin';
GO


-- 1. CREAR BASE DE DATOS
CREATE DATABASE ReservasCanchas;
GO

USE ReservasCanchas;
GO

-- 2. TABLAS

-- Tabla Clientes
CREATE TABLE Clientes (
    CedulaID INT PRIMARY KEY,
    Nombre NVARCHAR(50),
    Apellido NVARCHAR(50),
    Telefono NVARCHAR(20),
    Correo NVARCHAR(100)
);
GO

-- Tabla Canchas
CREATE TABLE Canchas (
    CanchaID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(50),
    Tipo NVARCHAR(20),
    Descripcion NVARCHAR(200),
    PrecioPorHora DECIMAL(10,2),
    Estado NVARCHAR(20)
);
GO

-- Tabla Reservaciones (sin cálculo MontoTotal, se mueve a la vista)
CREATE TABLE Reservaciones (
    ReservaID INT PRIMARY KEY IDENTITY(1,1),
    CedulaID INT,
    CanchaID INT,
    Fecha DATE,
    HoraInicio TIME,
    HoraFin TIME,
    Estado NVARCHAR(20),
    FOREIGN KEY (CedulaID) REFERENCES Clientes(CedulaID),
    FOREIGN KEY (CanchaID) REFERENCES Canchas(CanchaID)
);
GO

-- Tabla Pagos
CREATE TABLE Pagos (
    PagoID INT PRIMARY KEY IDENTITY(1,1),
    ReservaID INT,
    FechaPago DATE,
    MontoPago DECIMAL(10,2),
    MetodoPago NVARCHAR(30),
    EstadoPago NVARCHAR(20),
    FOREIGN KEY (ReservaID) REFERENCES Reservaciones(ReservaID)
);
GO

-- 3. ÍNDICE
CREATE INDEX IDX_FechaPago ON Pagos (FechaPago);
GO

-- 4. TRIGGERS

-- Evitar reserva doble
CREATE TRIGGER trg_EvitarReservaDoble
ON Reservaciones
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Reservaciones r ON i.CanchaID = r.CanchaID AND i.Fecha = r.Fecha
        WHERE i.HoraInicio < r.HoraFin AND i.HoraFin > r.HoraInicio
    )
    BEGIN
        RAISERROR('⚠️ La cancha ya está reservada en ese horario.', 16, 1);
        RETURN;
    END
    ELSE
    BEGIN
        INSERT INTO Reservaciones (CedulaID, CanchaID, Fecha, HoraInicio, HoraFin, Estado)
        SELECT CedulaID, CanchaID, Fecha, HoraInicio, HoraFin, Estado FROM inserted;
    END
END;
GO

-- Validar estado de pago
CREATE TRIGGER trg_ValidarEstadoPago
ON Pagos
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE EstadoPago NOT IN ('Pagado', 'Pendiente', 'Cancelado')
    )
    BEGIN
        RAISERROR('⚠️ EstadoPago inválido. Use: Pagado, Pendiente, o Cancelado.', 16, 1);
        ROLLBACK;
    END
END;
GO

-- 5. VISTAS

-- Vista reservaciones con MontoTotal calculado
CREATE VIEW Vista_Reservaciones AS
SELECT 
    r.ReservaID,
    c.Nombre + ' ' + c.Apellido AS Cliente,
    ca.Nombre AS Cancha,
    r.Fecha,
    r.HoraInicio,
    r.HoraFin,
    DATEDIFF(HOUR, r.HoraInicio, r.HoraFin) * ca.PrecioPorHora AS MontoTotal,
    r.Estado
FROM Reservaciones r
JOIN Clientes c ON r.CedulaID = c.CedulaID
JOIN Canchas ca ON r.CanchaID = ca.CanchaID;
GO

-- Vista pagos
CREATE VIEW Vista_Pagos AS
SELECT 
    p.PagoID,
    r.ReservaID,
    p.FechaPago,
    p.MontoPago,
    p.MetodoPago,
    p.EstadoPago
FROM Pagos p
JOIN Reservaciones r ON p.ReservaID = r.ReservaID;
GO

-- Vista canchas disponibles
CREATE VIEW Vista_CanchasDisponibles AS
SELECT 
    CanchaID,
    Nombre,
    Tipo,
    Estado
FROM Canchas
WHERE Estado = 'Disponible';
GO

-- 6. PROCEDIMIENTOS

-- Insertar cliente
CREATE PROCEDURE sp_InsertarCliente
    @CedulaID INT,
    @Nombre NVARCHAR(50),
    @Apellido NVARCHAR(50),
    @Telefono NVARCHAR(20),
    @Correo NVARCHAR(100)
AS
BEGIN
    INSERT INTO Clientes VALUES (@CedulaID, @Nombre, @Apellido, @Telefono, @Correo);
END;
GO

-- Insertar pago
CREATE PROCEDURE sp_InsertarPago
    @ReservaID INT,
    @FechaPago DATE,
    @MontoPago DECIMAL(10,2),
    @MetodoPago NVARCHAR(30),
    @EstadoPago NVARCHAR(20)
AS
BEGIN
    INSERT INTO Pagos (ReservaID, FechaPago, MontoPago, MetodoPago, EstadoPago)
    VALUES (@ReservaID, @FechaPago, @MontoPago, @MetodoPago, @EstadoPago);
END;
GO

-- Eliminar pago
CREATE PROCEDURE sp_EliminarPago
    @PagoID INT
AS
BEGIN
    DELETE FROM Pagos WHERE PagoID = @PagoID;
END;
GO

-- Actualizar estado reserva
CREATE PROCEDURE sp_ActualizarEstadoReserva
    @ReservaID INT,
    @NuevoEstado NVARCHAR(20)
AS
BEGIN
    UPDATE Reservaciones SET Estado = @NuevoEstado WHERE ReservaID = @ReservaID;
END;
GO

-- 7. INSERCIONES DE PRUEBA
EXEC sp_InsertarCliente 101, 'Luis', 'Ramírez', '8888-0000', 'lramirez@email.com';
GO

INSERT INTO Canchas (Nombre, Tipo, Descripcion, PrecioPorHora, Estado)
VALUES ('Cancha Principal', '5v5', 'Sintética techada', 2000, 'Disponible');
GO

INSERT INTO Reservaciones (CedulaID, CanchaID, Fecha, HoraInicio, HoraFin, Estado)
VALUES (101, 1, '2025-08-05', '18:00', '20:00', 'Reservada');
GO

EXEC sp_InsertarPago 1, '2025-08-05', 4000, 'Efectivo', 'Pagado';
GO
