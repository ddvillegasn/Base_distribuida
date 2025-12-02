# Script para lanzar el nodo PEREIRA y su réplica.

# Iniciar nodos principales
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Pereira.db --http-addr=127.0.0.2:8080 --config-file=sharding-distributed.toml --shard=Pereira"

# Iniciar réplicas
# Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Pereira-r.db --http-addr=127.0.0.22:8080 --config-file=sharding.toml --shard=Pereira --replica"

Write-Host "Se ha iniciado el nodo PEREIRA y su réplica."
Write-Host "1 nodo principal + 1 replica = 2 procesos en total"
