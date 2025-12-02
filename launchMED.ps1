# Script para lanzar el nodo MEDELLIN y su réplica.

# Iniciar nodo principal
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Medellin.db --http-addr=10.1.0.4:8080 --config-file=sharding-distributed.toml --shard=Medellin"

# Iniciar réplica
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Medellin-r.db --http-addr=10.1.0.4:8081 --config-file=sharding-distributed.toml --shard=Medellin --replica"

Write-Host "Se ha iniciado el nodo MEDELLIN y su réplica."
Write-Host "1 nodo principal + 1 replica = 2 procesos en total"