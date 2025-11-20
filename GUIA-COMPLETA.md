# 🗄️ Guía Completa - Base de Datos Distribuida con Sharding

## 📋 ¿Qué es este proyecto?

Es una **base de datos clave-valor distribuida** que reparte los datos entre múltiples computadoras (nodos). Cada nodo almacena solo una parte de los datos, no todo.

---

## 🏗️ Arquitectura y Conceptos

### 1️⃣ **Sharding (Particionamiento)**
Los datos se dividen entre 4 nodos usando un **hash de la clave**:

```
┌─────────────────────────────────────┐
│  Cliente hace: SET nombre=Juan      │
└──────────────┬──────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Hash("nombre") % 4  │  → Resultado: 2
    └──────────┬───────────┘
               │
               ▼
    ┌─────────────────────────────────┐
    │ PC 1    │ PC 2   │ PC 3   │ PC 4│
    │ Mumbai  │ Delhi  │Chennai │Bangl│
    │ Shard 0 │Shard 1 │Shard 2 │Shard│
    │         │        │  ✓     │  3  │
    └─────────────────────────────────┘
           "nombre=Juan" se guarda en Chennai (Shard 2)
```

### 2️⃣ **Redirección Automática**
Si haces una petición a cualquier nodo, él:
1. Calcula qué nodo debe tener esos datos
2. Si NO es él, **redirige** automáticamente al nodo correcto
3. El nodo correcto procesa y devuelve la respuesta

### 3️⃣ **Réplicas (Opcional)**
Cada nodo puede tener una **copia de respaldo** (réplica) que:
- Solo **lee** datos
- Se sincroniza automáticamente con el nodo principal
- Si el principal falla, la réplica puede responder consultas

---

## 🖥️ Configuración de 4 Computadoras

### **Requisitos**
- 4 PCs conectadas a la **misma red WiFi/LAN**
- Cada PC debe tener **Go instalado** (go.dev/download)
- Puerto **8080 abierto** en el firewall

---

## 📝 Instrucciones para tu Equipo

### **PASO 1: Preparación en TODAS las PCs**

Cada persona debe:

1. **Instalar Go** desde https://go.dev/download/
   - Descargar el instalador `.msi` para Windows
   - Instalar con las opciones por defecto
   - Verificar: `go version`

2. **Obtener su IP**:
   ```powershell
   ipconfig | Select-String -Pattern "IPv4"
   ```
   Ejemplo: `192.168.1.10`

3. **Copiar el proyecto** completo a su PC (compartir por USB o Google Drive)

4. **Abrir PowerShell como Administrador** y ejecutar:
   ```powershell
   New-NetFirewallRule -DisplayName "Distributed DB" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
   ```

---

### **PASO 2: Recopilar las IPs**

Anota las IPs de las 4 computadoras:

| Computadora | Nombre Nodo | IP              | Puerto | Responsable  |
|-------------|-------------|-----------------|--------|--------------|
| PC 1        | Mumbai      | 192.168.1.10    | 8080   | Persona A    |
| PC 2        | Delhi       | 192.168.1.11    | 8080   | Persona B    |
| PC 3        | Chennai     | 192.168.1.12    | 8080   | Persona C    |
| PC 4        | Bangalore   | 192.168.1.13    | 8080   | Persona D    |

*(Cambia las IPs por las reales)*

---

### **PASO 3: Editar la Configuración**

**EN TODAS LAS PCs**, editar el archivo `sharding-distributed.toml` con las IPs reales:

```toml
[[shards]]
name = "Mumbai"
idx = 0
address = "192.168.1.10:8080"    # IP de la PC 1
replicas = []

[[shards]]
name = "Delhi"
idx = 1
address = "192.168.1.11:8080"    # IP de la PC 2
replicas = []

[[shards]]
name = "Chennai"
idx = 2
address = "192.168.1.12:8080"    # IP de la PC 3
replicas = []

[[shards]]
name = "Bangalore"
idx = 3
address = "192.168.1.13:8080"    # IP de la PC 4
replicas = []
```

**⚠️ IMPORTANTE:** El archivo debe ser **idéntico** en las 4 PCs.

---

### **PASO 4: Compilar el Proyecto**

**EN TODAS LAS PCs**, abrir PowerShell normal en la carpeta del proyecto:

```powershell
cd "ruta\del\proyecto"
go mod download
go build
```

Esto crea el archivo `distributedKV.exe`

---

### **PASO 5: Ejecutar Cada Nodo**

Cada persona ejecuta **SU nodo** correspondiente:

**📍 En la PC 1 (Mumbai):**
```powershell
.\distributedKV.exe --db-location=Mumbai.db --http-addr=0.0.0.0:8080 --config-file=sharding-distributed.toml --shard=Mumbai
```

**📍 En la PC 2 (Delhi):**
```powershell
.\distributedKV.exe --db-location=Delhi.db --http-addr=0.0.0.0:8080 --config-file=sharding-distributed.toml --shard=Delhi
```

**📍 En la PC 3 (Chennai):**
```powershell
.\distributedKV.exe --db-location=Chennai.db --http-addr=0.0.0.0:8080 --config-file=sharding-distributed.toml --shard=Chennai
```

**📍 En la PC 4 (Bangalore):**
```powershell
.\distributedKV.exe --db-location=Bangalore.db --http-addr=0.0.0.0:8080 --config-file=sharding-distributed.toml --shard=Bangalore
```

**✅ Si funciona**, verás en cada consola:
```
2025/11/19 21:30:00 Shard count is 4, current shard: X
```

---

### **PASO 6: Probar la Base de Datos**

Desde **CUALQUIER PC**, puedes hacer peticiones:

#### **Guardar datos:**
```powershell
# Desde cualquier PC, apunta a CUALQUIER nodo (Mumbai en este ejemplo)
curl "http://192.168.1.10:8080/set?key=nombre&value=Juan"
curl "http://192.168.1.10:8080/set?key=edad&value=25"
curl "http://192.168.1.10:8080/set?key=ciudad&value=Madrid"
```

#### **Leer datos:**
```powershell
curl "http://192.168.1.10:8080/get?key=nombre"
# Respuesta: "Juan"

curl "http://192.168.1.10:8080/get?key=edad"
# Respuesta: "25"
```

#### **Lo que sucede internamente:**
```
1. Haces petición a Mumbai (192.168.1.10)
2. Mumbai calcula: hash("nombre") % 4 = 2
3. Mumbai ve que Shard 2 = Chennai (192.168.1.12)
4. Mumbai redirige automáticamente a Chennai
5. Chennai guarda/obtiene el dato
6. Chennai responde
```

---

## 🧪 Experimentos para Demostrar

### **Experimento 1: Ver la Distribución**
```powershell
# Guardar 10 claves
curl "http://192.168.1.10:8080/set?key=clave1&value=valor1"
curl "http://192.168.1.10:8080/set?key=clave2&value=valor2"
curl "http://192.168.1.10:8080/set?key=clave3&value=valor3"
# ... hasta clave10

# Observar en cada consola qué nodo guardó qué datos
# Los datos se reparten automáticamente entre los 4 nodos
```

### **Experimento 2: Tolerancia a Fallos**
```powershell
# 1. Guardar un dato
curl "http://192.168.1.10:8080/set?key=test&value=funciona"

# 2. Apagar UNA de las PCs (ej: Chennai)

# 3. Intentar leer un dato que estaba en Chennai
curl "http://192.168.1.10:8080/get?key=test"
# Si "test" estaba en Chennai, dará error

# 4. Leer datos de otros nodos (siguen funcionando)
curl "http://192.168.1.10:8080/get?key=clave1"
# Si "clave1" estaba en Mumbai/Delhi/Bangalore, funciona perfectamente
```

### **Experimento 3: Balanceo de Carga**
```powershell
# Hacer peticiones a diferentes nodos
curl "http://192.168.1.10:8080/set?key=a&value=1"  # A Mumbai
curl "http://192.168.1.11:8080/set?key=b&value=2"  # A Delhi
curl "http://192.168.1.12:8080/set?key=c&value=3"  # A Chennai

# Todos redirigen correctamente según el hash
# Observar en las consolas las redirecciones
```

---

## 🔍 Cómo Funciona Internamente

### **Algoritmo de Sharding:**
```go
// En el código (config/config.go)
func (s *Shards) Index(key string) int {
    h := fnv.New64()           // Función hash
    h.Write([]byte(key))       // Hashear la clave
    return int(h.Sum64() % uint64(s.Count))  // Módulo para obtener el shard
}
```

**Ejemplo:**
- `hash("nombre")` = `12847563982765432`
- `12847563982765432 % 4` = `2` → **Shard 2 (Chennai)**

### **Flujo de una petición SET:**
```
Cliente → Nodo A → ¿Es mi shard? 
                    ├─ SÍ → Guardar localmente
                    └─ NO → HTTP Redirect → Nodo B → Guardar
```

### **Archivos importantes:**
- `main.go` - Punto de entrada, parsea argumentos
- `config/config.go` - Lee configuración y calcula sharding
- `db/db.go` - Interactúa con la base de datos local (BoltDB)
- `web/web.go` - Maneja peticiones HTTP y redirecciones
- `replication/replication.go` - Sincroniza réplicas

---

## ❓ Preguntas Frecuentes

**P: ¿Por qué usar `0.0.0.0:8080` en lugar de `127.0.0.1`?**  
R: `0.0.0.0` escucha en TODAS las interfaces de red (permite conexiones externas). `127.0.0.1` solo acepta conexiones locales.

**P: ¿Qué pasa si una PC se desconecta?**  
R: Los datos que estaban en ese nodo NO estarán disponibles, pero el resto del sistema sigue funcionando. Por eso existen las réplicas.

**P: ¿Cómo sé qué datos están en cada nodo?**  
R: Cada nodo crea un archivo `.db` (Mumbai.db, Delhi.db, etc.) con sus datos. El tamaño del archivo indica cuántos datos tiene.

**P: ¿Puedo usar solo 2 o 3 PCs?**  
R: Sí, edita `sharding-distributed.toml` y reduce el número de shards. Pero necesitas al menos 2 para demostrar distribución.

**P: ¿Por qué a veces da error "connection refused"?**  
R: Verifica:
1. Firewall abierto en todas las PCs
2. Todas las PCs ejecutando su nodo
3. IPs correctas en `sharding-distributed.toml`
4. Todas en la misma red WiFi/LAN

---

## 📊 Para la Presentación

**Demuestra:**
1. ✅ **Sharding**: Los datos se reparten entre nodos
2. ✅ **Escalabilidad**: Agregar más nodos distribuye más la carga
3. ✅ **Redirección**: Cualquier nodo puede recibir cualquier petición
4. ✅ **Disponibilidad parcial**: Si cae un nodo, los demás siguen funcionando

**Conceptos técnicos:**
- Consistent Hashing (hash + módulo)
- HTTP redirects (307 Temporary Redirect)
- Key-Value Store (BoltDB)
- Concurrent requests (goroutines de Go)

---

## 🎯 Checklist Final

- [ ] Go instalado en las 4 PCs
- [ ] IPs obtenidas de las 4 PCs
- [ ] `sharding-distributed.toml` editado con IPs reales (IGUAL en todas)
- [ ] Proyecto copiado a las 4 PCs
- [ ] Puerto 8080 abierto en firewall (las 4 PCs)
- [ ] `go build` ejecutado en las 4 PCs
- [ ] Cada nodo ejecutándose en su PC correspondiente
- [ ] Prueba exitosa: `curl "http://IP:8080/set?key=test&value=ok"`
- [ ] Verificación: Los datos se distribuyen entre los 4 nodos

---

**¡Buena suerte con la presentación! 🚀**
