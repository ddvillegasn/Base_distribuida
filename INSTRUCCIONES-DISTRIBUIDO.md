# Configuración de Base de Datos Distribuida Real

## Pasos para configurar en múltiples computadoras

### 1. Preparación en cada computadora

En **cada una de las 4 computadoras**, necesitas:

1. **Instalar Go**: https://go.dev/download/
2. **Copiar este proyecto** completo a cada PC
3. **Obtener la IP** de cada computadora:
   ```powershell
   ipconfig | Select-String -Pattern "IPv4"
   ```

### 2. Editar el archivo de configuración

Edita el archivo `sharding-distributed.toml` y pon las **IPs reales** de tus computadoras:

```toml
[[shards]]
name = "Pereira"
idx = 0
address = "192.168.1.10:8080"    # IP real de la PC 1

[[shards]]
name = "Bogota"
idx = 1
address = "192.168.1.11:8080"    # IP real de la PC 2

[[shards]]
name = "Medellin"
idx = 2
address = "192.168.1.12:8080"    # IP real de la PC 3

[[shards]]
name = "Cali"
idx = 3
address = "192.168.1.13:8080"    # IP real de la PC 4
```

### 3. Configurar el Firewall

En **cada computadora**, permite el puerto 8080:

```powershell
New-NetFirewallRule -DisplayName "Distributed DB" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

### 4. Ejecutar en cada computadora

**En la Computadora 1 (Pereira):**
```powershell
.\distributedKV.exe --db-location=Pereira.db --http-addr=0.0.0.0:8080 --config-file=sharding-distributed.toml --shard=Pereira
```

**En la Computadora 2 (Bogota):**
```powershell
.\distributedKV.exe --db-location=Bogota.db --http-addr=0.0.0.0:8080 --config-file=sharding-distributed.toml --shard=Bogota
```

**En la Computadora 3 (Medellin):**
```powershell
.\distributedKV.exe --db-location=Medellin.db --http-addr=0.0.0.0:8080 --config-file=sharding-distributed.toml --shard=Medellin
```

**En la Computadora 4 (Cali):**
```powershell
.\distributedKV.exe --db-location=Cali.db --http-addr=0.0.0.0:8080 --config-file=sharding-distributed.toml --shard=Cali
```

**IMPORTANTE:** Usa `0.0.0.0:8080` para que escuche en todas las interfaces de red.

### 5. Probar la base de datos distribuida

Desde **cualquier computadora**, puedes hacer peticiones:

```powershell
# Guardar datos (desde cualquier PC)
curl "http://192.168.1.10:8080/set?key=nombre&value=Juan"

# Obtener datos (desde cualquier PC)
curl "http://192.168.1.10:8080/get?key=nombre"

# El sistema automáticamente redirige al nodo correcto
```

### 6. Verificar que funciona

Cada nodo debe mostrar en consola:
```
2025/11/19 21:30:00 Shard count is 4, current shard: X
```

Donde X es el índice del shard (0, 1, 2, o 3).

---

## Arquitectura

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   PC 1      │    │   PC 2      │    │   PC 3      │    │   PC 4      │
│  Pereira    │◄──►│   Bogota    │◄──►│  Medellin   │◄──►│    Cali     │
│  Shard 0    │    │  Shard 1    │    │  Shard 2    │    │  Shard 3    │
│ 192.168.1.10│    │192.168.1.11 │    │192.168.1.12 │    │192.168.1.13 │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

Cada PC almacena solo una porción de los datos (sharding).
Las peticiones se redirigen automáticamente al nodo correcto según el hash de la clave.
